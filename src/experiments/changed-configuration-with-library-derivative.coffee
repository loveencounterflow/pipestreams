


'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/DERIVATIVE'
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
test                      = require 'guy-test'
eq                        = CND.equals
jr                        = JSON.stringify
#...........................................................................................................
PS                        = require '../..'
{ $
  $async }                = PS
#...........................................................................................................
{ jr
  copy
  is_empty
  assign }                = CND
create 										= Object.create
{ inspect, }              = require 'util'
xrpr                      = ( x ) -> inspect x, { colors: yes, breakLength: Infinity, maxArrayLength: Infinity, depth: Infinity, }
abort                     = -> throw new Error 'abort'



{ key: '~end', }
{ key: '~collect', }
{ key: '~recycle',value: {key: 'foo', value: 42, }, }


#===========================================================================================================
provide_library = ->
	@settings = { foo:42, bar: 0, }

	@add = ( x ) -> x + @settings.foo

#===========================================================================================================
L1 = {}
provide_library.apply L1
L2 = assign ( Object.create L1 ), { settings: assign {}, L1.settings, { foo: 2, } }
L3 = assign ( Object.create L1 ), { settings: assign ( Object.create L1.settings ), { foo: 3, } }
L4 = CND.deep_copy L1
L4.settings.foo = 4

debug 'L1         	', xrpr L1
debug 'L1.settings	', xrpr L1.settings
debug 'L1.add     	', xrpr L1.add
echo()
debug 'L2         	', xrpr L2
debug 'L2.settings	', xrpr L2.settings
debug 'L2.add     	', xrpr L2.add
echo()
debug 'L3         	', xrpr L3
debug 'L3.settings	', xrpr L3.settings
debug 'L3.add     	', xrpr L3.add
echo()
debug 'L4         	', xrpr L4
debug 'L4.settings	', xrpr L4.settings
debug 'L4.add     	', xrpr L4.add
echo()
debug 'L1.add 100		', xrpr L1.add 100
debug 'L2.add 100		', xrpr L2.add 100
debug 'L3.add 100		', xrpr L3.add 100
debug 'L4.add 100		', xrpr L4.add 100

debug ( key for key of L1 ), ( key for key of L1.settings )
debug ( key for key of L2 ), ( key for key of L2.settings )
debug ( key for key of L3 ), ( key for key of L3.settings )
debug ( key for key of L4 ), ( key for key of L4.settings )

info ( eq ( Symbol     'x' ), ( Symbol     'x' ) ), ( eq ( Symbol     'x' ), ( Symbol     'y' ) )
info ( eq ( Symbol.for 'x' ), ( Symbol.for 'x' ) ), ( eq ( Symbol.for 'x' ), ( Symbol.for 'y' ) )
info ( eq { key: Symbol.for 'end', }, { key: Symbol.for 'end', } )
info ( eq { key: Symbol.for 'end', }, { key: Symbol.for 'other', } )
info ( eq { key: Symbol     'end', }, { key: Symbol     'end', } )
d = { key: Symbol.for 'end', }
info d, CND.deep_copy { key: Symbol.for 'end', }
info eq ( Symbol.for 'x' ), CND.deep_copy ( Symbol.for 'x' )
echo()
info L1 is L2
info L1 is L3
info L1 is L4






