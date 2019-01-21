

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/PULL-STREAM-EXAMPLES-PULL'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
test                      = require 'guy-test'
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
STACKTRACE                = require 'stack-trace' ### https://github.com/felixge/node-stack-trace ###
get_source                = require 'get-source' ### https://github.com/xpl/get-source ###


#-----------------------------------------------------------------------------------------------------------
get_source_ref = ( delta, color ) ->
  trace           = STACKTRACE.get()[ delta + 1 ]
  js_filename     = trace.getFileName()
  js_line_nr      = trace.getLineNumber()
  js_column_nr    = trace.getColumnNumber()
  target          = ( get_source js_filename ).resolve { line: js_line_nr, column: js_column_nr, }
  target_column   = target.column
  target_line     = target.sourceLine[ target_column .. ]
  target_line     = target_line.replace /^\s*(.*?)\s*$/g, '$1'
  target_path     = target.sourceFile.path
  display_path    = target_path.replace /\.[^.]+$/, ''
  display_path    = '...' + display_path[ display_path.length - 10 .. ]
  target_line_nr  = target.line
  ### TAINT use tabular as in old pipedreams ###
  R               = ( CND.grey display_path ) + ' ' + ( CND.white target_line_nr ) + ' ' + ( CND[ color ] target_line )
  return R.padEnd 150, ' '

#-----------------------------------------------------------------------------------------------------------
get_logger = ( color ) ->
  is_first_transform = true
  return ( transform ) ->
    source_ref = get_source_ref 1, color
    pipeline      = []
    switch transform.length
      when 0
        pipeline.push transform
        pipeline.push PS.$watch ( d ) -> echo source_ref, xrpr d
      when 1
        if is_first_transform
          is_first_transform = false
          pipeline.push PS.$watch ( d ) -> echo '-'.repeat 108
        pipeline.push PS.$watch ( d ) -> echo source_ref, '->', ( xrpr d ), '  '
        pipeline.push transform
        # pipeline.push PS.$watch ( d ) -> echo source_ref, '  ', ( xrpr d ), '->'
    return PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "demo through with null" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    # [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    [[1,2,3,null,4,5],[2,4,6,null,8,10],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      is_odd    = ( d ) -> ( d %% 2 ) isnt 0
      bylog     = get_logger 'lime'
      mainlog   = get_logger 'yellow'
      #.....................................................................................................
      source    = PS.new_value_source probe
      # source    = PS.new_random_async_value_source probe
      collector = []
      byline    = []
      byline.push bylog PS.$filter ( d ) -> d %% 2 is 0
      byline.push bylog $ ( d, send ) -> send if d? then d * 3 else d
      # byline.push bylog PS.$watch ( d ) -> info xrpr d
      byline.push bylog PS.$drain()
      bystream  = PS.pull byline...
      pipeline  = []
      pipeline.push source
      # pipeline.push log PS.$watch ( d ) -> info '--->', d
      pipeline.push mainlog PS.$tee bystream
      pipeline.push mainlog $ ( d, send ) -> send if d? then d * 2 else d
      # pipeline.push mainlog PS.$tee is_odd, PS.pull byline...
      pipeline.push mainlog PS.$collect { collector, }
      pipeline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull pipeline...
  #.........................................................................................................
  done()
  return null



############################################################################################################
unless module.parent?
  null
  test @


###
That covers 3 types of pull streams. Source, Transform, & Sink.
There is one more important type, although it's not used as much.

Duplex streams

(see duplex.js!)
###
