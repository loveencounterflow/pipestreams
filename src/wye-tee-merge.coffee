
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/WYE-TEE-MERGE'
# log                       = CND.get_logger 'plain',     badge
# info                      = CND.get_logger 'info',      badge
# whisper                   = CND.get_logger 'whisper',   badge
# alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# echo                      = CND.echo.bind CND
{ jr }                    = CND
mux                       = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###
defer                     = setImmediate

#-----------------------------------------------------------------------------------------------------------
@$tee = ( stream ) ->
  ### **NB** that in contradistinction to `pull-tee`, you can only divert to a single by-stream with each
  call to `PS.$tee` ###
  # R = if ( CND.isa_list stream_or_pipeline ) then ( pull stream_or_pipeline ) else stream_or_pipeline
  return ( require 'pull-tee' ) stream

#-----------------------------------------------------------------------------------------------------------
@$merge = ( sources... ) ->
  #.........................................................................................................
  $_mux = ( sources... ) =>
    R = {}
    R[ idx ] = source for source, idx in sources
    return mux R
  #.........................................................................................................
  $_demux = => @$map ( [ k, v, ] ) -> v
  #.........................................................................................................
  pipeline  = []
  pipeline.push $_mux sources...
  pipeline.push $_demux()
  return @pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@$wye = ( bysource ) ->
  bystream_started  = false
  bystream_ended    = false
  send              = null
  done              = null
  buffer            = []
  stack             = ( x ) => buffer.unshift x
  pop               = => send buffer.pop() if buffer.length > 0
  flush             = => send buffer.pop() while buffer.length > 0
  last_sym_1        = Symbol 'last'
  last_sym_2        = Symbol 'last'
  #.........................................................................................................
  bystream          = []
  bystream.push bysource
  bystream.push @$async { last: last_sym_1, }, ( d, _send, _done ) =>
    if d isnt last_sym_1
      ### When `done` is defined, mainstream has ended, but `done` has not been called, meaning we can
      send directly (but avoid calling `done` yet); otherwise, we buffer the data: ###
      if done?
        send  d
      else
        stack d
    else
      ### When bystream and mainstream have both ended, `done` will be defined,
      so we flush out any remaining data, then call `done`: ###
      bystream_ended = true
      if done?
        flush()
        done()
    _done()
    return null
  bystream.push @$drain()
  #.........................................................................................................
  mainstream        = []
  mainstream.push @$async { last: last_sym_2, }, ( d, _send, _done ) =>
    ### `send` and `done` are shared within this method and will be needed to send values from bystream
    if it terminates later than mainstream: ###
    send = _send
    done = _done
    #.......................................................................................................
    unless bystream_started
      ### In case bystream has not yeen been started, do that now: ###
      bystream_started = true
      @pull bystream...
    #.......................................................................................................
    unless d is last_sym_2
      ### In case there's mainstream data, flush out any bystream data, send d, call `done` and
      un-define it: ###
      # flush()
      send d
      pop()
      done()
      done = null
    else
      ### In case mainstream data is `null`, mainstream has terminated. If bystream has been terminated
      as well, call `done` and un-define it: ###
      flush()
      if bystream_ended
        defer -> send null
        done()
        done = null
    #.......................................................................................................
    return null
  #.........................................................................................................
  R = @pull mainstream...
  return R
