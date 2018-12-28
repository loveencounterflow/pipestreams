

'use strict'

############################################################################################################
CND                       = require 'cnd'
$pull_split               = require 'pull-split'
$pull_utf8_decoder        = require 'pull-utf8-decoder'


#-----------------------------------------------------------------------------------------------------------
@new_text_source = ( text ) -> $values [ text, ]

# #-----------------------------------------------------------------------------------------------------------
# @new_text_sink = -> throw new Error "µ8648 not implemented"

#-----------------------------------------------------------------------------------------------------------
@$split = ( settings ) ->
  throw new Error "µ26243 MEH" if settings?
  R         = []
  matcher   = null
  mapper    = null
  reverse   = no
  skip_last = yes
  R.push $pull_utf8_decoder()
  R.push $pull_split matcher, mapper, reverse, skip_last
  return pull R...

#-----------------------------------------------------------------------------------------------------------
@$join = ( joiner = null ) ->
  collector = []
  length    = 0
  type      = null
  is_first  = yes
  return @$ 'null', ( data, send ) ->
    if data?
      if is_first
        is_first  = no
        type      = CND.type_of data
        switch type
          when 'text'
            joiner ?= ''
          when 'buffer'
            throw new Error "µ27008 joiner not supported for buffers, got #{rpr joiner}" if joiner?
          else
            throw new Error "µ27773 expected a text or a buffer, got a #{type}"
      else
        unless ( this_type = CND.type_of data ) is type
          throw new Error "µ28538 expected a #{type}, got a #{this_type}"
      length += data.length
      collector.push data
    else
      return send '' if ( collector.length is 0 ) or ( length is 0 )
      return send collector.join '' if type is 'text'
      return send Buffer.concat collector, length
    return null

#-----------------------------------------------------------------------------------------------------------
@$as_line = ->
  return @_map_errors ( line ) =>
    "µ839833 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    line + '\n'

#-----------------------------------------------------------------------------------------------------------
@$trim = ->
  return @_map_errors ( line ) =>
    "µ839833 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    line.trim()

#-----------------------------------------------------------------------------------------------------------
@$skip_empty = ->
  return @$filter ( line ) =>
    "µ839833 expected a text, got a #{type}" unless ( type = CND.type_of line ) is 'text'
    line.length > 0

#-----------------------------------------------------------------------------------------------------------
@$as_text = ( settings ) ->
  serialize = settings?[ 'serialize' ] ? JSON.stringify
  return @_map_errors ( data ) => serialize data

#-----------------------------------------------------------------------------------------------------------
@$desaturate = ->
  ### remove ANSI escape sequences ###
  pattern = /\x1b\[[0-9;]*[JKmsu]/g
  return @map ( line ) =>
    return line.replace pattern, ''



