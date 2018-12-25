
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
unpack_sym                = Symbol 'unpack'
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
@map_start = ( method ) ->
  throw new Error "µ9413 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ10178 method arity #{arity} not implemented" unless ( arity = method.length ) is 0
  is_first = yes
  return @_map_errors ( data ) =>
    if is_first
      is_first = no
      method()
    return data

#-----------------------------------------------------------------------------------------------------------
@map_stop = ( method ) ->
  throw new Error "µ10943 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ11708 method arity #{arity} not implemented" unless ( arity = method.length ) is 0
  return $pass_through return_id, ( abort ) ->
    method()
    return abort

#-----------------------------------------------------------------------------------------------------------
@map_first = ( method ) ->
  throw new Error "µ12473 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ13238 method arity #{arity} not implemented" unless ( arity = method.length ) is 1
  is_first = yes
  return @_map_errors ( data ) =>
    if is_first
      is_first = no
      method data
    return data

#-----------------------------------------------------------------------------------------------------------
@map_last = ( method ) ->
  throw new Error "µ14003 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ14768 method arity #{arity} not implemented" unless ( arity = method.length ) is 1
  throw new Error 'meh'

#-----------------------------------------------------------------------------------------------------------
@$filter = ( method ) ->
  throw new Error "µ15533 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "µ16298 method arity #{arity} not implemented"
  #.........................................................................................................
  return pull.filter method

#-----------------------------------------------------------------------------------------------------------
@map = ( method ) ->
  throw new Error "µ17063 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "µ17828 method arity #{arity} not implemented"
  #.........................................................................................................
  return @_map_errors method

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
@$async = ( method ) ->
  ### TAINT signature should be ( hint, method ) ###
  ### TAINT currently all results from client method are buffered until `done` gets called; see whether
  it is possible to use `await` so that each result can be sent doen the pipeline w/out buffering ###
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


#===========================================================================================================
# ASYNC TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@$defer =         -> @$async ( d, send, done ) -> defer -> send d; done()
@$delay = ( dts ) -> @$async ( d, send, done ) -> after dts, -> send d; done()


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$pass            = -> @_map_errors     ( data ) => data
#...........................................................................................................
@$push_to_list    = ( collector ) -> @_map_errors ( data ) => collector.push  data; return data
@$add_to_set      = ( collector ) -> @_map_errors ( data ) => collector.add   data; return data
#...........................................................................................................
@$count           = -> throw new Error "µ23183 not implemented"
@$take            = $take

#-----------------------------------------------------------------------------------------------------------
@$drain = ( on_end = null ) -> $pull_drain null, on_end

#-----------------------------------------------------------------------------------------------------------
@$watch = ( method ) ->
  return @_map_errors ( data ) =>
    method data
    return data

#-----------------------------------------------------------------------------------------------------------
### TAINT not sure how to call this / how to unify with the rest of the API ###
@_$watch_null = ( method ) ->
  on_each = ( data ) ->
    method data
    return null
  on_stop = ( abort ) ->
    method null
    return null
  return $pass_through on_each, on_stop
#-----------------------------------------------------------------------------------------------------------
@pull = ( methods... ) ->
  return @$pass() if methods.length is 0
  for method, idx in methods
    continue if ( type = CND.type_of method ) is 'function'
    throw new Error "µ25478 expected a function, got a #{type} for argument # #{idx + 1}"
  return pull methods...


#-----------------------------------------------------------------------------------------------------------
@$gliding_window = ( width, method ) ->
  throw new Error "µ32363 expected a number, got a #{type}" unless ( CND.type_of width ) is 'number'
  section = []
  send    = null
  #.........................................................................................................
  push = ( x ) ->
    section.push x
    R =
    while section.length > width
      send section.shift()
    return null
  #.........................................................................................................
  return @$ 'null', ( new_data, send_ ) =>
    send = send_
    if new_data?
      push new_data
      method section if section.length >= width
    else
      while section.length > 0
        send section.shift()
      send null
    return null

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
@$tee = ( stream ) ->
  ### **NB** that in contradistinction to `pull-tee`, you can only divert to a single by-stream with each
  call to `PS.$tee` ###
  # R = if ( CND.isa_list stream_or_pipeline ) then ( pull stream_or_pipeline ) else stream_or_pipeline
  return ( require 'pull-tee' ) stream

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
  return ( @map     ( record ) => record  ) if p == 1
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
      # debug '38833', "#{path}##{key}"
      continue if key.startsWith '_'
      throw new Error "duplicate key #{rpr key}" if L[ key ]?
      L[ key ] = value
  #.........................................................................................................
  for key, value of L
    continue unless CND.isa_function value
    L[ key ] = value.bind L
  return null

