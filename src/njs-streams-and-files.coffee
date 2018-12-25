

'use strict'


############################################################################################################
CND                       = require 'cnd'
badge                     = 'PIPESTREAMS/NJS-STREAMS-AND-FILES'
FS                        = require 'fs'
STPS                      = require 'stream-to-pull-stream'



#===========================================================================================================
# READ FROM, WRITE TO FILES, NODEJS STREAMS
#-----------------------------------------------------------------------------------------------------------
@read_from_file = ( path, options ) ->
  ### TAINT consider using https://pull-stream.github.io/#pull-file-reader instead ###
  switch ( arity = arguments.length )
    when 1 then null
    when 2
      if CND.isa_function options
        [ path, options, on_stop, ] = [ path, null, options, ]
    else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  return @read_from_nodejs_stream ( FS.createReadStream path, options )

#-----------------------------------------------------------------------------------------------------------
@write_to_file = ( path, options, on_stop ) ->
  ### TAINT consider using https://pull-stream.github.io/#pull-write-file instead ###
  ### TAINT code duplication ###
  switch ( arity = arguments.length )
    when 1 then null
    when 2
      if CND.isa_function options
        [ path, options, on_stop, ] = [ path, null, options, ]
    when 3
    else throw new Error "µ9983 expected 1 to 3 arguments, got #{arity}"
  #.........................................................................................................
  return @write_to_nodejs_stream ( FS.createWriteStream path, options ), on_stop

#-----------------------------------------------------------------------------------------------------------
@read_from_nodejs_stream = ( stream ) ->
  switch ( arity = arguments.length )
    when 1 then null
    else throw new Error "µ9983 expected 1 argument, got #{arity}"
  #.........................................................................................................
  return STPS.source stream, ( error ) -> finish error

#-----------------------------------------------------------------------------------------------------------
@write_to_nodejs_stream = ( stream, on_stop ) ->
  ### TAINT code duplication ###
  switch ( arity = arguments.length )
    when 1, 2 then null
    else throw new Error "µ9983 expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  if on_stop? and ( ( type = CND.type_of on_stop ) isnt 'function' )
    throw new Error "µ9383 expected a function, got a #{type}"
  #.........................................................................................................
  has_finished = false
  #.........................................................................................................
  finish = ( error ) ->
    ### In case there was an error, throw that error if we already called on_stop, or there is no
    callback given; this is to prevent silent failures: ###
    if error? and ( has_finished or ( not on_stop? ) )
      has_finished = true
      throw error
    #.......................................................................................................
    ### Otherwise, call back (with optional error) only in case we have not yet finished; this is to
    prevent inadvertently calling back more than once: ###
    if not has_finished
      has_finished = true
      if on_stop?
        return on_stop error if error?
        return on_stop()
    #.......................................................................................................
    return null
  #.........................................................................................................
  stream.on 'close', -> finish()
  return STPS.sink stream, ( error ) -> finish error
