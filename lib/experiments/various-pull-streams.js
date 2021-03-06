(function() {
  //###########################################################################################################
  var $, $async, CND, PS, after, alert, async_with_end_detection, async_with_end_detection_2, async_with_first_and_last, badge, debug, defer, demo_alternating_source, demo_merge_1, demo_merge_async_sources, demo_mux_async_sources_1, demo_mux_async_sources_2, demo_on_demand_source, demo_on_demand_transform, demo_through, echo, every, generator_source, help, info, is_empty, jr, log, new_async_source, rpr, sync_with_first_and_last, urge, warn, whisper, wye_3b, wye_4, wye_with_external_push_source, wye_with_internal_push_source, wye_with_random_value_source, wye_with_value_source;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/EXPERIMENTS/VARIOUS-PULL-STREAMS';

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
  PS = require('../..');

  ({$, $async} = PS.export());

  //...........................................................................................................
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  every = function(dts, f) {
    return setInterval(f, dts * 1000);
  };

  defer = setImmediate;

  ({jr, is_empty} = CND);

  // https://pull-stream.github.io/#pull-through
  // nope https://github.com/dominictarr/pull-flow (https://github.com/pull-stream/pull-stream/issues/4)

  // https://github.com/pull-stream/pull-cont
  // https://github.com/pull-stream/pull-defer
  // https://github.com/scrapjs/pull-imux

  //-----------------------------------------------------------------------------------------------------------
  demo_merge_1 = function() {
    /* https://github.com/pull-stream/pull-merge */
    var merge, pipeline, pull, x;
    pull = require('pull-stream');
    merge = require('pull-merge');
    pipeline = [];
    // pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, ] )
    // pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 2, 4, 7, 10, 11, 12, ] )
    // pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [] )
    // pipeline.push merge ( pull.values [ 1, 5, 6, ] ), ( pull.values [ 1, 5, 6, ] )
    // pipeline.push merge ( pull.values [ [1], [5], [6], ] ), ( pull.values [ [1], [5], [6], [7], ] )
    x = +1;
    pipeline.push(merge(pull.values([1, 5, 6]), pull.values([20, 19, 18, 17]), function(a, b) {
      return x = -x;
    }));
    pipeline.push(pull.collect(function(error, collector) {
      if (error != null) {
        throw error;
      }
      return help(collector);
    }));
    pull(...pipeline);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  new_async_source = function(name) {
    var R, pipeline, source;
    source = PS.new_push_source();
    pipeline = [];
    pipeline.push(source);
    pipeline.push(PS.$watch(function(d) {
      return urge(name, jr(d));
    }));
    R = PS.pull(...pipeline);
    R.push = function(x) {
      return source.push(x);
    };
    R.end = function() {
      return source.end();
    };
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_merge_async_sources = function() {
    /* won't take all inputs from both sources */
    var merge, source_1, source_2;
    merge = require('pull-merge');
    source_1 = new_async_source('s1');
    source_2 = new_async_source('s2');
    return new Promise(function(resolve) {
      var pipeline;
      pipeline = [];
      pipeline.push(merge(source_2, source_1, function(a, b) {
        return -1;
      }));
      pipeline.push(PS.$watch(function(d) {
        return help('-->', jr(d));
      }));
      pipeline.push(PS.$drain(function() {
        help('ok');
        return resolve(null);
      }));
      PS.pull(...pipeline);
      after(0.1, function() {
        return source_2.push(4);
      });
      after(0.2, function() {
        return source_2.push(5);
      });
      after(0.3, function() {
        return source_2.push(6);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.5, function() {
        return source_1.push(2);
      });
      after(0.6, function() {
        return source_1.push(3);
      });
      // after 1.0, -> source_1.push null
      // after 1.0, -> source_2.push null
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_mux_async_sources_1 = function() {
    var $_demux, $_mux, mux;
    mux = require('pull-mux');
    //.........................................................................................................
    /* https://github.com/nichoth/pull-mux */    $_mux = function(...sources) {
      var R, i, idx, len, source;
      R = {};
      for (idx = i = 0, len = sources.length; i < len; idx = ++i) {
        source = sources[idx];
        R[idx] = source;
      }
      return mux(R);
    };
    //.........................................................................................................
    $_demux = function() {
      return PS.$map(function([k, v]) {
        return v;
      });
    };
    //.........................................................................................................
    return new Promise(function(resolve) {
      var pipeline, source_1, source_2;
      pipeline = [];
      source_1 = new_async_source('s1');
      source_2 = new_async_source('s2');
      pipeline.push($_mux(source_1, source_2));
      pipeline.push($_demux());
      pipeline.push(PS.$collect());
      pipeline.push(PS.$watch(function(d) {
        return help('-->', jr(d));
      }));
      pipeline.push(PS.$drain(function() {
        help('ok');
        return resolve(null);
      }));
      PS.pull(...pipeline);
      after(0.1, function() {
        return source_2.push(4);
      });
      after(0.5, function() {
        return source_1.push(2);
      });
      after(0.6, function() {
        return source_1.push(3);
      });
      after(0.2, function() {
        return source_2.push(5);
      });
      after(0.3, function() {
        return source_2.push(6);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.05, function() {
        return source_2.push(42);
      });
      after(1.0, function() {
        return source_1.end();
      });
      after(1.0, function() {
        return source_2.end();
      });
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_mux_async_sources_2 = function() {
    var mux;
    mux = require('pull-mux');
    //-----------------------------------------------------------------------------------------------------------
    /* https://github.com/nichoth/pull-mux */    PS.$wye = function(...sources) {
      var $_demux, $_mux, pipeline;
      //.........................................................................................................
      $_mux = function(...sources) {
        var R, i, idx, len, source;
        R = {};
        for (idx = i = 0, len = sources.length; i < len; idx = ++i) {
          source = sources[idx];
          R[idx] = source;
        }
        return mux(R);
      };
      //.........................................................................................................
      $_demux = function() {
        return PS.$map(function([k, v]) {
          return v;
        });
      };
      //.........................................................................................................
      pipeline = [];
      pipeline.push($_mux(...sources));
      pipeline.push($_demux());
      return PS.pull(...pipeline);
    };
    //.........................................................................................................
    return new Promise(function(resolve) {
      var pipeline, source_1, source_2;
      pipeline = [];
      source_1 = new_async_source('s1');
      source_2 = new_async_source('s2');
      pipeline.push(PS.$wye(source_1, source_2));
      pipeline.push(PS.$collect());
      pipeline.push(PS.$watch(function(d) {
        return help('-->', jr(d));
      }));
      pipeline.push(PS.$drain(function() {
        help('ok');
        return resolve(null);
      }));
      PS.pull(...pipeline);
      after(0.1, function() {
        return source_2.push(4);
      });
      after(0.5, function() {
        return source_1.push(2);
      });
      after(0.6, function() {
        return source_1.push(3);
      });
      after(0.2, function() {
        return source_2.push(5);
      });
      after(0.3, function() {
        return source_2.push(6);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.4, function() {
        return source_1.push(1);
      });
      after(0.05, function() {
        return source_2.push(42);
      });
      after(1.0, function() {
        return source_1.end();
      });
      after(1.0, function() {
        return source_2.end();
      });
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_through = function() {
    var through;
    return through = require('pull-through');
  };

  //-----------------------------------------------------------------------------------------------------------
  /* https://github.com/pull-stream/pull-through */  async_with_end_detection = function() {
    var buffer, flush, pipeline, send;
    buffer = [11, 12, 13, 14, 15];
    pipeline = [];
    send = null;
    flush = () => {
      var results;
      results = [];
      while (!is_empty(buffer)) {
        results.push(send(buffer.pop()));
      }
      return results;
    };
    pipeline.push(PS.new_value_source([1, 2, 3, 4, 5]));
    pipeline.push(PS.$defer());
    //.........................................................................................................
    pipeline.push((() => {
      var is_first;
      is_first = true;
      return $({
        last: PS.symbols.last
      }, (d, send) => {
        if (is_first) {
          is_first = false;
          send(PS.symbols.first);
        }
        return send(d);
      });
    })());
    //.........................................................................................................
    pipeline.push(PS.$async((d, _send, done) => {
      send = _send;
      switch (d) {
        case PS.symbols.first:
          debug('start');
          send(buffer.pop());
          done();
          break;
        case PS.symbols.last:
          flush();
          debug('end');
          // done()
          after(2, done);
          break;
        default:
          send(d);
          done();
      }
      return null;
    }));
    //.........................................................................................................
    pipeline.push(PS.$show());
    pipeline.push(PS.$drain());
    PS.pull(...pipeline);
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  async_with_end_detection_2 = function() {
    var buffer, flush, pipeline, send;
    buffer = [11, 12, 13, 14, 15];
    pipeline = [];
    send = null;
    flush = () => {
      var results;
      results = [];
      while (!is_empty(buffer)) {
        results.push(send(buffer.pop()));
      }
      return results;
    };
    //.........................................................................................................
    pipeline.push(PS.new_value_source([1, 2, 3, 4, 5]));
    pipeline.push(PS.$defer());
    //.........................................................................................................
    pipeline.push(PS.$async('null', (d, _send, done) => {
      send = _send;
      if (d != null) {
        send(d);
        done();
      } else {
        flush();
        debug('end');
        // done()
        after(2, done);
      }
      return null;
    }));
    //.........................................................................................................
    pipeline.push(PS.$show());
    pipeline.push(PS.$drain());
    PS.pull(...pipeline);
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  sync_with_first_and_last = function() {
    var drainer, pipeline;
    drainer = function() {
      return help('ok');
    };
    pipeline = [];
    pipeline.push(PS.new_value_source([1, 2, 3, 4, 5]));
    //.........................................................................................................
    pipeline.push(PS.$surround({
      first: '[',
      last: ']',
      before: '(',
      between: ',',
      after: ')'
    }));
    pipeline.push(PS.$surround({
      first: 'first',
      last: 'last'
    }));
    // pipeline.push PS.$surround { first: 'first', last: 'last', before: 'before', between: 'between', after: 'after' }
    // pipeline.push PS.$surround { first: '[', last: ']', }
    //.........................................................................................................
    pipeline.push(PS.$collect());
    pipeline.push($(function(d, send) {
      var x;
      return send(((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = d.length; i < len; i++) {
          x = d[i];
          results.push(x.toString());
        }
        return results;
      })()).join(''));
    }));
    pipeline.push(PS.$show());
    pipeline.push(PS.$drain(drainer));
    PS.pull(...pipeline);
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  async_with_first_and_last = function() {
    var drainer, pipeline;
    drainer = function() {
      return help('ok');
    };
    pipeline = [];
    pipeline.push(PS.new_value_source([1, 2, 3]));
    //.........................................................................................................
    pipeline.push(PS.$surround({
      first: 'first',
      last: 'last'
    }));
    pipeline.push($async({
      first: '[',
      last: ']',
      between: '|'
    }, (d, send, done) => {
      return defer(function() {
        // debug '22922', jr d
        send(d);
        return done();
      });
    }));
    //.........................................................................................................
    // pipeline.push PS.$watch ( d ) -> urge '20292', d
    pipeline.push(PS.$collect());
    pipeline.push($(function(d, send) {
      var x;
      return send(((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = d.length; i < len; i++) {
          x = d[i];
          results.push(x.toString());
        }
        return results;
      })()).join(''));
    }));
    pipeline.push(PS.$show());
    pipeline.push(PS.$drain(drainer));
    PS.pull(...pipeline);
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_3b = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, mainline;
        bysource = PS.new_push_source();
        byline = [];
        byline.push(bysource);
        byline.push($(function(d, send) {
          if (CND.isa_text(d)) {
            send(d.length);
          } else {
            send(d);
          }
          return null;
        }));
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push($(function(d, send) {
          if (CND.isa_text(d)) {
            bysource.send(d);
            send(d);
          } else {
            send(d);
          }
          return null;
        }));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_4 = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, bystream, mainline;
        bysource = PS.new_push_source();
        byline = [];
        byline.push(bysource);
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        bystream = PS.pull(...byline);
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_value_source([5, 7]));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(bystream));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push($(function(d, send) {
          if (d < 1.001) {
            return send(null);
          } else {
            send(d);
            return bysource.send(Math.sqrt(d));
          }
        }));
        mainline.push(PS.$map(function(d) {
          return d.toFixed(3);
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_with_random_value_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, mainline;
        byline = [];
        byline.push(PS.new_random_async_value_source(0.1, [3, 4, 5, 6, 7, 8]));
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_with_value_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, mainline;
        byline = [];
        byline.push(PS.new_value_source([3, 4, 5, 6, 7, 8]));
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_with_external_push_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, i, mainline, x;
        bysource = PS.new_push_source(function(error) {
          return debug('10203', "Bysource ended");
        });
        byline = [];
        byline.push(bysource);
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        for (x = i = 3; i <= 8; x = ++i) {
          bysource.send(x);
        }
        bysource.send(null);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  wye_with_internal_push_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, mainline, tick;
        tick = function() {
          process.stdout.write('*');
          after(0.5, tick);
          return null;
        };
        after(0.5, tick);
        //.......................................................................................................
        bysource = PS.new_push_source(function(error) {
          return debug('10203', "Bysource ended");
        });
        // bysource  = PS.new_push_source()
        byline = [];
        byline.push(bysource);
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push($async(function(d, send, done) {
          debug('34844', d);
          send(d);
          if (d !== 'few') {
            return done();
          }
        }));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push($({
          last: null
        }, function(d, send) {
          debug('10191', CND.green(d));
          if (d != null) {
            if (CND.isa_text(d)) {
              bysource.send(d.length);
              send(d);
            } else {
              send(d);
            }
          } else {
            bysource.send(null);
          }
          return null;
        }));
        mainline.push(PS.$defer());
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        PS.pull(...mainline);
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  generator_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, bysource, g, iterator, mainline;
        //.......................................................................................................
        g = function*() {
          var i, nr, x;
          for (nr = i = 1; i < 10; nr = ++i) {
            x = (yield nr);
            debug('77873', x);
          }
          return null;
        };
        //.......................................................................................................
        iterator = g();
        bysource = PS.new_generator_source(iterator);
        byline = [];
        byline.push(bysource);
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_random_async_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push(PS.$wye(PS.pull(...byline)));
        mainline.push(PS.$show({
          title: 'confluence'
        }));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        // mainline.push PS.$drain -> help 'ok'; resolve()
        urge(iterator.next());
        urge(iterator.next('foo'));
        PS.pull(...mainline);
        // for x in [ 3 .. 8 ]
        //   bysource.send x
        // bysource.send null
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_alternating_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var i, n, pipeline, source_1, source_2;
        source_1 = PS.new_push_source();
        source_2 = PS.new_push_source();
        pipeline = [];
        pipeline.push(PS.new_alternating_source(source_1, source_2));
        pipeline.push(PS.$show({
          title: 'pipeline'
        }));
        pipeline.push(PS.$drain(function() {
          return "pipeline terminated";
        }));
        PS.pull(...pipeline);
        source_1.send('a');
        source_1.send('b');
        for (n = i = 1; i <= 5; n = ++i) {
          // source_1.send 'c'
          source_2.send(n);
        }
        info('----');
        after(1.0, function() {
          whisper("source_1 ended");
          return source_1.end();
        });
        after(1.5, function() {
          whisper("source_2 ended");
          return source_2.end();
        });
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_on_demand_source = async function() {
    var demo;
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var i, mainsource, nr, on_demand_source, pipeline;
        // mainsource            = PS.new_push_source()
        mainsource = PS.new_value_source([1, 2, 3, 4, 5]);
        pipeline = [];
        on_demand_source = PS.new_on_demand_source(mainsource);
        pipeline.push(on_demand_source);
        pipeline.push(PS.$watch(function(d) {
          return info(((CND.type_of(d)) === 'symbol' ? CND.grey : CND.white)(d));
        }));
        pipeline.push(PS.$drain(function() {
          return "pipeline terminated";
        }));
        PS.pull(...pipeline);
// mainsource.send n for n in [ 1 .. 5 ]
        for (nr = i = 1; i <= 3; nr = ++i) {
          on_demand_source.next();
        }
        // on_demand_source.next()
        // on_demand_source.next()
        info('----');
        // after 1.0, -> whisper "triggersource ended"; triggersource.end()
        // after 1.5, -> whisper "mainsource ended"; mainsource.end()
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_on_demand_transform = async function() {
    var $gate, demo;
    $gate = function() {};
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var gate, i, mainsource, nr, pipeline;
        // mainsource            = PS.new_push_source()
        mainsource = PS.new_value_source([1, 2, 3, 4, 5]);
        pipeline = [];
        gate = $gate();
        pipeline.push(mainsource);
        pipeline.push(gate);
        pipeline.push(PS.$drain(function() {
          return "pipeline terminated";
        }));
        PS.pull(...pipeline);
        for (nr = i = 1; i <= 3; nr = ++i) {
          gate.next();
        }
        // after 1.5, -> whisper "mainsource ended"; mainsource.end()
        //.......................................................................................................
        return null;
      });
    };
    await demo();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    (async function() {
      // demo_merge_1()
      // demo_merge_async_sources()
      // demo_mux_async_sources_1()
      // demo_mux_async_sources_2()
      // demo_through()
      // async_with_end_detection()
      // async_with_end_detection_2()
      // sync_with_first_and_last()
      // async_with_first_and_last()
      // await wye_1()
      return (await wye_2());
    })();
  }

  // await wye_with_random_value_source()
// await wye_with_value_source()
// await wye_with_external_push_source()
// await wye_with_internal_push_source()
// await generator_source()
// await test_continuity()
// wye_3b()
// wye_4()
// await demo_alternating_source()
// await demo_on_demand_source()

}).call(this);
