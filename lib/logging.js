(function() {
  'use strict';
  var CND, STACKTRACE, after, alert, badge, debug, defer, echo, every, get_source/* https://github.com/felixge/node-stack-trace */, help, info, inspect, is_empty, jr, log, rpr, urge, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/LOGGING';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  every = function(dts, f) {
    return setInterval(f, dts * 1000);
  };

  defer = setImmediate;

  ({jr, is_empty} = CND);

  //...........................................................................................................
  // PS                        = require '../..'
  // { $, $async, }            = PS.export()
  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  //...........................................................................................................
  STACKTRACE = require('stack-trace');

  get_source = require('get-source');

  //-----------------------------------------------------------------------------------------------------------
  this./* https://github.com/xpl/get-source */_get_source_ref = function(delta, prefix, color) {
    /* TAINT use tabular as in old pipedreams */
    var R, display_path, js_column_nr, js_filename, js_line_nr, target, target_column, target_line, target_line_nr, target_path, trace;
    trace = STACKTRACE.get()[delta + 1];
    js_filename = trace.getFileName();
    js_line_nr = trace.getLineNumber();
    js_column_nr = trace.getColumnNumber();
    target = (get_source(js_filename)).resolve({
      line: js_line_nr,
      column: js_column_nr
    });
    target_column = target.column;
    target_line = target.sourceLine.slice(target_column);
    target_line = target_line.replace(/^\s*(.*?)\s*$/g, '$1');
    target_path = target.sourceFile.path;
    display_path = target_path.replace(/\.[^.]+$/, '');
    display_path = '...' + display_path.slice(display_path.length - 10);
    target_line_nr = target.line;
    R = `${CND.gold(prefix)} ${CND.grey(display_path)} ${CND.white(target_line_nr)} ${CND[color](target_line)}`;
    return R.padEnd(150, ' ');
  };

  //-----------------------------------------------------------------------------------------------------------
  this.get_logger = function(letter, color) {
    var transform_nr;
    transform_nr = 0;
    return (transform) => {
      var leader, pipeline, prefix, source_ref;
      transform_nr += +1;
      prefix = `${CND[color](CND.reverse('  '))} ${CND[color](letter + transform_nr)}`;
      source_ref = this._get_source_ref(1, prefix, color);
      pipeline = [];
      leader = '  '.repeat(transform_nr);
      echo(source_ref);
      if ((transform.source != null) && (transform.sink != null)) {
        throw new Error("unable to use logging with duplex stream");
      }
      switch (transform.length) {
        case 0:
          pipeline.push(transform);
          pipeline.push(this.$watch(function(d) {
            return echo(`${prefix}${leader}${xrpr(d)}`);
          }));
          break;
        case 1:
          if (transform_nr === 1) {
            pipeline.push(this.$watch(function(d) {
              return echo('-'.repeat(108));
            }));
          }
          pipeline.push(this.$watch(function(d) {
            return echo(`${prefix}${leader}${CND[color](CND.reverse('  '))} ${xrpr(d)}`);
          }));
          pipeline.push(transform);
          pipeline.push(this.$watch(function(d) {
            return echo(`${prefix}${leader}${CND[color](CND.reverse('  '))} ${xrpr(d)}`);
          }));
      }
      return this.pull(...pipeline);
    };
  };

  //###########################################################################################################
  if (module.parent == null) {
    null;
  }

  // test @
// test @[ "circular pipeline 1" ], { timeout: 5000, }
// test @[ "circular pipeline 2" ], { timeout: 5000, }
// test @[ "duplex" ]
// @[ "_duplex 1" ]()
// @[ "_duplex 2" ]()

}).call(this);
