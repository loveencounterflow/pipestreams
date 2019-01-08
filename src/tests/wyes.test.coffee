

'use strict'

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
{ jr
  is_empty }              = CND
defer                     = setImmediate

# https://pull-stream.github.io/#pull-through

# https://github.com/pull-stream/pull-cont
# https://github.com/pull-stream/pull-defer
# https://github.com/scrapjs/pull-imux
# https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)


#-----------------------------------------------------------------------------------------------------------
@[ "$merge 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      R                   = []
      drainer             = -> resolve R
      source_1            = PS.new_push_source()
      source_2            = PS.new_push_source()
      #...................................................................................................
      pipeline_1          = []
      pipeline_1.push source_1
      pipeline_1.push PS.$watch ( d ) -> whisper '10191-2', d
      #...................................................................................................
      pipeline_2          = []
      pipeline_2.push source_2
      pipeline_2.push PS.$watch ( d ) -> whisper '10191-3', d
      #...................................................................................................
      pipeline_3          = []
      pipeline_3.push PS.$merge ( PS.pull pipeline_1... ), ( PS.pull pipeline_2... )
      pipeline_3.push PS.$watch ( d ) -> R.push d
      pipeline_3.push PS.$watch ( d ) -> urge '10191-4', d
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
new_filtered_bysink = ( name, collector, filter ) ->
  R = []
  R.push PS.$filter filter
  R.push PS.$watch ( d ) -> collector.push d
  R.push PS.$watch ( d ) -> whisper '10191', name, jr d
  R.push PS.$drain()
  return PS.pull R...

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[["a","b","c"],[1,2,3,4,5,6]],[[1,2,3,4,5,6],["a","b","c"]],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve, reject ) ->
      numbers             = []
      texts               = []
      R                   = [ numbers, texts, ]
      drainer             = -> resolve R
      source_1            = PS.new_push_source()
      source_2            = PS.new_push_source()
      #...................................................................................................
      bysource            = []
      bysource.push source_2
      bysource.push PS.$watch ( d ) -> whisper '10191-5', 'bysource', jr d
      # bysource.push PS.$defer()
      bysource            = PS.pull bysource...
      #...................................................................................................
      mainstream          = []
      mainstream.push source_1
      # mainstream.push PS.$defer()
      mainstream.push PS.$wye bysource
      # mainstream.push PS.$watch ( d ) -> whisper '10191-6', 'confluence', jr d
      mainstream.push PS.$tee new_filtered_bysink 'number', numbers,  ( d ) -> CND.isa_number d
      mainstream.push PS.$tee new_filtered_bysink 'text',   texts,    ( d ) -> CND.isa_text d
      mainstream.push PS.$tee new_filtered_bysink 'other',  null,     ( d ) -> ( not CND.isa_number d ) and ( not CND.isa_text d )
      mainstream.push PS.$drain drainer
      PS.pull mainstream...
      #...................................................................................................
      max_idx = ( Math.max probe[ 0 ].length, probe[ 1 ].length ) - 1
      for idx in [ 0 .. max_idx ]
        source_1.push x if ( x = probe[ 0 ][ idx ] )?
        source_2.push x if ( x = probe[ 1 ][ idx ] )?
      source_1.end()
      source_2.end()
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,true,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[false,true,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[false,false,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    [[true,false,["a","b","c"],[1,2,3,4,5,6]],["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    matcher = matcher.sort()
    await T.perform probe, matcher, error, ->
      return new Promise ( resolve, reject ) ->
        [ defer_mainstream
          defer_bystream
          mainstream_values
          bystream_values ] = probe
        R                   = []
        drainer             = -> R = R.sort(); resolve R
        mainsource          = PS.new_push_source()
        bysource            = PS.new_push_source()
        #...................................................................................................
        bystream            = []
        bystream.push bysource
        bystream.push PS.$watch ( d ) -> whisper '10191-5', 'bysource', jr d
        bystream.push PS.$defer() if defer_bystream
        bystream = PS.pull bystream...
        #...................................................................................................
        mainstream          = []
        mainstream.push mainsource
        mainstream.push PS.$defer() if defer_mainstream
        mainstream.push PS.$watch ( d ) -> whisper '10191-6', 'mainstream', jr d
        mainstream.push PS.$wye bystream
        mainstream.push PS.$watch ( d ) -> R.push d
        mainstream.push PS.$watch ( d ) -> urge CND.white '10191-7', 'confluence', jr d
        mainstream.push PS.$drain drainer
        PS.pull mainstream...
        max_idx = ( Math.max mainstream_values.length, bystream_values.length ) - 1
        for idx in [ 0 .. max_idx ]
          mainsource.push x if ( x = mainstream_values[ idx ] )?
          bysource.push   x if ( x = bystream_values[   idx ] )?
        mainsource.end()
        bysource.end()
        return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 3" ] = ( T, done ) ->
  probes_and_matchers = [
    [{start_value:0.5,delta: 0.01},["a",1,"b",2,"c",3,4,5,6],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    probe.min = 1 / 3 - probe.delta
    probe.max = 1 / 3 + probe.delta
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R                   = []
      drainer             = -> debug '10191-1', "mainstream ended"; resolve R
      mainsource          = PS.new_push_source()
      bysource            = PS.new_push_source()
      #...................................................................................................
      bystream            = []
      bystream.push bysource
      bystream.push PS.$watch ( d ) -> whisper '10191-1', 'bysource', jr d
      bystream = PS.pull bystream...
      #...................................................................................................
      mainstream          = []
      mainstream.push mainsource
      mainstream.push PS.$watch ( d ) -> whisper '10191-2', 'mainstream', jr d
      # mainstream.push PS.$drain()
      mainstream.push PS.$wye bystream
      mainstream.push PS.$watch ( d ) -> whisper '10191-3', 'mainstream', jr d
      # mainstream.push PS.$defer()
      mainstream.push PS.$ ( d, send ) ->
        send d
        if probe.min <= d <= probe.max
          bysource.send null
          send null
        else
          debug d
          bysource.send ( 1 - d ) / 2
      mainstream.push PS.$defer()
      mainstream.push PS.$watch ( d ) -> urge CND.white '10191-4', 'confluence', jr d
      mainstream.push PS.$watch ( d ) -> R.push d
      mainstream.push PS.$drain drainer
      PS.pull mainstream...
      mainsource.send probe.start_value
      return null
  return null




############################################################################################################
unless module.parent?
  # test @
  # test @[ "$merge 1" ]
  # test @[ "$wye 1" ]
  # test @[ "$wye 2" ]
  test @[ "$wye 3" ]

