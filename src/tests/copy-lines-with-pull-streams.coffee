
'use strict'


###
Testing Parameters

* number of no-op pass-through transforms
* highWaterMark for input stream
* whether input stream emits buffers or strings (if it emits strings, whether `$utf8` transform should be kept)
* implementation model for transforms
* implementation model for pass-throughs

Easy to show that `$split` doesn't work correctly on buffers (set highWaterMark to, say, 3 and have
input stream emit buffers).

###


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
O.pass_through_count      = 0
# O.pass_through_count      = 1
# O.pass_through_count      = 100
# O.implementation          = 'pull-stream'
O.implementation          = 'pipestreams-map'
# O.implementation          = 'pipestreams-remit'
#...........................................................................................................
TAP                       = require 'tap'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS


#-----------------------------------------------------------------------------------------------------------
TAP.test "tail-call optimization works", ( T ) ->
  'use strict'
  f = ( count = 0 ) ->
    whisper format_integer count if count % 1e5 is 0
    if count < 1e6
      f count + 1
  f()
  T.pass "looks good"
  T.end()

#-----------------------------------------------------------------------------------------------------------
TAP.test "performance regression", ( T ) ->

  #---------------------------------------------------------------------------------------------------------
  input_settings  = { encoding: 'utf-8', }
  input_path      = PATH.resolve __dirname, '../../test-data/ids.txt'
  # input_path  = PATH.resolve __dirname, '../../test-data/ids-short.txt'
  # input_path  = PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  output_path     = PATH.resolve __dirname, '../../test-data/ids-copy.txt'

  #---------------------------------------------------------------------------------------------------------
  input                     = PS.new_file_source input_path, input_settings
  # output                    = PS.new_file_sink              output_path
  # output                    = PS._new_file_sink_using_stps  output_path
  # output                    = PS._new_file_sink_using_pwf   output_path
  output                    = PS.new_file_sink output_path

  #---------------------------------------------------------------------------------------------------------
  pipeline                  = []
  push                      = pipeline.push.bind pipeline
  t0                        = null
  t1                        = null
  item_count                = 0

  #---------------------------------------------------------------------------------------------------------
  $on_start = ->
    return PS.map_start ->
      help 44402, "start"
      t0 = Date.now()

  #---------------------------------------------------------------------------------------------------------
  $on_stop = ->
    return PS.map_stop ->
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

  ```
  function XXX_map (read, map) {
    //return a readable function!
    return function (end, cb) {
      read(end, function (end, data) {
        debug(20323,rpr(data))
        cb(end, data != null ? map(data) : null)
      })
    }
  }
  ```


  ```
  function XXX_through (op, onEnd) {
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

  XXX_through2 = ( on_data, on_stop ) ->
    has_ended = false
    collector = []

    once = ( abort ) ->
      return null if has_ended
      return null if not on_stop?
      has_ended = true
      on_stop if abort is true then null else abort
      return null

    send = ( data ) -> collector.push data

    return ( read ) ->
      return ( end, handler ) ->
        once end if end
        read end, ( end, data ) ->
          if end
            once end
          else
            on_data data, send if on_data?
          if collector.length > 0
            handler end, d for d in collector
            collector.length = 0
          else
            handler end, null
          return


  #---------------------------------------------------------------------------------------------------------
  switch O.implementation
    #.......................................................................................................
    when 'pull-stream'
      $as_line            = -> pull.map ( line    ) -> line + '\n'
      $as_text            = -> pull.map ( fields  ) -> JSON.stringify fields
      $count              = -> pull.map ( line    ) -> item_count += +1; return line
      # $count              = -> pull.map ( line    ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; return line
      $select_fields      = -> pull.map ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> pull.map ( line    ) -> line.split '\t'
      $trim               = -> pull.map ( line    ) -> line.trim()
      $pass               = -> pull.map ( line    ) -> line
    #.......................................................................................................
    when 'pipestreams-remit'
      $as_line            = -> $ ( line,   send ) -> send line + '\n'
      $as_text            = -> $ ( fields, send ) -> send JSON.stringify fields
      $count              = -> $ ( line,   send ) -> item_count += +1; send line
      # $count              = -> $ ( line,   send ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; send line
      $select_fields      = -> $ ( fields, send ) -> [ _, glyph, formula, ] = fields; send [ glyph, formula, ]
      $split_fields       = -> $ ( line,   send ) -> send line.split '\t'
      $trim               = -> $ ( line,   send ) -> send line.trim()
      $pass               = -> $ ( line,   send ) -> send line
    #.......................................................................................................
    when 'pipestreams-map'
      $as_line            = -> PS.map ( line    ) -> line + '\n'
      $as_text            = -> PS.map ( fields  ) -> JSON.stringify fields
      $count              = -> PS.map ( line    ) -> item_count += +1; return line
      # $count              = -> PS.map ( line    ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; return line
      $select_fields      = -> PS.map ( fields  ) -> [ _, glyph, formula, ] = fields; return [ glyph, formula, ]
      $split_fields       = -> PS.map ( line    ) -> line.split '\t'
      $trim               = -> PS.map ( line    ) -> line.trim()
      $pass               = -> PS.map ( line    ) -> line
      $my_utf8            = -> PS.map ( buffer  ) -> debug buffer; buffer.toString 'utf-8'
      $show               = -> PS.map ( data    ) -> info rpr data; return data
      $sink_example = ->
        return ( read ) ->
          'use strict'
          next = ( error, data ) ->
            'use strict'
            return warn error if error
            # info '77775', rpr data
            ### recursively call read again ###
            return read null, next
            # return null
          return read null, next
          # return null

  #.........................................................................................................
  $filter_empty       = -> PS.filter ( line   ) -> line.length > 0
  $filter_comments    = -> PS.filter ( line   ) -> not line.startsWith '#'
  $filter_incomplete  = -> PS.filter ( fields ) -> [ a, b, ] = fields; return a? or b?

  #---------------------------------------------------------------------------------------------------------
  push input
  push $on_start()
  # push $utf8()
  push $split()
  # push $show()
  push $count()
  push $trim()
  push $filter_empty()
  push $filter_comments()
  # push pull.filter   ( line    ) -> ( /魚/ ).test line
  push $split_fields()
  push $select_fields()
  push $filter_incomplete()
  # push XXX_through2 ( data, send ) ->
  #   urge data
  #   send data
  #   send data
  push $as_text()
  push $as_line()
  push $pass() for idx in [ 1 .. O.pass_through_count ] by +1
  # push ( pull.map ( line ) -> line ) for idx in [ 1 .. O.pass_through_count ] by +1
  push $on_stop()
  push $sink_example()
  # push output
  pull pipeline...

