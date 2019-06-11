
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
# CP                        = require 'child_process'
glob                      = require 'globby'
#...........................................................................................................
$pass_through             = require 'pull-stream/throughs/through'
$pull_drain               = require 'pull-stream/sinks/drain'
$values                   = require 'pull-stream/sources/values'
$paramap                  = require 'pull-paramap'
pull                      = require 'pull-stream'
pull_through              = require '../deps/pull-through-with-end-symbol'
pull_cont                 = require 'pull-cont'
map                       = require './_map_errors'
#...........................................................................................................
after                     = ( dts, f ) -> setTimeout  f, dts * 1000
every                     = ( dts, f ) -> setInterval f, dts * 1000
defer                     = setImmediate
return_id                 = ( x ) -> x
{ is_empty
  copy
  assign
  jr }                    = CND
#...........................................................................................................
@_symbols                 = require './_symbols'


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
@new_push_source = ( P... ) ->
  ### Return a `pull-streams` `pushable`. Methods `push` and `end` will be bound to the instance
  so they can be freely passed around. ###
  new_pushable  = require 'pull-pushable'
  source        = new_pushable P...
  R             = ( P... ) -> source P...
  PS            = @
  #.........................................................................................................
  send = ( d ) ->
    source.push d
    return null
  #.........................................................................................................
  end = ( P... ) ->
    source.end P...
    return null
  #.........................................................................................................
  R.send  = send.bind R
  R.end   = end.bind R
  return R

#-----------------------------------------------------------------------------------------------------------
@new_alternating_source = ( source_a, source_b ) ->
  ### Given two sources `a` and `b`, return a new source that will emit events
  from both streams in an interleaved fashion, such that the first data item
  from `a` is followed from the first item from `b`, followed by the second from
  `a`, the second from `b` and so on. Once one of the streams has ended, omit
  the remaining items from the other one, if any, until that stream ends, too.
  See also https://github.com/tounano/pull-robin. ###
  merge     = require 'pull-merge'
  toggle    = +1
  return merge source_a, source_b, ( -> toggle = -toggle )

#-----------------------------------------------------------------------------------------------------------
@new_on_demand_source = ( stream ) ->
  ### Given a stream, return a source `s` with a method `s.next()` such that the next data item from `s`
  will only be sent as soon as that method is called. ###
  triggersource   = @new_push_source()
  pipeline        = []
  next_sym        = Symbol 'next'
  pipeline.push @new_alternating_source triggersource, stream
  pipeline.push @$filter ( d ) -> d isnt next_sym
  R               = @pull pipeline...
  R.next          = -> triggersource.send next_sym
  R.next()
  return R

#-----------------------------------------------------------------------------------------------------------
@new_random_async_value_source = ( dts, values ) ->
  ### Given an optional delta time in seconds `dts` (which defaults to 0.1 seconds) and a list of values,
  return a source that will asynchronously produce values at irregular intervals that randomly oscillate
  around `dts`. ###
  switch arity = arguments.length
    when 1 then [ dts, values, ] = [ 0.1, dts, ]
    when 2 then null
    else throw new Error "µ77749 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  R           = @new_push_source()
  new_timeout = -> ( Math.random() + 0.001 ) * dts
  #.........................................................................................................
  idx         = 0
  last_idx    = values.length - 1
  #.........................................................................................................
  unless ( CND.isa_number last_idx )
    throw new Error "µ89231 expected a list-like object, got a #{CND.type_of values}"
  #.........................................................................................................
  tick = =>
    if idx <= last_idx
      R.send values[ idx ]
      idx += +1
      after new_timeout(), tick
    else
      R.end()
    return null
  #.........................................................................................................
  after new_timeout(), tick
  return R

#-----------------------------------------------------------------------------------------------------------
@new_generator_source = ( generator ) ->
  return ( end, handler ) ->
    return handler end if end
    R = generator.next()
    defer ->
      return handler true if R.done
      handler null, R.value

#-----------------------------------------------------------------------------------------------------------
@new_refillable_source = ( values, settings ) ->
  ### A refillable source expects a list of `values` (or a listlike object with a `shift()` method); when a
  read occurs, it will empty `values` one element at a time, always shifting the leftmost element (with
  index zero) from `values`. Transforms down the line may choose to `values.push()` new values into the
  list, which will in time be sent down again. When a read occurs and `values` happens to be empty, a
  special value (the `trailer`, by default a symbol) will be sent down the line (only to be filtered out
  immediately) up to `repeat` times (by default one time) in a row to avoid depleting the pipeline. ###
  discard_sym   = Symbol 'discard'
  settings      = assign { repeat: 1, trailer: discard_sym, show: false, }, settings
  trailer_count = 0
  #.........................................................................................................
  filter        = @$filter ( d ) => d isnt discard_sym
  #.........................................................................................................
  read          = ( abort, handler ) =>
    return handler abort if abort
    if values.length is 0
      trailer_count  += +1
      info '23983', "refillable source depleted: #{trailer_count} / #{settings.repeat}" if settings.show
      if trailer_count < settings.repeat
        value = settings.trailer
      else
        return handler true
    else
      trailer_count = 0
      value         = values.shift()
    ### Must defer callback so the the pipeline gets a chance to refill: ###
    defer -> handler null, value
    return null
  #.........................................................................................................
  R = @pull read, filter
  # R.end = ->
  return R

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
  return map method

#-----------------------------------------------------------------------------------------------------------
@_get_remit_settings = ( hint, method ) ->
  defaults  =
    first:    @_symbols.misfit
    last:     @_symbols.misfit
    between:  @_symbols.misfit
    after:    @_symbols.misfit
    before:   @_symbols.misfit
  settings  = assign {}, defaults
  switch arity = arguments.length
    when 1
      method    = hint
      hint      = null
    when 2
      if CND.isa_text hint
        throw new Error "µ30902 Deprecated: use `{last:null}` instead of `'null'`"
      else
        settings = assign settings, hint
    else throw new Error "µ19358 expected 1 or 2 arguments, got #{arity}"
  settings._surround = \
    ( settings.first    isnt @_symbols.misfit ) or \
    ( settings.last     isnt @_symbols.misfit ) or \
    ( settings.between  isnt @_symbols.misfit ) or \
    ( settings.after    isnt @_symbols.misfit ) or \
    ( settings.before   isnt @_symbols.misfit )
  return { settings, method, }

#-----------------------------------------------------------------------------------------------------------
@$ = @remit = ( P... ) ->
  ### NOTE we're transitioning from the experimental `hint` call convention to the more flexible and
  standard `settings` (which are here placed first, not last, b/c one frequently wants to write out a
  function body as last argument). For a limited time, `'null'` is accepted in place of a `settings` object;
  after that, `{ last: null }` should be used. ###
  #.........................................................................................................
  { settings, method, } = @_get_remit_settings P...
  switch client_arity = method.length
    when 2 then null
    else throw new Error "µ20123 method arity #{client_arity} not implemented"
  #.........................................................................................................
  throw new Error "µ20888 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  #.........................................................................................................
  self          = null
  data_first    = settings.first
  data_before   = settings.before
  data_between  = settings.between
  data_after    = settings.after
  data_last     = settings.last
  send_first    = data_first    isnt @_symbols.misfit
  send_before   = data_before   isnt @_symbols.misfit
  send_between  = data_between  isnt @_symbols.misfit
  send_after    = data_after    isnt @_symbols.misfit
  send_last     = data_last     isnt @_symbols.misfit
  on_end        = null
  is_first      = true
  PS            = @
  #.........................................................................................................
  send = ( d ) ->
    throw new Error "µ93892 called `send` method too late" unless self?
    self.queue d
  #.........................................................................................................
  send.end = ->
    throw new Error "µ09833 `send.end()` takes no arguments, got #{rpr [arguments...]}" unless arguments.length is 0
    self.queue PS._symbols.end
  #.........................................................................................................
  on_data = ( d ) ->
    self = @
    if is_first
      is_first = false
      method data_first, send if send_first
    else
      method data_between, send if send_between
    method data_before, send  if send_before
    method d,           send
    method data_after,  send  if send_after
    self = null
    return null
  #.........................................................................................................
  on_end = ->
    if send_last
      self = @
      method data_last, send
      self = null
    # defer -> @queue PS._symbols.end
    @queue PS._symbols.end
    return null
  #.........................................................................................................
  return pull_through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$async = ( P... ) ->
  ### TAINT currently all results from client method are buffered until `done` gets called; see whether
  it is possible to use `await` so that each result can be sent doen the pipeline w/out buffering ###
  #.........................................................................................................
  ### NOTE we're transitioning from the experimental `hint` call convention to the more flexible and
  standard `settings` (which are here placed first, not last, b/c one frequently wants to write out a
  function body as last argument). For a limited time, `'null'` is accepted in place of a `settings` object;
  after that, `{ last: null }` (or using other value except `PS._symbols.misfit`) should be used. ###
  #.........................................................................................................
  { settings, method, } = @_get_remit_settings P...
  throw new Error "µ18187 expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "µ18203 expected one or two arguments, got #{arity}" unless 1 <= ( arity = arguments.length ) <= 2
  throw new Error "µ18219 method arity #{arity} not implemented" unless ( arity = method.length ) is 3
  #.........................................................................................................
  pipeline    = []
  call_count  = 0
  has_ended   = false
  last_sym    = Symbol 'last'
  #.........................................................................................................
  pipeline.push @$surround settings if settings._surround
  pipeline.push @$surround { last: last_sym, }
  #.........................................................................................................
  pipeline.push $paramap ( d, handler ) =>
    collector   = []
    #.......................................................................................................
    send = ( d ) =>
      return handler true if d is @_symbols.end
      collector.unshift d
      return null
    #.......................................................................................................
    done = =>
      call_count += -1
      handler null, collector
      handler true if has_ended and call_count < 1
      return null
    #.......................................................................................................
    if d is last_sym
      has_ended = true
      handler true if call_count < 1
    else
      call_count += +1
      defer -> method d, send, done
    return null
  #.........................................................................................................
  pipeline.push @$defer()
  pipeline.push @$ ( d, send ) => send d.pop() while d.length > 0
  #.........................................................................................................
  return @pull pipeline...

#-----------------------------------------------------------------------------------------------------------
### Given a `settings` object, add values to the stream as `$ settings, ( d, send ) -> send d` would do,
e.g. `$surround { first: 'first!', between: 'to appear in-between two values', }`. ###
@$surround = ( settings ) -> @$ settings, ( d, send ) => send d


#===========================================================================================================
# MARK POSITION IN STREAM
#-----------------------------------------------------------------------------------------------------------
@$mark_position = ->
  ### Turns values into objects `{ first, last, value, }` where `value` is the original value and `first`
  and `last` are booleans that indicate position of value in the stream. ###
  last      = @_symbols.last
  is_first  = true
  prv       = []
  return @$ { last, }, ( d, send ) =>
    if ( d is last ) and prv.length > 0
      if prv.length > 0
        send { is_first, is_last: true, d: prv.pop(), }
      return null
    if prv.length > 0
      send { is_first, is_last: false, d: prv.pop(), }
      is_first = false
    prv.push d
    return null

#===========================================================================================================
# ASYNC TRANSFORMS
#-----------------------------------------------------------------------------------------------------------
@$defer =         -> $paramap ( d, handler ) -> defer       -> handler null, d
@$delay = ( dts ) -> $paramap ( d, handler ) -> after dts,  -> handler null, d


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$pass        =                   -> map ( data ) => data
@$end_if      = ( filter )        -> @$ ( d, send ) -> if (     filter d ) then send.end() else send d
@$continue_if = ( filter )        -> @$ ( d, send ) -> if ( not filter d ) then send.end() else send d

#-----------------------------------------------------------------------------------------------------------
@$drain = ( on_end = null ) ->
  return $pull_drain() unless on_end?
  return $pull_drain null, ( error ) ->
    throw error if error?
    on_end()

#-----------------------------------------------------------------------------------------------------------
@new_pausable = -> ( require 'pull-pause' )()

#-----------------------------------------------------------------------------------------------------------
@$watch = ( settings, method ) ->
  #.........................................................................................................
  switch arity = arguments.length
    #.......................................................................................................
    when 1
      [ settings, method, ] = [ null, settings, ]
      #.....................................................................................................
      return @$ ( d, send ) =>
        method d
        send d
        return null
    #.......................................................................................................
    when 2
      return @$watch method unless settings?
      ### If any `surround` feature is called for, wrap all surround values so that we can safely
      distinguish between them and ordinary stream values; this is necessary to prevent them from leaking
      into the regular stream outside the `$watch` transform: ###
      take_second     = Symbol 'take-second'
      settings        = assign {}, settings
      settings[ key ] = [ take_second, value, ] for key, value of settings
      #.....................................................................................................
      return @$ settings, ( d, send ) =>
        if ( CND.isa_list d ) and ( d[ 0 ] is take_second )
          method d[ 1 ]
        else
          method d
          send d
        return null
  #.........................................................................................................
  throw new Error "µ18244 expected one or two arguments, got #{arity}"

#-----------------------------------------------------------------------------------------------------------
@pull = ( methods... ) ->
  return @$pass() if methods.length is 0
  for method, idx in methods
    continue if ( type = CND.type_of method ) is 'function'
    continue if CND.isa_pod method ### allowing for `{ x.source, x.sink, }` duplex streams ###
    throw new Error "µ25478 expected a function, got a #{type} for argument # #{idx + 1}"
  return pull methods...

#-----------------------------------------------------------------------------------------------------------
@$collect = ( settings ) ->
  collector = settings?.collector ? []
  last_sym  = Symbol 'last'
  return @$ { last: last_sym, }, ( d, send ) =>
    if d is last_sym then send collector
    else collector.push d
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


#===========================================================================================================
# NEW LIBRARY
#-----------------------------------------------------------------------------------------------------------
@_copy_library = ->
  ### `_copy_library()` may be used to derive a new instance of the PipeStreams library to alter
  configurations. ###
  CND.deep_copy @


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
      # continue if key.startsWith '_'
      throw new Error "duplicate key #{rpr key}" if L[ key ]?
      L[ key ] = value
  #.........................................................................................................
  for key, value of L
    continue unless CND.isa_function value
    L[ key ] = value.bind L
  #.........................................................................................................
  return null

