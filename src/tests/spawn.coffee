

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/TEE'
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
TAP                       = require 'tap'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
#...........................................................................................................


#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn 1", ( T ) ->
  # new_pushable              = require 'pull-pushable'
  # source            = new_pushable()
  #.........................................................................................................
  on_error = ( error ) ->
    warn '20191', error.message
      # throw error
  #.........................................................................................................
  command           = 'ls -AlF'
  source            = PS.spawn command, { on_error, cwd: '/tmp', }
  on_stop           = PS.new_event_collector 'stop', -> T.end()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push PS.$watch ( data ) -> whisper rpr data
  pipeline.push PS.$split()
  # pipeline.push PS.$show title: '==='
  pipeline.push PS.$collect()
  pipeline.push PS.$watch ( lines ) -> help lines
  pipeline.push on_stop.add PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

