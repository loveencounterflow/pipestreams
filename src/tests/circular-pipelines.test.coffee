
'use strict'




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'GENERATOR-AS-SOURCE'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS


#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 1" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    [[false,3,4],[3,4,10,2,5,1,16,8,4,2,1],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      buffer                    = [ values..., ]
      mainsource                = PS.new_refillable_source buffer, { repeat: 1, }
      collector                 = []
      mainline                  = []
      mainline.push mainsource
      mainline.push PS.$defer() if use_defer
      mainline.push $ ( d, send ) ->
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
      mainline.push PS.$collect { collector, }
      mainline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "circular pipeline 2" ] = ( T, done ) ->
  probes_and_matchers = [
    [[true,3,4],[3,4,10,2,5,1,],null]
    [[false,3,4],[3,4,10,2,5,1,],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> new Promise ( resolve ) ->
      #.....................................................................................................
      [ use_defer, values..., ] = probe
      buffer                    = [ values..., ]
      mainsource                = PS.new_refillable_source buffer, { repeat: 1, }
      collector                 = []
      mainline                  = []
      mainline.push mainsource
      mainline.push PS.$defer() if use_defer
      mainline.push $ ( d, send ) ->
        return send PS.symbols.end if d is 16
        if d > 1
          if d %% 2 is 0 then buffer.push d / 2
          else                buffer.push d * 3 + 1
        send d
      mainline.push PS.$collect { collector, }
      mainline.push PS.$drain ->
        help collector
        resolve collector
      PS.pull mainline...
  #.........................................................................................................
  done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "_generator as source 2" ] = ( T, done ) ->
  count = 0
  #.........................................................................................................
  g = ( max ) ->
    loop
      break if count >= max
      yield ++count
    return null
  #.........................................................................................................
  await T.perform null, [1,2,3,4,null,6,7,8,9,10], ->
    return new Promise ( resolve ) ->
      pipeline = []
      pipeline.push PS.new_generator_source g 10
      pipeline.push $ ( d, send ) -> send if d is 5 then null else d
      pipeline.push PS.$show()
      pipeline.push PS.$collect()
      pipeline.push PS.$watch ( d ) ->
        debug '22920', d
        resolve d
      pipeline.push PS.$drain()
      PS.pull pipeline...
  done()
  return null


############################################################################################################
unless module.parent?
  test @

