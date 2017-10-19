
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
# #...........................................................................................................
# PATH                      = require 'path'
# OS                        = require 'os'
FS                        = require 'fs'
CP                        = require 'child_process'
#...........................................................................................................
### files, conversion from/to NodeJS push streams: ###
### later
new_file_source           = require 'pull-file'
new_file_sink             = require 'pull-write-file'
###
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
### stream creation: ###
new_pushable              = require 'pull-pushable'
#...........................................................................................................
### transforms: ###
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
pull_async_map            = require 'pull-stream/throughs/async-map'
pull_many                 = require 'pull-many'
pull_cont                 = require 'pull-cont'
# pull_infinite             = require 'pull-stream/sources/infinite'
Event_emitter             = require 'eventemitter3'
#...........................................................................................................
return_id                 = ( x ) -> x
# { step, }                 = CND.suspend
#-----------------------------------------------------------------------------------------------------------
pluck = ( x, key, fallback ) ->
  R = x[ key ]
  R = fallback if R is undefined
  delete x[ key ]
  return R


#===========================================================================================================
# EVENTS AND EMITTERS
#-----------------------------------------------------------------------------------------------------------
@_new_event_emitter = ->
  R               = new Event_emitter()
  _emit           = R.emit.bind R
  #.........................................................................................................
  R.emit = ( event_name, P... ) ->
    _emit '*',  event_name, P... unless event_name is '*'
    _emit       event_name, P...
  # #.........................................................................................................
  # R.on = ( name, P... ) ->
  #   # ### experimental: accept only 'namespaced' event names a la 'foo/bar' and known names
  #   # so as to prevent accidental usage of bogus event names like `end`, `close`, `finish` etc: ###
  #   # unless ( '/' in name ) or ( name is 'stop' )
  #   #   throw new Error "unknown event name #{rpr name}"
  #   emitter.on name, P...
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@new_event_collector = ( for_event_name, method ) ->
  switch arity = arguments.length
    when 0 then null
    when 2
      unless ( type = CND.type_of for_event_name ) is 'text'
        throw new Error "expected a text, got a #{type}"
      unless ( type = CND.type_of method ) is 'function'
        throw new Error "expected a function, got a #{type}"
    else throw new Error "expected 0 or 2 arguments, got #{arity}"
  #.........................................................................................................
  R               = @_new_event_emitter()
  R._event_counts = {}
  R._source_count = 0
  R._emitters     = new WeakMap()
  #.........................................................................................................
  aggregator = ( event_name ) ->
    event_count = R._event_counts[ event_name ] = ( R._event_counts[ event_name ] ? 0 ) + 1
    R.emit event_name if event_count is R._source_count
    return null
  #.........................................................................................................
  R.add = ( emitter ) ->
    ### TAINT only works with PipeStreams event emitters; could overwrite `emit` method otherwise ###
    unless ( type = CND.type_of emitter.on ) is 'function'
      throw new Error "expected an event emitter with an `on` method, got a #{type}"
    throw new Error "got duplicate emitter" if R._emitters.has emitter
    R._emitters.set emitter, 1
    R._source_count += +1
    emitter.on '*', aggregator
    return emitter
  #.........................................................................................................
  R.on for_event_name, method if method?
  return R

#-----------------------------------------------------------------------------------------------------------
@_mixin_event_emitter = ( method ) ->
  emitter = @_new_event_emitter()
  #.........................................................................................................
  method.on = ( event_name, P... ) ->
    emitter.on event_name, P...
  #.........................................................................................................
  method.emit = ( event_name, P... ) ->
    emitter.emit event_name, P...
  #.........................................................................................................
  return method


### This is the original `pull-stream/throughs/map` implementation with the `try`/`catch` clause removed so
all errors are thrown. This, until we find out how to properly handle errors the pull-streams way. Note
that `_map_errors` behaves exactly like `pull-stream/throughs/filter` which tells me this shouldn't be
too wrong. Also observe that while any library may require all errors to be given to a callback or
somesuch, no library can really enforce that because not all client code may be wrapped, so I think
we're stuck with throwing errors anyway. ###

```
var prop = require('pull-stream/util/prop')

this._map_errors = function (mapper) {
  if(!mapper) return return_id
  mapper = prop(mapper)
  return function (read) {
    return function (abort, cb) {
      read(abort, function (end, data) {
        // try {
        data = !end ? mapper(data) : null
        // } catch (err) {
        //   return read(err, function () {
        //     return cb(err)
        //   })
        // }
        cb(end, data)
      })
    }
  }
}
```

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


#-----------------------------------------------------------------------------------------------------------
@_nodejs_input_to_pull_source = ( P... ) -> STPS.source P...

#-----------------------------------------------------------------------------------------------------------
@new_file_source              = ( P... ) -> @_new_file_source_using_stps      P...
@new_file_sink                = ( P... ) -> @_new_file_sink_using_stps        P...
@_new_file_source_using_stps  = ( P... ) -> STPS.source FS.createReadStream   P...

#-----------------------------------------------------------------------------------------------------------
@_new_file_sink_using_stps = ( path_or_stream ) ->
  if CND.isa_text path_or_stream
    path    = path_or_stream
    stream  = FS.createWriteStream path_or_stream
  else
    path    = path_or_stream.path ? '<UNKNOWN PATH>'
    unless @_isa_njs_stream path_or_stream
      throw new Error "expected a path or a stream, got a #{CND.type_of path_or_stream}"
    unless path_or_stream.writable
      throw new Error "expected a path or a stream, got a #{CND.type_of path_or_stream}"
    stream  = path_or_stream
  ### TAINT intermediate solution ###
  R       = STPS.sink stream, ( error ) => throw error if error?
  emitter = @_new_event_emitter()
  R.on    = ( name, P... ) -> emitter.on name, P...
  #.........................................................................................................
  stream.on 'finish', ->
    if ( not emitter.listeners 'stop', true ) and ( not emitter.listeners '*', true )
      warn "stream to #{rpr path} finished without listener"
    emitter.emit 'stop'
  #.........................................................................................................
  return R


### later (perhaps)
#-----------------------------------------------------------------------------------------------------------
@_new_file_source_using_pullfile  = ( P... ) -> new_file_source P...

#-----------------------------------------------------------------------------------------------------------
@_new_file_sink_using_pwf = ( path, options = null ) ->
  throw new Error "not implemented"
  # TAINT errors with "DeprecationWarning: Calling an asynchronous function without callback is deprecated." (???)
  options ?= {}
  return new_file_sink path, options, ( error ) ->
    throw error if error?
    return null
###

#-----------------------------------------------------------------------------------------------------------
### TAINT refactor: `PS.new_source.from_path`, `PS.new_source.from_text`..., `PS.new_sink.as_text` (???) ###
@new_text_source = ( text ) -> $values [ text, ]
@new_text_sink = ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
@new_value_source = ( values ) -> $values values

#-----------------------------------------------------------------------------------------------------------
@map_start = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "method arity #{arity} not implemented" unless ( arity = method.length ) is 0
  is_first = yes
  return @_map_errors ( data ) =>
    if is_first
      is_first = no
      method()
    return data

#-----------------------------------------------------------------------------------------------------------
@map_stop = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "method arity #{arity} not implemented" unless ( arity = method.length ) is 0
  return $pass_through return_id, ( abort ) ->
    method()
    return abort

#-----------------------------------------------------------------------------------------------------------
@map_first = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "method arity #{arity} not implemented" unless ( arity = method.length ) is 1
  is_first = yes
  return @_map_errors ( data ) =>
    if is_first
      is_first = no
      method data
    return data

#-----------------------------------------------------------------------------------------------------------
@map_last = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  throw new Error "method arity #{arity} not implemented" unless ( arity = method.length ) is 1
  throw new Error 'meh'

#-----------------------------------------------------------------------------------------------------------
@filter = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "method arity #{arity} not implemented"
  #.........................................................................................................
  return pull.filter method

#-----------------------------------------------------------------------------------------------------------
@map = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 1 then null
    else throw new Error "method arity #{arity} not implemented"
  #.........................................................................................................
  return @_map_errors method

#-----------------------------------------------------------------------------------------------------------
@$ = @remit = ( hint, method ) ->
  switch arity = arguments.length
    when 1
      method  = hint
      hint    = null
    when 2
      throw new Error "unknown hint #{rpr hint}" unless hint is 'null'
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  switch client_arity = method.length
    when 2 then null
    else throw new Error "method arity #{client_arity} not implemented"
  #.........................................................................................................
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
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
@async_map = pull_async_map

# #-----------------------------------------------------------------------------------------------------------
# @$async = @remit_async = ( method ) ->
#   throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
#   throw new Error "### MEH ###" unless ( arity = method.length ) is 2


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$pass            = -> @_map_errors     ( data ) => data
#...........................................................................................................
@$as_line         = -> @_map_errors     ( line    ) => line + '\n'
@$trim            = -> @_map_errors     ( line    ) => line.trim()
@$split_fields    = -> @_map_errors     ( line    ) => line.split /\s*\t\s*/
@$skip_empty      = -> @filter          ( line    ) => line.length > 0
#...........................................................................................................
@$push_to_list    = ( collector ) -> @_map_errors ( data ) => collector.push  data; return data
@$add_to_set      = ( collector ) -> @_map_errors ( data ) => collector.add   data; return data
#...........................................................................................................
@$count           = -> throw new Error "not implemented"
@$take            = $take

#-----------------------------------------------------------------------------------------------------------
@$drain = ( on_end = null ) ->
  R = @_mixin_event_emitter $pull_drain null, -> R.emit 'stop'
  R.on 'stop', on_end if on_end?
  return R

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
  throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of names ) is 'list'
  return @_map_errors ( fields ) =>
    throw new Error "expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
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
  R.push @filter ( line ) -> not line.startsWith '#'
  R.push @$split_fields()
  # R.push @$trim_fields()
  return @pull R...

#-----------------------------------------------------------------------------------------------------------
@pull = ( methods... ) ->
  for method, idx in methods
    continue if ( type = CND.type_of method ) is 'function'
    throw new Error "expected a function, got a #{type} for argument # #{idx + 1}"
  return pull methods...

#-----------------------------------------------------------------------------------------------------------
@$split = ( settings ) ->
  throw new Error "MEH" if settings?
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
            throw new Error "joiner not supported for buffers, got #{rpr joiner}" if joiner?
          else
            throw new Error "expected a text or a buffer, got a #{type}"
      else
        unless ( this_type = CND.type_of data ) is type
          throw new Error "expected a #{type}, got a #{this_type}"
      length += data.length
      collector.push data
    else
      return send '' if ( collector.length is 0 ) or ( length is 0 )
      return send collector.join '' if type is 'text'
      return send Buffer.concat collector, length
    return null

#-----------------------------------------------------------------------------------------------------------
@$pluck = ( settings ) ->
  throw new Error "need settings 'keys', got #{rpr settings}" unless settings?
  { keys, } = settings
  throw new Error "need settings 'keys', got #{rpr settings}" unless keys?
  keys      = keys.split /,\s*|\s+/ if CND.isa_text keys
  throw new Error "need settings 'keys', got #{rpr settings}" unless keys.length > 0
  as        = settings[ 'as' ] ? 'object'
  unless as in [ 'list', 'object', 'pod', ]
    throw new Error "expected 'list', 'object' or 'pod', got #{rpr as}"
  if as is 'list'
    return @map ( data ) => ( data[ key ] for key in keys )
  return @map ( data ) =>
    Z         = {}
    Z[ key ]  = data[ key ] for key in keys
    return Z

#-----------------------------------------------------------------------------------------------------------
@$gliding_window = ( width, method ) ->
  throw new Error "expected a number, got a #{type}" unless ( CND.type_of width ) is 'number'
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
  throw new Error "API changed" if settings?
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
@$sort = ( settings ) ->
  ### https://github.com/mziccard/node-timsort ###
  TIMSORT   = require 'timsort'
  direction = 'ascending'
  sorter    = null
  key       = null
  switch arity = arguments.length
    when 0 then null
    when 1
      direction = settings[ 'direction' ] ? 'ascending'
      sorter    = settings[ 'sorter'    ] ? null
      key       = settings[ 'key'       ] ? null
    else throw new Error "expected 0 or 1 arguments, got #{arity}"
  #.........................................................................................................
  unless direction in [ 'ascending', 'descending', ]
    throw new Error "expected 'ascending' or 'descending' for direction, got #{rpr direction}"
  #.........................................................................................................
  unless sorter?
    #.......................................................................................................
    type_of = ( x ) =>
      ### NOTE for the purposes of magnitude comparison, `Infinity` can be treated as a number: ###
      R = CND.type_of x
      return if R is 'infinity' then 'number' else R
    #.......................................................................................................
    validate_type = ( type_a, type_b, include_list = no ) =>
      unless type_a is type_b
        throw new Error "unable to compare a #{type_a} with a #{type_b}"
      if include_list
        unless type_a in [ 'number', 'date', 'text', 'list', ]
          throw new Error "unable to compare values of type #{type_a}"
      else
        unless type_a in [ 'number', 'date', 'text', ]
          throw new Error "unable to compare values of type #{type_a}"
      return null
    #.......................................................................................................
    if key?
      sorter = ( a, b ) =>
        a = a[ key ]
        b = b[ key ]
        validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
    #.......................................................................................................
    else
      sorter = ( a, b ) =>
        validate_type ( type_a = type_of a ), ( type_b = type_of b ), yes
        if type_a is 'list'
          a = a[ 0 ]
          b = b[ 0 ]
          validate_type ( type_of a ), ( type_of b ), no
        return +1 if ( if direction is 'ascending' then a > b else a < b )
        return -1 if ( if direction is 'ascending' then a < b else a > b )
        return  0
  #.........................................................................................................
  $sort = =>
    collector = []
    return @$ 'null', ( data, send ) =>
      if data?
        collector.push data
      else
        TIMSORT.sort collector, sorter
        send x for x in collector
        collector.length = 0
      return null
  #.........................................................................................................
  return $sort()

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
# SPAWN
#-----------------------------------------------------------------------------------------------------------
@spawn_collect = ( P..., handler ) ->
  #.........................................................................................................
  $on_data = =>
    command   = null
    stderr    = []
    stdout    = []
    return @$watch ( event ) =>
      [ key, value, ] = event
      switch key
        when 'command'  then  command = value
        when 'stdout'   then  stdout.push value
        when 'stderr'   then  stderr.push value
        when 'exit'     then  return handler null, Object.assign { command, stdout, stderr, }, value
        else throw new Error "internal error 2201991"
      return null
  #.........................................................................................................
  source    = @spawn P...
  pipeline  = []
  #.........................................................................................................
  pipeline.push source
  pipeline.push $on_data()
  pipeline.push @$drain()
  #.........................................................................................................
  pull pipeline...
  return null

#-----------------------------------------------------------------------------------------------------------
@spawn = ( P... ) -> ( @_spawn P... )[ 1 ]

#-----------------------------------------------------------------------------------------------------------
@_spawn = ( command, settings ) ->
  #.........................................................................................................
  switch arity = arguments.length
    when 1, 2 then null
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  # throw new Error "deprecated setting: error_to_exit" if ( pluck settings, 'error_to_exit',  null )?
  # stderr_target     = pluck settings, 'stderr', 'stderr'
  settings          = Object.assign { shell: yes, }, settings
  stdout_is_binary  = pluck settings, 'binary',         no
  comments          = pluck settings, 'comments',       {}
  on_data           = pluck settings, 'on_data',        null
  error_to_exit     = pluck settings, 'error_to_exit',  no
  command_source    = @new_value_source [ [ 'command', command, ] ]
  #.........................................................................................................
  switch command_type = CND.type_of command
    when 'text'
      cp = CP.spawn command, settings
    when 'list'
      unless command.length > 0
        throw new Error "expected a list with at least one value, got #{rpr command}"
      cp = CP.spawn command[ 0 ], command[ 1 .. ], settings
    else throw new Error "expected a text or a list for command, got #{command_type}"
  #.........................................................................................................
  stdout            = STPS.source cp.stdout
  stderr            = STPS.source cp.stderr
  #.........................................................................................................
  stdout_pipeline   = []
  stderr_pipeline   = []
  funnel            = []
  event_pipeline    = []
  event_buffer      = []
  #.........................................................................................................
  stdout_pipeline.push stdout
  stdout_pipeline.push @$split() unless stdout_is_binary
  # stdout_pipeline.push @async_map ( data, handler ) -> defer -> handler null, data
  stdout_pipeline.push @map ( line ) -> [ 'stdout', line, ]
  #.........................................................................................................
  stderr_pipeline.push stderr
  stderr_pipeline.push @$split()
  # stderr_pipeline.push @async_map ( data, handler ) -> defer -> handler null, data
  stderr_pipeline.push @map ( line ) -> [ 'stderr', line, ]
  #.........................................................................................................
  ### Event handling: collect all events from child process ###
  cp.on 'disconnect',                   => event_buffer.push [ 'disconnect',  null,          ]
  ### TAINT exit and error events should use same method to do post-processing ###
  cp.on 'error',      ( error )         => event_buffer.push [ 'error',       error ? null,  ]
  cp.on 'exit',       ( code, signal )  =>
    code      = ( 128 + ( @_spawn._signals_and_codes[ signal ] ? 0 ) ) if signal? and not code?
    comment   = comments[ code ] ? @_spawn._codes_and_comments[ code ] ? signal
    comment  ?= if code is 0 then 'ok' else comments[ 'error' ] ? 'error'
    event_buffer.push [ 'exit',   { code, signal, comment, },  ]
  #.......................................................................................................
  ### The 'close' event should always come last, so we use that to trigger asynchronous sending of
  all events collected in the signal buffer. See https://github.com/dominictarr/pull-cont ###
  event_pipeline.push pull_cont ( handler ) =>
    cp.on 'close', =>
      handler null, @new_value_source event_buffer
      return null
  #.........................................................................................................
  ### Since reading from a spawned process is inherently asynchronous, we cannot be sure all of the output
  from stdout and stderr has been sent down the pipeline before events from the child process arrive.
  Therefore, we have to buffer those events and send them on only when the confluence stream has indicated
  exhaustion: ###
  $ensure_event_order = =>
    cp_buffer     = []
    std_buffer    = []
    command_sent  = no
    return @$ 'null', ( event, send ) =>
      if event?
        [ category, ] = event
        ### Events from stdout and stderr are buffered until the command event has been sent; after that,
        they are sent immediately: ###
        if category in [ 'stdout', 'stderr', ]
          if command_sent
            return ( if on_data? then on_data else send ) event
          return std_buffer.push event
        ### The command event is sent right away; any buffered stdout, stderr events are flushed: ###
        if category is 'command'
          command_sent = yes
          send event
          while std_buffer.length > 0
            ( if on_data? then on_data else send ) std_buffer.shift()
          return
        ### Keep everything else (i.e. events from child process) for later: ###
        cp_buffer.push event
      else
        ### Send all buffered CP events: ###
        send cp_buffer.shift() while cp_buffer.length > 0
      return null
  #.........................................................................................................
  confluence = pull_many [
    ( pull command_source     )
    ( pull stdout_pipeline... )
    ( pull stderr_pipeline... )
    ( pull event_pipeline...  )
    ]
  #.........................................................................................................
  funnel.push confluence
  funnel.push $ensure_event_order()
  #.........................................................................................................
  if error_to_exit
    funnel.push do =>
      error = []
      return @$ ( event, send ) =>
        if event?
          [ key, value, ] = event
          switch key
            when 'command', 'stdout'  then send event
            when 'stderr'             then error.push value.trimRight()
            when 'exit'
              value.error = error.join '\n'
              value.error = null if value.error.length is 0
              send event
            else throw new Error "internal error 110918"
  #.........................................................................................................
  source = pull funnel...
  return [ cp, source, ]

#-----------------------------------------------------------------------------------------------------------
@_spawn._signals_and_codes = {
  SIGHUP: 1, SIGINT: 2, SIGQUIT: 3, SIGILL: 4, SIGTRAP: 5, SIGABRT: 6, SIGIOT: 6, SIGBUS: 7, SIGFPE: 8,
  SIGKILL: 9, SIGUSR1: 10, SIGSEGV: 11, SIGUSR2: 12, SIGPIPE: 13, SIGALRM: 14, SIGTERM: 15, SIGSTKFLT: 16,
  SIGCHLD: 17, SIGCONT: 18, SIGSTOP: 19, SIGTSTP: 20, SIGTTIN: 21, SIGTTOU: 22, SIGURG: 23, SIGXCPU: 24,
  SIGXFSZ: 25, SIGVTALRM: 26, SIGPROF: 27, SIGWINCH: 28, SIGIO: 29, SIGPOLL: 29, SIGPWR: 30, SIGSYS: 31, }

#-----------------------------------------------------------------------------------------------------------
@_spawn._codes_and_comments =
  # 1:      'an error has occurred'
  126:    'permission denied'
  127:    'command not found'


#===========================================================================================================
# SAMPLING / THINNING OUT
#-----------------------------------------------------------------------------------------------------------
@$sample = ( p = 0.5, options ) ->
  #.........................................................................................................
  unless 0 <= p <= 1
    throw new Error "expected a number between 0 and 1, got #{rpr p}"
  #.........................................................................................................
  ### Handle trivial edge cases faster (hopefully): ###
  return ( @map     ( record ) => record  ) if p == 1
  return ( @filter  ( record ) => false   ) if p == 0
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





