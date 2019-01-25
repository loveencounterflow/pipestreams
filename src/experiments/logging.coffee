

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
assign                    = Object.assign
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
#...........................................................................................................
STACKTRACE                = require 'stack-trace' ### https://github.com/felixge/node-stack-trace ###
get_source                = require 'get-source' ### https://github.com/xpl/get-source ###


#-----------------------------------------------------------------------------------------------------------
get_source_ref = ( delta, prefix, color ) ->
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
  R               = "#{CND.gold prefix} #{CND.grey display_path} #{CND.white target_line_nr} #{CND[ color ] target_line}"
  return R.padEnd 150, ' '

#-----------------------------------------------------------------------------------------------------------
get_logger = ( letter, color ) ->
  transform_nr = 0
  return ( transform ) ->
    debug '34984', transform
    transform_nr   += +1
    prefix          = "#{CND[ color ] CND.reverse '  '} #{CND[ color ] letter + transform_nr}"
    source_ref      = get_source_ref 1, prefix, color
    pipeline        = []
    leader          = '  '.repeat transform_nr
    echo source_ref
    if transform.source? and transform.sink?
      throw new Error "unable to use logging with duplex stream"
    switch transform.length
      when 0
        pipeline.push transform
        pipeline.push PS.$watch ( d ) -> echo "#{prefix}#{leader}#{xrpr d}"
      when 1
        if transform_nr is 1
          pipeline.push PS.$watch ( d ) -> echo '-'.repeat 108
        pipeline.push PS.$watch ( d ) -> echo "#{prefix}#{leader}#{CND[ color ] CND.reverse '  '} #{xrpr d}"
        pipeline.push transform
        pipeline.push PS.$watch ( d ) -> echo "#{prefix}#{leader}#{CND[ color ] CND.reverse '  '} #{xrpr d}"
    return PS.pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@[ "demo through with null" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    # [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    [[1,2,3,null,4,5],[2,6,4,6,null,null,12,8,10],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      is_odd    = ( d ) -> ( d %% 2 ) isnt 0
      bylog     = get_logger 'b', 'red'
      mainlog   = get_logger 'm', 'gold'
      #.....................................................................................................
      # source    = PS.new_value_source probe
      source    = PS.new_random_async_value_source probe
      collector = []
      byline    = []
      byline.push bylog PS.$pass()
      byline.push PS.$filter ( d ) -> d %% 2 is 0
      byline.push $ ( d, send ) -> send if d? then d * 3 else d
      # byline.push PS.$watch ( d ) -> info xrpr d
      byline.push bylog PS.$pass()
      byline.push PS.$collect { collector, }
      byline.push bylog PS.$pass()
      byline.push PS.$drain()
      bystream  = PS.pull byline...
      mainline  = []
      mainline.push source
      # mainline.push log PS.$watch ( d ) -> info '--->', d
      mainline.push mainlog PS.$tee bystream
      mainline.push mainlog PS.$defer()
      mainline.push mainlog $ ( d, send ) -> send if d? then d * 2 else d
      # mainline.push mainlog PS.$tee is_odd, PS.pull byline...
      mainline.push mainlog PS.$collect { collector, }
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 1" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    # [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    # [[1,2,3,4,5],[2,6,4,6,null,null,12,8,10],null]
    [[3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #-----------------------------------------------------------------------------------------------------
      bylog                   = get_logger 'b', 'red'
      mainlog                 = get_logger 'm', 'gold'
      #.....................................................................................................
      use_defer               = true
      buffer                  = [ probe..., ]
      mainsource              = PS.new_refillable_source buffer, { repeat: 1, }
      collector               = []
      mainline                = []
      mainline.push mainsource
      mainline.push mainlog PS.$defer() if use_defer
      mainline.push mainlog $ ( d, send ) ->
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
        # send PS.symbols.end if d is 1
      mainline.push mainlog PS.$collect { collector, }
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
      # mainsource.send 3
      # mainsource.end()
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 2" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[true,3,4],[30,32,34,10,12,14,20,22,24,94,100,34,40,64,70],null]
    [[false,3,4],[10,30,12,32,14,34,20,22,24,34,94,40,100,64,70],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      upperlog                  = get_logger 'U', 'gold'
      lowerlog                  = get_logger 'L', 'red'
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      collector                 = []
      upperline                 = []
      lowerline                 = []
      refillable                = [ 20 .. 24 ]
      #.....................................................................................................
      source_1                  = PS.new_value_source [ 10 .. 14 ]
      source_2                  = PS.new_refillable_source refillable, { repeat: 1, show: true, }
      source_3                  = PS.new_value_source [ 30 .. 34 ]
      #.....................................................................................................
      upperline.push PS.$merge source_1, source_2
      upperline.push upperlog PS.$defer() if use_defer
      upperline.push PS.$watch ( d ) -> echo 'U', xrpr d
      upperstream = PS.pull upperline...
      #.....................................................................................................
      lowerline.push PS.$merge upperstream, source_3
      lowerline.push PS.$watch ( d ) -> echo 'L', xrpr d
      lowerline.push lowerlog $ ( d, send ) ->
        if d %% 2 is 0
          send d
        else
          refillable.push d * 3 + 1
      lowerline.push PS.$collect { collector, }
      lowerline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull lowerline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "duplex" ] = ( T, done ) ->
  # through = require 'pull-through'
  probes_and_matchers = [
    [[1,2,3,4,5],[11,12,13,14,15],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      bylog         = get_logger 'b', 'red'
      mainlog       = get_logger 'm', 'gold'
      mainsource    = PS.new_value_source probe
      collector     = []
      mainline      = []
      # duplexsource = PS.new_push_source()
      stream_a = PS.pull ( bylog $ ( d, send ) -> send d * 3 )
      stream_b = PS.pull ( bylog $ ( d, send ) -> send d * 2 )
      stream_c = { source: stream_a, sink: stream_b, }
      #.....................................................................................................
      mainline.push mainsource
      mainline.push mainlog stream_c
      # mainline.push mainlog stream_c
      # # mainline.push mainlog PS.$defer()
      # mainline.push mainlog PS.$pass()
      # mainline.push mainlog $ ( d, send ) -> send d + 10
      # # mainline.push mainlog $async ( d, send, done ) -> send d + 10; done()
      mainline.push mainlog PS.$watch ( d ) -> collector.push d
      mainline.push mainlog PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

###
Duplex streams are used to communicate with a remote service,
and they are a pair of source and sink streams `{source, sink}`

in node, you see duplex streams to connect replication or rpc protocols.
client.pipe(server).pipe(client)
or
server.pipe(client).pipe(server)
both do the same thing.

the pull function we wrote before doesn't detect this,
but if you use the pull-stream module it will.
Then we can pipe duplex pull-streams like this:

var pull = require('pull-stream')
pull(client, server, client)

Also, sometimes you'll need to interact with a regular node stream.
there are two modules for this.

stream-to-pull-stream
and
pull-stream-to-stream
###


#-----------------------------------------------------------------------------------------------------------
@[ "_duplex 1" ] = ->
  NET           = require 'net'
  toPull        = require 'stream-to-pull-stream'
  pull          = require 'pull-stream'
  bylog         = get_logger 'b', 'red'
  mainlog       = get_logger 'm', 'gold'
  #.........................................................................................................
  server_as_duplex_stream = ( nodejs_stream ) ->
    ### convert into a duplex pull-stream ###
    server_stream = toPull.duplex nodejs_stream
    pipeline      = []
    pipeline.push server_stream
    pipeline.push bylog PS.$split()
    pipeline.push bylog pull.map ( x ) -> x.toString().toUpperCase() + '!!!'
    # pipeline.push server_stream
    pipeline.push bylog pull.map ( x ) -> "*#{x}*"
    pipeline.push bylog PS.$as_line()
    pipeline.push PS.$watch ( d ) -> debug '32387', xrpr d
    pipeline.push server_stream
    # pipeline.push PS.$watch ( d ) -> console.log d.toString()
    # pipeline.push bylog PS.$drain()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server = NET.createServer server_as_duplex_stream
  listener = ->
    client_stream = toPull.duplex NET.connect 9999
    pipeline      = []
    pipeline.push PS.new_random_async_value_source [ 'quiet stream\n', 'great thing\n', ]
    # pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
    pipeline.push client_stream
    pipeline.push mainlog PS.$split()
    pipeline.push mainlog PS.$drain ->
      help 'ok'
      server.close()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server.listen 9999, listener

#-----------------------------------------------------------------------------------------------------------
@[ "_duplex 2" ] = ->
  NET           = require 'net'
  toPull        = require 'stream-to-pull-stream'
  pull          = require 'pull-stream'
  bylog         = get_logger 'b', 'red'
  mainlog       = get_logger 'm', 'gold'
  #.........................................................................................................
  server_as_duplex_stream = ( nodejs_stream ) ->
    ### convert into a duplex pull-stream ###
    server_stream = toPull.duplex nodejs_stream
    pipeline      = []
    pipeline.push server_stream
    pipeline.push bylog PS.$split()
    pipeline.push bylog pull.map ( x ) -> x.toString().toUpperCase() + '!!!'
    # pipeline.push server_stream
    pipeline.push bylog pull.map ( x ) -> "*#{x}*"
    pipeline.push bylog PS.$as_line()
    pipeline.push PS.$watch ( d ) -> debug '32387', xrpr d
    pipeline.push server_stream
    # pipeline.push PS.$watch ( d ) -> console.log d.toString()
    # pipeline.push bylog PS.$drain()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server = NET.createServer server_as_duplex_stream
  listener = ->
    client_stream = toPull.duplex NET.connect 9999
    pipeline      = []
    pipeline.push PS.new_random_async_value_source [ 'quiet stream\n', 'great thing\n', ]
    # pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
    pipeline.push client_stream
    pipeline.push mainlog PS.$split()
    pipeline.push mainlog PS.$drain ->
      help 'ok'
      server.close()
    PS.pull pipeline...
    return null
  #.........................................................................................................
  server.listen 9999, listener



############################################################################################################
unless module.parent?
  null
  # test @
  # test @[ "circular pipeline 1" ], { timeout: 5000, }
  test @[ "circular pipeline 2" ], { timeout: 5000, }
  # test @[ "duplex" ]
  # @[ "_duplex 1" ]()
  # @[ "_duplex 2" ]()

