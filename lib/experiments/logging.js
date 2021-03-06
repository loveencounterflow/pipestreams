(function() {
  'use strict';
  var $, $async, CND, PS, after, alert, assign, badge, debug, defer, echo, every, help, info, inspect, is_empty, jr, log, rpr, test, urge, warn, whisper, xrpr,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/EXPERIMENTS/PULL-STREAM-EXAMPLES-PULL';

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
  PS = require('../..');

  ({$, $async} = PS.export());

  test = require('guy-test');

  assign = Object.assign;

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["demo through with null"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    // [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    probes_and_matchers = [[[1, 2, 3, null, 4, 5], [2, 6, 4, 6, null, null, 12, 8, 10], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var byline, bylog, bystream, collector, is_odd, mainline, mainlog, source;
          is_odd = function(d) {
            return (modulo(d, 2)) !== 0;
          };
          bylog = PS.get_logger('b', 'red');
          mainlog = PS.get_logger('m', 'gold');
          //.....................................................................................................
          // source    = PS.new_value_source probe
          source = PS.new_random_async_value_source(probe);
          collector = [];
          byline = [];
          byline.push(bylog(PS.$pass()));
          byline.push(PS.$filter(function(d) {
            return modulo(d, 2) === 0;
          }));
          byline.push($(function(d, send) {
            return send(d != null ? d * 3 : d);
          }));
          // byline.push PS.$watch ( d ) -> info xrpr d
          byline.push(bylog(PS.$pass()));
          byline.push(PS.$collect({collector}));
          byline.push(bylog(PS.$pass()));
          byline.push(PS.$drain());
          bystream = PS.pull(...byline);
          mainline = [];
          mainline.push(source);
          // mainline.push log PS.$watch ( d ) -> info '--->', d
          mainline.push(mainlog(PS.$tee(bystream)));
          mainline.push(mainlog(PS.$defer()));
          mainline.push(mainlog($(function(d, send) {
            return send(d != null ? d * 2 : d);
          })));
          // mainline.push mainlog PS.$tee is_odd, PS.pull byline...
          mainline.push(mainlog(PS.$collect({collector})));
          mainline.push(mainlog(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          })));
          return PS.pull(...mainline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["circular pipeline 1"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    // [[ 5, 15, 20, undefined, 25, 30, ], [ 10, 30, 40, undefined, 50, 60 ]]
    // [[1,2,3,4,5],[2,6,4,6,null,null,12,8,10],null]
    probes_and_matchers = [[[3, 4], [3, 4, 10, 2, 5, 1, 16, 8, 4, 2, 1], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var buffer, bylog, collector, mainline, mainlog, mainsource, use_defer;
          //-----------------------------------------------------------------------------------------------------
          bylog = PS.get_logger('b', 'red');
          mainlog = PS.get_logger('m', 'gold');
          //.....................................................................................................
          use_defer = true;
          buffer = [...probe];
          mainsource = PS.new_refillable_source(buffer, {
            repeat: 1
          });
          collector = [];
          mainline = [];
          mainline.push(mainsource);
          if (use_defer) {
            mainline.push(mainlog(PS.$defer()));
          }
          mainline.push(mainlog($(function(d, send) {
            if (d > 1) {
              if (modulo(d, 2) === 0) {
                buffer.push(d / 2);
              } else {
                buffer.push(d * 3 + 1);
              }
            }
            return send(d);
          })));
          // send PS.symbols.end if d is 1
          mainline.push(mainlog(PS.$collect({collector})));
          mainline.push(mainlog(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          })));
          return PS.pull(...mainline);
        });
      });
    }
    // mainsource.send 3
    // mainsource.end()
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["circular pipeline 2"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [[[true, 3, 4], [30, 32, 34, 10, 12, 14, 20, 22, 24, 94, 100, 34, 40, 64, 70], null], [[false, 3, 4], [10, 30, 12, 32, 14, 34, 20, 22, 24, 34, 94, 40, 100, 64, 70], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var collector, lowerline, lowerlog, refillable, source_1, source_2, source_3, upperline, upperlog, upperstream, use_defer, values;
          upperlog = PS.get_logger('U', 'gold');
          lowerlog = PS.get_logger('L', 'red');
          //.....................................................................................................
          [use_defer, ...values] = probe;
          collector = [];
          upperline = [];
          lowerline = [];
          refillable = [20, 21, 22, 23, 24];
          //.....................................................................................................
          source_1 = PS.new_value_source([10, 11, 12, 13, 14]);
          source_2 = PS.new_refillable_source(refillable, {
            repeat: 1,
            show: true
          });
          source_3 = PS.new_value_source([30, 31, 32, 33, 34]);
          //.....................................................................................................
          upperline.push(PS.new_merged_source(source_1, source_2));
          if (use_defer) {
            upperline.push(upperlog(PS.$defer()));
          }
          upperline.push(PS.$watch(function(d) {
            return echo('U', xrpr(d));
          }));
          upperstream = PS.pull(...upperline);
          //.....................................................................................................
          lowerline.push(PS.new_merged_source(upperstream, source_3));
          lowerline.push(PS.$watch(function(d) {
            return echo('L', xrpr(d));
          }));
          lowerline.push(lowerlog($(function(d, send) {
            if (modulo(d, 2) === 0) {
              return send(d);
            } else {
              return refillable.push(d * 3 + 1);
            }
          })));
          lowerline.push(PS.$collect({collector}));
          lowerline.push(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          }));
          return PS.pull(...lowerline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["duplex"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [[[1, 2, 3, 4, 5], [11, 12, 13, 14, 15], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var bylog, collector, mainline, mainlog, mainsource, stream_a, stream_b, stream_c;
          bylog = PS.get_logger('b', 'red');
          mainlog = PS.get_logger('m', 'gold');
          mainsource = PS.new_value_source(probe);
          collector = [];
          mainline = [];
          // duplexsource = PS.new_push_source()
          stream_a = PS.pull(bylog($(function(d, send) {
            return send(d * 3);
          })));
          stream_b = PS.pull(bylog($(function(d, send) {
            return send(d * 2);
          })));
          stream_c = {
            source: stream_a,
            sink: stream_b
          };
          //.....................................................................................................
          mainline.push(mainsource);
          mainline.push(mainlog(stream_c));
          // mainline.push mainlog stream_c
          // # mainline.push mainlog PS.$defer()
          // mainline.push mainlog PS.$pass()
          // mainline.push mainlog $ ( d, send ) -> send d + 10
          // # mainline.push mainlog $async ( d, send, done ) -> send d + 10; done()
          mainline.push(mainlog(PS.$watch(function(d) {
            return collector.push(d);
          })));
          mainline.push(mainlog(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          })));
          return PS.pull(...mainline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    null;
    // test @
    // test @[ "circular pipeline 1" ], { timeout: 5000, }
    test(this["circular pipeline 2"], {
      timeout: 5000
    });
  }

  // test @[ "duplex" ]
// @[ "_duplex 1" ]()
// @[ "_duplex 2" ]()

}).call(this);
