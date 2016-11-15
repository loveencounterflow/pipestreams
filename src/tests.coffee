

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS'
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
tap                       = require 'tap'
PS                        = require '..'
{ $, $async, }            = PS


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
tap.test 'test throughput', ( T ) ->
  # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
  input   = @new_stream PATH.resolve __dirname, '../test-data/Unicode-NamesList.txt'
  output  = FS.createWriteStream '/tmp/output.txt'
  input
    .pipe @$split()
    .pipe @$pass()
    # .pipe @$show()
    .pipe @$as_line()
    .pipe output
  ### TAINT use PipeStreams method ###
  output.on 'close', ->
    T.end
  return null



