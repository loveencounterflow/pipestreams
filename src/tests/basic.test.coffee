

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TESTS/BASIC'
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
test                      = require 'guy-test'
#...........................................................................................................
PS                        = require '../..'
{ $, $async, }            = PS
#...........................................................................................................
pull                      = require 'pull-stream'
$take                     = require 'pull-stream/throughs/take'
$values                   = require 'pull-stream/sources/values'
$pull_drain               = require 'pull-stream/sinks/drain'
pull_through              = require 'pull-through'
#...........................................................................................................
read                      = ( path ) -> FS.readFileSync path, { encoding: 'utf-8', }

#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  test @, 'timeout': 30000

# #-----------------------------------------------------------------------------------------------------------
# @[ "test line assembler" ] = ( T, done ) ->
#   text = """
#   "　2. 纯；专：专～。～心～意。"
#   !"　3. 全；满：～生。～地水。"
#   "　4. 相同：～样。颜色不～。"
#   "　5. 另外!的：蟋蟀～名促织。!"
#   "　6. 表示动作短暂，或是一次，或具试探性：算～算。试～试。"!
#   "　7. 乃；竞：～至于此。"
#   """
#   # text = "abc\ndefg\nhijk"
#   chunks    = text.split '!'
#   text      = text.replace /!/g, ''
#   collector = []
#   assembler = PS._new_line_assembler { extra: true, splitter: '\n', }, ( error, line ) ->
#     throw error if error?
#     if line?
#       collector.push line
#       info rpr line
#     else
#       # urge rpr text
#       # help rpr collector.join '\n'
#       # debug collector
#       if CND.equals text, collector.join '\n'
#         T.succeed "texts are equal"
#       done()
#   for chunk in chunks
#     assembler chunk
#   assembler null

# #-----------------------------------------------------------------------------------------------------------
# @[ "test throughput (1)" ] = ( T, done ) ->
#   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
#   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
#   output  = FS.createWriteStream '/tmp/output.txt'
#   lines   = []
#   input
#     .pipe PS.$split()
#     # .pipe PS.$show()
#     .pipe PS.$succeed()
#     .pipe PS.$as_line()
#     .pipe $ ( line, send ) ->
#       lines.push line
#       send line
#     .pipe output
#   ### TAINT use PipeStreams method ###
#   input.on 'end', -> outpudone()
#   output.on 'close', ->
#     # if CND.equals lines.join '\n'
#     T.succeed "assuming equality"
#     done()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "test throughput (2)" ] = ( T, done ) ->
#   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
#   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
#   output  = FS.createWriteStream '/tmp/output.txt'
#   lines   = []
#   p       = input
#   p       = p.pipe PS.$split()
#   # p       = p.pipe PS.$show()
#   p       = p.pipe PS.$succeed()
#   p       = p.pipe PS.$as_line()
#   p       = p.pipe $ ( line, send ) ->
#       lines.push line
#       send line
#   p       = p.pipe output
#   ### TAINT use PipeStreams method ###
#   input.on 'end', -> outpudone()
#   output.on 'close', ->
#     # if CND.equals lines.join '\n'
#     # debug '12001', lines
#     T.succeed "assuming equality"
#     done()
#   return null

# #-----------------------------------------------------------------------------------------------------------
# @[ "read with pipestreams" ] = ( T, done ) ->
#   matcher       = [
#     '01 ; charset=UTF-8',
#     '02 @@@\tThe Unicode Standard 9.0.0',
#     '03 @@@+\tU90M160615.lst',
#     '04 \tUnicode 9.0.0 final names list.',
#     '05 \tThis file is semi-automatically derived from UnicodeData.txt and',
#     '06 \ta set of manually created annotations using a script to select',
#     '07 \tor suppress information from the data file. The rules used',
#     '08 \tfor this process are aimed at readability for the human reader,',
#     '09 \tat the expense of some details; therefore, this file should not',
#     '10 \tbe parsed for machine-readable information.',
#     '11 @+\t\t© 2016 Unicode®, Inc.',
#     '12 \tFor terms of use, see http://www.unicode.org/terms_of_use.html',
#     '13 @@\t0000\tC0 Controls and Basic Latin (Basic Latin)\t007F',
#     '14 @@+'
#     ]
#   # input_path    = '../../test-data/Unicode-NamesList-tiny.txt'
#   input_path    = '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList-tiny.txt'
#   # output_path   = '/dev/null'
#   output_path   = '/tmp/output.txt'
#   input         = PS.new_stream input_path
#   output        = FS.createWriteStream output_path
#   collector     = []
#   S             = {}
#   S.item_count  = 0
#   S.byte_count  = 0
#   p             = input
#   p             = p.pipe $ ( data, send ) -> whisper '20078-1', rpr data; send data
#   p             = p.pipe PS.$split()
#   p             = p.pipe $ ( data, send ) -> help '20078-1', rpr data; send data
#   #.........................................................................................................
#   p             = p.pipe PS.$ ( line, send ) ->
#     S.item_count += +1
#     S.byte_count += line.length
#     debug '22001-0', rpr line
#     collector.push line
#     send line
#   #.........................................................................................................
#   p             = p.pipe $ ( data, send ) -> urge '20078-2', rpr data; send data
#   p             = p.pipe PS.$as_line()
#   p             = p.pipe output
#   #.........................................................................................................
#   ### TAINT use PipeStreams method ###
#   output.on 'close', ->
#     # debug '88862', S
#     # debug '88862', collector
#     if CND.equals collector, matcher
#       T.succeed "collector equals matcher"
#     done()
#   #.........................................................................................................
#   ### TAINT should be done by PipeStreams ###
#   input.on 'end', ->
#     outpudone()
#   #.........................................................................................................
#   return null


# #-----------------------------------------------------------------------------------------------------------
# @[ "remit without end detection" ] = ( T, done ) ->
#   pipeline = []
#   pipeline.push $values Array.from 'abcdef'
#   pipeline.push $ ( data, send ) ->
#     send data
#     send '*' + data + '*'
#   pipeline.push PS.$show()
#   pipeline.push $pull_drain()
#   PS.pull pipeline...
#   T.succeed "ok"
#   done()

#-----------------------------------------------------------------------------------------------------------
@[ "remit with end detection" ] = ( T, done ) ->
  # debug ( key for key of T ); xxx
  pipeline = []
  pipeline.push $values Array.from 'abcdef'
  # pipeline.push pull_through ( ( data ) -> urge data ), ( -> urge 'ok'; @queue null )
  # pipeline.push pull_through ( ( data ) -> urge data ), null
  pipeline.push $ 'null', ( data, send ) ->
    if data?
      send data
      send '*' + data + '*'
    else
      send 'ok'
  pipeline.push PS.$show()
  pipeline.push $pull_drain()
  PS.pull pipeline...
  T.succeed "ok"
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "wrap FS object for sink" ] = ( T, done ) ->
  output_path   = '/tmp/pipestreams-test-output.txt'
  output_stream = FS.createWriteStream output_path
  sink          = PS.write_to_nodejs_stream output_stream #, ( error ) -> debug '37783', error
  pipeline      = []
  pipeline.push $values Array.from 'abcdef'
  pipeline.push PS.$show()
  pipeline.push sink
  pull pipeline...
  output_stream.on 'finish', =>
    T.ok CND.equals 'abcdef', read output_path
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "function as pull-stream source" ] = ( T, done ) ->
  random = ( n ) =>
    return ( end, callback ) =>
      if end?
        debug '40998', rpr callback
        debug '40998', rpr end
        return callback end
      #only read n times, then stop.
      n += -1
      if n < 0
        return callback true
      callback null, Math.random()
      return null
  #.........................................................................................................
  pipeline  = []
  Ø         = ( x ) => pipeline.push x
  Ø random 10
  # Ø random 3
  Ø PS.$collect()
  Ø $ 'null', ( data, send ) ->
    if data?
      T.ok data.length is 10
      debug data
      send data
    else
      T.succeed "function works as pull-stream source"
      done()
      send null
  Ø PS.$show()
  Ø PS.$drain()
  #.........................................................................................................
  PS.pull pipeline...
  return null

############################################################################################################
unless module.parent?
  # include = []
  # @_prune()
  @_main()
