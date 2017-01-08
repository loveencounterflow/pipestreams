


############################################################################################################
PATH                      = require 'path'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPESTREAMS/PROFILER'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
# ƒ                         = CND.format_number.bind CND
#...........................................................................................................
new_numeral               = require 'numeral'
format_float              = ( x ) -> ( new_numeral x ).format '0,0.000'
format_integer            = ( x ) -> ( new_numeral x ).format '0,0'


@timers    = {}
@sums      = {}
@dt_total  = null
@counts    = {}
if global.performance? then @now = global.performance.now.bind global.performance
else                        @now = require 'performance-now'
@start = ( title ) ->
  ( @timers[ title ] ?= [] ).push -@now()
  return null
@stop  = ( title ) ->
  @timers[ title ].push @now() + @timers[ title ].pop()
  return null
@wrap  = ( title, method ) ->
  throw new Error "expected a text, got a #{type}"      unless ( type = CND.type_of title  ) is 'text'
  throw new Error "expected a function, got a #{type}"  unless ( type = CND.type_of method ) is 'function'
  parameters = ( "a#{idx}" for idx in [ 1 .. method.length ] by +1 ).join ', '
  title_txt = JSON.stringify title
  self      = @
  source = """
    var R;
    R = function ( #{parameters} ) {
      self.start( #{title_txt} );
      R = method.apply( null, arguments );
      self.stop( #{title_txt} );
      return R;
      }
    """
  R = eval source
  return R
@_average = ->
  ### only call after calibration, before actual usage ###
  @aggregate()
  @dt = @sums[ 'dt' ] / 10
  delete @sums[ 'dt' ]
  delete @counts[ 'dt' ]
@aggregate = ->
  if @timers[ '*' ]?
    @stop '*' if @timers[ '*' ] < 0
    @dt_total = @timers[ '*' ]
    delete @timers[ '*' ]
    delete @counts[ '*' ]
  for title, timers of @timers
    dts               = @timers[ title ]
    @counts[ title ]  = dts.length
    @sums[ title ]    = ( @sums[ title ] ? 0 ) + dts.reduce ( ( a, b ) -> a + b ), 0
    delete @timers[ title ]
  return null
@report = ->
  @aggregate()
  lines   = []
  dt_sum  = 0
  for title, dt of @sums
    count   = ' ' + @counts[ title ]
    leader  = '...'
    leader += '.' until title.length + leader.length + count.length > 50
    dt_sum += dt
    dt_txt  = format_float dt
    dt_txt  = ' ' + dt_txt until dt_txt.length > 10
    line    = [ title, leader, count, dt_txt, ].join ' '
    lines.push [ dt, line, ]
  lines.sort ( a, b ) ->
    return +1 if a[ 0 ] > b[ 0 ]
    return -1 if a[ 0 ] < b[ 0 ]
    return  0
  dt_reference = @dt_total ? dt_sum
  whisper "epsilon: #{@dt}"
  percentage_txt = ( ( dt_sum / dt_reference * 100 ).toFixed 0 ) + '%'
  whisper "dt reference: #{format_float dt_reference / 1000}s (#{percentage_txt})"
  for [ dt, line, ] in lines
    percentage_txt = ( ( dt / dt_reference * 100 ).toFixed 0 ) + '%'
    percentage_txt = ' ' + percentage_txt until percentage_txt.length > 3
    info line, percentage_txt

#-----------------------------------------------------------------------------------------------------------
### provide a minmum delta time: ###
for _ in [ 1 .. 10 ]
  @start 'dt'
  @stop  'dt'
@_average()

#-----------------------------------------------------------------------------------------------------------
start_profile = ( S ) ->
  S.t0 = Date.now()
  if running_in_devtools
    console.profile S.job_name
  else if V8PROFILER?
    V8PROFILER.startProfiling S.job_name

#-----------------------------------------------------------------------------------------------------------
stop_profile = ( S, handler ) ->
  if running_in_devtools
    console.profileEnd S.job_name
  else if V8PROFILER?
    step ( resume ) ->
      profile         = V8PROFILER.stopProfiling S.job_name
      profile_data    = yield profile.export resume
      S.profile_name  = "profile-#{S.job_name}.json"
      S.profile_home  = PATH.resolve __dirname, '../results', S.fingerprint, 'profiles'
      mkdirp.sync S.profile_home
      S.profile_path  = PATH.resolve S.profile_home, S.profile_name
      FS.writeFileSync S.profile_path, profile_data
      handler()
