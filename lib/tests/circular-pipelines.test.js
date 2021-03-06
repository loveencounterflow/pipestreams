(function() {
  'use strict';
  var $, $async, CND, PS, badge, debug, echo, help, info, rpr, test, urge, warn, whisper,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'GENERATOR-AS-SOURCE';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  //...........................................................................................................
  PS = require('../..');

  ({$, $async} = PS.export());

  //-----------------------------------------------------------------------------------------------------------
  this["circular pipeline 1"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[true, 3, 4], [3, 4, 10, 2, 5, 1, 16, 8, 4, 2, 1], null], [[false, 3, 4], [3, 4, 10, 2, 5, 1, 16, 8, 4, 2, 1], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var collector, mainline, mainsource, refillable, use_defer, values;
          //.....................................................................................................
          [use_defer, ...values] = probe;
          refillable = [...values];
          mainsource = PS.new_refillable_source(refillable, {
            repeat: 2,
            show: true
          });
          collector = [];
          mainline = [];
          mainline.push(mainsource);
          if (use_defer) {
            mainline.push(PS.$defer());
          }
          mainline.push($(function(d, send) {
            if (d > 1) {
              if (modulo(d, 2) === 0) {
                refillable.push(d / 2);
              } else {
                refillable.push(d * 3 + 1);
              }
            }
            return send(d);
          }));
          mainline.push(PS.$collect({collector}));
          mainline.push(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          }));
          return PS.pull(...mainline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["circular pipeline 2"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[true, 3, 4], [3, 4, 10, 2, 5, 1], null], [[false, 3, 4], [3, 4, 10, 2, 5, 1], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var buffer, collector, mainline, mainsource, use_defer, values;
          //.....................................................................................................
          [use_defer, ...values] = probe;
          buffer = [...values];
          mainsource = PS.new_refillable_source(buffer, {
            repeat: 1
          });
          collector = [];
          mainline = [];
          mainline.push(mainsource);
          if (use_defer) {
            mainline.push(PS.$defer());
          }
          mainline.push($(function(d, send) {
            if (d === 16) {
              return send.end();
            }
            if (d > 1) {
              if (modulo(d, 2) === 0) {
                buffer.push(d / 2);
              } else {
                buffer.push(d * 3 + 1);
              }
            }
            return send(d);
          }));
          mainline.push(PS.$collect({collector}));
          mainline.push(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          }));
          return PS.pull(...mainline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["circular pipeline 3"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[true, 3, 4], [3, 4, 10, 2, 5, 1], null], [[false, 3, 4], [3, 4, 10, 2, 5, 1], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var buffer, collector, mainline, mainsource, use_defer, values;
          //.....................................................................................................
          [use_defer, ...values] = probe;
          buffer = [...values];
          mainsource = PS.new_refillable_source(buffer, {
            repeat: 1
          });
          collector = [];
          mainline = [];
          mainline.push(mainsource);
          if (use_defer) {
            mainline.push(PS.$defer());
          }
          mainline.push(PS.$continue_if(function(d) {
            return d !== 16;
          }));
          mainline.push($(function(d, send) {
            if (d > 1) {
              if (modulo(d, 2) === 0) {
                buffer.push(d / 2);
              } else {
                buffer.push(d * 3 + 1);
              }
            }
            return send(d);
          }));
          mainline.push(PS.$collect({collector}));
          mainline.push(PS.$drain(function() {
            help(collector);
            return resolve(collector);
          }));
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
    test(this);
  }

  // test @[ "circular pipeline 1" ]
// test @[ "circular pipeline 2" ]
// test @[ "generator as source 2" ]

}).call(this);
