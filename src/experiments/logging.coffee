

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
test                      = require 'guy-test'



# #-----------------------------------------------------------------------------------------------------------
# @[ "demo through with null" ] = ( T, done ) ->
#   # through = require 'pull-through'
#   probes_and_matchers = [
#     [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
#     [[ 5, 15, 20, null, 25, 30, ], [ 10, 30, 40, null, 50, 60 ]]
#     ]
#   #.........................................................................................................
#   for [ probe, matcher, error, ] in probes_and_matchers
#     await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
#       #.....................................................................................................
#       source    = source_from_values probe
#       collector = []
#       pipeline  = []
#       pipeline.push source
#       pipeline.push map ( d ) -> info '--->', d; return d
#       pipeline.push PS.$ ( d, send ) -> send if d? then d * 2 else d
#       # pipeline.push map ( d ) -> collector.push d; return d
#       pipeline.push PS.$collect { collector, }
#       pipeline.push PS.$drain ->
#         help collector
#         resolve collector
#       pull pipeline...
#   #.........................................................................................................
#   done()
#   return null



# ############################################################################################################
# unless module.parent?
#   null
#   test @


###
That covers 3 types of pull streams. Source, Transform, & Sink.
There is one more important type, although it's not used as much.

Duplex streams

(see duplex.js!)
###
