(function() {
  'use strict';
  var $, $async, CND, PS, alert, badge, debug, echo, help, info, log, praise, rpr, test, urge, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr.bind(CND);

  badge = 'PIPESTREAMS/TESTS/WINDOW';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  praise = CND.get_logger('praise', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  PS = require('../..');

  ({$, $async} = PS.export());

  //-----------------------------------------------------------------------------------------------------------
  this["$window"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    //.........................................................................................................
    probes_and_matchers = [[[[1, 2, 3, 4], 1, null], [[1], [2], [3], [4]], null], [[[1, 2, 3, 4], 2, null], [[null, 1], [1, 2], [2, 3], [3, 4], [4, null]], null], [[[1, 2, 3, 4], 3, null], [[null, null, 1], [null, 1, 2], [1, 2, 3], [2, 3, 4], [3, 4, null], [4, null, null]], null], [[[1, 2, 3, 4], 4, null], [[null, null, null, 1], [null, null, 1, 2], [null, 1, 2, 3], [1, 2, 3, 4], [2, 3, 4, null], [3, 4, null, null], [4, null, null, null]], null], [[[1, 2, 3, 4], 5, null], [[null, null, null, null, 1], [null, null, null, 1, 2], [null, null, 1, 2, 3], [null, 1, 2, 3, 4], [1, 2, 3, 4, null], [2, 3, 4, null, null], [3, 4, null, null, null], [4, null, null, null, null]], null], [[[1], 1, null], [[1]], null], [[[1], 2, null], [[null, 1], [1, null]], null], [[[1], 3, null], [[null, null, 1], [null, 1, null], [1, null, null]], null], [[[1], 4, null], [[null, null, null, 1], [null, null, 1, null], [null, 1, null, null], [1, null, null, null]], null], [[[], 1, null], [], null], [[[], 2, null], [], null], [[[], 3, null], [], null], [[[], 4, null], [], null], [[[1, 2, 3], 0, null], [], 'not a valid pipestreams_\\$window_settings'], [[[1], 2, 'novalue'], [['novalue', 1], [1, 'novalue']], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, fallback, pipeline, source, values, width;
          [values, width, fallback] = probe;
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PS.$window({width, fallback}));
          pipeline.push(PS.$show());
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
            return resolve(collector);
          }));
          PS.pull(...pipeline);
          return null;
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["window with leapfrogging"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    //.........................................................................................................
    probes_and_matchers = [[[[1, 2, 3, 4], 1, null], [1, [2], 3, [4]], null], [[[1, 2, 3, 4], 2, null], [1, [null, 2], 3, [2, 4], [4, null]], null], [[[1, 2, 3, 4], 3, null], [1, [null, null, 2], 3, [null, 2, 4], [2, 4, null], [4, null, null]], null], [[[1, 2, 3, 4], 4, null], [1, [null, null, null, 2], 3, [null, null, 2, 4], [null, 2, 4, null], [2, 4, null, null], [4, null, null, null]], null], [[[1, 2, 3, 4], 5, null], [1, [null, null, null, null, 2], 3, [null, null, null, 2, 4], [null, null, 2, 4, null], [null, 2, 4, null, null], [2, 4, null, null, null], [4, null, null, null, null]], null], [[[1], 1, null], [1], null], [[[1], 2, null], [1], null], [[[1], 3, null], [1], null], [[[1], 4, null], [1], null], [[[], 1, null], [], null], [[[], 2, null], [], null], [[[], 3, null], [], null], [[[], 4, null], [], null], [[[1, 2, 3], 0, null], null, "not a valid pipestreams_\\$window_settings"], [[[1], 2, "novalue"], [1], null], [[[2], 2, "novalue"], [["novalue", 2], [2, "novalue"]], null], [[[1, 2], 2, "novalue"], [1, ["novalue", 2], [2, "novalue"]], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, fallback, jumper, pipeline, source, values, width;
          [values, width, fallback] = probe;
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          jumper = function(d) {
            return modulo(d, 2) === 1;
          };
          pipeline.push(source);
          pipeline.push(PS.window({
            width,
            fallback,
            leapfrog: jumper
          }, $(function(dx, send) {
            debug('µ44772', dx);
            return send(dx);
          })));
          pipeline.push(PS.$show());
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
            return resolve(collector);
          }));
          PS.pull(...pipeline);
          return null;
        });
      });
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$lookaround"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    //.........................................................................................................
    probes_and_matchers = [[[[1, 2, 3, 4], 0, null], [[1], [2], [3], [4]], null], [[[1, 2, 3, 4], 1, null], [[null, 1, 2], [1, 2, 3], [2, 3, 4], [3, 4, null]], null], [[[1, 2, 3, 4], 2, null], [[null, null, 1, 2, 3], [null, 1, 2, 3, 4], [1, 2, 3, 4, null], [2, 3, 4, null, null]], null], [[[1], 1, null], [[null, 1, null]], null], [[[], 1, null], [], null], [[[], 2, null], [], null], [[[], 3, null], [], null], [[[], 4, null], [], null], [[[1, 2, 3], -1], [], 'not a valid pipestreams_\\$lookaround_settings'], [[[1], 1, 42], [[42, 1, 42]], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, delta, fallback, pipeline, source, values;
          [values, delta, fallback] = probe;
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PS.$lookaround({delta, fallback}));
          pipeline.push(PS.$show());
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
            return resolve(collector);
          }));
          PS.pull(...pipeline);
          return null;
        });
      });
    }
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

  // test @[ "$window" ]
// test @[ "$lookaround" ]
// test @[ "window with leapfrogging" ]
// test @[ "cast" ]
// test @[ "isa.list_of A" ]
// test @[ "isa.list_of B" ]
// test @[ "validate.list_of A" ]
// test @[ "validate.list_of B" ]

}).call(this);
