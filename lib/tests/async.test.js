(function() {
  'use strict';
  var $, $async, $send_three, CND, PS, after, badge, debug, echo, help, info, jr, rpr, test, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/TESTS/ASYNC-MAP';

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  info = CND.get_logger('info', badge);

  urge = CND.get_logger('urge', badge);

  help = CND.get_logger('help', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  test = require('guy-test');

  jr = JSON.stringify;

  //...........................................................................................................
  PS = require('../..');

  ({$, $async} = PS.export());

  //-----------------------------------------------------------------------------------------------------------
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["async 1"] = function(T, done) {
    var matcher, ok, pipeline, probe;
    ok = false;
    [probe, matcher] = ["abcdef", "1a-2a-1b-2b-1c-2c-1d-2d-1e-2e-1f-2f"];
    pipeline = [];
    pipeline.push(PS.new_value_source(Array.from(probe)));
    pipeline.push($async(function(d, send, done) {
      send(`1${d}`);
      send(`2${d}`);
      return done();
    }));
    pipeline.push(PS.$surround({
      between: '-'
    }));
    pipeline.push(PS.$join());
    //.........................................................................................................
    pipeline.push(PS.$watch(function(result) {
      echo(CND.gold(jr([probe, result])));
      T.eq(result, matcher);
      return ok = true;
    }));
    //.........................................................................................................
    pipeline.push(PS.$drain(function() {
      if (!ok) {
        T.fail("failed to pass test");
      }
      return done();
    }));
    //.........................................................................................................
    PS.pull(...pipeline);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  $send_three = function() {
    return PS.$async(function(d, send, done) {
      var count, i, nr;
      count = 0;
      for (nr = i = 1; i <= 3; nr = ++i) {
        (function(d, nr) {
          return after(Math.random() / 5, function() {
            count += 1;
            send(`(${d}:${nr})`);
            if (count === 3) {
              return done();
            }
          });
        })(d, nr);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["async 2"] = function(T, done) {
    var matcher, ok, pipeline, probe;
    ok = false;
    probe = "abcdef";
    matcher = "(a:1)(a:2)(a:3)(b:1)(b:2)(b:3)(c:1)(c:2)(c:3)(d:1)(d:2)(d:3)(e:1)(e:2)(e:3)(f:1)(f:2)(f:3)";
    pipeline = [];
    pipeline.push(PS.new_value_source(Array.from(probe)));
    pipeline.push($send_three());
    pipeline.push(PS.$sort());
    pipeline.push(PS.$join());
    //.........................................................................................................
    pipeline.push(PS.$watch(function(result) {
      T.eq(result, matcher);
      return ok = true;
    }));
    //.........................................................................................................
    pipeline.push(PS.$watch(function(d) {
      return urge(d);
    }));
    pipeline.push(PS.$drain(function() {
      if (!ok) {
        T.fail("failed to pass test");
      }
      return done();
    }));
    //.........................................................................................................
    PS.pull(...pipeline);
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    test(this);
  }

  // test @[ "async 1" ]
// test @[ "async 2" ]

}).call(this);
