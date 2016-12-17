

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS-2/COPY-LINES-WITH-PULL-STREAM'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
$split                    = require 'pull-split'
$stringify                = require 'pull-stringify'
$utf8                     = require 'pull-utf8-decoder'
pull                      = require 'pull-stream'
### NOTE these two are different: ###
# $pass_through             = require 'pull-stream/throughs/through'
through                   = require 'pull-through'
async_map                 = require 'pull-stream/throughs/async-map'
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
O                         = {}
O.pass_through_count      = 100
O.pass_through_async      = no
#...........................................................................................................
TAP                       = require 'tap'


#-----------------------------------------------------------------------------------------------------------
$ = ( method ) ->
  switch arity = method.length
    when 2 then null
    else throw new Error "method arity #{arity} not implemented"
  #.........................................................................................................
  # queue = null
  #.........................................................................................................
  on_data = ( data ) ->
    ### TAINT constructs a new single-use function for each data item ###
    send = ( data ) => @queue data
    method data, send
  #.........................................................................................................
  R = through on_data
    # @queue null
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
TAP.test "performance regression", ( T ) ->

  #---------------------------------------------------------------------------------------------------------
  input_stream              = FS.createReadStream   PATH.resolve __dirname, '../../test-data/ids.txt'
  output_stream             = FS.createWriteStream  PATH.resolve __dirname, '../../test-data/ids-copy.txt'

  #---------------------------------------------------------------------------------------------------------
  pipeline                  = []
  push                      = pipeline.push.bind pipeline
  t0                        = null
  t1                        = null
  item_count                = 0

  #---------------------------------------------------------------------------------------------------------
  input_stream.on 'open', ->
    t0 = Date.now()
    # help "input_stream: open"

  #---------------------------------------------------------------------------------------------------------
  output_stream.on 'close', ->
    t1              = Date.now()
    dts             = ( t1 - t0 ) / 1000
    dts_txt         = format_float dts
    item_count_txt  = format_integer item_count
    ips             = item_count / dts
    ips_txt         = format_float ips
    help PATH.basename __filename
    help "pass-through count: #{O.pass_through_count}"
    help "#{item_count_txt} items; dts: #{dts_txt}, ips: #{ips_txt}"
    T.pass "looks good"
    T.end()

  #---------------------------------------------------------------------------------------------------------
  $count              = -> pull.map      ( line    ) -> item_count += +1; return line
  $trim               = -> pull.map      ( line    ) -> line.trim()
  $filter_empty       = -> pull.filter   ( line    ) -> line.length > 0
  $filter_comments    = -> pull.filter   ( line    ) -> not line.startsWith '#'
  $split_fields       = -> pull.map      ( line    ) -> line.split '\t'
  $select_fields      = -> pull.map      ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
  $filter_incomplete  = -> pull.filter   ( fields  ) -> [ a, b, ] = fields; return a? or b?
  $as_text            = -> pull.map      ( fields  ) -> JSON.stringify fields
  $as_line            = -> pull.map      ( line    ) -> line + '\n'

  #---------------------------------------------------------------------------------------------------------
  if O.pass_through_async
    $pass = ->
      return async_map ( data, handler ) ->
        setImmediate ->
          handler null, data
  else
    $pass = -> pull.map ( line ) -> line

  #---------------------------------------------------------------------------------------------------------
  $input = -> STPS.source input_stream

  #---------------------------------------------------------------------------------------------------------
  $output = ->
    return STPS.sink output_stream, ( error ) ->
      throw error if error?
      t1  = Date.now()
      dts = ( t1 - t0 ) / 1000

  #---------------------------------------------------------------------------------------------------------
  push $input()
  push $utf8()
  push $split()
  push $count()
  push $trim()
  push $filter_empty()
  push $filter_comments()
  # push pull.filter   ( line    ) -> ( /魚/ ).test line
  push $split_fields()
  push $select_fields()
  push $filter_incomplete()
  # push $ ( data, send ) => debug '60000', data; send data
  push $as_text()
  push $as_line()
  push $output()
  push $pass() for idx in [ 1 .. O.pass_through_count ] by +1
  pull pipeline...

