

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS'
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
PS                        = require '../..'
{ $, $async, }            = PS
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout f, dts * 1000
defer                     = setImmediate
{ jr
  is_empty }              = CND

# https://pull-stream.github.io/#pull-through
# nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux

#-----------------------------------------------------------------------------------------------------------
demo_merge_1 = ->
  ### https://github.com/pull-stream/pull-merge ###
  pull      = require 'pull-stream'
  merge     = require 'pull-merge'
  pipeline  = []
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, ] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, 10, 11, 12, ] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [] )
  # pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 1, 5, 6, ] )
  # pipeline.push merge ( pull.values [ [1], [5], [6], ] ), ( pull.values [ [1], [5], [6], [7], ] )
  pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 1, 5, 6, ] ), ( a, b ) -> -1
  pipeline.push pull.collect ( error, collector ) ->
    throw error if error?
    help collector
  pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
new_async_source = ( name ) ->
    source    = PS.new_push_source()
    pipeline  = []
    pipeline.push source
    pipeline.push PS.$watch ( d ) -> urge name, jr d
    R         = PS.pull pipeline...
    R.push    = ( x ) -> source.push x
    R.end     = -> source.end()
    return R

#-----------------------------------------------------------------------------------------------------------
demo_merge_async_sources = ->
  ### won't take all inputs from both sources ###
  merge     = require 'pull-merge'
  source_1 = new_async_source 's1'
  source_2 = new_async_source 's2'
  return new Promise ( resolve ) ->
    pipeline  = []
    pipeline.push merge source_2, source_1, ( a, b ) -> -1
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    # after 1.0, -> source_1.push null
    # after 1.0, -> source_2.push null
    return null

#-----------------------------------------------------------------------------------------------------------
demo_mux_async_sources_1 = ->
  mux = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###
  #.........................................................................................................
  $_mux = ( sources... ) ->
    R = {}
    for source, idx in sources
      R[ idx ] = source
    return mux R
  #.........................................................................................................
  $_demux = ->
    return PS.$map ( [ k, v, ] ) -> v
  #.........................................................................................................
  return new Promise ( resolve ) ->
    pipeline  = []
    source_1  = new_async_source 's1'
    source_2  = new_async_source 's2'
    pipeline.push $_mux source_1, source_2
    pipeline.push $_demux()
    pipeline.push PS.$collect()
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.05, -> source_2.push 42
    after 1.0, -> source_1.end()
    after 1.0, -> source_2.end()
    return null

#-----------------------------------------------------------------------------------------------------------
demo_mux_async_sources_2 = ->
  mux = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###
  #-----------------------------------------------------------------------------------------------------------
  PS.$wye = ( sources... ) ->
    #.........................................................................................................
    $_mux = ( sources... ) ->
      R = {}
      R[ idx ] = source for source, idx in sources
      return mux R
    #.........................................................................................................
    $_demux = -> PS.$map ( [ k, v, ] ) -> v
    #.........................................................................................................
    pipeline  = []
    pipeline.push $_mux sources...
    pipeline.push $_demux()
    return PS.pull pipeline...
  #.........................................................................................................
  return new Promise ( resolve ) ->
    pipeline  = []
    source_1  = new_async_source 's1'
    source_2  = new_async_source 's2'
    pipeline.push PS.$wye source_1, source_2
    pipeline.push PS.$collect()
    pipeline.push PS.$watch ( d ) -> help '-->', jr d
    pipeline.push PS.$drain ->
      help 'ok'
      resolve null
    PS.pull pipeline...
    after 0.1, -> source_2.push 4
    after 0.5, -> source_1.push 2
    after 0.6, -> source_1.push 3
    after 0.2, -> source_2.push 5
    after 0.3, -> source_2.push 6
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.4, -> source_1.push 1
    after 0.05, -> source_2.push 42
    after 1.0, -> source_1.end()
    after 1.0, -> source_2.end()
    return null

#-----------------------------------------------------------------------------------------------------------
demo_through = ->
  through = require 'pull-through' ### https://github.com/pull-stream/pull-through ###

#-----------------------------------------------------------------------------------------------------------
async_with_end_detection = ->
  buffer    = [ 11 .. 15 ]
  pipeline  = []
  send      = null
  flush     = => send buffer.pop() while not is_empty buffer
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  pipeline.push PS.$defer()
  #.........................................................................................................
  pipeline.push do =>
    is_first = true
    return $ { last: PS.symbols.last, }, ( d, send ) =>
      if is_first
        is_first = false
        send PS.symbols.first
      send d
  #.........................................................................................................
  pipeline.push PS.$async ( d, _send, done ) =>
    send = _send
    switch d
      when PS.symbols.first
        debug 'start'
        send buffer.pop()
        done()
      when PS.symbols.last
        flush()
        debug 'end'
        # done()
        after 2, done
      else
        send d
        done()
    return null
  #.........................................................................................................
  pipeline.push PS.$show()
  pipeline.push PS.$drain()
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
async_with_end_detection_2 = ->
  buffer    = [ 11 .. 15 ]
  pipeline  = []
  send      = null
  flush     = => send buffer.pop() while not is_empty buffer
  #.........................................................................................................
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  pipeline.push PS.$defer()
  #.........................................................................................................
  pipeline.push PS.$async 'null', ( d, _send, done ) =>
    send = _send
    if d?
      send d
      done()
    else
      flush()
      debug 'end'
      # done()
      after 2, done
    return null
  #.........................................................................................................
  pipeline.push PS.$show()
  pipeline.push PS.$drain()
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
sync_with_first_and_last = ->
  drainer   = -> help 'ok'
  pipeline  = []
  pipeline.push PS.new_value_source [ 1 .. 5 ]
  #.........................................................................................................
  pipeline.push PS.$surround { first: '[', last: ']', before: '(', between: ',', after: ')' }
  pipeline.push PS.$surround { first: 'first', last: 'last', }
  # pipeline.push PS.$surround { first: 'first', last: 'last', before: 'before', between: 'between', after: 'after' }
  # pipeline.push PS.$surround { first: '[', last: ']', }
  #.........................................................................................................
  pipeline.push PS.$collect()
  pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
  pipeline.push PS.$show()
  pipeline.push PS.$drain drainer
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
async_with_first_and_last = ->
  drainer   = -> help 'ok'
  pipeline  = []
  pipeline.push PS.new_value_source [ 1 .. 3 ]
  #.........................................................................................................
  pipeline.push PS.$surround { first: 'first', last: 'last', }
  pipeline.push $async { first: '[', last: ']', between: '|', }, ( d, send, done ) =>
    defer ->
      # debug '22922', jr d
      send d
      done()
  #.........................................................................................................
  # pipeline.push PS.$watch ( d ) -> urge '20292', d
  pipeline.push PS.$collect()
  pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
  pipeline.push PS.$show()
  pipeline.push PS.$drain drainer
  PS.pull pipeline...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
pull_pair_1 = ->
  new_pair    = require 'pull-pair'
  pair        = new_pair()
  pipeline_1  = []
  pipeline_2  = []
  #.........................................................................................................
  # read values into this sink...
  pipeline_1.push PS.new_value_source [ 1, 2, 3, ]
  pipeline_1.push PS.$watch ( d ) -> urge d
  pipeline_1.push pair.sink
  PS.pull pipeline_1...
  #.........................................................................................................
  # but that should become the source over here.
  pipeline_2.push pair.source
  pipeline_2.push PS.$collect()
  pipeline_2.push PS.$show()
  pipeline_2.push PS.$drain()
  #.........................................................................................................
  PS.pull pipeline_2...
  return null

#-----------------------------------------------------------------------------------------------------------
pull_pair_2 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  f = ->
    pair        = new_pair()
    pushable    = PS.new_push_source()
    pipeline_1  = []
    #.......................................................................................................
    pipeline_1.push pair.source
    pipeline_1.push PS.$surround before: '(', after: ')', between: '-'
    pipeline_1.push PS.$join()
    pipeline_1.push PS.$show title: 'substream'
    pipeline_1.push PS.$watch ( d ) -> pushable.push d
    pipeline_1.push PS.$drain()
    #.......................................................................................................
    PS.pull pipeline_1...
    return { sink: pair.sink, source: pushable, }
  #.........................................................................................................
  pipeline = []
  pipeline.push PS.new_value_source "just a few words".split /\s/
  pipeline.push PS.$watch ( d ) -> whisper d
  pipeline.push f()
  pipeline.push PS.$show title: 'mainstream'
  pipeline.push PS.$drain()
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
wye_1 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  $wye = ( bystream ) ->
    pair        = new_pair()
    pushable    = PS.new_push_source()
    pipeline_1  = []
    pipeline_2  = []
    #.......................................................................................................
    pipeline_1.push pair.source
    pipeline_1.push PS.$surround before: '(', after: ')', between: '-'
    # pipeline_1.push PS.$join()
    pipeline_1.push PS.$show title: 'substream'
    pipeline_1.push PS.$watch ( d ) -> pushable.push d
    pipeline_1.push PS.$drain -> urge "substream ended"
    #.......................................................................................................
    pipeline_2.push bystream
    pipeline_2.push $ { last: null, }, ( d, send ) -> urge "bystream ended" unless d?; send d
    pipeline_2.push PS.$show title: 'bystream'
    #.......................................................................................................
    PS.pull pipeline_1...
    confluence = PS.$merge pushable, PS.pull pipeline_2...
    return { sink: pair.sink, source: confluence, }
  #.........................................................................................................
  bysource = PS.new_value_source [ 3 .. 7 ]
  pipeline = []
  pipeline.push PS.new_value_source "just a few words".split /\s/
  # pipeline.push PS.$watch ( d ) -> whisper d
  pipeline.push $wye bysource
  pipeline.push PS.$collect()
  pipeline.push PS.$show title: 'mainstream'
  pipeline.push PS.$drain -> help 'ok'
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
wye_2 = ->
  new_pair    = require 'pull-pair'
  #.........................................................................................................
  $wye = ( bystream ) ->
    pair              = new_pair()
    pushable          = PS.new_push_source()
    subline           = []
    byline            = []
    end_sym           = Symbol 'end'
    bystream_ended    = false
    substream_ended   = false
    #.......................................................................................................
    subline.push pair.source
    subline.push $ { last: end_sym, }, ( d, send ) ->
      if d is end_sym
        substream_ended = true
        pushable.end() if bystream_ended
      else
        pushable.push d
    subline.push PS.$drain()
    #.......................................................................................................
    byline.push bystream
    byline.push $ { last: end_sym, }, ( d, send ) ->
      if d is end_sym
        bystream_ended = true
        pushable.end() if substream_ended
      else
        send d
    #.......................................................................................................
    PS.pull subline...
    confluence = PS.$merge pushable, PS.pull byline...
    return { sink: pair.sink, source: confluence, }
  #.........................................................................................................
  demo = ->
    return new Promise ( resolve ) ->
      byline = []
      byline.push PS.new_value_source [ 3 .. 7 ]
      byline.push PS.$watch ( d ) -> whisper 'bystream', jr d
      #.......................................................................................................
      mainline = []
      mainline.push PS.new_value_source "just a few words".split /\s/
      mainline.push PS.$watch ( d ) -> whisper 'mainstream', jr d
      mainline.push $wye PS.pull byline...
      mainline.push PS.$collect()
      mainline.push PS.$show title: 'mainstream'
      mainline.push PS.$drain -> help 'ok'; resolve()
      PS.pull mainline...
  await demo()
  return null

#-----------------------------------------------------------------------------------------------------------
duplex_stream_3 = ->
  new_duplex_pair     = require 'pull-pair/duplex'
  [ client, server, ] = new_duplex_pair()
  pipeline_1          = []
  pipeline_2          = []
  #.........................................................................................................
  pipeline_1.push PS.new_value_source [ 1, 2, 3, ]
  pipeline_1.push client
  pipeline_1.push PS.$collect()
  pipeline_1.push PS.$show()
  # pipeline_1.push client
  pipeline_1.push PS.$drain()
  PS.pull pipeline_1...
  #.........................................................................................................
  # pipe the second duplex stream back to itself.
  pipeline_2.push server
  pipeline_2.push PS.$watch ( d ) -> urge d
  pipeline_2.push $ ( d, send ) -> send d * 10
  pipeline_2.push server
  PS.pull pipeline_2...
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
duplex_stream_4 = ->
  new_duplex_pair     = require 'pull-pair/duplex'
  [ client, server, ] = new_duplex_pair()
  pipeline_1          = []
  pipeline_2          = []
  #.........................................................................................................
  pipeline_1.push PS.new_value_source [ 1, 2, 3, ]
  pipeline_1.push client
  pipeline_1.push PS.$collect()
  pipeline_1.push PS.$show()
  # pipeline_1.push client
  pipeline_1.push PS.$drain()
  PS.pull pipeline_1...
  #.........................................................................................................
  # pipe the second duplex stream back to itself.
  pipeline_2.push server
  pipeline_2.push PS.$watch ( d ) -> urge d
  pipeline_2.push $ ( d, send ) -> send d * 10
  pipeline_2.push server
  pipeline_1.push PS.$drain()
  PS.pull pipeline_2...
  #.........................................................................................................
  return null


############################################################################################################
unless module.parent?
  # demo_merge_1()
  # demo_merge_async_sources()
  # demo_mux_async_sources_1()
  # demo_mux_async_sources_2()
  # demo_through()
  # async_with_end_detection()
  # async_with_end_detection_2()
  # sync_with_first_and_last()
  # async_with_first_and_last()
  # pull_pair_1()
  # pull_pair_2()
  # wye_1()
  wye_2()
  # duplex_stream_3()
  # duplex_stream_4()





