(function() {
  'use strict';
  var $, $async, CND, PS, badge, debug, echo, help, info, rpr, test, urge, warn, whisper,
    splice = [].splice;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'GLIDING-WINDOW';

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
  this["gliding window: basic functionality"] = function(T, done) {
    var expect_count, i, pipeline, probes, section_count, width, Ø;
    //.........................................................................................................
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    section_count = 0;
    probes = (function() {
      var j, results;
      results = [];
      for (i = j = 0; j <= 9; i = ++j) {
        results.push(i);
      }
      return results;
    })();
    width = 3;
    expect_count = Math.max(0, probes.length - width + 1);
    //.........................................................................................................
    Ø((require('pull-stream/sources/values'))(probes));
    Ø(PS.$gliding_window(width, function(section) {
      section_count += +1;
      return urge(section);
    }));
    Ø(PS.$collect());
    // Ø PS.$show()
    Ø($('null', function(data, send) {
      if (data != null) {
        T.ok(section_count === expect_count);
        return send(data);
      } else {
        return done();
      }
    }));
    // send null
    Ø(PS.$drain());
    //.........................................................................................................
    return PS.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["gliding window: drop values"] = function(T, done) {
    var i, pipeline, probes, width, Ø;
    //.........................................................................................................
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    probes = (function() {
      var j, results;
      results = [];
      for (i = j = 0; j <= 9; i = ++j) {
        results.push(i);
      }
      return results;
    })();
    width = 3;
    //.........................................................................................................
    Ø((require('pull-stream/sources/values'))(probes));
    Ø(PS.$gliding_window(width, function(section) {
      var d0, d1, d2;
      [d0, d1, d2] = section;
      if (d1 % 2 === 0) {
        return (splice.apply(section, [0, 3].concat([d0, d2])), [d0, d2]);
      }
    }));
    Ø(PS.$collect());
    // Ø PS.$show()
    Ø($('null', function(data, send) {
      if (data != null) {
        urge(data);
        T.ok(CND.equals(data, [0, 1, 3, 5, 7, 9]));
        return send(data);
      } else {
        return done();
      }
    }));
    // send null
    Ø(PS.$drain());
    //.........................................................................................................
    return PS.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["gliding window: insert values"] = function(T, done) {
    var i, pipeline, probes, Ø;
    //.........................................................................................................
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    probes = (function() {
      var j, results;
      results = [];
      for (i = j = 0; j <= 9; i = ++j) {
        results.push(i);
      }
      return results;
    })();
    //.........................................................................................................
    Ø((require('pull-stream/sources/values'))(probes));
    Ø(PS.$gliding_window(1, function(section) {
      var d0;
      [d0] = section;
      if (d0 % 2 === 1) {
        return section.push(d0 * 2);
      }
    }));
    Ø(PS.$collect());
    // Ø PS.$show()
    Ø($('null', function(data, send) {
      if (data != null) {
        urge(data);
        T.ok(CND.equals(data, [0, 1, 2, 2, 3, 6, 4, 5, 10, 6, 7, 14, 8, 9, 18]));
        return send(data);
      } else {
        return done();
      }
    }));
    // send null
    Ø(PS.$drain());
    //.........................................................................................................
    return PS.pull(...pipeline);
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

}).call(this);
