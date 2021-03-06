(function() {
  'use strict';
  var $, $async, $drain, $split, $stringify, $utf8, CND, FS, PATH, PRFLR, PS, S, STPS, V8PROFILER, _, async_map, badge, debug, echo, error, format_float, format_integer, help, i, info, new_file_source, new_numeral, pull, rpr, start_profile, stop_profile, test, through, urge, warn, whisper;

  /*
  Testing Parameters

  * number of no-op pass-through transforms
  * highWaterMark for input stream
  * whether input stream emits buffers or strings (if it emits strings, whether `$utf8` transform should be kept)
  * implementation model for transforms
  * implementation model for pass-throughs

  Easy to show that `$split` doesn't work correctly on buffers (set highWaterMark to, say, 3 and have
  input stream emit buffers).

   */
  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'BASIC-STREAM-BENCHMARKS-2/COPY-LINES-WITH-PULL-STREAM';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  new_numeral = require('numeral');

  format_float = function(x) {
    return (new_numeral(x)).format('0,0.000');
  };

  format_integer = function(x) {
    return (new_numeral(x)).format('0,0');
  };

  //...........................................................................................................
  PATH = require('path');

  FS = require('fs');

  //...........................................................................................................
  $split = require('pull-split');

  $stringify = require('pull-stringify');

  $utf8 = require('pull-utf8-decoder');

  new_file_source = require('pull-file');

  pull = require('pull-stream');

  /* NOTE these two are different: */
  // $pass_through             = require 'pull-stream/throughs/through'
  through = require('pull-through');

  async_map = require('pull-stream/throughs/async-map');

  $drain = require('pull-stream/sinks/drain');

  STPS = require('stream-to-pull-stream');

  //...........................................................................................................
  S = {};

  S.pass_through_count = 0;

  // S.pass_through_count      = 1
  // S.pass_through_count      = 100
  // S.implementation          = 'pull-stream'
  S.implementation = 'pipestreams-map';

  // S.implementation          = 'pipestreams-remit'
  //...........................................................................................................
  test = require('guy-test');

  //...........................................................................................................
  PS = require('../..');

  ({$, $async} = PS.export());

  //...........................................................................................................
  /* Avoid to try to require `v8-profiler` when running this module with `devtool`: */
  S.running_in_devtools = console.profile != null;

  V8PROFILER = null;

  if (!S.running_in_devtools) {
    try {
      V8PROFILER = require('v8-profiler');
    } catch (error1) {
      error = error1;
      if (error['code'] !== 'MODULE_NOT_FOUND') {
        throw error;
      }
      warn("unable to `require v8-profiler`");
    }
  }

  PRFLR = {};

  PRFLR.timers = {};

  PRFLR.sums = {};

  PRFLR.dt_total = null;

  PRFLR.counts = {};

  if (global.performance != null) {
    PRFLR.now = global.performance.now.bind(global.performance);
  } else {
    PRFLR.now = require('performance-now');
  }

  PRFLR.start = function(title) {
    var base;
    ((base = this.timers)[title] != null ? base[title] : base[title] = []).push(-this.now());
    return null;
  };

  PRFLR.stop = function(title) {
    this.timers[title].push(this.now() + this.timers[title].pop());
    return null;
  };

  PRFLR.wrap = function(title, method) {
    var R, idx, parameters, source, title_txt, type;
    if ((type = CND.type_of(title)) !== 'text') {
      throw new Error(`expected a text, got a ${type}`);
    }
    if ((type = CND.type_of(method)) !== 'function') {
      throw new Error(`expected a function, got a ${type}`);
    }
    parameters = ((function() {
      var i, ref, results;
      results = [];
      for (idx = i = 1, ref = method.length; i <= ref; idx = i += +1) {
        results.push(`a${idx}`);
      }
      return results;
    })()).join(', ');
    title_txt = JSON.stringify(title);
    source = `var R;\nR = function ( ${parameters} ) {\n  PRFLR.start( ${title_txt} );\n  R = method.apply( null, arguments );\n  PRFLR.stop( ${title_txt} );\n  return R;\n  }`;
    R = eval(source);
    return R;
  };

  PRFLR._average = function() {
    /* only call after calibration, before actual usage */
    this.aggregate();
    this.dt = this.sums['dt'] / 10;
    delete this.sums['dt'];
    return delete this.counts['dt'];
  };

  PRFLR.aggregate = function() {
    var dts, ref, ref1, timers, title;
    if (this.timers['*'] != null) {
      if (this.timers['*'] < 0) {
        this.stop('*');
      }
      this.dt_total = this.timers['*'];
      delete this.timers['*'];
      delete this.counts['*'];
    }
    ref = this.timers;
    for (title in ref) {
      timers = ref[title];
      dts = this.timers[title];
      this.counts[title] = dts.length;
      this.sums[title] = ((ref1 = this.sums[title]) != null ? ref1 : 0) + dts.reduce((function(a, b) {
        return a + b;
      }), 0);
      delete this.timers[title];
    }
    return null;
  };

  PRFLR.report = function() {
    var count, dt, dt_reference, dt_sum, dt_txt, i, leader, len, line, lines, percentage_txt, ref, ref1, results, title;
    this.aggregate();
    lines = [];
    dt_sum = 0;
    ref = this.sums;
    for (title in ref) {
      dt = ref[title];
      count = ' ' + this.counts[title];
      leader = '...';
      while (!(title.length + leader.length + count.length > 50)) {
        leader += '.';
      }
      dt_sum += dt;
      dt_txt = format_float(dt);
      while (!(dt_txt.length > 10)) {
        dt_txt = ' ' + dt_txt;
      }
      line = [title, leader, count, dt_txt].join(' ');
      lines.push([dt, line]);
    }
    lines.sort(function(a, b) {
      if (a[0] > b[0]) {
        return +1;
      }
      if (a[0] < b[0]) {
        return -1;
      }
      return 0;
    });
    dt_reference = (ref1 = this.dt_total) != null ? ref1 : dt_sum;
    whisper(`epsilon: ${this.dt}`);
    percentage_txt = ((dt_sum / dt_reference * 100).toFixed(0)) + '%';
    whisper(`dt reference: ${format_float(dt_reference / 1000)}s (${percentage_txt})`);
    results = [];
    for (i = 0, len = lines.length; i < len; i++) {
      [dt, line] = lines[i];
      percentage_txt = ((dt / dt_reference * 100).toFixed(0)) + '%';
      while (!(percentage_txt.length > 3)) {
        percentage_txt = ' ' + percentage_txt;
      }
      results.push(info(line, percentage_txt));
    }
    return results;
  };

//-----------------------------------------------------------------------------------------------------------
/* provide a minmum delta time: */
  for (_ = i = 1; i <= 10; _ = ++i) {
    PRFLR.start('dt');
    PRFLR.stop('dt');
  }

  PRFLR._average();

  //-----------------------------------------------------------------------------------------------------------
  start_profile = function(S) {
    S.t0 = Date.now();
    if (running_in_devtools) {
      return console.profile(S.job_name);
    } else if (V8PROFILER != null) {
      return V8PROFILER.startProfiling(S.job_name);
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  stop_profile = function(S, handler) {
    if (running_in_devtools) {
      return console.profileEnd(S.job_name);
    } else if (V8PROFILER != null) {
      return step(function*(resume) {
        var profile, profile_data;
        profile = V8PROFILER.stopProfiling(S.job_name);
        profile_data = (yield profile.export(resume));
        S.profile_name = `profile-${S.job_name}.json`;
        S.profile_home = PATH.resolve(__dirname, '../results', S.fingerprint, 'profiles');
        mkdirp.sync(S.profile_home);
        S.profile_path = PATH.resolve(S.profile_home, S.profile_name);
        FS.writeFileSync(S.profile_path, profile_data);
        return handler();
      });
    }
  };

  //-----------------------------------------------------------------------------------------------------------
  TAP.test("performance regression", function(T) {
    var $as_line, $as_text, $count, $filter_comments, $filter_empty, $filter_incomplete, $my_utf8, $on_start, $on_stop, $pass, $select_fields, $show, $split_fields, $trim, XXX_through2, idx, input, input_path, input_settings, item_count, j, output, output_path, pipeline, push, ref, t0, t1;
    //---------------------------------------------------------------------------------------------------------
    input_settings = {
      encoding: 'utf-8'
    };
    input_path = PATH.resolve(__dirname, '../../test-data/ids.txt');
    // input_path      = PATH.resolve __dirname, '../../test-data/ids-short.txt'
    // input_path      = PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
    output_path = PATH.resolve(__dirname, '../../test-data/ids-copy.txt');
    //---------------------------------------------------------------------------------------------------------
    input = PS.new_file_source(input_path, input_settings);
    // output                    = PS.new_file_sink              output_path
    // output                    = PS._new_file_sink_using_stps  output_path
    // output                    = PS._new_file_sink_using_pwf   output_path
    output = PS.new_file_sink(output_path);
    //---------------------------------------------------------------------------------------------------------
    pipeline = [];
    push = pipeline.push.bind(pipeline);
    t0 = null;
    t1 = null;
    item_count = 0;
    //---------------------------------------------------------------------------------------------------------
    $on_start = function() {
      return PS.map_start(function() {
        help(44402, "start");
        PRFLR.start('*');
        t0 = Date.now();
        if (S.running_in_devtools) {
          return console.profile('copy-lines');
        }
      });
    };
    //---------------------------------------------------------------------------------------------------------
    $on_stop = function() {
      return PS.map_stop(function() {
        var dts, dts_txt, ips, ips_txt, item_count_txt;
        PRFLR.stop('*');
        PRFLR.report();
        if (S.running_in_devtools) {
          console.profileEnd('copy-lines');
        }
        t1 = Date.now();
        dts = (t1 - t0) / 1000;
        dts_txt = format_float(dts);
        item_count_txt = format_integer(item_count);
        ips = item_count / dts;
        ips_txt = format_float(ips);
        help(PATH.basename(__filename));
        help(`pass-through count: ${S.pass_through_count}`);
        help(`${item_count_txt} items; dts: ${dts_txt}, ips: ${ips_txt}`);
        T.pass("looks good");
        return T.end();
      });
    };
    
  function XXX_map (read, map) {
    //return a readable function!
    return function (end, cb) {
      read(end, function (end, data) {
        debug(20323,rpr(data))
        cb(end, data != null ? map(data) : null)
      })
    }
  }
  ;
    
  function XXX_through (op, onEnd) {
    var a = false

    function once (abort) {
      if(a || !onEnd) return
      a = true
      onEnd(abort === true ? null : abort)
    }

    return function (read) {
      return function (end, cb) {
        if(end) once(end)
        return read(end, function (end, data) {
          if(!end) op && op(data)
          else once(end)
          cb(end, data)
        })
      }
    }
  }
  ;
    XXX_through2 = function(on_data, on_stop) {
      var collector, has_ended, once, send;
      has_ended = false;
      collector = [];
      once = function(abort) {
        if (has_ended) {
          return null;
        }
        if (on_stop == null) {
          return null;
        }
        has_ended = true;
        on_stop(abort === true ? null : abort);
        return null;
      };
      send = function(data) {
        return collector.push(data);
      };
      return function(read) {
        return function(end, handler) {
          if (end) {
            once(end);
          }
          return read(end, function(end, data) {
            var d, j, len;
            if (end) {
              once(end);
            } else {
              if (on_data != null) {
                on_data(data, send);
              }
            }
            if (collector.length > 0) {
              for (j = 0, len = collector.length; j < len; j++) {
                d = collector[j];
                handler(end, d);
              }
              collector.length = 0;
            } else {
              handler(end, null);
            }
          });
        };
      };
    };
    //---------------------------------------------------------------------------------------------------------
    switch (S.implementation) {
      //.......................................................................................................
      case 'pull-stream':
        $as_line = function() {
          return pull.map(function(line) {
            return line + '\n';
          });
        };
        $as_text = function() {
          return pull.map(function(fields) {
            return JSON.stringify(fields);
          });
        };
        $count = function() {
          return pull.map(function(line) {
            item_count += +1;
            return line;
          });
        };
        // $count              = -> pull.map ( line    ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; return line
        $select_fields = function() {
          return pull.map(function(fields) {
            var formula, glyph;
            [_, glyph, formula] = fields;
            return [glyph, formula];
          });
        };
        $split_fields = function() {
          return pull.map(function(line) {
            return line.split('\t');
          });
        };
        $trim = function() {
          return pull.map(function(line) {
            return line.trim();
          });
        };
        $pass = function() {
          return pull.map(function(line) {
            return line;
          });
        };
        break;
      //.......................................................................................................
      case 'pipestreams-remit':
        $as_line = function() {
          return $(function(line, send) {
            return send(line + '\n');
          });
        };
        $as_text = function() {
          return $(function(fields, send) {
            return send(JSON.stringify(fields));
          });
        };
        $count = function() {
          return $(function(line, send) {
            item_count += +1;
            return send(line);
          });
        };
        // $count              = -> $ ( line,   send ) -> item_count += +1; whisper item_count if item_count % 1000 is 0; send line
        $select_fields = function() {
          return $(function(fields, send) {
            var formula, glyph;
            [_, glyph, formula] = fields;
            return send([glyph, formula]);
          });
        };
        $split_fields = function() {
          return $(function(line, send) {
            return send(line.split('\t'));
          });
        };
        $trim = function() {
          return $(function(line, send) {
            return send(line.trim());
          });
        };
        $pass = function() {
          return $(function(line, send) {
            return send(line);
          });
        };
        break;
      //.......................................................................................................
      case 'pipestreams-map':
        $as_line = function() {
          return PS.map(PRFLR.wrap('$as_line', function(line) {
            return line + '\n';
          }));
        };
        $as_text = function() {
          return PS.map(PRFLR.wrap('$as_text', function(fields) {
            return JSON.stringify(fields);
          }));
        };
        $count = function() {
          return PS.map(PRFLR.wrap('$count', function(line) {
            item_count += +1;
            return line;
          }));
        };
        $select_fields = function() {
          return PS.map(PRFLR.wrap('$select_fields', function(fields) {
            var formula, glyph;
            [_, glyph, formula] = fields;
            return [glyph, formula];
          }));
        };
        $split_fields = function() {
          return PS.map(PRFLR.wrap('$split_fields', function(line) {
            return line.split('\t');
          }));
        };
        $trim = function() {
          return PS.map(PRFLR.wrap('$trim', function(line) {
            return line.trim();
          }));
        };
        $pass = function() {
          return PS.map(PRFLR.wrap('$pass', function(line) {
            return line;
          }));
        };
        $my_utf8 = function() {
          return PS.map(PRFLR.wrap('$my_utf8', function(buffer) {
            debug(buffer);
            return buffer.toString('utf-8');
          }));
        };
        $show = function() {
          return PS.map(PRFLR.wrap('$show', function(data) {
            info(rpr(data));
            return data;
          }));
        };
    }
    //.........................................................................................................
    $filter_empty = function() {
      return PS.$filter(PRFLR.wrap('$filter_empty', function(line) {
        return line.length > 0;
      }));
    };
    $filter_comments = function() {
      return PS.$filter(PRFLR.wrap('$filter_comments', function(line) {
        return !line.startsWith('#');
      }));
    };
    $filter_incomplete = function() {
      return PS.$filter(PRFLR.wrap('$filter_incomplete', function(fields) {
        var a, b;
        [a, b] = fields;
        return (a != null) || (b != null);
      }));
    };
    //---------------------------------------------------------------------------------------------------------
    push(input);
    push($on_start());
    // push $utf8()
    push(PRFLR.wrap('$split', $split()));
    // push $show()
    push($count());
    push($trim());
    push($filter_empty());
    push($filter_comments());
    // push pull.filter   ( line    ) -> ( /魚/ ).test line
    push($split_fields());
    push($select_fields());
    push($filter_incomplete());
    // push XXX_through2 ( data, send ) ->
    //   urge data
    //   send data
    //   send data
    push($as_text());
    push($as_line());
    for (idx = j = 1, ref = S.pass_through_count; j <= ref; idx = j += +1) {
      // push ( pull.map ( line ) -> line ) for idx in [ 1 .. S.pass_through_count ] by +1
      /*
      */
      push($pass());
    }
    push($on_stop());
    // push $sink_example()
    // push output
    // push $drain ( ( data ) -> urge data ), ( ( P... )-> help P )
    push(PRFLR.wrap('$drain', $drain()));
    return pull(...pipeline);
  });

}).call(this);
