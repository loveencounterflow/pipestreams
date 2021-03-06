(function() {
  'use strict';
  var $, $async, CND, PS, after, alert, assign, badge, debug, defer, echo, every, help, info, inspect, is_empty, jr, log, rpr, test, urge, warn, whisper, xrpr;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/EXPERIMENTS/DUPLEX-STREAMS';

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

  test = require('guy-test');

  assign = Object.assign;

  ({inspect} = require('util'));

  xrpr = function(x) {
    return inspect(x, {
      colors: true,
      breakLength: 2e308,
      maxArrayLength: 2e308,
      depth: 2e308
    });
  };

  /*
  Duplex streams are used to communicate with a remote service,
  and they are a pair of source and sink streams `{source, sink}`

  in node, you see duplex streams to connect replication or rpc protocols.
  client.pipe(server).pipe(client)
  or
  server.pipe(client).pipe(server)
  both do the same thing.

  the pull function we wrote before doesn't detect this,
  but if you use the pull-stream module it will.
  Then we can pipe duplex pull-streams like this:

  var pull = require('pull-stream')
  pull(client, server, client)

  Also, sometimes you'll need to interact with a regular node stream.
  there are two modules for this.

  stream-to-pull-stream
  and
  pull-stream-to-stream
  */
  //-----------------------------------------------------------------------------------------------------------
  this.wye_1 = function() {
    var $wye, bysource, new_pair, pipeline;
    new_pair = require('pull-pair');
    //.........................................................................................................
    $wye = function(bystream) {
      var confluence, pair, pipeline_1, pipeline_2, pushable;
      pair = new_pair();
      pushable = PS.new_push_source();
      pipeline_1 = [];
      pipeline_2 = [];
      //.......................................................................................................
      pipeline_1.push(pair.source);
      pipeline_1.push(PS.$surround({
        before: '(',
        after: ')',
        between: '-'
      }));
      // pipeline_1.push PS.$join()
      pipeline_1.push(PS.$show({
        title: 'substream'
      }));
      pipeline_1.push(PS.$watch(function(d) {
        return pushable.send(d);
      }));
      pipeline_1.push(PS.$drain(function() {
        return urge("substream ended");
      }));
      //.......................................................................................................
      pipeline_2.push(bystream);
      pipeline_2.push($({
        last: null
      }, function(d, send) {
        if (d == null) {
          urge("bystream ended");
        }
        return send(d);
      }));
      pipeline_2.push(PS.$show({
        title: 'bystream'
      }));
      //.......................................................................................................
      PS.pull(...pipeline_1);
      confluence = PS.$merge(pushable, PS.pull(...pipeline_2));
      return {
        sink: pair.sink,
        source: confluence
      };
    };
    //.........................................................................................................
    bysource = PS.new_value_source([3, 4, 5, 6, 7]);
    pipeline = [];
    pipeline.push(PS.new_value_source("just a few words".split(/\s/)));
    // pipeline.push PS.$watch ( d ) -> whisper d
    pipeline.push($wye(bysource));
    pipeline.push(PS.$collect());
    pipeline.push(PS.$show({
      title: 'mainstream'
    }));
    pipeline.push(PS.$drain(function() {
      return help('ok');
    }));
    PS.pull(...pipeline);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.wye_2 = async function() {
    var $wye, demo, new_pair;
    new_pair = require('pull-pair');
    //.........................................................................................................
    $wye = function(bystream) {
      var byline, bystream_ended, confluence, end_sym, pair, pushable, subline, substream_ended;
      pair = new_pair();
      pushable = PS.new_push_source();
      subline = [];
      byline = [];
      end_sym = Symbol('end');
      bystream_ended = false;
      substream_ended = false;
      //.......................................................................................................
      subline.push(pair.source);
      subline.push($({
        last: end_sym
      }, function(d, send) {
        if (d === end_sym) {
          substream_ended = true;
          if (bystream_ended) {
            return pushable.end();
          }
        } else {
          return pushable.send(d);
        }
      }));
      subline.push(PS.$drain());
      //.......................................................................................................
      byline.push(bystream);
      byline.push($({
        last: end_sym
      }, function(d, send) {
        if (d === end_sym) {
          bystream_ended = true;
          if (substream_ended) {
            return pushable.end();
          }
        } else {
          return send(d);
        }
      }));
      //.......................................................................................................
      PS.pull(...subline);
      confluence = PS.$merge(pushable, PS.pull(...byline));
      return {
        sink: pair.sink,
        source: confluence
      };
    };
    //.........................................................................................................
    demo = function() {
      return new Promise(function(resolve) {
        var byline, mainline;
        byline = [];
        byline.push(PS.new_value_source([3, 4, 5, 6, 7]));
        byline.push(PS.$watch(function(d) {
          return whisper('bystream', jr(d));
        }));
        //.......................................................................................................
        mainline = [];
        mainline.push(PS.new_value_source("just a few words".split(/\s/)));
        mainline.push(PS.$watch(function(d) {
          return whisper('mainstream', jr(d));
        }));
        mainline.push($wye(PS.pull(...byline)));
        mainline.push(PS.$collect());
        mainline.push(PS.$show({
          title: 'mainstream'
        }));
        mainline.push(PS.$drain(function() {
          help('ok');
          return resolve();
        }));
        return PS.pull(...mainline);
      });
    };
    await demo();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.pull_pair_1 = function() {
    var new_pair, pair, pipeline_1, pipeline_2;
    new_pair = require('pull-pair');
    pair = new_pair();
    pipeline_1 = [];
    pipeline_2 = [];
    //.........................................................................................................
    // read values into this sink...
    pipeline_1.push(PS.new_value_source([1, 2, 3]));
    pipeline_1.push(PS.$watch(function(d) {
      return urge(d);
    }));
    pipeline_1.push(pair.sink);
    PS.pull(...pipeline_1);
    //.........................................................................................................
    // but that should become the source over here.
    pipeline_2.push(pair.source);
    pipeline_2.push(PS.$collect());
    pipeline_2.push(PS.$show());
    pipeline_2.push(PS.$drain());
    //.........................................................................................................
    PS.pull(...pipeline_2);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.pull_pair_2 = function() {
    var f, new_pair, pipeline;
    new_pair = require('pull-pair');
    //.........................................................................................................
    f = function() {
      var pair, pipeline_1, pushable;
      pair = new_pair();
      pushable = PS.new_push_source();
      pipeline_1 = [];
      //.......................................................................................................
      pipeline_1.push(pair.source);
      pipeline_1.push(PS.$surround({
        before: '(',
        after: ')',
        between: '-'
      }));
      pipeline_1.push(PS.$join());
      pipeline_1.push(PS.$show({
        title: 'substream'
      }));
      pipeline_1.push(PS.$watch(function(d) {
        return pushable.send(d);
      }));
      pipeline_1.push(PS.$drain());
      //.......................................................................................................
      PS.pull(...pipeline_1);
      return {
        sink: pair.sink,
        source: pushable
      };
    };
    //.........................................................................................................
    pipeline = [];
    pipeline.push(PS.new_value_source("just a few words".split(/\s/)));
    pipeline.push(PS.$watch(function(d) {
      return whisper(d);
    }));
    pipeline.push(f());
    pipeline.push(PS.$show({
      title: 'mainstream'
    }));
    pipeline.push(PS.$drain());
    PS.pull(...pipeline);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["_duplex 1"] = function() {
    var NET, bylog, listener, mainlog, pull, server, server_as_duplex_stream, toPull;
    NET = require('net');
    toPull = require('stream-to-pull-stream');
    pull = require('pull-stream');
    bylog = PS.get_logger('b', 'red');
    mainlog = PS.get_logger('m', 'gold');
    //.........................................................................................................
    server_as_duplex_stream = function(nodejs_stream) {
      /* convert into a duplex pull-stream */
      var extra_stream, pipeline, server_stream;
      server_stream = toPull.duplex(nodejs_stream);
      extra_stream = PS.new_random_async_value_source("xxx here comes the sun".split(/\s+/));
      pipeline = [];
      // pipeline.push server_stream
      pipeline.push(PS.new_merged_source(server_stream, extra_stream));
      pipeline.push(bylog(PS.$split()));
      pipeline.push(bylog(pull.map(function(x) {
        return x.toString().toUpperCase() + '!!!';
      })));
      // pipeline.push server_stream
      pipeline.push(bylog(pull.map(function(x) {
        return `*${x}*`;
      })));
      pipeline.push(bylog(PS.$as_line()));
      pipeline.push(PS.$watch(function(d) {
        return debug('32387', xrpr(d));
      }));
      pipeline.push(server_stream);
      // pipeline.push PS.$watch ( d ) -> console.log d.toString()
      // pipeline.push bylog PS.$drain()
      PS.pull(...pipeline);
      return null;
    };
    //.........................................................................................................
    server = NET.createServer(server_as_duplex_stream);
    listener = function() {
      var client_stream, pipeline;
      client_stream = toPull.duplex(NET.connect(9999));
      pipeline = [];
      pipeline.push(PS.new_random_async_value_source(['quiet stream\n', 'great thing\n']));
      // pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
      pipeline.push(client_stream);
      pipeline.push(mainlog(PS.$split()));
      pipeline.push(PS.$watch(function(d) {
        return debug('32388', xrpr(d));
      }));
      pipeline.push(mainlog(PS.$drain(function() {
        help('ok');
        return server.close();
      })));
      PS.pull(...pipeline);
      return null;
    };
    //.........................................................................................................
    return server.listen(9999, listener);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["_duplex 2"] = function() {
    var NET, bylog, listener, mainlog, pull, server, server_as_duplex_stream, toPull;
    NET = require('net');
    toPull = require('stream-to-pull-stream');
    pull = require('pull-stream');
    bylog = PS.get_logger('b', 'red');
    mainlog = PS.get_logger('m', 'gold');
    //.........................................................................................................
    server_as_duplex_stream = function(nodejs_stream) {
      /* convert into a duplex pull-stream */
      var extra_stream, pipeline, server_stream;
      extra_stream = PS.new_random_async_value_source("xxx here comes the sun".split(/\s+/));
      server_stream = toPull.duplex(nodejs_stream);
      pipeline = [];
      pipeline.push(PS.new_merged_source(server_stream, extra_stream));
      pipeline.push(bylog(PS.$split()));
      pipeline.push(bylog(pull.map(function(x) {
        return x.toString().toUpperCase() + '!!!';
      })));
      // pipeline.push server_stream
      pipeline.push(bylog(pull.map(function(x) {
        return `*${x}*`;
      })));
      pipeline.push(bylog(PS.$as_line()));
      pipeline.push(PS.$watch(function(d) {
        return debug('32387', xrpr(d));
      }));
      pipeline.push(server_stream);
      // pipeline.push PS.$watch ( d ) -> console.log d.toString()
      // pipeline.push bylog PS.$drain()
      PS.pull(...pipeline);
      return null;
    };
    //.........................................................................................................
    server = NET.createServer(server_as_duplex_stream);
    listener = function() {
      var client_stream, pipeline;
      client_stream = toPull.duplex(NET.connect(9999));
      pipeline = [];
      pipeline.push(PS.new_random_async_value_source('quiet stream this is one great thing'.split(/\s+/)));
      // pipeline.push PS.new_value_source [ 'quiet stream\n', 'great thing\n', ]
      pipeline.push(client_stream);
      pipeline.push(mainlog(PS.$split()));
      pipeline.push(PS.$watch(function(d) {
        return debug('32388', xrpr(d));
      }));
      pipeline.push(mainlog(PS.$drain(function() {
        help('ok');
        return server.close();
      })));
      PS.pull(...pipeline);
      return null;
    };
    //.........................................................................................................
    return server.listen(9999, listener);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.duplex_stream_3 = function() {
    var client, clientline, extra_stream, new_duplex_pair, refillable, server, serverline;
    new_duplex_pair = require('pull-pair/duplex');
    [client, server] = new_duplex_pair();
    clientline = [];
    serverline = [];
    refillable = [];
    extra_stream = PS.new_refillable_source(refillable, {
      repeat: 10,
      show: true
    });
    // extra_stream        = PS.new_push_source()
    //.........................................................................................................
    // pipe the second duplex stream back to itself.
    serverline.push(PS.new_merged_source(server, extra_stream));
    // serverline.push client
    serverline.push(PS.$defer());
    serverline.push(PS.$watch(function(d) {
      return urge(d);
    }));
    serverline.push($(function(d, send) {
      return send(d * 10);
    }));
    serverline.push(server);
    PS.pull(...serverline);
    //.........................................................................................................
    clientline.push(PS.new_value_source([1, 2, 3]));
    // clientline.push PS.$defer()
    clientline.push(client);
    // clientline.push PS.$watch ( d ) -> extra_stream.send d if d < 30
    clientline.push(PS.$watch(function(d) {
      if (d < 30) {
        return refillable.push(d);
      }
    }));
    clientline.push(PS.$collect());
    clientline.push(PS.$show());
    // clientline.push client
    clientline.push(PS.$drain());
    PS.pull(...clientline);
    //.........................................................................................................
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["wye with duplex pair"] = async function(T, done) {
    var $wye, error, i, len, matcher, new_duplex_pair, probe, probes_and_matchers;
    new_duplex_pair = require('pull-pair/duplex');
    probes_and_matchers = [[[false, false, false, [11, 12, 13], [21, 22, 23, 24, 25]], [22, 42, 24, 44, 26, 46, 48, 50], null], [[false, false, true, [11, 12, 13], [21, 22, 23, 24, 25]], [22, 42, 24, 44, 26, 46, 48, 50], null], [[false, true, false, [11, 12, 13], [21, 22, 23, 24, 25]], [22, 42, 24, 44, 26, 46, 48, 50], null], [[false, true, true, [11, 12, 13], [21, 22, 23, 24, 25]], [22, 42, 24, 44, 26, 46, 48, 50], null], [[true, false, false, [11, 12, 13], [21, 22, 23, 24, 25]], [42, 44, 46, 48, 50, 22, 24, 26], null], [[true, false, true, [11, 12, 13], [21, 22, 23, 24, 25]], [42, 44, 46, 48, 50, 22, 24, 26], null], [[true, true, false, [11, 12, 13], [21, 22, 23, 24, 25]], [42, 44, 46, 48, 50, 22, 24, 26], null], [[true, true, true, [11, 12, 13], [21, 22, 23, 24, 25]], [42, 44, 46, 48, 50, 22, 24, 26], null]];
    //.........................................................................................................
    $wye = function(stream, use_defer) {
      var $log, client, server, serverline;
      $log = PS.get_logger('b', 'red');
      [client, server] = new_duplex_pair();
      serverline = [];
      serverline.push(PS.new_merged_source(server, stream));
      if (use_defer) {
        serverline.push(PS.$defer());
      }
      // serverline.push PS.$watch ( d ) -> urge d
      serverline.push($(function(d, send) {
        return send(d * 2);
      }));
      serverline.push(server);
      PS.pull(...serverline);
      return client;
    };
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var $log, a, b, clientline, collector, source_a, source_b, use_defer_1, use_defer_2, use_defer_3;
          $log = PS.get_logger('m', 'gold');
          [use_defer_1, use_defer_2, use_defer_3, a, b] = probe;
          source_a = PS.new_value_source(a);
          source_b = PS.new_value_source(b);
          collector = [];
          clientline = [];
          clientline.push(source_a);
          if (use_defer_1) {
            clientline.push(PS.$defer());
          }
          clientline.push($wye(source_b, use_defer_3));
          if (use_defer_2) {
            clientline.push(PS.$defer());
          }
          clientline.push(PS.$collect({collector}));
          // clientline.push PS.$show()
          clientline.push(PS.$drain(function() {
            return resolve(collector);
          }));
          return PS.pull(...clientline);
        });
      });
    }
    //.........................................................................................................
    done();
    return null;
  };

  //###########################################################################################################
  if (module.parent == null) {
    (() => {
      // await @duplex_stream_3()
      // await @wye_1()
      // await @wye_2()
      // await @pull_pair_1()
      // await @pull_pair_2()
      // await @[ "_duplex 1" ]()
      // await @[ "_duplex 2" ]()
      // await @wye_with_duplex_pair()
      return test(this["wye with duplex pair"]);
    })();
  }

}).call(this);
