
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
@$tee = ( a, b ) ->
  switch ( arity = arguments.length )
    when 1 then return @_$tee_without_filter  a
    when 2 then return @_$tee_with_filter     a, b
  throw new Error "µ93002 expected 1 or 2 arguments, got #{arity}"

#-----------------------------------------------------------------------------------------------------------
@_$tee_without_filter = ( bystream ) ->
  ### Given a `bystream`, send a data down both the mainstream and the bystream. This allows e.g. to log all
  events to a file sink while continuing to process the same data in the mainline. **NB** that in
  contradistinction to `pull-tee`, you can only divert to a single by-stream with each call to `PS.$tee` ###
  return ( require 'pull-tee' ) bystream

#-----------------------------------------------------------------------------------------------------------
@_$tee_with_filter = ( filter, bystream ) ->
  ### Given a `filter` function and a `bystream`, send only data `d` for which `filter d` returns true down
  the bystream. No data will be taken out of the mainstream. ###
  return @_$tee_without_filter @pull ( @$filter filter ), bystream

#-----------------------------------------------------------------------------------------------------------
@$bifurcate = ( filter, bystream ) ->
  ### Given a `filter` function and a `bystream`, send all data `d` either down the bystream if `filter d`
  returns true, or down the mainstream otherwise, causing a disjunct bifurcation of the data stream. ###
  byline    = []
  pipeline  = []
  byline.push @$ ( d, send ) -> send d[ 1 ] if d[ 0 ]
  byline.push bystream
  pipeline.push @$ ( d, send ) -> send [ ( filter d ), d, ]
  pipeline.push @_$tee_without_filter @pull byline...
  pipeline.push @$ ( d, send ) -> send d[ 1 ] if not d[ 0 ]
  return @pull pipeline...

#-----------------------------------------------------------------------------------------------------------
@new_merged_source = ( sources... ) ->
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
  # subline.push @$ { last: end_sym, }, ( d, send ) ->
  #   send d
  subline.push @$defer()
  subline.push @$async { last: end_sym, }, ( d, send, done ) ->
    debug CND.yellow '11190-1', d
    if d is end_sym
      substream_ended = true
      debug CND.white '22209-1 pipestreams.$wye', d, { bystream_ended, substream_ended, }
      if bystream_ended
        # debug '66373-1', "ending pushable"
        # pushable.end()
        # defer -> done()
        defer ->
          debug '66373-1', "ending pushable"
          pushable.end()
          defer -> done()
    else
      pushable.send d
      done()
    return null
  subline.push @$defer()
  subline.push @$drain()
  #.........................................................................................................
  byline.push bystream
  byline.push @$show title: '33839'
  byline.push @$defer()
  byline.push @$async { last: end_sym, }, ( d, send, done ) ->
    debug CND.yellow '11190-2', d
    if d is end_sym
      bystream_ended = true
      debug CND.white '22209-2 pipestreams.$wye', d, { bystream_ended, substream_ended, }
      if substream_ended
        # debug '66373-2', "ending pushable"
        # pushable.end()
        # defer -> done()
        defer ->
          debug '66373-2', "ending pushable"
          pushable.end()
          defer -> done()
    else
      send d
      done()
    return null
  #.........................................................................................................
  byline.push @$defer()
  @pull subline...
  confluence = @new_merged_source pushable, @pull byline...
  return { sink: pair.sink, source: confluence, }



