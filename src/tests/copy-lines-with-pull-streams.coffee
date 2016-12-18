

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
new_file_source           = require 'pull-file'
pull                      = require 'pull-stream'
### NOTE these two are different: ###
# $pass_through             = require 'pull-stream/throughs/through'
through                   = require 'pull-through'
async_map                 = require 'pull-stream/throughs/async-map'
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
O                         = {}
O.pass_through_count      = 1000
O.pass_through_async      = no
# O.implementation          = 'pull-stream'
# O.implementation          = 'pipestreams-map'
O.implementation          = 'pipestreams-remit'
#...........................................................................................................
TAP                       = require 'tap'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS


#-----------------------------------------------------------------------------------------------------------
TAP.test "performance regression", ( T ) ->

  #---------------------------------------------------------------------------------------------------------
  # input                     = PS.new_file_source  PATH.resolve __dirname, '../../test-data/ids.txt'
  input                     = PS.new_file_source  PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  output_stream             = PS.new_file_sink    PATH.resolve __dirname, '../../test-data/ids-copy.txt'

  #---------------------------------------------------------------------------------------------------------
  pipeline                  = []
  push                      = pipeline.push.bind pipeline
  t0                        = null
  t1                        = null
  item_count                = 0

  #---------------------------------------------------------------------------------------------------------
  PS.map_start ->
    help 44402, "start"
    t0 = Date.now()

  ###
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
  ###

  ```
  f = function through (op, onEnd) {
    var a = false

    function once (abort) {
      if(a || !onEnd) return
      a = true
      onEnd(abort === true ? null : abort)
    }

    return function (read) {
      return function (end, cb) {
        if(end) once(end)
        return read(end, function (end, data) {
          if(!end) op && op(data)
          else once(end)
          cb(end, data)
        })
      }
    }
  }
  ```

  #---------------------------------------------------------------------------------------------------------
  switch O.implementation
    #.......................................................................................................
    when 'pull-stream'
      $as_line            = -> pull.map ( line    ) -> line + '\n'
      $as_text            = -> pull.map ( fields  ) -> JSON.stringify fields
      $count              = -> pull.map ( line    ) -> item_count += +1; return line
      $select_fields      = -> pull.map ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> pull.map ( line    ) -> line.split '\t'
      $trim               = -> pull.map ( line    ) -> line.trim()
    #.......................................................................................................
    when 'pipestreams-remit'
      $as_line            = -> $ ( line,   send ) -> send line + '\n'
      $as_text            = -> $ ( fields, send ) -> send JSON.stringify fields
      $count              = -> $ ( line,   send ) -> item_count += +1; send line
      $select_fields      = -> $ ( fields, send ) -> [ _, glyph, formula, ] = fields; send [ glyph, formula, ]
      $split_fields       = -> $ ( line,   send ) -> send line.split '\t'
      $trim               = -> $ ( line,   send ) -> send line.trim()
    #.......................................................................................................
    when 'pipestreams-map'
      $as_line            = -> PS.map ( line    ) -> line + '\n'
      $as_text            = -> PS.map ( fields  ) -> JSON.stringify fields
      $count              = -> PS.map ( line    ) -> item_count += +1; return line
      $select_fields      = -> PS.map ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> PS.map ( line    ) -> line.split '\t'
      $trim               = -> PS.map ( line    ) -> line.trim()
  #.........................................................................................................
  $filter_empty       = -> PS.filter ( line   ) -> line.length > 0
  $filter_comments    = -> PS.filter ( line   ) -> not line.startsWith '#'
  $filter_incomplete  = -> PS.filter ( fields ) -> [ a, b, ] = fields; return a? or b?

  #---------------------------------------------------------------------------------------------------------
  if O.pass_through_async
    $pass = ->
      return async_map ( data, handler ) ->
        setImmediate ->
          handler null, data
  else
  switch O.implementation
    when 'pull-stream'
      $pass = -> pull.map ( line ) -> line
    when 'pipestreams-remit'
      $pass = -> $ ( line, send ) -> send line
    when 'pipestreams-map'
      $pass = -> PS.map ( line ) -> line


  # #---------------------------------------------------------------------------------------------------------
  # $input = -> STPS.source input

  #---------------------------------------------------------------------------------------------------------
  $output = ->
    return STPS.sink output_stream, ( error ) ->
      throw error if error?
      t1  = Date.now()
      dts = ( t1 - t0 ) / 1000

  #---------------------------------------------------------------------------------------------------------
  push input
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
  # push $ ( data, send ) => send data
  push $as_text()
  push $as_line()
  push $output()
  push $pass() for idx in [ 1 .. O.pass_through_count ] by +1
  pull pipeline...

