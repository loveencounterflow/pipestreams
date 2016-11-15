

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
@new_line_assembler = ( settings, handler ) ->
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



#-----------------------------------------------------------------------------------------------------------
@new_stream = ( path ) ->
  #.........................................................................................................
  R             = {}
  R.transforms  = []
  R.pipe = ( transform ) ->
    @transforms.push transform
    return @
  #.........................................................................................................
  input = FS.createReadStream path, { highWaterMark: 120, encoding: 'utf-8', }
  #.........................................................................................................
  input.on 'data', ( chunk ) ->
    # debug '22010', rpr chunk
    # debug '22010', rpr R.transforms
    this_value = chunk
    for transform, transform_idx in R.transforms
      transform this_value, ( next_value ) => this_value = next_value
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
@$show = ->
  ### TAINT rewrite as observer transform (with the `send` argument) ###
  my_info = CND.get_logger 'info', '*'
  return @$ ( data, send ) ->
    send data
    my_info rpr data
    return null

#-----------------------------------------------------------------------------------------------------------
@$split = ->
  main_send = null
  #.........................................................................................................
  assembler = @new_line_assembler { extra: false, splitter: '\n', }, ( error, line ) ->
    return main_send.error error if error?
    main_send line
  #.........................................................................................................
  return @$ ( chunk, send ) =>
    main_send = send
    assembler chunk
    return null

# debug '33631', transform is transform.pipe()

# transform
#   .pipe 42
#   .pipe 'foo'
#   .pipe 'bar'


# debug '78000', transform



#-----------------------------------------------------------------------------------------------------------
@[ "test line assembler" ] = ( T, done ) ->
  text = """
  "　2. 纯；专：专～。～心～意。"
  !"　3. 全；满：～生。～地水。"
  "　4. 相同：～样。颜色不～。"
  "　5. 另外!的：蟋蟀～名促织。!"
  "　6. 表示动作短暂，或是一次，或具试探性：算～算。试～试。"!
  "　7. 乃；竞：～至于此。"
  """
  # text = "abc\ndefg\nhijk"
  chunks    = text.split '!'
  text      = text.replace /!/g, ''
  collector = []
  assembler = @new_line_assembler { extra: true, splitter: '\n', }, ( error, line ) ->
    throw error if error?
    if line?
      collector.push line
      info rpr line
    else
      # urge rpr text
      # help rpr collector.join '\n'
      # debug collector
      debug CND.truth CND.equals text, collector.join '\n'
  for chunk in chunks
    assembler chunk
  assembler null


#-----------------------------------------------------------------------------------------------------------
# input = @new_stream '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList.txt'
# input = @new_stream '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList-short.txt'
input   = @new_stream '/home/flow/io/basic-stream-benchmarks/test-data/guoxuedashi-excerpts-short.txt'
output  = FS.createWriteStream '/tmp/output.txt'
input
  .pipe @$split()
  .pipe @$show()
  .pipe output
