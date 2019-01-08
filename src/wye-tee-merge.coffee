
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
@$wye = ( bystream ) ->
  pair              = ( require 'pull-pair' )()
  pushable          = @new_push_source()
  subline           = []
  byline            = []
  end_sym           = Symbol 'end'
  bystream_ended    = false
  substream_ended   = false
  #.........................................................................................................
  subline.push pair.source
  subline.push @$ { last: end_sym, }, ( d, send ) ->
    if d is end_sym
      substream_ended = true
      pushable.end() if bystream_ended
    else
      pushable.push d
  subline.push @$drain()
  #.........................................................................................................
  byline.push bystream
  byline.push @$ { last: end_sym, }, ( d, send ) ->
    if d is end_sym
      bystream_ended = true
      pushable.end() if substream_ended
    else
      send d
  #.........................................................................................................
  @pull subline...
  confluence = @$merge pushable, @pull byline...
  return { sink: pair.sink, source: confluence, }

