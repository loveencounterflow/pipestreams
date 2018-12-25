


'use strict'

############################################################################################################
CND                       = require 'cnd'

#-----------------------------------------------------------------------------------------------------------
@$name_fields = ( names ) ->
  throw new Error "µ23948 expected a list, got a #{type}" unless ( type = CND.type_of names ) is 'list'
  return @_map_errors ( fields ) =>
    throw new Error "µ24713 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
    R = {}
    for value, idx in fields
      name      = names[ idx ] ?= "field_#{idx}"
      R[ name ] = value
    return R

#-----------------------------------------------------------------------------------------------------------
@$trim_fields = -> @$watch ( fields  ) =>
  throw new Error "µ24713 expected a list, got a #{type}" unless ( type = CND.type_of fields ) is 'list'
  fields[ idx ] = field.trim() for field, idx in fields
  return null

#-----------------------------------------------------------------------------------------------------------
@$split_tsv = ->
  R = []
  R.push @$split()
  R.push @$trim()
  R.push @$skip_empty()
  R.push @$filter ( line ) -> not line.startsWith '#'
  R.push @$split_fields()
  # R.push @$trim_fields()
  return @pull R...
