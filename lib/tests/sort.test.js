(function() {
  'use strict';
  var $, $async, CND, PS, alert, assign, badge, copy, debug, echo, help, info, is_empty, jr, log, rpr, sort, test, urge, warn, whisper,
    indexOf = [].indexOf;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/TESTS/SORT';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  ({is_empty, copy, assign, jr} = CND);

  //...........................................................................................................
  test = require('guy-test');

  //...........................................................................................................
  PS = require('../..');

  ({$, $async} = PS.export());

  //-----------------------------------------------------------------------------------------------------------
  this._prune = function() {
    var name, ref, value;
    ref = this;
    for (name in ref) {
      value = ref[name];
      if (name.startsWith('_')) {
        continue;
      }
      if (indexOf.call(include, name) < 0) {
        delete this[name];
      }
    }
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this._main = function() {
    return test(this, {
      'timeout': 30000
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  sort = function(values) {
    /* TAINT should handle errors (?) */
    return new Promise((resolve, reject) => {
      var pipeline;
      pipeline = [];
      pipeline.push(PS.new_value_source(values));
      pipeline.push(PS.$sort());
      // pipeline.push PS.$show()
      pipeline.push(PS.$collect());
      pipeline.push(PS.$watch(function(result) {
        return resolve(result);
      }));
      pipeline.push(PS.$drain());
      PS.pull(...pipeline);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["sort 1"] = async function(T, done) {
    var count, i, len, matcher, probe, probes_and_matchers, result, source;
    // debug jr ( key for key of PS ).sort(); xxx
    probes_and_matchers = [[[4, 9, 10, 3, 2], [2, 3, 4, 9, 10]], [['a', 'z', 'foo'], ['a', 'foo', 'z']]];
    count = probes_and_matchers.length;
    source = PS.new_push_source();
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher] = probes_and_matchers[i];
      result = (await sort(probe));
      echo(CND.gold(jr([probe, result])));
    }
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["sort 2"] = async function(T, done) {
    var count, error, i, len, matcher, pattern, probe, probes_and_matchers, regex, result, source;
    // debug jr ( key for key of PS ).sort(); xxx
    probes_and_matchers = [[[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, 3, 2, null], [2, 3, 4, 9, 10], null], [[4, 9, 10, "frob", 3, 2, null], null, "unable to compare a text to a number"], [["a", 1, "z", "foo"], null, "unable to compare a number to a text"]];
    count = probes_and_matchers.length;
    source = PS.new_push_source();
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, pattern] = probes_and_matchers[i];
      regex = pattern != null ? new RegExp(pattern) : null;
      try {
        result = (await sort(probe));
      } catch (error1) {
        error = error1;
        if ((regex != null) && (regex.test(error.message))) {
          echo(CND.green(jr([probe, null, pattern])));
          T.ok(true);
        } else {
          echo(CND.red(jr([probe, null, error.message])));
        }
        continue;
      }
      echo(CND.gold(jr([probe, result, null])));
    }
    done();
    return null;
  };

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "sort 2" ] = ( T, done ) ->
  //   # debug jr ( key for key of PS ).sort(); xxx
  //   probes_and_matchers = [
  //     [[4,9,10,3,2]]
  //     [['a', 'z', 'foo',]]
  //     [['a', 'z', 'foo',33],null]
  //     ]
  //   count = probes_and_matchers.length
  //   for [ probe, matcher, ] in probes_and_matchers
  //     do ( probe, matcher ) ->
  //       pipeline = []
  //       pipeline.push PS.new_value_source probe
  //       pipeline.push PS.$sort()
  //       pipeline.push PS.$collect()
  //       pipeline.push PS.$show()
  //       #.....................................................................................................
  //       pipeline.push $ { last: null, }, ( result, send ) ->
  //         if result?
  //           echo CND.gold jr [ probe, result, ]
  //           count += -1
  //         else
  //           if count != 0
  //             T.fail "expected count to be zero, is #{count}"
  //           done()
  //         send result
  //       #.....................................................................................................
  //       pipeline.push PS.$drain()
  //       #.....................................................................................................
  //       try
  //         PS.pull pipeline...
  //       catch error
  //         count += -1
  //         if matcher is null
  //           echo CND.green jr [ probe, null, ]
  //           T.succeed "error expected"
  //         else
  //           echo CND.red jr [ probe, null, ]
  //           T.fail error.message
  //         done() if count <= 0
  //   return null

  //###########################################################################################################
  if (module.parent == null) {
    // include = []
    // @_prune()
    this._main();
  }

}).call(this);
