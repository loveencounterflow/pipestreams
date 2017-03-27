
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
TAP                       = require 'tap'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS


#-----------------------------------------------------------------------------------------------------------
TAP.test "genrator as source: random numbers", ( T ) ->
  #.........................................................................................................
  pipeline      = []
  Ø             = ( x ) => pipeline.push x
  # expect_count  = Math.max 0, probes.length - width + 1
  #.........................................................................................................
  $random = ( n, seed, delta ) ->
    rnd = CND.get_rnd n, seed, delta
    return ( end, callback ) ->
      return callback end   if end
      return callback true  if 0 > ( n += -1 )
      callback null, rnd()
  #.........................................................................................................
  Ø $random 10, 1, 1
  Ø PS.$show()
  Ø PS.$collect()
  Ø $ 'null', ( data, send ) ->
    if data?
      # T.ok section_count is expect_count
      send data
    else
      T.end()
      # send null
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...

