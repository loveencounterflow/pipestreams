
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
pull                      = require 'pull-stream'
map                       = pull.map.bind pull
pull_through              = require 'pull-through'
pull_async_map            = require 'pull-stream/throughs/async-map'
#...........................................................................................................
return_id                 = ( x ) -> x



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
@_isa_readable_njs_stream   = ( x ) -> ( @_isa_njs_njs_stream x ) and x.readable
@_isa_writable_njs_stream   = ( x ) -> ( @_isa_njs_njs_stream x ) and x.writable
@_isa_readonly_njs_stream   = ( x ) -> ( @_isa_njs_njs_stream x ) and x.readable and not x.writable
@_isa_writeonly_njs_stream  = ( x ) -> ( @_isa_njs_njs_stream x ) and x.writable and not x.readable
@_isa_duplex_njs_stream     = ( x ) -> ( @_isa_njs_njs_stream x ) and x.readable and     x.writable


#-----------------------------------------------------------------------------------------------------------
@new_file_source              = ( P... ) -> @_new_file_source_using_stps      P...
@new_file_sink                = ( P... ) -> @_new_file_sink_using_stps        P...
@_new_file_source_using_stps  = ( P... ) -> STPS.source FS.createReadStream   P...

#-----------------------------------------------------------------------------------------------------------
@_new_file_sink_using_stps = ( path_or_stream ) ->
  if CND.isa_text path_or_stream
    stream  = FS.createWriteStream path_or_stream
  else
    unless @_isa_njs_stream path_or_stream
      throw new Error "expected a path or a stream, got a #{CND.type_of path_or_stream}"
    unless path_or_stream.writable
      throw new Error "expected a path or a stream, got a #{CND.type_of path_or_stream}"
    stream  = path_or_stream
  ### TAINT intermediate solution ###
  R       = STPS.sink stream, ( error ) => throw error if error?
  R.on    = ( P... ) -> stream.on P...
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
  return map method

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
#
#-----------------------------------------------------------------------------------------------------------
@spawn = ( command, settings, handler ) ->
  ### `spawn` accepts a `command` (as a string) and a `handler`. It will execute the command in a child
  process (using  `child_process command, { shell: yes, }`).

  `spawn` expects the output to be UTF-8-encoded text, but this may become configurable in the future to
  acommodate for non-textual outputs. Also, it may become possible to directly plug into the subprocess's
  `stdout` and `stderr` streams; for now, the callback is the only way to handle command output. ###
  #.........................................................................................................
  ### TAINT must also consider exit code other than zero ###
  ### TAINT consider case where there is output on both channels ###
  #.........................................................................................................
  switch arity = arguments.length
    when 2
      handler   = settings
      settings  = null
    when 3 then null
    else throw new Error "expected 2 or 3 arguments, got #{arity}"
  #.........................................................................................................
  tap               = settings?[ 'tap' ] ? null
  cp                = CP.spawn command, { shell: yes, }
  #.........................................................................................................
  stdout            = STPS.source cp.stdout
  stdout_has_ended  = no
  stdout_lines      = []
  stdout_message    = null
  stdout_pipeline   = []
  #.........................................................................................................
  stderr            = STPS.source cp.stderr
  stderr_has_ended  = no
  stderr_lines      = []
  stderr_message    = null
  stderr_pipeline   = []
  #.........................................................................................................
  stdout_pipeline.push stdout
  stdout_pipeline.push @$split()
  if tap?
    stdout_pipeline.push @async_map ( line, handler ) ->
      ### By deferring passing on each line both in this and the tapping stream we create an opportunity
      for the tapping stream to run concurrently; without this, all lines would be buffered until the
      main stream has finished: ###
      setImmediate ->
        ### TAINT use a 1-element list, callback, only conclude when list empty ###
        tap.push line
        handler null, line
  stdout_pipeline.push @$show title: '***'
  stdout_pipeline.push @$push_to_list stdout_lines
  stdout_pipeline.push @$drain null, ->
      stdout_has_ended = yes
      if stderr_message?
        return handler stderr_message
      stdout_message = stdout_lines.join '\n' if stdout_lines.length > 0
      handler null, stdout_message if stderr_has_ended
      return null
  pull stdout_pipeline...
  #.........................................................................................................
  stderr_pipeline.push stderr
  stdout_pipeline.push @$split()
  stderr_pipeline.push @$push_to_list stderr_lines
  stderr_pipeline.push @$drain null, ->
    stderr_has_ended = yes
    if stderr_lines.length > 0
      stderr_message = stderr_lines.join '\n'
      return handler stderr_message if stdout_has_ended
    handler null, stdout_message if stdout_has_ended
    return null
  pull stderr_pipeline...
  #.........................................................................................................
  return null
