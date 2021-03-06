(function() {
  //###########################################################################################################
  var $, $async, CND, PS, after, alert, badge, debug, defer, demo_x, echo, every, help, info, is_empty, jr, log, rpr, test_continuity_1, urge, warn, whisper;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS';

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
  PS = require('../..');

  ({$, $async} = PS.export());

  //...........................................................................................................
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  every = function(dts, f) {
    return setInterval(f, dts * 1000);
  };

  defer = setImmediate;

  ({jr, is_empty} = CND);

  //-----------------------------------------------------------------------------------------------------------
  test_continuity_1 = async function() {
    var $end_as_symbol, $keep_open_with_timer, $terminate_on_end_symbol, P, demo, map, new_pushable, pull_through;
    P = require('pull-stream');
    pull_through = require('pull-through');
    new_pushable = require('pull-pushable');
    map = require('../_map_errors');
    //.........................................................................................................
    $keep_open_with_timer = function() {
      var timer;
      timer = every(1, function() {
        return process.stdout.write('*');
      });
      process.on('unhandledRejection', function(reason, promise) {
        clearInterval(timer);
        throw reason;
      });
      return map(function(d) {
        debug('20922', d);
        // debug '20922', send
        if (d === PS.symbols.end) {
          clearInterval(timer);
        }
        return d;
      });
    };
    //.........................................................................................................
    $terminate_on_end_symbol = function() {
      return P.asyncMap(function(d, handler) {
        if (d === PS.symbols.end) {
          return handler(true);
        } else {
          return handler(null, d);
        }
      });
    };
    //.........................................................................................................
    $end_as_symbol = function() {
      var count, on_data, on_end;
      count = 0;
      on_data = function(d) {
        return this.queue(d);
      };
      on_end = function() {
        count += +1;
        if (count > 1) {
          throw new Error("µ30903 on_end called more than once");
        }
        help('on_end');
        this.queue('yo');
        return this.queue(PS.symbols.end);
      };
      return pull_through(on_data, on_end);
    };
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var new_PS_pushable, pipeline, source;
        new_PS_pushable = PS.new_push_source;
        source = new_PS_pushable();
        pipeline = [];
        pipeline.push(source);
        pipeline.push($end_as_symbol());
        pipeline.push($keep_open_with_timer());
        pipeline.push(map(function(d) {
          whisper(d);
          return d;
        }));
        pipeline.push(P.asyncMap(function(d, handler) {
          return after(0.1, function() {
            return handler(null, d);
          });
        }));
        /* Convert end symbol to actual end action */
        pipeline.push($terminate_on_end_symbol());
        pipeline.push(P.onEnd(function() {
          help('ok');
          return resolve();
        }));
        //.......................................................................................................
        P.pull(...pipeline);
        source.send(42);
        after(0.5, function() {
          return source.send(null);
        });
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_x = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var P, bysource, i, merge, n, new_pushable, pipeline, pull_through, source;
        P = require('pull-stream');
        pull_through = require('pull-through');
        new_pushable = require('pull-pushable');
        merge = require('pull-merge');
        source = PS.new_push_source();
        bysource = PS.new_push_source();
        pipeline = [];
        for (n = i = 1; i <= 5; n = ++i) {
          // pipeline.push P.values [ 1 .. 3 ]
          bysource.send(n);
        }
        pipeline.push(source);
        pipeline.push((function() {
          var next_value, othersource, subline, x;
          othersource = PS.new_push_source();
          subline = [];
          // subline.push merge bysource, othersource, ( -> -1 )
          next_value = null;
          x = +1;
          subline.push(merge(bysource, othersource, function(a, b) {
            return x = -x;
          }));
          subline.push(PS.$show({
            title: 'subline'
          }));
          subline.push(PS.$drain(function() {
            return "subline terminated";
          }));
          PS.pull(...subline);
          othersource.send('a');
          othersource.send('b');
          othersource.send('c');
          after(5, function() {});
          // othersource.end()
          return $({
            last: null
          }, function(d, send) {
            if (d != null) {
              return send(d);
            } else {
              return info('ok');
            }
          });
        })());
        // pipeline.push P.asyncMap ( d, handler ) ->
        //   after 0.1, -> handler null, d
        // pipeline.push PS.$show title: '-->'
        // pipeline.push P.onEnd -> help 'ok'; resolve()
        // # pipeline.push P.drain -> help 'ok'; resolve()
        // P.pull pipeline...
        // source.send 108
        // # source.end()
        // after 0.5, -> source.send null
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    (async function() {
      // await test_continuity_1()
      return (await demo_x());
    })();
  }

}).call(this);
