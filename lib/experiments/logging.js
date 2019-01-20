// Generated by CoffeeScript 2.3.1
(function() {
  'use strict';
  var CND, PS, after, alert, badge, debug, defer, echo, every, help, info, is_empty, jr, log, rpr, test, urge, warn, whisper;

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

  test = require('guy-test');

  //-----------------------------------------------------------------------------------------------------------
  this["demo through with null"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [[[5, 15, 20, void 0, 25, 30], [10, 30, 40, void 0, 50, 60]], [[5, 15, 20, null, 25, 30], [10, 30, 40, null, 50, 60]]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var collector, pipeline, source;
          //.....................................................................................................
          source = source_from_values(probe);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(map(function(d) {
            info('--->', d);
            return d;
          }));
          pipeline.push(PS.$(function(d, send) {
            return send(d != null ? d * 2 : d);
          }));
          // pipeline.push map ( d ) -> collector.push d; return d
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          }));
          return pull(...pipeline);
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
    test(this);
  }

  /*
That covers 3 types of pull streams. Source, Transform, & Sink.
There is one more important type, although it's not used as much.

Duplex streams

(see duplex.js!)
*/

}).call(this);

//# sourceMappingURL=logging.js.map