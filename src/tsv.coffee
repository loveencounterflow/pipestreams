


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/TSV'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND

#-----------------------------------------------------------------------------------------------------------
@$name_fields = ( names ) ->
  throw new Error "µ27276 expected a list, got a #{type}" unless ( type = CND.type_of names ) is 'list'
  return @_map_errors ( fields ) =>
    throw new Error "µ27597 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
    R = {}
    for value, idx in fields
      name      = names[ idx ] ?= "field_#{idx}"
      R[ name ] = value
    return R

#-----------------------------------------------------------------------------------------------------------
@$split_on_tabs = ( settings ) ->
  return @$ ( line, send ) =>
    "µ27918 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    send line.split /\t/

#-----------------------------------------------------------------------------------------------------------
@$split_on_whitespace = ( field_count = null ) ->
  #.........................................................................................................
  ### If user requested null or zero fields, we can just split the line: ###
  if ( not field_count? ) or ( field_count is 0 )
    return @$ ( line, send ) => send line.split /\s+/
  #.........................................................................................................
  ### If user requested one field, then the entire line is the field: ###
  if field_count is 1
    return @$ ( line, send ) => send [ line, ]
  #.........................................................................................................
  ### TAINT validate field_count is integer ###
  ### TAINT validate field_count is non-negative ###
  return @$ ( line, send ) =>
    "µ28239 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    fields  = []
    parts   = line.split /(\s+)/
    pairs   = ( [ parts[ idx ], parts[ idx + 1 ] ? '' ] for idx in [ 0 ... parts.length ] by +2 )
    #.......................................................................................................
    ### Shift-push line contents from `pairs` into `fields` until exhausted or saturated: ###
    loop
      break if pairs.length <= 0
      break if fields.length >= field_count - 1
      fields.push pairs.shift()[ 0 ]
    #.......................................................................................................
    ### Concat remaining parts and add as one more field: ###
    if pairs.length > 0
      fields.push ( ( ( fld + spc ) for [ fld, spc, ] in pairs ).join '' ).trim()
    #.......................................................................................................
    ### Pad missing fields with `null`: ###
    ### TAINT allow to configure padding value ###
    fields.push null while fields.length < field_count
    #.......................................................................................................
    send fields

#-----------------------------------------------------------------------------------------------------------
@$trim_fields = -> @$watch ( fields  ) =>
  throw new Error "µ28560 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
  fields[ idx ] = field.trim() for field, idx in fields
  return null

#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ->
  R = []
  R.push @$split()
  # R.push @$trim()
  R.push @$skip_blank()
  ### TAINT use named method; allow to configure comment marker ###
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_on_tabs()
  R.push @$trim_fields()
  return @pull R...

#-----------------------------------------------------------------------------------------------------------
### TAINT use `settings` for extensibility ###
@$split_wsv = ( field_count = 0 ) ->
  R = []
  R.push @$split()
  # R.push @$trim()
  R.push @$skip_blank()
  ### TAINT use named method; allow to configure comment marker ###
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_on_whitespace field_count
  return @pull R...


