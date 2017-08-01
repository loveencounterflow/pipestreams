

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
TAP.test "sample (p = 0)", ( T ) ->
  probe             = Array.from '𠳬矗㒹兢林森𣡕𣡽𨲍騳𩥋驫𦣦臦𦣩𫇆'
  matcher           = ''
  source            = PS.new_value_source Array.from probe
  on_stop           = PS.new_event_collector 'stop', -> T.end()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push PS.$sample 0
  pipeline.push PS.$collect()
  pipeline.push PS.$watch ( chrs ) ->
    chrs = chrs.join ''
    help chrs, chrs.length
    T.ok CND.equals chrs, matcher
  pipeline.push on_stop.add PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "sample (p = 1)", ( T ) ->
  probe             = '𠳬矗㒹兢林森𣡕𣡽𨲍騳𩥋驫𦣦臦𦣩𫇆'
  matcher           = probe
  source            = PS.new_value_source Array.from probe
  on_stop           = PS.new_event_collector 'stop', -> T.end()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push PS.$sample 1
  pipeline.push PS.$collect()
  pipeline.push PS.$watch ( chrs ) ->
    chrs = chrs.join ''
    help chrs, chrs.length
    T.ok CND.equals chrs, matcher
  pipeline.push on_stop.add PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
TAP.test "sample (1)", ( T ) ->
  probe             = '𠳬矗㒹兢林森𣡕𣡽𨲍騳𩥋驫𦣦臦𦣩𫇆'
  matcher           = '𠳬㒹森𣡽𨲍騳𩥋𦣦臦𦣩𫇆'
  source            = PS.new_value_source Array.from probe
  on_stop           = PS.new_event_collector 'stop', -> T.end()
  #.........................................................................................................
  pipeline = []
  pipeline.push source
  pipeline.push PS.$sample 8 / 16, seed: 6615
  pipeline.push PS.$collect()
  pipeline.push PS.$watch ( data ) ->
    help ( data.join '' ), data.length
  pipeline.push on_stop.add PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null