(function() {
  'use strict';
  var CND, PS_ORIGINAL, alert, assign, badge, copy, create, debug, defer, echo, eq, help, info, inspect, is_empty, jr, log, new_pipestreams_library, rpr, test, urge, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/DERIVATIVE';

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
  test = require('guy-test');

  eq = CND.equals;

  jr = JSON.stringify;

  //...........................................................................................................
  PS_ORIGINAL = require('../..');

  //...........................................................................................................
  ({jr, copy, is_empty, assign} = CND);

  create = Object.create;

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  defer = setImmediate;

  //-----------------------------------------------------------------------------------------------------------
  new_pipestreams_library = function(end_symbol = null) {
    var R;
    R = PS_ORIGINAL._copy_library();
    if (end_symbol !== null) {
      R.symbols.end = end_symbol;
    }
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["pipeline using altered configuration"] = async function(T, done) {
    var $, $async, PS, aborting_map, error, i, len, matcher, my_end_sym, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [[[false, [1, 2, 3, null, 5]], [1, 1, 1, 2, 2, 2, 3, 3, 3, null, null, null, 5, 5, 5], null], [[false, [1, 2, 3, 42, 5]], [1, 1, 1, 2, 2, 2, 3, 3, 3], null]];
    //.........................................................................................................
    // [[true,[1,2,3,null,5]],[1,1,1,2,2,2,3,3,3,null,null,null,5,5,5],null]
    // [[false,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    // [[true,[1,2,3,null,"stop",25,30]],[1,1,1,2,2,2,3,3,3,null,null,null],null]
    // [[false,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    // [[true,[1,2,3,undefined,"stop",25,30]],[1,1,1,2,2,2,3,3,3,undefined,undefined,undefined,],null]
    // [[false,["stop",25,30]],[],null]
    // [[true,["stop",25,30]],[],null]
    my_end_sym = 42;
    PS = new_pipestreams_library(my_end_sym);
    debug(PS.symbols);
    ({$, $async} = PS.export());
    //.........................................................................................................
    aborting_map = function(use_defer, mapper) {
      var react;
      react = function(handler, data) {
        if (data === 'stop') {
          return handler(true);
        } else {
          return handler(null, mapper(data));
        }
      };
      // a sink function: accept a source...
      return function(read) {
        // ...but return another source!
        return function(abort, handler) {
          read(abort, function(error, data) {
            if (error) {
              // if the stream has ended, pass that on.
              return handler(error);
            }
            if (use_defer) {
              defer(function() {
                return react(handler, data);
              });
            } else {
              react(handler, data);
            }
            return null;
          });
          return null;
        };
        return null;
      };
    };
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var collector, pipeline, source, use_defer, values;
          //.....................................................................................................
          [use_defer, values] = probe;
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(aborting_map(use_defer, function(d) {
            info('22398-1', xrpr(d));
            return d;
          }));
          pipeline.push(PS.$map(function(d) {
            info('22398-2', xrpr(d));
            collector.push(d);
            return d;
          }));
          pipeline.push(PS.$map(function(d) {
            info('22398-3', xrpr(d));
            collector.push(d);
            return d;
          }));
          pipeline.push(PS.$map(function(d) {
            info('22398-4', xrpr(d));
            collector.push(d);
            return d;
          }));
          pipeline.push(PS.$drain(function() {
            help('44998', xrpr(collector));
            return resolve(collector);
          }));
          return PS.pull(...pipeline);
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

  // test @[ "demo through with null" ]
// test @[ "demo watch pipeline on abort 1" ]
// test @[ "demo watch pipeline on abort 2" ]

}).call(this);
