
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS'
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
CP                        = require 'child_process'
glob                      = require 'globby'
#...........................................................................................................
_new_push_source          = require 'pull-pushable'
$pass_through             = require 'pull-stream/throughs/through'
$pull_drain               = require 'pull-stream/sinks/drain'
$values                   = require 'pull-stream/sources/values'
$paramap                  = require 'pull-paramap'
pull                      = require 'pull-stream'
pull_through              = require 'pull-through'
pull_cont                 = require 'pull-cont'
_map_errors               = require './_map_errors'
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout f, dts * 1000
defer                     = setImmediate
return_id                 = ( x ) -> x
{ is_empty
  copy
  assign
  jr }                    = CND


#===========================================================================================================
# ISA METHODS
#-----------------------------------------------------------------------------------------------------------
### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
@_isa_njs_stream            = ( x ) -> x instanceof ( require 'stream' ).Stream
@_isa_readable_njs_stream   = ( x ) -> ( @_isa_njs_stream x ) and x.readable
@_isa_writable_njs_stream   = ( x ) -> ( @_isa_njs_stream x ) and x.writable
@_isa_readonly_njs_stream   = ( x ) -> ( @_isa_njs_stream x ) and x.readable and not x.writable
@_isa_writeonly_njs_stream  = ( x ) -> ( @_isa_njs_stream x ) and x.writable and not x.readable
@_isa_duplex_njs_stream     = ( x ) -> ( @_isa_njs_stream x ) and x.readable and     x.writable



#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@new_value_source = ( values ) -> $values values

#-----------------------------------------------------------------------------------------------------------
@new_push_source = ->
  ### Return a `pull-streams` `pushable`. Methods `push` and `end` will be bound to the instance
  so they can be freely passed around. ###
  R       = _new_push_source()
  R.push  = R.push.bind R
  R.end   = R.end.bind R
  return R

#-----------------------------------------------------------------------------------------------------------
@new_generator_source = ( generator ) ->
  return ( end, handler ) ->
    return handler end if end
    R = generator.next()
    return handler true if R.done
    handler null, R.value

#-----------------------------------------------------------------------------------------------------------
@$filter = ( method ) ->
  throw new Error "µ15533 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "µ16298 method arity #{arity} not implemented"
  #.........................................................................................................
  return pull.filter method

#-----------------------------------------------------------------------------------------------------------
@$map = ( method ) ->
  throw new Error "µ17063 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "µ17828 method arity #{arity} not implemented"
  #.........................................................................................................
  return _map_errors method

#-----------------------------------------------------------------------------------------------------------
@$ = @remit = ( hint, method ) ->
  switch arity = arguments.length
    when 1
      method  = hint
      hint    = null
    when 2
      throw new Error "µ18593 unknown hint #{rpr hint}" unless hint is 'null'
    else throw new Error "µ19358 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  switch client_arity = method.length
    when 2 then null
    else throw new Error "µ20123 method arity #{client_arity} not implemented"
  #.........................................................................................................
  throw new Error "µ20888 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  #.........................................................................................................
  self    = null
  send    = ( data ) => self.queue data
  on_end  = null
  #.........................................................................................................
  on_data = ( data ) ->
    self = @
    method data, send
    self = null
    return null
  #.........................................................................................................
  if hint is 'null'
    on_end = ->
      self = @
      method null, send
      self = null
      ### somewhat hidden in the docs: *must* call `@queue null` to end stream: ###
      @queue null
      return null
  #.........................................................................................................
  return pull_through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$async = ( hint, method ) ->
  ### TAINT currently all results from client method are buffered until `done` gets called; see whether
  it is possible to use `await` so that each result can be sent doen the pipeline w/out buffering ###
  switch arity = arguments.length
    when 1
      method  = hint
      hint    = null
    when 2
      throw new Error "µ18594 unknown hint #{rpr hint}" unless hint is 'null'
    else throw new Error "µ19359 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  throw new Error "µ18187 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ18203 expected one or two arguments, got #{arity}" unless 1 <= ( arity = arguments.length ) <= 2
  throw new Error "µ18219 method arity #{arity} not implemented" unless ( arity = method.length ) is 3
  end_sym   = Symbol 'end'
  pipeline  = []
  #.........................................................................................................
  if hint is 'null'
    pipeline.push @$ 'null', ( d, send ) => send if d? then d else end_sym
  #.........................................................................................................
  pipeline.push $paramap ( d, handler ) =>
    collector = []
    prv_send  = null
    #.......................................................................................................
    send = ( d ) =>
      return handler true if d is null
      collector.unshift d
      return null
    #.......................................................................................................
    done = =>
      handler null, collector
      return null
    #.......................................................................................................
    d = null if d is end_sym
    method d, send, done
    return null
  #.........................................................................................................
  pipeline.push @$defer()
  pipeline.push @$ ( d, send ) => send d.pop() while d.length > 0
  #.........................................................................................................
  return @pull pipeline...


#===========================================================================================================
# ASYNC TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@$defer =         -> $paramap ( d, handler ) -> defer       -> handler null, d
@$delay = ( dts ) -> $paramap ( d, handler ) -> after dts,  -> handler null, d


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$pass = -> _map_errors ( data ) => data
@$drain = ( on_end = null ) -> $pull_drain null, on_end

#-----------------------------------------------------------------------------------------------------------
@$watch = ( method ) ->
  return _map_errors ( data ) =>
    method data
    return data

#-----------------------------------------------------------------------------------------------------------
@pull = ( methods... ) ->
  return @$pass() if methods.length is 0
  for method, idx in methods
    continue if ( type = CND.type_of method ) is 'function'
    throw new Error "µ25478 expected a function, got a #{type} for argument # #{idx + 1}"
  return pull methods...


#-----------------------------------------------------------------------------------------------------------
@$collect = ( settings ) ->
  throw new Error "µ33128 API changed" if settings?
  collector = []
  return @$ 'null', ( data, send ) =>
    if data? then collector.push data
    else send collector
    return null

#-----------------------------------------------------------------------------------------------------------
@$spread = ->
  return @$ ( collection, send ) =>
    send element for element in collection
    return null

#-----------------------------------------------------------------------------------------------------------
@$show = ( settings ) ->
  title     = settings?[ 'title'      ] ? '-->'
  serialize = settings?[ 'serialize'  ] ? JSON.stringify
  return @$watch ( data ) => info title, serialize data


#===========================================================================================================
# SAMPLING / THINNING OUT
#-----------------------------------------------------------------------------------------------------------
@$sample = ( p = 0.5, options ) ->
  #.........................................................................................................
  unless 0 <= p <= 1
    throw new Error "µ42308 expected a number between 0 and 1, got #{rpr p}"
  #.........................................................................................................
  ### Handle trivial edge cases faster (hopefully): ###
  return ( @$map    ( record ) => record  ) if p == 1
  return ( @$filter ( record ) => false   ) if p == 0
  #.........................................................................................................
  headers   = options?[ 'headers'     ] ? false
  seed      = options?[ 'seed'        ] ? null
  is_first  = headers
  rnd       = if seed? then CND.get_rnd seed else Math.random
  #.........................................................................................................
  return @$ ( record, send ) =>
    if is_first
      is_first = false
      return send record
    send record if rnd() < p

############################################################################################################
### Gather methods from submodules, bind all methods ###
L = @
do ->
  patterns  = [ '*.js', '!main.js', '!_*' ]
  settings  = { cwd: ( PATH.join __dirname ), deep: false, absolute: true, }
  paths     = glob.sync patterns, settings
  #.........................................................................................................
  for path in paths
    module = require path
    for key, value of module
      continue if key.startsWith '_'
      throw new Error "duplicate key #{rpr key}" if L[ key ]?
      L[ key ] = value
  #.........................................................................................................
  for key, value of L
    continue unless CND.isa_function value
    L[ key ] = value.bind L
  #.........................................................................................................
  return null

