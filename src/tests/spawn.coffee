

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

#-----------------------------------------------------------------------------------------------------------
###
@remote_spawn = ( node, handler ) ->
  step @, ( resume ) ->
    yield defer resume
    # debug '20991', node
    on_stop = PS.new_event_collector 'stop', ->
      help 'stopped'
      handler()
    command = 'xxx ; echo "helo" && exit 1'
    command = 'xxx ; echo "helo" && exit 0'
    command = 'xxx ; echo "helo"'
    command = 'xxx && echo "helo"'
    # command = 'exit 111'
    # command = 'ls && echo_to_stderr() { cat <<< "$@" 1>&2; }; echo_to_stderr what'
    # command = '( >&2 echo "error" )'
    command = 'echo_to_stderr() { cat <<< "$@" 1>&2; }; echo_to_stderr what; echo else; sleep 1; kill -9 $$'
    command = 'kill -2 $$'
    command = 'exit 130'
    command = 'bonkers'
    command = 'bonkers 2>&1; exit 0'
    command = 'bonkers; echo "success!"; exit 0'
    command = 'bonkers; echo "success!"; kill -27 $$'
    source  = PS.spawn command, resume
    pipeline        = []
    pipeline.push source
    pipeline.push PS.$show()
    pipeline.push PS.$watch ( [ key, value, ] ) ->
      switch key
        when 'command'  then  urge    rpr value
        when 'stdout'   then  help    rpr value
        when 'stderr'   then  warn    rpr value
        else                  info    rpr value
      return null
    pipeline.push on_stop.add PS.$drain()
    PS.pull pipeline...
    return null
  return null
###