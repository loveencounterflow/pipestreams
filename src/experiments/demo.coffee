
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/DEMO'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
PS 												= require '../..'
{ $ }											= PS


#-----------------------------------------------------------------------------------------------------------
@demo = -> new Promise ( resolve, reject ) =>
	source 		= PS.new_push_source()
	pipeline 	= []
	pipeline.push source
	pipeline.push PS.$show()
	pipeline.push PS.$drain =>
		help 'ok'
		resolve()
	PS.pull pipeline...
	for idx in [ 1 .. 5 ]
		source.send idx
	source.end()
	return null

############################################################################################################
unless module.parent?
	L = @
	do ->
		await L.demo()






