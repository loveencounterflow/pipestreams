(function() {
  'use strict';
  var $, $async, CND, FS, OS, PATH, PS, alert, badge, debug, defer, echo, help, info, inspect, is_empty, jr, log, rpr, test, urge, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/TESTS/WYE';

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

  ({$, $async} = PS.export());

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

  //-----------------------------------------------------------------------------------------------------------
  this["1 leapfrog lookaround with groups"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1,
        2,
        4,
        5,
        [null,
        3,
        6],
        7,
        8,
        [3,
        6,
        9],
        10,
        11,
        [6,
        9,
        12],
        [9,
        12,
        null]],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [[null,
        1,
        2],
        3,
        [1,
        2,
        4],
        [2,
        4,
        5],
        6,
        [4,
        5,
        7],
        [5,
        7,
        8],
        9,
        [7,
        8,
        10],
        [8,
        10,
        11],
        12,
        [10,
        11,
        null]],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.leapfrog(tester, PS.lookaround($(function(d3, send) {
            var d, nxt, prv;
            [prv, d, nxt] = d3;
            return send(d3);
          }))));
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

  //-----------------------------------------------------------------------------------------------------------
  this["1 leapfrog lookaround with groups 2"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1,
        2,
        4,
        5,
        [null,
        3,
        6],
        7,
        8,
        [3,
        6,
        9],
        10,
        11,
        [6,
        9,
        12],
        [9,
        12,
        null]],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [[null,
        1,
        2],
        3,
        [1,
        2,
        4],
        [2,
        4,
        5],
        6,
        [4,
        5,
        7],
        [5,
        7,
        8],
        9,
        [7,
        8,
        10],
        [8,
        10,
        11],
        12,
        [10,
        11,
        null]],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          // pipeline.push PS.$show { title: 'µ33421-1', }
          // pipeline.push PS.leapfrog tester, PS.lookaround $ ( d3, send ) ->
          pipeline.push(PS.lookaround({
            leapfrog: tester
          }, $(function(d3, send) {
            var d, nxt, prv;
            // debug 'µ43443', jr d3
            [prv, d, nxt] = d3;
            return send(d3);
          })));
          // pipeline.push PS.$show { title: 'µ33421-2', }
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

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT ordering not preserved */
  this["_____________ 2 leapfrog lookaround ungrouped"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.leapfrog(tester, PS.lookaround($(function(d3, send) {
            var d, nxt, prv;
            help('µ44333', jr(d3));
            [prv, d, nxt] = d3;
            return send(d);
          }))));
          pipeline.push(PS.$show());
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

  //-----------------------------------------------------------------------------------------------------------
  this["3 lookaround"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.lookaround($(function(d3, send) {
            var d, nxt, prv;
            [prv, d, nxt] = d3;
            return send(d);
          })));
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

  //-----------------------------------------------------------------------------------------------------------
  this["4 leapfrog"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1,
        2,
        300,
        4,
        5,
        600,
        7,
        8,
        900,
        10,
        11,
        1200],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [100,
        200,
        3,
        400,
        500,
        6,
        700,
        800,
        9,
        1000,
        1100,
        12],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.leapfrog(tester, $(function(d, send) {
            return send(d * 100);
          })));
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

  //-----------------------------------------------------------------------------------------------------------
  /* TAINT ordering not preserved */
  this["_____________ 5 leapfrog window ungrouped"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) !== 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ],
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
          (function(d) {
            return (d % 3) === 0;
          })
        ],
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
        null
      ]
    ];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var collector, pipeline, tester, values;
          [values, tester] = probe;
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.leapfrog(tester, PS.window($(function(d3, send) {
            var d, nxt, prv;
            help('µ44333', jr(d3));
            [prv, d, nxt] = d3;
            return send(d);
          }))));
          pipeline.push(PS.$show());
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
    test(this["1 leapfrog lookaround with groups 2"]);
  }

  // test @[ "2 leapfrog lookaround ungrouped" ]
// test @[ "3 lookaround" ]
// test @[ "4 leapfrog" ]
// test @[ "5 leapfrog window ungrouped" ]

}).call(this);
