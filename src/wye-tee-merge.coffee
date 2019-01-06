
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
  mainstream_ended  = false
  bystream_started  = false
  bystream_ended    = false
  send              = null
  done              = null
  buffer            = []
  stack             = ( x ) => buffer.unshift x
  flush             = => send buffer.pop() while buffer.length > 0
  #.........................................................................................................
  bystream          = []
  bystream.push bysource
  bystream.push @$watch ( d ) => debug '77100-1', jr d
  bystream.push @$ 'null', ( d, _send ) =>
    if d?
      ### When `done` is defined, mainstream has ended, but `done` has not been called, meaning we can
      send directly (but avoid calling `done` yet); otherwise, we buffer the data: ###
      debug '77100-2', done?, jr d
      if done?
        debug '77100-3', done?, jr d
        send  d
      else
        debug '77100-4', done?, jr d
        stack d
    else
      ### When data is `null`, bystream has ended; if mainstream has already ended, `done` is be defined,
      so we flush out any remaining data, then call `done`: ###
      bystream_ended = true
      if done?
        debug '77100-5', jr d
        flush()
        done()
    return null
  bystream.push @$watch ( d ) => debug '77100-6', jr d
  bystream.push @$drain()
  #.........................................................................................................
  mainstream        = []
  mainstream.push @$async 'null', ( d, _send, _done ) =>
    ### `send` and `done` are shared within this method and will be needed to send values from bystream
    if it terminates later than mainstream: ###
    send = _send
    done = _done
    #.......................................................................................................
    unless bystream_started
      ### In case bystream has not yeen been started, do that now: ###
      debug '77100-7', "bystream started", jr d
      bystream_started = true
      @pull bystream...
    #.......................................................................................................
    if d?
      debug '77100-8', jr d
      ### In case there's mainstream data, flush out any bystream data, send d, call `done` and
      un-define it: ###
      flush()
      send d
      done()
      done = null
    else
      debug '77100-9', bystream_ended, buffer, jr d #; send 'xxx'
      ### In case mainstream data is `null`, mainstream has terminated. If bystream has been terminated
      as well, call `done` and un-define it: ###
      flush()
      if bystream_ended
        send null
        done()
        done = null
    #.......................................................................................................
    return null
  #.........................................................................................................
  R = @pull mainstream...
  return R
