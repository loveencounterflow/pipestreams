(function() {
  //###########################################################################################################
  var $, $async, $pull_drain, $take, $values, CND, FS, OS, PATH, PS, alert, badge, debug, defer, echo, help, info, inspect, log, pull, pull_through, read, rpr, test, urge, warn, whisper, xrpr,
    indexOf = [].indexOf,
    modulo = function(a, b) { return (+a % (b = +b) + b) % b; };

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/TESTS/BASIC';

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
  pull = require('pull-stream');

  $take = require('pull-stream/throughs/take');

  $values = require('pull-stream/sources/values');

  $pull_drain = require('pull-stream/sinks/drain');

  pull_through = require('pull-through');

  //...........................................................................................................
  read = function(path) {
    return FS.readFileSync(path, {
      encoding: 'utf-8'
    });
  };

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

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test line assembler" ] = ( T, done ) ->
  //   text = """
  //   "　2. 纯；专：专～。～心～意。"
  //   !"　3. 全；满：～生。～地水。"
  //   "　4. 相同：～样。颜色不～。"
  //   "　5. 另外!的：蟋蟀～名促织。!"
  //   "　6. 表示动作短暂，或是一次，或具试探性：算～算。试～试。"!
  //   "　7. 乃；竞：～至于此。"
  //   """
  //   # text = "abc\ndefg\nhijk"
  //   chunks    = text.split '!'
  //   text      = text.replace /!/g, ''
  //   collector = []
  //   assembler = PS._new_line_assembler { extra: true, splitter: '\n', }, ( error, line ) ->
  //     throw error if error?
  //     if line?
  //       collector.push line
  //       info rpr line
  //     else
  //       # urge rpr text
  //       # help rpr collector.join '\n'
  //       # debug collector
  //       if CND.equals text, collector.join '\n'
  //         T.succeed "texts are equal"
  //       done()
  //   for chunk in chunks
  //     assembler chunk
  //   assembler null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test throughput (1)" ] = ( T, done ) ->
  //   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
  //   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  //   output  = FS.createWriteStream '/tmp/output.txt'
  //   lines   = []
  //   input
  //     .pipe PS.$split()
  //     # .pipe PS.$show()
  //     .pipe PS.$succeed()
  //     .pipe PS.$as_line()
  //     .pipe $ ( line, send ) ->
  //       lines.push line
  //       send line
  //     .pipe output
  //   ### TAINT use PipeStreams method ###
  //   input.on 'end', -> outpudone()
  //   output.on 'close', ->
  //     # if CND.equals lines.join '\n'
  //     T.succeed "assuming equality"
  //     done()
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "test throughput (2)" ] = ( T, done ) ->
  //   # input   = @new_stream PATH.resolve __dirname, '../test-data/guoxuedashi-excerpts-short.txt'
  //   input   = PS.new_stream PATH.resolve __dirname, '../../test-data/Unicode-NamesList-tiny.txt'
  //   output  = FS.createWriteStream '/tmp/output.txt'
  //   lines   = []
  //   p       = input
  //   p       = p.pipe PS.$split()
  //   # p       = p.pipe PS.$show()
  //   p       = p.pipe PS.$succeed()
  //   p       = p.pipe PS.$as_line()
  //   p       = p.pipe $ ( line, send ) ->
  //       lines.push line
  //       send line
  //   p       = p.pipe output
  //   ### TAINT use PipeStreams method ###
  //   input.on 'end', -> outpudone()
  //   output.on 'close', ->
  //     # if CND.equals lines.join '\n'
  //     # debug '12001', lines
  //     T.succeed "assuming equality"
  //     done()
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "read with pipestreams" ] = ( T, done ) ->
  //   matcher       = [
  //     '01 ; charset=UTF-8',
  //     '02 @@@\tThe Unicode Standard 9.0.0',
  //     '03 @@@+\tU90M160615.lst',
  //     '04 \tUnicode 9.0.0 final names list.',
  //     '05 \tThis file is semi-automatically derived from UnicodeData.txt and',
  //     '06 \ta set of manually created annotations using a script to select',
  //     '07 \tor suppress information from the data file. The rules used',
  //     '08 \tfor this process are aimed at readability for the human reader,',
  //     '09 \tat the expense of some details; therefore, this file should not',
  //     '10 \tbe parsed for machine-readable information.',
  //     '11 @+\t\t© 2016 Unicode®, Inc.',
  //     '12 \tFor terms of use, see http://www.unicode.org/terms_of_use.html',
  //     '13 @@\t0000\tC0 Controls and Basic Latin (Basic Latin)\t007F',
  //     '14 @@+'
  //     ]
  //   # input_path    = '../../test-data/Unicode-NamesList-tiny.txt'
  //   input_path    = '/home/flow/io/basic-stream-benchmarks/test-data/Unicode-NamesList-tiny.txt'
  //   # output_path   = '/dev/null'
  //   output_path   = '/tmp/output.txt'
  //   input         = PS.new_stream input_path
  //   output        = FS.createWriteStream output_path
  //   collector     = []
  //   S             = {}
  //   S.item_count  = 0
  //   S.byte_count  = 0
  //   p             = input
  //   p             = p.pipe $ ( data, send ) -> whisper '20078-1', rpr data; send data
  //   p             = p.pipe PS.$split()
  //   p             = p.pipe $ ( data, send ) -> help '20078-1', rpr data; send data
  //   #.........................................................................................................
  //   p             = p.pipe PS.$ ( line, send ) ->
  //     S.item_count += +1
  //     S.byte_count += line.length
  //     debug '22001-0', rpr line
  //     collector.push line
  //     send line
  //   #.........................................................................................................
  //   p             = p.pipe $ ( data, send ) -> urge '20078-2', rpr data; send data
  //   p             = p.pipe PS.$as_line()
  //   p             = p.pipe output
  //   #.........................................................................................................
  //   ### TAINT use PipeStreams method ###
  //   output.on 'close', ->
  //     # debug '88862', S
  //     # debug '88862', collector
  //     if CND.equals collector, matcher
  //       T.succeed "collector equals matcher"
  //     done()
  //   #.........................................................................................................
  //   ### TAINT should be done by PipeStreams ###
  //   input.on 'end', ->
  //     outpudone()
  //   #.........................................................................................................
  //   return null

  // #-----------------------------------------------------------------------------------------------------------
  // @[ "remit without end detection" ] = ( T, done ) ->
  //   pipeline = []
  //   pipeline.push $values Array.from 'abcdef'
  //   pipeline.push $ ( data, send ) ->
  //     send data
  //     send '*' + data + '*'
  //   pipeline.push PS.$show()
  //   pipeline.push $pull_drain()
  //   PS.pull pipeline...
  //   T.succeed "ok"
  //   done()

  //-----------------------------------------------------------------------------------------------------------
  this["remit with end detection 1"] = function(T, done) {
    var pipeline;
    /* Sending `PS._symbols.end` has undefined behavior; in this case, it does end the stream, which is
    OK. */
    // debug xrpr PS._symbols
    // debug xrpr PS._symbols.end; xxx
    pull_through = require('../../deps/pull-through-with-end-symbol');
    pipeline = [];
    // pipeline.push $values Array.from 'abcdef'
    pipeline.push(PS.new_value_source(Array.from('abcdef')));
    pipeline.push(PS.$map(function(d) {
      return d;
    }));
    pipeline.push($(function(d, send) {
      return send(d === 'c' ? PS._symbols.end : d);
    }));
    pipeline.push(PS.$pass());
    pipeline.push(pull_through((function(d) {
      return this.queue(d);
    })));
    pipeline.push($({
      last: null
    }, function(data, send) {
      if (data != null) {
        send(data);
        return send('*' + data + '*');
      } else {
        return send('ok');
      }
    }));
    pipeline.push($pull_drain(null, function() {
      T.succeed("ok");
      return done();
    }));
    return PS.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["remit with end detection 2"] = function(T, done) {
    var pipeline;
    pull_through = require('../../deps/pull-through-with-end-symbol');
    pipeline = [];
    pipeline.push(PS.new_value_source(Array.from('abcdef')));
    pipeline.push(PS.$map(function(d) {
      return d;
    }));
    pipeline.push($(function(d, send) {
      if (d === 'c') {
        return send.end();
      } else {
        return send(d);
      }
    }));
    pipeline.push(PS.$pass());
    pipeline.push(pull_through((function(d) {
      return this.queue(d);
    })));
    pipeline.push($({
      last: null
    }, function(data, send) {
      if (data != null) {
        send(data);
        return send('*' + data + '*');
      } else {
        return send('ok');
      }
    }));
    pipeline.push($pull_drain(null, function() {
      T.succeed("ok");
      return done();
    }));
    return PS.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  this["watch with end detection 1"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = ["abcdef", ["(", "*a*", "|", "*b*", "|", "*c*", "|", "*d*", "|", "*e*", "|", "*f*", ")"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var collector, pipeline;
        collector = [];
        pipeline = [];
        pipeline.push(PS.new_value_source(Array.from(probe)));
        pipeline.push($(function(d, send) {
          return send(`*${d}*`);
        }));
        pipeline.push(PS.$watch({
          first: '(',
          between: '|',
          last: ')'
        }, function(d) {
          debug('44874', xrpr(d));
          return collector.push(d);
        }));
        // pipeline.push PS.$collect { collector, }
        pipeline.push(PS.$drain(function() {
          help('ok');
          debug('44874', xrpr(collector));
          return resolve(collector);
        }));
        return PS.pull(...pipeline);
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["watch with end detection 2"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = ["abcdef", ["*a*", "*b*", "*c*", "*d*", "*e*", "*f*"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var collector, pipeline;
        collector = [];
        pipeline = [];
        pipeline.push(PS.new_value_source(Array.from(probe)));
        pipeline.push($(function(d, send) {
          return send(`*${d}*`);
        }));
        pipeline.push(PS.$watch({
          first: '(',
          between: '|',
          last: ')'
        }, function(d) {
          return debug('44874', xrpr(d));
        }));
        pipeline.push(PS.$collect({collector}));
        pipeline.push(PS.$drain(function() {
          help('ok');
          debug('44874', xrpr(collector));
          return resolve(collector);
        }));
        return PS.pull(...pipeline);
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["wrap FS object for sink"] = function(T, done) {
    var output_path, output_stream, pipeline, sink;
    output_path = '/tmp/pipestreams-test-output.txt';
    output_stream = FS.createWriteStream(output_path);
    sink = PS.write_to_nodejs_stream(output_stream); //, ( error ) -> debug '37783', error
    pipeline = [];
    pipeline.push($values(Array.from('abcdef')));
    pipeline.push(PS.$show());
    pipeline.push(sink);
    pull(...pipeline);
    return output_stream.on('finish', () => {
      T.ok(CND.equals('abcdef', read(output_path)));
      return done();
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this["function as pull-stream source"] = function(T, done) {
    var pipeline, random, Ø;
    random = (n) => {
      return (end, callback) => {
        if (end != null) {
          debug('40998', rpr(callback));
          debug('40998', rpr(end));
          return callback(end);
        }
        //only read n times, then stop.
        n += -1;
        if (n < 0) {
          return callback(true);
        }
        callback(null, Math.random());
        return null;
      };
    };
    //.........................................................................................................
    pipeline = [];
    Ø = (x) => {
      return pipeline.push(x);
    };
    Ø(random(10));
    // Ø random 3
    Ø(PS.$collect());
    Ø($({
      last: null
    }, function(data, send) {
      if (data != null) {
        T.ok(data.length === 10);
        debug(data);
        return send(data);
      } else {
        T.succeed("function works as pull-stream source");
        done();
        return send(null);
      }
    }));
    Ø(PS.$show());
    Ø(PS.$drain());
    //.........................................................................................................
    PS.pull(...pipeline);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$surround"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [null, "first[(1),(2),(3),(4),(5)]last", null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, pipeline;
        R = null;
        drainer = function() {
          help('ok');
          return resolve(R);
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
        pipeline.push(PS.$watch(function(d) {
          return R = d;
        }));
        pipeline.push(PS.$drain(drainer));
        PS.pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["$surround async"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [null, "[first|1|2|3|4|5|last]", null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, pipeline;
        R = null;
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        pipeline = [];
        pipeline.push(PS.new_value_source([1, 2, 3, 4, 5]));
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
        pipeline.push(PS.$watch(function(d) {
          return R = d;
        }));
        pipeline.push(PS.$drain(drainer));
        PS.pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (1)"] = async function(T, done) {
    /* The proper way to end a push source is to call `source.end()`. */
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, i, len, pipeline, source, word;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        source = PS.new_push_source();
        pipeline = [];
        pipeline.push(source);
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        source.end();
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (2)"] = async function(T, done) {
    /* The proper way to end a push source is to call `source.end()`. */
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles", "stop"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, i, len, pipeline, source, word;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        source = PS.new_push_source();
        pipeline = [];
        pipeline.push(source);
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push($(function(d, send) {
          if (d === 'stop') {
            return source.end();
          } else {
            return send(d);
          }
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (3)"] = async function(T, done) {
    /* The proper way to end a push source is to call `source.end()`; `send.end()` is largely equivalent. */
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles", "stop"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, i, len, pipeline, source, word;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        source = PS.new_push_source();
        pipeline = [];
        pipeline.push(source);
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push($(function(d, send) {
          if (d === 'stop') {
            return send.end();
          } else {
            return send(d);
          }
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end push source (4)"] = async function(T, done) {
    /* A stream may be ended by using an `$end_if()` (alternatively, `$continue_if()`) transform. */
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles", "stop"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, i, len, pipeline, source, word;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        source = PS.new_push_source();
        pipeline = [];
        pipeline.push(source);
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$end_if(function(d) {
          return d === 'stop';
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        for (i = 0, len = probe.length; i < len; i++) {
          word = probe[i];
          source.send(word);
        }
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["end random async source"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [["what", "a", "lot", "of", "little", "bottles"], ["what", "a", "lot", "of", "little", "bottles"], null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, drainer, pipeline, source;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(R);
        };
        source = PS.new_random_async_value_source(probe);
        pipeline = [];
        pipeline.push(source);
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["read file chunks"] = async function(T, done) {
    var error, matcher, probe;
    [probe, matcher, error] = [__filename, null, null];
    await T.perform(probe, matcher, error, function() {
      return new Promise(function(resolve, reject) {
        var R, count, drainer, pipeline, source;
        R = [];
        drainer = function() {
          help('ok');
          return resolve(null);
        };
        source = PS.read_chunks_from_file(probe, 50);
        count = 0;
        pipeline = [];
        pipeline.push(source);
        pipeline.push($(function(d, send) {
          return send(d.toString('utf-8'));
        }));
        pipeline.push(PS.$watch(function() {
          count += +1;
          if (count > 3) {
            return source.end();
          }
        }));
        pipeline.push(PS.$collect({
          collector: R
        }));
        pipeline.push(PS.$watch(function(d) {
          return info(xrpr(d));
        }));
        pipeline.push(PS.$drain(drainer));
        pull(...pipeline);
        return null;
      });
    });
    //.........................................................................................................
    done();
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  this["demo watch pipeline on abort 2"] = async function(T, done) {
    var aborting_map, error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [[[false, [1, 2, 3, null, 5]], [1, 1, 1, 2, 2, 2, 3, 3, 3, null, null, null, 5, 5, 5], null], [[true, [1, 2, 3, null, 5]], [1, 1, 1, 2, 2, 2, 3, 3, 3, null, null, null, 5, 5, 5], null], [[false, [1, 2, 3, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3], null], [[true, [1, 2, 3, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3], null], [[false, [1, 2, 3, null, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3, null, null, null], null], [[true, [1, 2, 3, null, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3, null, null, null], null], [[false, [1, 2, 3, void 0, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3, void 0, void 0, void 0], null], [[true, [1, 2, 3, void 0, "stop", 25, 30]], [1, 1, 1, 2, 2, 2, 3, 3, 3, void 0, void 0, void 0], null], [[false, ["stop", 25, 30]], [], null], [[true, ["stop", 25, 30]], [], null]];
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
          pipeline.push(PS.$(function(d, send) {
            info('22398-2', xrpr(d));
            collector.push(d);
            return send(d);
          }));
          pipeline.push(PS.$(function(d, send) {
            info('22398-3', xrpr(d));
            collector.push(d);
            return send(d);
          }));
          pipeline.push(PS.$(function(d, send) {
            info('22398-4', xrpr(d));
            collector.push(d);
            return send(d);
          }));
          // pipeline.push PS.$map ( d ) -> info '22398-2', xrpr d; collector.push d; return d
          // pipeline.push PS.$map ( d ) -> info '22398-3', xrpr d; collector.push d; return d
          // pipeline.push PS.$map ( d ) -> info '22398-4', xrpr d; collector.push d; return d
          pipeline.push(PS.$drain(function() {
            help('44998', xrpr(collector));
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

  //-----------------------------------------------------------------------------------------------------------
  this["$mark_position"] = async function(T, done) {
    var collector, error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [
      [
        ["a"],
        [
          {
            "is_first": true,
            "is_last": true,
            "d": "a"
          }
        ],
        null
      ],
      [[],
      [],
      null],
      [
        [1,
        2,
        3],
        [
          {
            "is_first": true,
            "is_last": false,
            "d": 1
          },
          {
            "is_first": false,
            "is_last": false,
            "d": 2
          },
          {
            "is_first": false,
            "is_last": true,
            "d": 3
          }
        ],
        null
      ],
      [
        ["a",
        "b"],
        [
          {
            "is_first": true,
            "is_last": false,
            "d": "a"
          },
          {
            "is_first": false,
            "is_last": true,
            "d": "b"
          }
        ],
        null
      ]
    ];
    //.........................................................................................................
    collector = [];
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var pipeline, source;
          //.....................................................................................................
          source = PS.new_value_source(probe);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PS.$mark_position());
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
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

  //-----------------------------------------------------------------------------------------------------------
  this["leapfrog 1"] = async function(T, done) {
    var collector, error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          (function(d) {
            return modulo(d,
          2) !== 0;
          })
        ],
        [1,
        102,
        3,
        104,
        5,
        106,
        7,
        108,
        9,
        110],
        null
      ]
    ];
    //.........................................................................................................
    collector = [];
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var jumper, pipeline, source, values;
          [values, jumper] = probe;
          //.....................................................................................................
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PS.$({
            leapfrog: jumper
          }, function(d, send) {
            return send(100 + d);
          }));
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
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

  //-----------------------------------------------------------------------------------------------------------
  this["leapfrog 2"] = async function(T, done) {
    var collector, error, i, len, matcher, probe, probes_and_matchers;
    // through = require 'pull-through'
    probes_and_matchers = [
      [
        [
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          (function(d) {
            return modulo(d,
          2) !== 0;
          })
        ],
        [1,
        102,
        3,
        104,
        5,
        106,
        7,
        108,
        9,
        110],
        null
      ]
    ];
    //.........................................................................................................
    collector = [];
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve) {
          var jumper, pipeline, source, values;
          [values, jumper] = probe;
          //.....................................................................................................
          source = PS.new_value_source(values);
          collector = [];
          pipeline = [];
          pipeline.push(source);
          pipeline.push(PS.$({
            leapfrog: jumper
          }, function(d, send) {
            return send(100 + d);
          }));
          pipeline.push(PS.$collect({collector}));
          pipeline.push(PS.$drain(function() {
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

  //-----------------------------------------------------------------------------------------------------------
  this["$scramble"] = async function(T, done) {
    var error, i, len, matcher, probe, probes_and_matchers;
    probes_and_matchers = [[[[], 0.5, 42], [], null], [[[1], 0.5, 42], [1], null], [[[1, 2], 0.5, 42], [1, 2], null], [[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40], 0.5, 42], [1, 4, 2, 5, 3, 6, 7, 14, 12, 9, 13, 8, 16, 10, 15, 11, 17, 18, 19, 20, 21, 22, 24, 26, 23, 25, 27, 28, 29, 30, 32, 31, 33, 34, 35, 37, 36, 38, 39, 40], null], [[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 1, 2], [9, 2, 7, 5, 8, 4, 10, 1, 3, 6], null], [[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 0.1, 2], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], null], [[[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 0, 2], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], null]];
//.........................................................................................................
    for (i = 0, len = probes_and_matchers.length; i < len; i++) {
      [probe, matcher, error] = probes_and_matchers[i];
      //.......................................................................................................
      await T.perform(probe, matcher, error, function() {
        return new Promise(function(resolve, reject) {
          var cache, collector, p, pipeline, seed, values;
          [values, p, seed] = probe;
          cache = {};
          collector = [];
          pipeline = [];
          pipeline.push(PS.new_value_source(values));
          pipeline.push(PS.$scramble(p, {seed}));
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
    // include = []
    // @_prune()
    // @_main()
    // test @
    // test @[ "read file chunks" ]
    // test @[ "$mark_position" ]
    // test @[ "leapfrog 2" ]
    test(this["$scramble"]);
  }

  // test @[ "remit with end detection 1" ]
// test @[ "remit with end detection 2" ]
// test @[ "$surround async" ]
// test @[ "end push source (1)" ]
// test @[ "end push source (2)" ]
// test @[ "end push source (3)" ]
// test @[ "end push source (4)" ]
// test @[ "end random async source" ]
// test @[ "watch with end detection 1" ]
// test @[ "watch with end detection 2" ]
// test @[ "demo watch pipeline on abort 2" ]

}).call(this);
