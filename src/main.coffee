
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
#...........................................................................................................
pull                      = require 'pull-stream'
map                       = pull.map.bind pull
through                   = require 'pull-through'
pull_async_map            = require 'pull-stream/throughs/async-map'
#...........................................................................................................
return_id                 = ( x ) -> x

#-----------------------------------------------------------------------------------------------------------
@new_file_source              = ( P... ) -> @_new_file_source_using_stps      P...
@new_file_sink                = ( P... ) -> @_new_file_sink_using_stps        P...
@_new_file_source_using_stps  = ( P... ) -> STPS.source FS.createReadStream   P...
@_new_file_sink_using_stps    = ( P... ) -> STPS.sink   FS.createWriteStream  P...


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
  return @map ( data ) =>
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
  return @map ( data ) =>
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
@$ = @remit = ( method ) ->
  throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
  switch arity = method.length
    when 2 then null
    else throw new Error "method arity #{arity} not implemented"
  #.........................................................................................................
  self  = null
  send  = ( data ) => self.queue data
  #.........................................................................................................
  on_data = ( data ) ->
    self = @
    method data, send
  #.........................................................................................................
  R = through on_data
    # @queue null
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@async_map = pull_async_map

# #-----------------------------------------------------------------------------------------------------------
# @$async = @remit_async = ( method ) ->
#   throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
#   throw new Error "### MEH ###" unless ( arity = method.length ) is 2


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$pass            = -> @map ( data ) -> data
#...........................................................................................................
@$as_line         = -> @map ( line ) -> line + '\n'
@$trim            = -> @map ( line ) -> line.trim()
@$split_fields    = -> @map ( line ) -> line.split '\t'
#...........................................................................................................
@$push_to_list    = ( collector ) -> @map ( data ) -> collector.push  data; return data
@$add_to_set      = ( collector ) -> @map ( data ) -> collector.add   data; return data
#...........................................................................................................
@$count           = -> throw new Error "not implemented"
#...........................................................................................................
@$drain           = $pull_drain

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
@$show = ( settings ) ->
  title     = settings?[ 'title'      ] ? '-->'
  serialize = settings?[ 'serialize'  ] ? JSON.stringify
  return @map ( data ) ->
    info title, serialize data
    return data

#-----------------------------------------------------------------------------------------------------------
@$as_text = ( settings ) ->
  serialize = settings?[ 'serialize' ] ? JSON.stringify
  return @map ( data ) ->
    return serialize data


# #===========================================================================================================
# # ISA METHODS
# #-----------------------------------------------------------------------------------------------------------
# ### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
# ### TAINT copied from PipeDreams ###
# @_isa_nodestream            = ( x ) -> x instanceof ( require 'stream' ).Stream
# @_isa_readable_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.readable
# @_isa_writable_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.writable
# @_isa_readonly_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.readable and not x.writable
# @_isa_writeonly_nodestream  = ( x ) -> ( @_isa_nodestream x ) and x.writable and not x.readable
# @_isa_duplex_nodestream     = ( x ) -> ( @_isa_nodestream x ) and x.readable and     x.writable

# #-----------------------------------------------------------------------------------------------------------
# @_type_of = ( x ) ->
#   return 'nodestream' if @_isa_nodestream x
#   return CND.type_of x

# #-----------------------------------------------------------------------------------------------------------
# @new_stream = ( path ) ->
#   self = @
#   #.........................................................................................................
#   R             = {}
#   R.transforms  = []
#   #.........................................................................................................
#   ### TAINT strictly, no need to inline these methods; could be same for all instances, except @ binding ###
#   R.pipe = ( transform_info ) ->
#     type      = null
#     mode      = null
#     arity     = null
#     transform = null
#     switch type = self._type_of transform_info
#       when 'function'
#         throw new Error "### currently not supported ###"
#       when 'PIPESTREAMS/transform-info'
#         type                      = 'function'
#         { method, arity, mode, }  = transform_info
#         transform                 = method
#       when 'nodestream'
#         transform                 = transform_info
#       else
#         throw new Error "expected a NodeJS stream, a PIPESTREAMS/transform-info or a function, got a #{type}"
#     @transforms.push { type, mode, arity, transform, }
#     return @
#   #.........................................................................................................
#   R.on = ( P... ) ->
#     input.on P...
#   #.........................................................................................................
#   input = FS.createReadStream path, { highWaterMark: 120, encoding: 'utf-8', }
#   #.........................................................................................................
#   input.on 'data', ( chunk ) ->
#     # debug '22010', rpr chunk
#     # debug '22010', rpr R.transforms
#     this_collector  = [ chunk, ]
#     next_collector  = []
#     for { type, mode, arity, transform, }, transform_idx in R.transforms
#       #.....................................................................................................
#       switch type
#         #...................................................................................................
#         when 'function'
#           ### TAINT only works with synchronous transforms ###
#           handler = ( next_value ) =>
#             next_collector.push next_value
#           while this_collector.length > 0
#             this_value = this_collector.shift()
#             transform this_value, handler
#           this_collector  = next_collector
#           next_collector  = []
#         #...................................................................................................
#         when 'nodestream'
#           ### TAINT honor backpressure ###
#           while this_collector.length > 0
#             this_value = this_collector.shift()
#             transform.write this_value
#         #...................................................................................................
#         else
#           throw new Error "expected a NodeJS stream or a function, got a #{CND.type_of transform}"
#   #.........................................................................................................
#   # input.on 'end', -> urge 'input ended'
#   # input.on 'close', -> urge 'input closed'
#   #.........................................................................................................
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$ = @remit = ( method ) ->
#   throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
#   throw new Error "### MEH ###" unless ( arity = method.length ) is 2
#   R =
#     '~isa':     'PIPESTREAMS/transform-info'
#     mode:       'sync'
#     method:     method
#     arity:      arity
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$async = @remit_async = ( method ) ->
#   throw new Error "expected a function, got a #{type}" unless ( type = CND.type_of method ) is 'function'
#   throw new Error "### MEH ###" unless ( arity = method.length ) is 2
#   R =
#     '~isa':     'PIPESTREAMS/transform-info'
#     mode:       'async'
#     method:     method
#     arity:      arity
#   return R

# #-----------------------------------------------------------------------------------------------------------
# @$pass = ->
#   ### TAINT rewrite as observer transform (without the `send` argument) ###
#   return @$ ( data, send ) -> send data

# #-----------------------------------------------------------------------------------------------------------
# @$show = ->
#   ### TAINT rewrite as observer transform (without the `send` argument) ###
#   my_info = CND.get_logger 'info', '*'
#   return @$ ( data, send ) ->
#     send data
#     my_info rpr data
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$split = ->
#   main_send = null
#   #.........................................................................................................
#   assembler = @_new_line_assembler { extra: false, splitter: '\n', }, ( error, line ) ->
#     return main_send.error error if error?
#     main_send line
#   #.........................................................................................................
#   return @$ ( chunk, send ) =>
#     main_send = send
#     assembler chunk
#     return null

# #-----------------------------------------------------------------------------------------------------------
# @$as_line = ( stringify ) ->
#   stringify ?= JSON.stringify
#   return @$ ( data, send ) =>
#     send ( if ( CND.isa_text data ) then data else stringify data ) + '\n'
#     return null

# # debug '33631', transform is transform.pipe()

# # transform
# #   .pipe 42
# #   .pipe 'foo'
# #   .pipe 'bar'


# # debug '78000', transform









