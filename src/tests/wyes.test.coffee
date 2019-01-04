

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

# https://pull-stream.github.io/#pull-through

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux
# https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)


#-----------------------------------------------------------------------------------------------------------
f = ->

  #-----------------------------------------------------------------------------------------------------------
  @$wye = ( bysource ) ->
    ### NOTE: what is called (main-, by-) 'stream' here is called 'pipeline' elsewhere. The `mainstream`
    is really a stream transform, a.k.a. a through stream. ###
    mainstream_end_sym    = Symbol 'mainstream_end'
    bystream_end_sym      = Symbol 'bystream_end'
    mainstream_has_ended  = false
    # bystream_has_ended    = false
    bystream_started      = false
    mainstream            = []
    bystream              = []
    mainstream_send       = null
    bystream_buffer       = []
    #.........................................................................................................
    bystream.push bysource
    bystream.push @$ 'null', ( d, send ) ->
      d ?= bystream_end_sym
      if mainstream_send?
        mainstream_send bystream_buffer.pop() while bystream_buffer.length > 0
        mainstream_send d
      else
        bystream_buffer.unshift d
      return null
    bystream.push @$drain()
    #.........................................................................................................
    ### TAINT this step is necessary because `PS.$async 'null', $f` is not implemented ###
    mainstream.push @$ 'null', ( d, send ) ->
      ### When the first event—data or the end signal—comes down the mainstream, start the bystream: ###
      unless bystream_started
        PS.pull bystream...
        bystream_started = true
      #.......................................................................................................
      if d?
        send d
      else
        mainstream_has_ended = true
        send mainstream_end_sym
    #.........................................................................................................
    mainstream.push @$async ( d, send, done ) ->
      mainstream_send = send

      if d is mainstream_end_sym
        send null
        done()
      else
        send d
        done()
    #.........................................................................................................
    R = PS.pull mainstream...
    return R

  # #-----------------------------------------------------------------------------------------------------------
  # @$wye = ( bysource ) ->
  #   generator = ->
  #     loop
  #       yield d
  #     return null
  #   return @pull mainstream...

f.apply PS


#-----------------------------------------------------------------------------------------------------------
@[ "$wye 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[['a','b','c'],[1,2,3]],["a","b","c"],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, ->
      new Promise ( resolve, reject ) ->
        R                   = []
        drainer             = -> resolve R
        source_1            = PS.new_push_source()
        source_2            = PS.new_push_source()
        pipeline_1          = []
        pipeline_1.push source_1
        pipeline_1.push PS.$watch ( d ) -> whisper '10191', d
        pipeline_1.push PS.$wye source_2
        pipeline_1.push PS.$watch ( d ) -> R.push d
        pipeline_1.push PS.$watch ( d ) -> urge '10191', d
        pipeline_1.push PS.$drain drainer
        PS.pull pipeline_1...
        source_1.push chr for chr in probe[ 0 ]
        source_2.push chr for chr in probe[ 1 ]
        source_1.end()
  done()
  return null




############################################################################################################
unless module.parent?
  test @

