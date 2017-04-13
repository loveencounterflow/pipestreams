

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
TAP.test "tee and stop events", ( T ) ->
  sink_0_path       = '/tmp/pipestreams-test-tee-0.txt'
  sink_1_path       = '/tmp/pipestreams-test-tee-1.txt'
  sink_2_path       = '/tmp/pipestreams-test-tee-2.txt'
  sink_0            = PS.new_file_sink sink_0_path
  sink_1            = PS.new_file_sink sink_1_path
  sink_2            = PS.new_file_sink sink_2_path
  sink_0_finished   = no
  sink_1_finished   = no
  sink_2_finished   = no
  #.........................................................................................................
  $link       = ( linker )  -> PS.map    ( value  ) -> ( JSON.stringify value ) + linker
  $keep_odd   =             -> PS.filter ( number ) -> number % 2 isnt 0
  $keep_even  =             -> PS.filter ( number ) -> number % 2 is   0
  #.............'............................................................................................
  finish = ->
    if sink_0_finished then help "sink_0 finished" else warn "waiting for sink_0"
    if sink_1_finished then help "sink_1 finished" else warn "waiting for sink_1"
    if sink_2_finished then help "sink_2 finished" else warn "waiting for sink_2"
    whisper '----------------------'
    # return unless sink_0_finished
    # return unless sink_0_finished and sink_1_finished
    return unless sink_0_finished and sink_1_finished and sink_2_finished
    T.ok CND.equals ( FS.readFileSync sink_0_path, { encoding: 'utf-8', } ), '0-1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-'
    T.ok CND.equals ( FS.readFileSync sink_1_path, { encoding: 'utf-8', } ), '1*3*5*7*9*11*13*15*17*19*'
    T.ok CND.equals ( FS.readFileSync sink_2_path, { encoding: 'utf-8', } ), '0+2+4+6+8+10+12+14+16+18+20+'
    # debug '30091', FS.readFileSync sink_1_path, { encoding: 'utf-8', }
    # debug '30091', FS.readFileSync sink_2_path, { encoding: 'utf-8', }
    T.end()
  #.........................................................................................................
  sink_0.on 'stop', => sink_0_finished = yes; finish()
  sink_1.on 'stop', => sink_1_finished = yes; finish()
  sink_2.on 'stop', => sink_2_finished = yes; finish()
  #.........................................................................................................
  ppline_1  = []
  ppline_1.push $keep_odd()
  ppline_1.push $link '*'
  ppline_1.push sink_1
  stream_1 = PS.pull ppline_1...
  #.........................................................................................................
  ppline_2  = []
  ppline_2.push $keep_even()
  ppline_2.push $link '+'
  ppline_2.push sink_2
  stream_2 = PS.pull ppline_2...
  #.........................................................................................................
  ppline_0  = []
  ppline_0.push PS.new_value_source ( n for n in [ 0 .. 20 ] )
  ppline_0.push PS.$tee stream_1
  ppline_0.push PS.$tee stream_2
  ppline_0.push $link '-'
  ppline_0.push sink_0
  #.........................................................................................................
  stream_0 = PS.pull ppline_0...
  # PS.pull ppline_1...
  #.........................................................................................................
  return null

