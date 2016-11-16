

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
OS                        = require 'os'

#-----------------------------------------------------------------------------------------------------------
@_new_line_assembler = ( settings, handler ) ->
  switch arity = arguments.length
    when 1 then [ settings, handler, ] = [ null, settings, ]
    when 2 then null
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  collector     = []
  extra         = settings?[ 'extra'    ] ? yes
  splitter      = settings?[ 'splitter' ] ? '\n'
  #.........................................................................................................
  unless type = CND.isa_text splitter
    throw new Error "expected a text for splitter, got a #{type}"
  ### TAINT should accept multiple characters, characters beyond 0xffff, regexes ###
  unless ( length = splitter.length ) is 1
    throw new Error "expected single character for splitter, got #{length}"
  #.........................................................................................................
  push = ( data ) ->
    collector.push data
    return null
  #.........................................................................................................
  send = ( data ) ->
    handler null, data
  #.........................................................................................................
  flush = ( chunk ) ->
    push chunk if chunk?
    if collector.length > 0
      send collector.join ''
      collector.length = 0
    return null
  #.........................................................................................................
  R = ( chunk ) ->
    unless chunk?
      flush()
      handler null, null if extra
      return null
    start_idx   = 0
    last_idx    = chunk.length - 1
    #.......................................................................................................
    if last_idx < 0
      handler null, ''
      return null
    #.......................................................................................................
    loop
      nl_idx = chunk.indexOf splitter, start_idx
      #.....................................................................................................
      if nl_idx < 0
        push if start_idx is 0 then chunk else chunk[ start_idx .. ]
        break
      #.....................................................................................................
      if nl_idx is 0
        flush()
      #.....................................................................................................
      else
        flush chunk[ start_idx ... nl_idx ]
      #.....................................................................................................
      break if nl_idx is last_idx
      start_idx = nl_idx + 1
  #.........................................................................................................
  return R

#===========================================================================================================
# ISA METHODS
#-----------------------------------------------------------------------------------------------------------
### thx to German Attanasio http://stackoverflow.com/a/28564000/256361 ###
### TAINT copied from PipeDreams ###
@_isa_nodestream            = ( x ) -> x instanceof ( require 'stream' ).Stream
@_isa_readable_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.readable
@_isa_writable_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.writable
@_isa_readonly_nodestream   = ( x ) -> ( @_isa_nodestream x ) and x.readable and not x.writable
@_isa_writeonly_nodestream  = ( x ) -> ( @_isa_nodestream x ) and x.writable and not x.readable
@_isa_duplex_nodestream     = ( x ) -> ( @_isa_nodestream x ) and x.readable and     x.writable


#-----------------------------------------------------------------------------------------------------------
@new_stream = ( path ) ->
  self = @
  #.........................................................................................................
  R             = {}
  R.transforms  = []
  #.........................................................................................................
  R.pipe = ( transform ) ->
    if        CND.isa_function    transform then type = 'function'
    else if self._isa_nodestream  transform then type = 'nodestream'
    else throw new Error "expected a NodeJS stream or a function, got a #{CND.type_of transform}"
    @transforms.push [ type, transform, ]
    return @
  #.........................................................................................................
  R.on = ( P... ) ->
    input.on P...
  #.........................................................................................................
  input = FS.createReadStream path, { highWaterMark: 120, encoding: 'utf-8', }
  #.........................................................................................................
  input.on 'data', ( chunk ) ->
    # debug '22010', rpr chunk
    # debug '22010', rpr R.transforms
    this_value = chunk
    for [ type, transform, ], transform_idx in R.transforms
      switch type
        when 'function'   then transform this_value, ( next_value ) => this_value = next_value
        when 'nodestream' then transform.write this_value
        else throw new Error "expected a NodeJS stream or a function, got a #{CND.type_of transform}"
  #.........................................................................................................
  input.on 'end', -> urge 'input ended'
  input.on 'close', -> urge 'input closed'
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@$ = @remit = ( method ) ->
  throw new Error "### MEH ###" unless method.length is 2
  return method

#-----------------------------------------------------------------------------------------------------------
@$pass = ->
  ### TAINT rewrite as observer transform (without the `send` argument) ###
  return @$ ( data, send ) -> send data

#-----------------------------------------------------------------------------------------------------------
@$show = ->
  ### TAINT rewrite as observer transform (without the `send` argument) ###
  my_info = CND.get_logger 'info', '*'
  return @$ ( data, send ) ->
    send data
    my_info rpr data
    return null

#-----------------------------------------------------------------------------------------------------------
@$split = ->
  main_send = null
  #.........................................................................................................
  assembler = @_new_line_assembler { extra: false, splitter: '\n', }, ( error, line ) ->
    return main_send.error error if error?
    main_send line
  #.........................................................................................................
  return @$ ( chunk, send ) =>
    main_send = send
    assembler chunk
    return null

#-----------------------------------------------------------------------------------------------------------
@$as_line = ( stringify ) ->
  stringify ?= JSON.stringify
  return @$ ( data, send ) =>
    send ( if ( CND.isa_text data ) then data else stringify data ) + '\n'
    return null

# debug '33631', transform is transform.pipe()

# transform
#   .pipe 42
#   .pipe 'foo'
#   .pipe 'bar'


# debug '78000', transform









