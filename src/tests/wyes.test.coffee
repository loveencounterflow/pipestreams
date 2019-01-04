

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/WYE'
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
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
test                      = require 'guy-test'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
#...........................................................................................................
{ jr }                    = CND

# https://pull-stream.github.io/#pull-through

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux
# https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)


#-----------------------------------------------------------------------------------------------------------
provide_$wye = ->
  mux = require 'pull-mux' ### https://github.com/nichoth/pull-mux ###

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
    pipeline  = []
    pipeline.push @$watch ( d ) -> urge '***', d
    # pipeline.push @$tee ( d ) -> urge '***', d
    R         = @pull pipeline...
    x = []
    x.push @$merge R, bysource
    x.push @$show()
    x.push @$drain()
    return R

provide_$wye.apply PS


#-----------------------------------------------------------------------------------------------------------
@[ "$merge 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      new Promise ( resolve, reject ) ->
        R                   = []
        drainer             = -> resolve R
        source_1            = PS.new_push_source()
        source_2            = PS.new_push_source()
        #...................................................................................................
        pipeline_1          = []
        pipeline_1.push source_1
        pipeline_1.push PS.$watch ( d ) -> whisper '10191-1', d
        #...................................................................................................
        pipeline_2          = []
        pipeline_2.push source_2
        pipeline_2.push PS.$watch ( d ) -> whisper '10191-2', d
        #...................................................................................................
        pipeline_3          = []
        pipeline_3.push PS.$merge ( PS.pull pipeline_1... ), ( PS.pull pipeline_2... )
        pipeline_3.push PS.$watch ( d ) -> R.push d
        pipeline_3.push PS.$watch ( d ) -> urge '10191-3', d
        pipeline_3.push PS.$drain drainer
        PS.pull pipeline_3...
        max_idx = ( Math.max probe[ 0 ].length, probe[ 1 ].length ) - 1
        for idx in [ 0 .. max_idx ]
          source_1.push x if ( x = probe[ 0 ][ idx ] )?
          source_2.push x if ( x = probe[ 1 ][ idx ] )?
        source_1.end()
        source_2.end()
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      new Promise ( resolve, reject ) ->
        R                   = []
        drainer             = -> resolve R
        source_1            = PS.new_push_source()
        source_2            = PS.new_push_source()
        #...................................................................................................
        bystream            = []
        bystream.push source_2
        bystream.push PS.$watch ( d ) -> whisper '10191-2', d
        bystream = PS.pull bystream...
        #...................................................................................................
        mainstream          = []
        mainstream.push source_1
        mainstream.push PS.$watch ( d ) -> whisper '10191-1', d
        mainstream.push PS.$wye bystream
        mainstream.push PS.$watch ( d ) -> R.push d
        mainstream.push PS.$watch ( d ) -> urge '10191-3', d
        mainstream.push PS.$drain drainer
        PS.pull mainstream...
        max_idx = ( Math.max probe[ 0 ].length, probe[ 1 ].length ) - 1
        for idx in [ 0 .. max_idx ]
          source_1.push x if ( x = probe[ 0 ][ idx ] )?
          source_2.push x if ( x = probe[ 1 ][ idx ] )?
        source_1.end()
        source_2.end()
  done()
  return null




############################################################################################################
unless module.parent?
  # test @
  test @[ "$wye 1" ]

