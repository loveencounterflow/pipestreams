
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
new_pushable              = require 'pull-pushable'
$pull_split               = require 'pull-split'
# $pull_stringify           = require 'pull-stringify'
$pull_utf8_decoder        = require 'pull-utf8-decoder'
$pass_through             = require 'pull-stream/throughs/through'
$pull_drain               = require 'pull-stream/sinks/drain'
$take                     = require 'pull-stream/throughs/take'
$stringify                = require 'pull-stringify'
$values                   = require 'pull-stream/sources/values'
pull                      = require 'pull-stream'
# map                       = pull.map.bind pull
pull_through              = require 'pull-through'
pull_many                 = require 'pull-many'
pull_cont                 = require 'pull-cont'
@_$async_map              = require 'pull-stream/throughs/async-map'
@_$paramap                = require 'pull-paramap'
unpack_sym                = Symbol 'unpack'
# pull_infinite             = require 'pull-stream/sources/infinite'
@_map_errors              = require './_map_errors'
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
### TAINT refactor: `PS.new_source.from_path`, `PS.new_source.from_text`..., `PS.new_sink.as_text` (???) ###
@new_text_source = ( text ) -> $values [ text, ]
@new_text_sink = ->
  throw new Error "µ8648 not implemented"

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
@$as_line         = -> @_map_errors     ( line    ) => line + '\n'
@$trim            = -> @_map_errors     ( line    ) => line.trim()
@$split_fields    = -> @_map_errors     ( line    ) => line.split /\s*\t\s*/
@$skip_empty      = -> @$filter         ( line    ) => line.length > 0
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
@$name_fields = ( names ) ->
  throw new Error "µ23948 expected a list, got a #{type}" unless ( type = CND.type_of names ) is 'list'
  return @_map_errors ( fields ) =>
    throw new Error "µ24713 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
    R = {}
    for value, idx in fields
      name      = names[ idx ] ?= "field_#{idx}"
      R[ name ] = value
    return R

#-----------------------------------------------------------------------------------------------------------
@$trim_fields = -> @$watch ( fields  ) =>
  fields[ idx ] = field.trim() for field, idx in fields
  return null

#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ->
  R = []
  R.push @$split()
  R.push @$trim()
  R.push @$skip_empty()
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_fields()
  # R.push @$trim_fields()
  return @pull R...

#-----------------------------------------------------------------------------------------------------------
@pull = ( methods... ) ->
  return @$pass() if methods.length is 0
  for method, idx in methods
    continue if ( type = CND.type_of method ) is 'function'
    throw new Error "µ25478 expected a function, got a #{type} for argument # #{idx + 1}"
  return pull methods...

#-----------------------------------------------------------------------------------------------------------
@$split = ( settings ) ->
  throw new Error "µ26243 MEH" if settings?
  R         = []
  matcher   = null
  mapper    = null
  reverse   = no
  skip_last = yes
  R.push $pull_utf8_decoder()
  R.push $pull_split matcher, mapper, reverse, skip_last
  return pull R...

#-----------------------------------------------------------------------------------------------------------
@$join = ( joiner = null ) ->
  collector = []
  length    = 0
  type      = null
  is_first  = yes
  return @$ 'null', ( data, send ) ->
    if data?
      if is_first
        is_first  = no
        type      = CND.type_of data
        switch type
          when 'text'
            joiner ?= ''
          when 'buffer'
            throw new Error "µ27008 joiner not supported for buffers, got #{rpr joiner}" if joiner?
          else
            throw new Error "µ27773 expected a text or a buffer, got a #{type}"
      else
        unless ( this_type = CND.type_of data ) is type
          throw new Error "µ28538 expected a #{type}, got a #{this_type}"
      length += data.length
      collector.push data
    else
      return send '' if ( collector.length is 0 ) or ( length is 0 )
      return send collector.join '' if type is 'text'
      return send Buffer.concat collector, length
    return null


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

#-----------------------------------------------------------------------------------------------------------
@$as_text = ( settings ) ->
  serialize = settings?[ 'serialize' ] ? JSON.stringify
  return @_map_errors ( data ) => serialize data

#-----------------------------------------------------------------------------------------------------------
@$stringify = ( settings ) -> $stringify settings

#-----------------------------------------------------------------------------------------------------------
@$desaturate = ->
  ### remove ANSI escape sequences ###
  pattern = /\x1b\[[0-9;]*[JKmsu]/g
  return @map ( line ) =>
    return line.replace pattern, ''


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
  paths     = await glob patterns, settings
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
  return null

