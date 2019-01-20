

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
        source_1.send x if ( x = probe[ 0 ][ idx ] )?
        source_2.send x if ( x = probe[ 1 ][ idx ] )?
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
        source_1.send x if ( x = probe[ 0 ][ idx ] )?
        source_2.send x if ( x = probe[ 1 ][ idx ] )?
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
        bystream.push PS.$watch ( d ) -> whisper '10192-1', 'bysource', jr d
        bystream.push PS.$defer() if defer_bystream
        bystream.push PS.$watch ( d ) -> whisper '10192-1a', 'bysource', jr d
        bystream = PS.pull bystream...
        #...................................................................................................
        mainstream          = []
        mainstream.push mainsource
        mainstream.push $ { last: 'last' }, ( d, send ) -> urge '10192-2', 'mainstream', d; send d unless d is 'last'
        mainstream.push PS.$defer() if defer_mainstream
        mainstream.push PS.$watch ( d ) -> whisper '10192-3', 'mainstream', jr d
        mainstream.push PS.$wye bystream
        mainstream.push PS.$watch ( d ) -> R.push d
        mainstream.push PS.$watch ( d ) -> urge CND.white '10192-4', 'confluence', jr d
        mainstream.push PS.$drain drainer
        PS.pull mainstream...
        max_idx = ( Math.max mainstream_values.length, bystream_values.length ) - 1
        for idx in [ 0 .. max_idx ]
          mainsource.send x if ( x = mainstream_values[ idx ] )?
          bysource.send   x if ( x = bystream_values[   idx ] )?
        mainsource.end()
        bysource.end()
        return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "divert" ] = ( T, done ) ->
  probes_and_matchers = [
    [[10,11,12,13,14,15,16,17,18,19,20],{"odd_numbers":[11,13,15,17,19],"all_numbers":[10,11,12,13,14,15,16,17,18,19,20]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      is_odd      = ( d ) -> ( d % 2 ) isnt 0
      odd_numbers = []
      all_numbers = []
      R           = { odd_numbers, all_numbers, }
      #.....................................................................................................
      byline      = []
      mainline    = []
      #.....................................................................................................
      byline.push PS.$show title: 'bystream'
      byline.push PS.$watch ( d ) -> odd_numbers.push d
      byline.push PS.$drain()
      bystream  = PS.pull byline...
      #.....................................................................................................
      mainline.push PS.new_value_source probe
      mainline.push PS.$tee is_odd, bystream
      mainline.push PS.$show title: 'mainstream'
      mainline.push PS.$watch ( d ) -> all_numbers.push d
      mainline.push PS.$drain ->
        help 'ok'
        resolve R
      PS.pull mainline...
      #.....................................................................................................
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "bifurcate" ] = ( T, done ) ->
  probes_and_matchers = [
    [[10,11,12,13,14,15,16,17,18,19,20],{"odd_numbers":[11,13,15,17,19],"even_numbers":[10,12,14,16,18,20]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      is_even       = ( d ) -> ( d % 2 ) is 0
      odd_numbers   = []
      even_numbers  = []
      R             = { odd_numbers, even_numbers, }
      #.....................................................................................................
      byline        = []
      mainline      = []
      #.....................................................................................................
      byline.push PS.$show title: 'bystream'
      byline.push PS.$watch ( d ) -> even_numbers.push d
      byline.push PS.$drain()
      bystream  = PS.pull byline...
      #.....................................................................................................
      mainline.push PS.new_value_source probe
      mainline.push PS.$bifurcate is_even, bystream
      mainline.push PS.$show title: 'mainstream'
      mainline.push PS.$watch ( d ) -> odd_numbers.push d
      mainline.push PS.$drain ->
        help 'ok'
        resolve R
      PS.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "wye from asnyc random sources" ] = ( T, done ) ->
  ### A mainstream and a bystream are created from lists of values using
  `PS.new_random_async_value_source()`. Values from both streams are marked up for their respective source.
  After being funnelled together using `PS.$wye()`, the result is a POD whose keys are the source names
  and whose values are lists of the values in the order they were seen. The expected result is that the
  ordering of each stream is preserved, no values get lost, and that relative ordering of values in the
  mainstream and the bystream is arbitrary. ###
  probes_and_matchers = [
    # [[[3,4,5,6,7,8],["just","a","few","words"]],{"bystream":[3,4,5,6,7,8],"mainstream":["just","a","few","words"]},null]
    # [[[3,4],[9,10,11,true]],{"bystream":[3,4],"mainstream":[9,10,11,true]},null]
    [[[3,4,{"foo":"bar"}],[false,9,10,11,true]],{"bystream":[3,4,{"foo":"bar"}],"mainstream":[false,9,10,11,true]},null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    R = null
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      byline    = []
      byline.push PS.new_random_async_value_source 0.1, probe[ 0 ]
      byline.push $ ( d, send ) -> send [ 'bystream', d, ]
      byline.push $ { first: 'first', last: 'last', }, ( d, send ) ->
        if d in [ 'first', 'last', ]
          warn 'bystream', jr d
        else
          whisper 'bystream', jr d
      #.....................................................................................................
      mainline = []
      mainline.push PS.new_random_async_value_source probe[ 1 ]
      mainline.push $ ( d, send ) -> send [ 'mainstream', d, ]
      mainline.push PS.$wye PS.pull byline...
      mainline.push $ { first: 'first', last: 'last', }, ( d, send ) ->
        if d in [ 'first', 'last', ]
          warn 'mainstream', jr d
        else
          whisper 'mainstream', jr d
      mainline.push PS.$collect()
      mainline.push PS.$watch ( d ) ->
        R       = { bystream: [], mainstream: [], }
        R[ x[ 0 ] ].push x[ 1 ] for x in d
      mainline.push PS.$drain ->
        help 'ok'
        resolve R
      PS.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


#-----------------------------------------------------------------------------------------------------------
@[ "$wye 3" ] = ( T, done ) ->
  probes_and_matchers = [
    [{"start_value":0.5,"delta":0.01,},[0.5,0.25,0.375,0.3125,0.34375,0.328125],null]
    ]
  end_sym = Symbol.for 'end'
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      R                   = []
      drainer             = -> debug '10191-1', "mainstream ended"; resolve R
      mainsource          = PS.new_push_source()
      bysource            = PS.new_push_source()
      #...................................................................................................
      bystream            = []
      bystream.push bysource
      bystream.push $ { last: end_sym,}, ( d, send ) ->
        if d is end_sym
          debug '22092-1', "bystream ended"
        else
          send d
        return null
      bystream.push PS.$watch ( d ) -> whisper '10191-1', 'bysource', jr d
      bystream = PS.pull bystream...
      #...................................................................................................
      mainstream          = []
      mainstream.push mainsource
      mainstream.push PS.$wye bystream
      mainstream.push PS.$async ( d, send, done ) ->
        send d
        if ( 1 / 3 - probe.delta ) <= d <= ( 1 / 3 + probe.delta )
          defer ->
            # send end_sym
            mainsource.end()
            bysource.end()
            done()
        else
          defer ->
            bysource.send ( 1 - d ) / 2
            done()
        return null
      mainstream.push PS.$defer()
      mainstream.push PS.$watch ( d ) -> urge CND.white '10191-4', 'confluence', jr d
      mainstream.push PS.$watch ( d ) -> R.push d
      mainstream.push PS.$drain drainer
      PS.pull mainstream...
      mainsource.send probe.start_value
      return null
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "$wye 4" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,true,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    [[false,false,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    [[false,true,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    # [[true,false,[10,11,12,13,14,15],[20,21,22,23,24,25]],[10,11,12,13,14,15,20,21,22,23,24,25],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    #.......................................................................................................
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ use_bystream_vs
        use_mainstream_vs
        byline_values
        mainline_values ] = probe
      R                   = []
      #.....................................................................................................
      byline              = []
      mainline            = []
      #.....................................................................................................
      byline.push ( if use_bystream_vs then PS.new_value_source else PS.new_random_async_value_source ) byline_values
      byline.push PS.$show title: 'bystream'
      bystream            = PS.pull byline...
      #.....................................................................................................
      mainline.push ( if use_mainstream_vs then PS.new_value_source else PS.new_random_async_value_source ) mainline_values
      mainline.push PS.$show title: 'mainstream'
      # mainline.push PS.$defer()
      mainline.push PS.$wye bystream
      mainline.push PS.$show title: 'confluence'
      mainline.push PS.$collect { collector: R, }
      mainline.push PS.$drain ->
        help 'ok'
        resolve R.sort()
      mainstream          = PS.pull mainline...
      #.....................................................................................................
      return null
  #.........................................................................................................
  done()
  return null


############################################################################################################
unless module.parent?
  # test @
  # test @[ "$merge 1" ]
  # test @[ "$wye 1" ]
  # test @[ "$wye 2" ]
  # test @[ "$wye 3" ], { timeout: 5000, }
  # test @[ "divert" ]
  # test @[ "bifurcate" ]
  # test @[ "wye from asnyc random sources" ]
  test @[ "$wye 4" ], { timeout: 2000, }

