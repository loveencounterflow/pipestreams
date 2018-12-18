
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/ASYNC-MAP'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
$split                    = require 'pull-split'
$stringify                = require 'pull-stringify'
$utf8                     = require 'pull-utf8-decoder'
new_file_source           = require 'pull-file'
pull                      = require 'pull-stream'
### NOTE these two are different: ###
# $pass_through             = require 'pull-stream/throughs/through'
through                   = require 'pull-through'
async_map                 = require 'pull-stream/throughs/async-map'
$drain                    = require 'pull-stream/sinks/drain'
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
S                         = {}
S.pass_through_count      = 0
# S.pass_through_count      = 1
# S.pass_through_count      = 100
# S.implementation          = 'pull-stream'
S.implementation          = 'pipestreams-map'
# S.implementation          = 'pipestreams-remit'
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS

#-----------------------------------------------------------------------------------------------------------
after = ( dts, f ) -> setTimeout f, dts * 1000


#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 30000


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@[ "async 1" ] = ( T, done ) ->
  ok        = false
  probe     = "abcdef"
  matcher   =  "*a**b**c**d**e**f*"
  pipeline  = []
  pipeline.push PS.new_value_source Array.from probe
  pipeline.push PS._$async_map ( d, handler ) ->
    after ( Math.random() / 5 ), ->
      handler null, '*' + d + '*'
    return null
  pipeline.push PS.$show()
  pipeline.push PS.$join()
  #.........................................................................................................
  pipeline.push PS.$watch ( result ) ->
    echo CND.gold jr [ probe, result, ]
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push PS.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 1 paramap" ] = ( T, done ) ->
  ok        = false
  probe     = "abcdef"
  matcher   =  "*a**b**c**d**e**f*"
  pipeline  = []
  pipeline.push PS.new_value_source Array.from probe
  pipeline.push PS._$paramap ( d, handler ) ->
    after ( Math.random() / 5 ), ->
      handler null, '*' + d + '*'
    return null
  pipeline.push PS.$show()
  pipeline.push PS.$join()
  #.........................................................................................................
  pipeline.push PS.$watch ( result ) ->
    echo CND.gold jr [ probe, result, ]
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push PS.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  PS.pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
### TAINT should be ( hint, method ) ###
provide_async = ->
  unpack_sym = Symbol 'unpack'
  #-----------------------------------------------------------------------------------------------------------
  @$async = ( method ) ->
    throw new Error "µ18187 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
    throw new Error "µ18203 expected one argument, got #{arity}" unless ( arity = arguments.length ) is 1
    throw new Error "µ18219 method arity #{arity} not implemented" unless ( arity = method.length ) is 3
    pipeline = []
    #.........................................................................................................
    pipeline.push @_$paramap ( d, handler ) =>
      collector               = []
      collector[ unpack_sym ] = true
      #.......................................................................................................
      send = ( d ) =>
        return handler true if d is null
        collector.push d
        return null
      #.......................................................................................................
      done = =>
        handler null, collector
        collector = null
        return null
      #.......................................................................................................
      method d, send, done
      return null
    #.........................................................................................................
    pipeline.push @$ ( d, send ) =>
      if ( CND.isa_list d ) and d[ unpack_sym ]
        send x for x in d
      else
        send d
    #.........................................................................................................
    return @pull pipeline...
  return @
provide_async.apply PS

#-----------------------------------------------------------------------------------------------------------
$send_three = ->
  return PS.$async ( d, send, done ) ->
    count = 0
    n     = 3
    after ( Math.random() / 5 ), ->
      debug '77634', d
      for nr in [ 1 .. n ]
        count += +1
        send "(#{d}:#{nr})"
        done() if count >= n
    return null

#-----------------------------------------------------------------------------------------------------------
@[ "async 2" ] = ( T, done ) ->
  ok        = false
  probe     = "abcdef"
  matcher   = "(a:1)(a:2)(a:3)(b:1)(b:2)(b:3)(c:1)(c:2)(c:3)(d:1)(d:2)(d:3)(e:1)(e:2)(e:3)(f:1)(f:2)(f:3)"
  pipeline  = []
  pipeline.push PS.new_value_source Array.from probe
  pipeline.push $send_three()
  pipeline.push PS.$show()
  pipeline.push PS.$join()
  #.........................................................................................................
  pipeline.push PS.$watch ( result ) ->
    echo CND.gold jr [ probe, result, ]
    T.eq result, matcher
    ok = true
  #.........................................................................................................
  pipeline.push PS.$drain ->
    T.fail "failed to pass test" unless ok
    done()
  #.........................................................................................................
  PS.pull pipeline...
  return null


############################################################################################################
unless module.parent?
  include = [
    # "async 1"
    # "async 1 paramap"
    "async 2"
    ]
  @_prune()
  @_main()






