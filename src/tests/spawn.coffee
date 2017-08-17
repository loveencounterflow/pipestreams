

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

###
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
###

#-----------------------------------------------------------------------------------------------------------
TAP.test "spawn 2", ( T ) ->
  probes_and_matchers = [
    [ 'xxx ; echo "helo" && exit 1', ]
    [ 'xxx ; echo "helo" && exit 0', ]
    [ 'xxx ; echo "helo"', ]
    [ 'xxx && echo "helo"', ]
    [ 'exit 111', ]
    [ 'ls && echo_to_stderr() { cat <<< "$@" 1>&2; }; echo_to_stderr what', ]
    [ '( >&2 echo "error" )', ]
    [ 'echo_to_stderr() { cat <<< "$@" 1>&2; }; echo_to_stderr what; echo else; sleep 1; kill -9 $$', ]
    [ 'kill -2 $$', ]
    [ 'exit 130', ]
    [ 'bonkers', ]
    [ 'bonkers 2>&1; exit 0', ]
    [ 'bonkers; echo "success!"; exit 0', ]
    [ 'bonkers; echo "success!"; kill -27 $$', ]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    help 'stopped'
    tasks.shift()
    return T.end() if tasks.length is 0
    tasks[ 0 ]()
  #.........................................................................................................
  for [ command, ], idx in probes_and_matchers
    do ( command, idx ) ->
      tasks.push ->
        on_stop = PS.new_event_collector 'stop', ->
          # help "task #{idx} stopped"
          # next()
        source    = PS.spawn command
        pipeline  = []
        pipeline.push source
        pipeline.push PS.$collect()
        pipeline.push PS.$show()
        pipeline.push on_stop.add PS.$drain()
        PS.pull pipeline...
  #.........................................................................................................
  # tasks[ 0  ]() for _ in [ 0 .. 10 ]
  tasks[ 13 ]() for _ in [ 0 .. 10 ]
  return null


