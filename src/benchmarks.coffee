
'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'BASIC-STREAM-BENCHMARKS-2/BENCHMARKS'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'
#...........................................................................................................
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
$split                    = require 'pull-split'
$stringify                = require 'pull-stringify'
$utf8                     = require 'pull-utf8-decoder'
new_file_source           = require 'pull-file'
pull                      = require 'pull-stream'
### NOTE these two are different: ###
# $pass_through             = require 'pull-stream/throughs/through'
through                   = require 'pull-through'
async_map                 = require 'pull-stream/throughs/async-map'
STPS                      = require 'stream-to-pull-stream'
#...........................................................................................................
O                         = {}
O.running_in_devtools     = console.profile?
#...........................................................................................................
PS                        = require '..'
{ $, $async, }            = PS
#...........................................................................................................
### Avoid to try to require `v8-profiler` when running this module with `devtool`: ###
# V8PROFILER                = null
# unless running_in_devtools
#   try
#     V8PROFILER = require 'v8-profiler'
#   catch error
#     throw error unless error[ 'code' ] is 'MODULE_NOT_FOUND'
#     warn "unable to `require v8-profiler`"



#-----------------------------------------------------------------------------------------------------------
simple_recursive_function = ->
  log = console.log
  log process.versions
  console.profile 'simple_recursive_function' if O.running_in_devtools
  f = ( count = 0 ) ->
    # whisper format_integer count # if count % 1e5 is 0
    log count
    if count < 10
      return f count + 1
  f()
  console.profileEnd 'simple_recursive_function' if O.running_in_devtools


############################################################################################################
simple_recursive_function()






