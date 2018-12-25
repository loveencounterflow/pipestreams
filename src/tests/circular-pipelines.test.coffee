
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/CIRCULAR-PIPELINES'
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
test                      = require 'guy-test'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
assign                    = Object.assign
after                     = ( dts, f ) -> setTimeout f, dts * 1000
defer                     = setImmediate
jr                        = JSON.stringify
copy                      = ( P... ) -> assign {}, P...
rprx                      = ( d ) -> "#{d.sigil} #{d.key}:: #{jr d.value ? null} #{jr d.stamped ? false}"
# echo '{ ' + ( ( name for name of require './recycle' ).sort().join '\n  ' ) + " } = require './recycle'"
PS2                       = require '../experiments/recycle'
{ select
  select_all
  stamp }                 = PS2

#-----------------------------------------------------------------------------------------------------------
provide_collatz = ->

  #-----------------------------------------------------------------------------------------------------------
  @new_number_event = ( value, other... ) ->
    return PS2.new_single_event 'number', value, other...

  #-----------------------------------------------------------------------------------------------------------
  @is_one  = ( n ) -> n is 1
  @is_odd  = ( n ) -> n %% 2 isnt 0
  @is_even = ( n ) -> n %% 2 is 0

  #-----------------------------------------------------------------------------------------------------------
  @$odd_numbers = ( S ) ->
    return $ ( d, send ) =>
      if ( select d, '!', 'number' ) and ( not @is_one d.value ) and ( @is_odd d.value )
        ### If data event matches condition, stamp and send it; then, send new data that has been computed
        from the event: ###
        send stamp d
        send PS2.recycling ( @new_number_event ( d.value * 3 + 1 ), from: d.value )
      else
        ### If data event doesn't match condition, just send it on; this will implicitly include
        any `~sync` events: ###
        send d
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$even_numbers = ( S ) ->
    ### Same as `$odd_numbers()`, just simplified, and with a different condition for data selection: ###
    return $ ( d, send ) =>
      return send d unless ( select d, '!', 'number' ) and ( @is_even d.value )
      send stamp d
      send PS2.recycling @new_number_event ( d.value / 2 ), from: d.value
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$skip_known = ( S ) ->
    known = new Set()
    return $ ( d, send ) =>
      return send d unless select d, '!', 'number'
      return null if known.has d.value
      send d
      known.add d.value

  #-----------------------------------------------------------------------------------------------------------
  @$terminate = ( S ) ->
    return $ ( d, send ) =>
      if ( select_all d, '!', 'number' ) and ( @is_one d.value )
        send stamp d
        send PS2.new_end_event()
      else
        send d
      return null

  #-----------------------------------------------------------------------------------------------------------
  @$throw_on_illegal = -> PS.$watch ( d ) ->
    if ( select_all d, '!', 'number' ) and ( type = CND.type_of d.value ) isnt 'number'
      throw new Error "found an illegal #{type} in #{rpr d}"
    return null

  #-----------------------------------------------------------------------------------------------------------
  @$main = ( S ) ->
    pipeline = []
    pipeline.push COLLATZ.$skip_known           S
    # pipeline.push PS.$delay 0.1
    pipeline.push COLLATZ.$even_numbers         S
    pipeline.push COLLATZ.$odd_numbers          S
    pipeline.push COLLATZ.$throw_on_illegal     S
    # pipeline.push COLLATZ.$terminate            S
    return PS.pull pipeline...

  #-----------------------------------------------------------------------------------------------------------
  return @
COLLATZ = provide_collatz.apply {}

#-----------------------------------------------------------------------------------------------------------
$collect_numbers = ( S, handler ) ->
  collector = null
  return $ ( d, send ) ->
    collector ?= []
    if select_all d, '~', 'collect'
      send stamp d
      send PS2.new_event '!', 'numbers', collector
      collector = null
    else if select_all d, '!', 'number'
      collector.push d.value
    else
      send d
    return null

#-----------------------------------------------------------------------------------------------------------
$call_back = ( S, handler ) ->
  collector = null
  return PS.$watch ( d ) ->
    if select d, '!', 'numbers'
      collector ?= []
      collector.push d.value
    else if select d, '~', 'call_back'
      handler null, collector
      collector = null
    return null

#-----------------------------------------------------------------------------------------------------------
new_collatz_pipeline = ( S, handler ) ->
  S.source    = PS2.new_push_source()
  pipeline    = []
  #.........................................................................................................
  pipeline.push S.source
  pipeline.push PS2.$unwrap_recycled()
  # pipeline.push PS.$watch ( d ) -> help '37744-4', jr d
  # pipeline.push PS.$delay 0.25
  pipeline.push PS.$defer()
  pipeline.push COLLATZ.$main S
  pipeline.push PS2.$recycle S.source.push
  pipeline.push $collect_numbers  S
  pipeline.push $call_back        S, handler
  pipeline.push PS.$drain -> help 'ok'
  PS.pull pipeline...
  #.........................................................................................................
  R       = ( value ) ->
    if CND.isa_number value then  S.source.push PS2.new_event '!', 'number', value
    else                          S.source.push value
  R.end   = -> S.source.end()
  return R


#-----------------------------------------------------------------------------------------------------------
@[ "collatz-conjecture" ] = ( T, done ) ->
  S                   = {}
  probes_and_matchers = [
    [[2,3,4,5,6,7,8,9,10],[[2,1],[3,10,5,16,8,4],[],[],[6],[7,22,11,34,17,52,26,13,40,20],[],[9,28,14],[]]]
    ]
  #.........................................................................................................
  for [ probe, matcher, ] in probes_and_matchers
    handler = ( error, result ) ->
      throw error if error?
      help jr [ probe, result, ]
      T.eq result, matcher
      done()
    #.......................................................................................................
    send = new_collatz_pipeline S, handler
    for n in probe
      do ( n ) ->
        debug '84756', send n
        send PS2.new_system_event 'collect'
    send PS2.new_system_event 'call_back'
  #.........................................................................................................
  return null

############################################################################################################
unless module.parent?
  test @, { timeout: 30000, }

