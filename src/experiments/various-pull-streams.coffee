

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
  pipeline.push PS.$surround { first: 'first--', last: '--last', before: '(', between: ',', after: ')' }
  #.........................................................................................................
  pipeline.push PS.$collect()
  pipeline.push $ ( d, send ) -> send ( x.toString() for x in d ).join ''
  pipeline.push PS.$show()
  pipeline.push PS.$drain drainer
  PS.pull pipeline...
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
  sync_with_first_and_last()





