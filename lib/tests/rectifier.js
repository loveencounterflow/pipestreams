(function() {
  'use strict';
  var $, $async, CND, FS, OS, PATH, PS, alert, badge, debug, declare, defer, echo, help, info, inspect, is_empty, isa, jr, log, provide_rectify, rpr, size_of, test, type_of, types, urge, validate, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/TESTS/RECTIFIER';

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
  PATH = require('path');

  FS = require('fs');

  OS = require('os');

  test = require('guy-test');

  //...........................................................................................................
  PS = require('../..');

  ({$, $async} = PS);

  //...........................................................................................................
  ({jr, is_empty} = CND);

  defer = setImmediate;

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
  types = require('../_types');

  ({isa, validate, declare, size_of, type_of} = types);

  provide_rectify = function() {
    //-----------------------------------------------------------------------------------------------------------
    this.$rectify_prepare = function(cache) {
      validate.object(cache);
      return this.$(function(d, send) {
        validate.pipestreams_number_or_text(d);
        cache[d] = true;
        return send(d);
      });
    };
    //-----------------------------------------------------------------------------------------------------------
    return this.$rectify = function(cache) {
      validate.object(cache);
      return this.$(function(d, send) {
        return send(d);
      });
    };
  };

  provide_rectify.apply(PS);

  //-----------------------------------------------------------------------------------------------------------
  this["rectify"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]];
//.........................................................................................................
// [ [ 1 .. 12 ], ]
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var cache, collector, pipeline;
          cache = {};
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(probe));
          pipeline.push(PS.$rectify_prepare(cache));
          pipeline.push(PS.$scramble(0.5, {
            seed: 45
          }));
          // pipeline.push PS.$scramble()
          pipeline.push(PS.$show({
            title: 'µ49890-1'
          }));
          pipeline.push(PS.$rectify(cache));
          pipeline.push(PS.$show({
            title: 'µ49890-2'
          }));
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
            return resolve(collector);
          }));
          PS.pull(...pipeline);
          //.....................................................................................................
          return null;
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    // test @
    // test @[ "1 leapfrog lookaround with groups" ]
    test(this["rectify"]);
  }

  // test @[ "2 leapfrog lookaround ungrouped" ]
// test @[ "3 lookaround" ]
// test @[ "4 leapfrog" ]
// test @[ "5 leapfrog window ungrouped" ]

}).call(this);
