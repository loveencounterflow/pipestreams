

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
# TAP                       = require 'tape'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
#...........................................................................................................
jr                        = JSON.stringify

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
TAP.test "spawn 2", ( T ) ->
  probes_and_matchers = [
    ["xxx ; echo \"helo\" && exit 1","CDDX",1,null,"helo","/bin/sh: xxx: command not found"]
    ["xxx ; echo \"helo\" && exit 0","CDDX",0,null,"helo","/bin/sh: xxx: command not found"]
    ["xxx ; echo \"helo\"","CDDX",0,null,"helo","/bin/sh: xxx: command not found"]
    ["xxx && echo \"helo\"","CDX",127,null,"","/bin/sh: xxx: command not found"]
    ["exit 111","CX",111,null,"",""]
    ["ls && echo_to_stderr() { cat <<< \"$@\" 1>&2; }; echo_to_stderr what","CDDDDDDDDDDX",0,null,"coverage\nlib\nLICENSE\nnode_modules\npackage.json\npackage-lock.json\nREADME.md\nsrc\ntest-data","what"]
    ["( >&2 echo \"error\" )","CDX",0,null,"","error"]
    ["echo_to_stderr() { cat <<< \"$@\" 1>&2; }; echo_to_stderr what; echo else; sleep 1; kill -9 $$","CDDX",137,"SIGKILL","else","what"]
    ["kill -2 $$","CX",130,"SIGINT","",""]
    ["exit 130","CX",130,null,"",""]
    ["bonkers","CDX",127,null,"","/bin/sh: bonkers: command not found"]
    ["bonkers 2>&1; exit 0","CDX",0,null,"/bin/sh: bonkers: command not found",""]
    ["bonkers; echo \"success!\"; exit 0","CDDX",0,null,"success!","/bin/sh: bonkers: command not found"]
    ["bonkers; echo \"success!\"; kill -27 $$","CDDX",155,"SIGPROF","success!","/bin/sh: bonkers: command not found"]
    ]
  #.........................................................................................................
  tasks = []
  next  = ->
    tasks.shift()
    return T.end() if tasks.length is 0
    tasks[ 0 ]()
    # tasks[ 13 ]()
  #.........................................................................................................
  for probe_and_matcher in probes_and_matchers
    do ( probe_and_matcher ) ->
      [ command, shape_matcher, code_matcher, signal_matcher, out_matcher, err_matcher, ] = probe_and_matcher
      tasks.push ->
        shape       = []
        out         = []
        err         = []
        code        = undefined
        signal      = undefined
        command_ok  = no
        #...................................................................................................
        on_stop   = PS.new_event_collector 'stop', ->
          shape = shape.join ''
          out   = out.join '\n'
          err   = err.join '\n'
          T.ok command_ok
          T.equal shape,  shape_matcher,  "shape,  shape_matcher"
          T.equal code,   code_matcher,   "code,   code_matcher"
          T.equal signal, signal_matcher, "signal, signal_matcher"
          T.equal out,    out_matcher,    "out,    out_matcher"
          T.equal err,    err_matcher,    "err,    err_matcher"
          # debug jr [ command, shape, code, signal, out, err, ]
          next()
        #...................................................................................................
        source    = PS.spawn command
        pipeline  = []
        pipeline.push source
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'command'          then  shape.push 'C'
            when 'stdout', 'stderr' then  shape.push 'D'
            when 'exit'             then  shape.push 'X'
            else                          shape.push '?'
        pipeline.push PS.$watch ( [ key, value, ] ) -> command_ok = yes if key is 'command' and value is command
        pipeline.push PS.$watch ( [ key, value, ] ) ->
          switch key
            when 'stdout' then  out.push value
            when 'stderr' then  err.push value
            when 'exit'   then  { code, signal, } = value
        pipeline.push PS.$collect()
        # pipeline.push PS.$show()
        pipeline.push on_stop.add PS.$drain()
        PS.pull pipeline...
  #.........................................................................................................
  tasks[ 0 ]()
  # tasks[ 13 ]()
  return null


