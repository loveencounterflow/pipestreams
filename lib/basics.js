(function() {
  'use strict';
  var $paramap, $pass_through, $pull_drain, $values, CND, FS, PATH, after, alert, assign, badge, copy, debug, declare, defer, echo, every, help, info, is_empty, isa, jr, log, map, pull, pull_cont, pull_through, return_id, rpr, size_of, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/BASICS';

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

  // CP                        = require 'child_process'
  //...........................................................................................................
  $pass_through = require('pull-stream/throughs/through');

  $pull_drain = require('pull-stream/sinks/drain');

  $values = require('pull-stream/sources/values');

  $paramap = require('pull-paramap');

  pull = require('pull-stream');

  pull_through = require('../deps/pull-through-with-end-symbol');

  pull_cont = require('pull-cont');

  map = require('./_map_errors');

  //...........................................................................................................
  after = function(dts, f) {
    return setTimeout(f, dts * 1000);
  };

  every = function(dts, f) {
    return setInterval(f, dts * 1000);
  };

  defer = setImmediate;

  return_id = function(x) {
    return x;
  };

  ({is_empty, copy, assign, jr} = CND);

  //...........................................................................................................
  this._symbols = require('./_symbols');

  //...........................................................................................................
  types = require('./_types');

  ({isa, validate, declare, size_of, type_of} = types);

  //===========================================================================================================
  // ISA METHODS
  //-----------------------------------------------------------------------------------------------------------
  /* thx to German Attanasio http://stackoverflow.com/a/28564000/256361 */
  this._isa_njs_stream = function(x) {
    return x instanceof (require('stream')).Stream;
  };

  this._isa_readable_njs_stream = function(x) {
    return (this._isa_njs_stream(x)) && x.readable;
  };

  this._isa_writable_njs_stream = function(x) {
    return (this._isa_njs_stream(x)) && x.writable;
  };

  this._isa_readonly_njs_stream = function(x) {
    return (this._isa_njs_stream(x)) && x.readable && !x.writable;
  };

  this._isa_writeonly_njs_stream = function(x) {
    return (this._isa_njs_stream(x)) && x.writable && !x.readable;
  };

  this._isa_duplex_njs_stream = function(x) {
    return (this._isa_njs_stream(x)) && x.readable && x.writable;
  };

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.new_value_source = function(values) {
    return $values(values);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_push_source = function(...P) {
    /* Return a `pull-streams` `pushable`. Methods `push` and `end` will be bound to the instance
    so they can be freely passed around. */
    var PS, R, end, new_pushable, send, source;
    new_pushable = require('pull-pushable');
    source = new_pushable(...P);
    R = function(...P) {
      return source(...P);
    };
    PS = this;
    //.........................................................................................................
    send = function(d) {
      source.push(d);
      return null;
    };
    //.........................................................................................................
    end = function(...P) {
      source.end(...P);
      return null;
    };
    //.........................................................................................................
    R.send = send.bind(R);
    R.end = end.bind(R);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_alternating_source = function(source_a, source_b) {
    /* Given two sources `a` and `b`, return a new source that will emit events
    from both streams in an interleaved fashion, such that the first data item
    from `a` is followed from the first item from `b`, followed by the second from
    `a`, the second from `b` and so on. Once one of the streams has ended, omit
    the remaining items from the other one, if any, until that stream ends, too.
    See also https://github.com/tounano/pull-robin. */
    var merge, toggle;
    merge = require('pull-merge');
    toggle = +1;
    return merge(source_a, source_b, (function() {
      return toggle = -toggle;
    }));
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_on_demand_source = function(stream) {
    /* Given a stream, return a source `s` with a method `s.next()` such that the next data item from `s`
    will only be sent as soon as that method is called. */
    var R, next_sym, pipeline, triggersource;
    triggersource = this.new_push_source();
    pipeline = [];
    next_sym = Symbol('next');
    pipeline.push(this.new_alternating_source(triggersource, stream));
    pipeline.push(this.$filter(function(d) {
      return d !== next_sym;
    }));
    R = this.pull(...pipeline);
    R.next = function() {
      return triggersource.send(next_sym);
    };
    R.next();
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_random_async_value_source = function(dts, values) {
    /* Given an optional delta time in seconds `dts` (which defaults to 0.1 seconds) and a list of values,
    return a source that will asynchronously produce values at irregular intervals that randomly oscillate
    around `dts`. */
    var R, arity, idx, last_idx, new_timeout, tick;
    switch (arity = arguments.length) {
      case 1:
        [dts, values] = [0.1, dts];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ77749 expected 1 or 2 arguments, got ${arity}`);
    }
    //.........................................................................................................
    R = this.new_push_source();
    new_timeout = function() {
      return (Math.random() + 0.001) * dts;
    };
    //.........................................................................................................
    idx = 0;
    last_idx = values.length - 1;
    //.........................................................................................................
    if (!(CND.isa_number(last_idx))) {
      throw new Error(`µ89231 expected a list-like object, got a ${CND.type_of(values)}`);
    }
    //.........................................................................................................
    tick = () => {
      if (idx <= last_idx) {
        R.send(values[idx]);
        idx += +1;
        after(new_timeout(), tick);
      } else {
        R.end();
      }
      return null;
    };
    //.........................................................................................................
    after(new_timeout(), tick);
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_generator_source = function(generator) {
    return function(end, handler) {
      var R;
      if (end) {
        return handler(end);
      }
      R = generator.next();
      return defer(function() {
        if (R.done) {
          return handler(true);
        }
        return handler(null, R.value);
      });
    };
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_refillable_source = function(values, settings) {
    /* A refillable source expects a list of `values` (or a listlike object with a `shift()` method); when a
    read occurs, it will empty `values` one element at a time, always shifting the leftmost element (with
    index zero) from `values`. Transforms down the line may choose to `values.push()` new values into the
    list, which will in time be sent down again. When a read occurs and `values` happens to be empty, a
    special value (the `trailer`, by default a symbol) will be sent down the line (only to be filtered out
    immediately) up to `repeat` times (by default one time) in a row to avoid depleting the pipeline. */
    var R, discard_sym, filter, read, trailer_count;
    discard_sym = Symbol('discard');
    settings = assign({
      repeat: 1,
      trailer: discard_sym,
      show: false
    }, settings);
    trailer_count = 0;
    //.........................................................................................................
    filter = this.$filter((d) => {
      return d !== discard_sym;
    });
    //.........................................................................................................
    read = (abort, handler) => {
      var value;
      if (abort) {
        return handler(abort);
      }
      if (values.length === 0) {
        trailer_count += +1;
        if (settings.show) {
          info('23983', `refillable source depleted: ${trailer_count} / ${settings.repeat}`);
        }
        if (trailer_count < settings.repeat) {
          value = settings.trailer;
        } else {
          return handler(true);
        }
      } else {
        trailer_count = 0;
        value = values.shift();
      }
      /* Must defer callback so the the pipeline gets a chance to refill: */
      defer(function() {
        return handler(null, value);
      });
      return null;
    };
    //.........................................................................................................
    R = this.pull(read, filter);
    // R.end = ->
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$filter = function(method) {
    var arity, type;
    if ((type = CND.type_of(method)) !== 'function') {
      throw new Error(`µ15533 expected a function, got a ${type}`);
    }
    switch (arity = method.length) {
      case 1:
        null;
        break;
      default:
        throw new Error(`µ16298 method arity ${arity} not implemented`);
    }
    //.........................................................................................................
    return pull.filter(method);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$map = function(method) {
    var arity, type;
    if ((type = CND.type_of(method)) !== 'function') {
      throw new Error(`µ17063 expected a function, got a ${type}`);
    }
    switch (arity = method.length) {
      case 1:
        null;
        break;
      default:
        throw new Error(`µ17828 method arity ${arity} not implemented`);
    }
    //.........................................................................................................
    return map(method);
  };

  //-----------------------------------------------------------------------------------------------------------
  this._get_remit_settings = function(hint, method) {
    var arity, defaults, settings;
    defaults = {
      first: this._symbols.misfit,
      last: this._symbols.misfit,
      between: this._symbols.misfit,
      after: this._symbols.misfit,
      before: this._symbols.misfit
    };
    settings = assign({}, defaults);
    switch (arity = arguments.length) {
      case 1:
        method = hint;
        hint = null;
        break;
      case 2:
        if (CND.isa_text(hint)) {
          throw new Error("µ30902 Deprecated: use `{last:null}` instead of `'null'`");
        } else {
          settings = assign(settings, hint);
        }
        break;
      default:
        throw new Error(`µ19358 expected 1 or 2 arguments, got ${arity}`);
    }
    settings._surround = (settings.first !== this._symbols.misfit) || (settings.last !== this._symbols.misfit) || (settings.between !== this._symbols.misfit) || (settings.after !== this._symbols.misfit) || (settings.before !== this._symbols.misfit);
    return {settings, method};
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$ = this.remit = function(...P) {
    var PS, client_arity, data_after, data_before, data_between, data_first, data_last, do_leapfrog, is_first, method, on_data, on_end, self, send, send_after, send_before, send_between, send_first, send_last, settings, type;
    /* NOTE we're transitioning from the experimental `hint` call convention to the more flexible and
    standard `settings` (which are here placed first, not last, b/c one frequently wants to write out a
    function body as last argument). For a limited time, `'null'` is accepted in place of a `settings` object;
    after that, `{ last: null }` should be used. */
    //.........................................................................................................
    ({settings, method} = this._get_remit_settings(...P));
    switch (client_arity = method.length) {
      case 2:
        null;
        break;
      default:
        throw new Error(`µ20123 method arity ${client_arity} not implemented`);
    }
    if ((type = CND.type_of(method)) !== 'function') {
      //.........................................................................................................
      throw new Error(`µ20888 expected a function, got a ${type}`);
    }
    //.........................................................................................................
    self = null;
    //.........................................................................................................
    if (settings.leapfrog != null) {
      validate.function(settings.leapfrog);
      do_leapfrog = true;
    } else {
      do_leapfrog = false;
    }
    //.........................................................................................................
    data_first = settings.first;
    data_before = settings.before;
    data_between = settings.between;
    data_after = settings.after;
    data_last = settings.last;
    send_first = data_first !== this._symbols.misfit;
    send_before = data_before !== this._symbols.misfit;
    send_between = data_between !== this._symbols.misfit;
    send_after = data_after !== this._symbols.misfit;
    send_last = data_last !== this._symbols.misfit;
    on_end = null;
    is_first = true;
    PS = this;
    //.........................................................................................................
    send = function(d) {
      if (self == null) {
        throw new Error("µ93892 called `send` method too late");
      }
      return self.queue(d);
    };
    //.........................................................................................................
    send.end = function() {
      if (arguments.length !== 0) {
        throw new Error(`µ09833 \`send.end()\` takes no arguments, got ${rpr([...arguments])}`);
      }
      return self.queue(PS._symbols.end);
    };
    //.........................................................................................................
    on_data = function(d) {
      self = this;
      if (is_first) {
        is_first = false;
        if (send_first) {
          method(data_first, send);
        }
      } else {
        if (send_between) {
          method(data_between, send);
        }
      }
      if (send_before) {
        method(data_before, send);
      }
      //.......................................................................................................
      // When leapfrogging is being called for, only call method if the jumper returns false:
      if ((!do_leapfrog) || (!settings.leapfrog(d))) {
        method(d, send);
      } else {
        send(d);
      }
      if (send_after) {
        //.......................................................................................................
        method(data_after, send);
      }
      self = null;
      return null;
    };
    //.........................................................................................................
    on_end = function() {
      if (send_last) {
        self = this;
        method(data_last, send);
        self = null;
      }
      // defer -> @queue PS._symbols.end
      this.queue(PS._symbols.end);
      return null;
    };
    //.........................................................................................................
    return pull_through(on_data, on_end);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$async = function(...P) {
    var arity, call_count, has_ended, last_sym, method, pipeline, ref, settings, type;
    /* TAINT currently all results from client method are buffered until `done` gets called; see whether
    it is possible to use `await` so that each result can be sent doen the pipeline w/out buffering */
    //.........................................................................................................
    /* NOTE we're transitioning from the experimental `hint` call convention to the more flexible and
    standard `settings` (which are here placed first, not last, b/c one frequently wants to write out a
    function body as last argument). For a limited time, `'null'` is accepted in place of a `settings` object;
    after that, `{ last: null }` (or using other value except `PS._symbols.misfit`) should be used. */
    //.........................................................................................................
    ({settings, method} = this._get_remit_settings(...P));
    if ((type = CND.type_of(method)) !== 'function') {
      throw new Error(`µ18187 expected a function, got a ${type}`);
    }
    if (!((1 <= (ref = (arity = arguments.length)) && ref <= 2))) {
      throw new Error(`µ18203 expected one or two arguments, got ${arity}`);
    }
    if ((arity = method.length) !== 3) {
      throw new Error(`µ18219 method arity ${arity} not implemented`);
    }
    //.........................................................................................................
    pipeline = [];
    call_count = 0;
    has_ended = false;
    last_sym = Symbol('last');
    if (settings._surround) {
      //.........................................................................................................
      pipeline.push(this.$surround(settings));
    }
    pipeline.push(this.$surround({
      last: last_sym
    }));
    //.........................................................................................................
    pipeline.push($paramap((d, handler) => {
      var collector, done, send;
      collector = [];
      //.......................................................................................................
      send = (d) => {
        if (d === this._symbols.end) {
          return handler(true);
        }
        collector.unshift(d);
        return null;
      };
      //.......................................................................................................
      done = () => {
        call_count += -1;
        handler(null, collector);
        if (has_ended && call_count < 1) {
          handler(true);
        }
        return null;
      };
      //.......................................................................................................
      if (d === last_sym) {
        has_ended = true;
        if (call_count < 1) {
          handler(true);
        }
      } else {
        call_count += +1;
        defer(function() {
          return method(d, send, done);
        });
      }
      return null;
    }));
    //.........................................................................................................
    pipeline.push(this.$defer());
    pipeline.push(this.$((d, send) => {
      var results;
      results = [];
      while (d.length > 0) {
        results.push(send(d.pop()));
      }
      return results;
    }));
    //.........................................................................................................
    return this.pull(...pipeline);
  };

  //-----------------------------------------------------------------------------------------------------------
  /* Given a `settings` object, add values to the stream as `$ settings, ( d, send ) -> send d` would do,
  e.g. `$surround { first: 'first!', between: 'to appear in-between two values', }`. */
  this.$surround = function(settings) {
    return this.$(settings, (d, send) => {
      return send(d);
    });
  };

  //===========================================================================================================
  // MARK POSITION IN STREAM
  //-----------------------------------------------------------------------------------------------------------
  this.$mark_position = function() {
    /* Turns values into objects `{ first, last, value, }` where `value` is the original value and `first`
    and `last` are booleans that indicate position of value in the stream. */
    var is_first, last, prv;
    last = this._symbols.last;
    is_first = true;
    prv = [];
    return this.$({last}, (d, send) => {
      if ((d === last) && prv.length > 0) {
        if (prv.length > 0) {
          send({
            is_first,
            is_last: true,
            d: prv.pop()
          });
        }
        return null;
      }
      if (prv.length > 0) {
        send({
          is_first,
          is_last: false,
          d: prv.pop()
        });
        is_first = false;
      }
      prv.push(d);
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.mark_position = function(transform) {
    return this.pull(this.$mark_position(), transform);
  };

  //===========================================================================================================
  // WINDOWING
  //-----------------------------------------------------------------------------------------------------------
  this.$window = function(settings) {
    /* Moving window over data items in stream. Turns stream of values into stream of
    lists each `width` elements long. */
    var _, buffer, defaults, fallback, had_value, last;
    defaults = {
      width: 3,
      fallback: null
    };
    settings = assign({}, defaults, settings);
    validate.pipestreams_$window_settings(settings);
    //.........................................................................................................
    if (settings.leapfrog != null) {
      throw new Error("µ77871 setting 'leapfrog' only valid for PS.window(), not PS.$window()");
    }
    //.........................................................................................................
    if (settings.width === 1) {
      return this.$((d, send) => {
        return send([d]);
      });
    }
    //.........................................................................................................
    last = Symbol('last');
    had_value = false;
    fallback = settings.fallback;
    buffer = (function() {
      var i, ref, results;
      results = [];
      for (_ = i = 1, ref = settings.width; (1 <= ref ? i <= ref : i >= ref); _ = 1 <= ref ? ++i : --i) {
        results.push(fallback);
      }
      return results;
    })();
    //.........................................................................................................
    return this.$({last}, (d, send) => {
      var i, ref;
      if (d === last) {
        if (had_value) {
          for (_ = i = 1, ref = settings.width; (1 <= ref ? i < ref : i > ref); _ = 1 <= ref ? ++i : --i) {
            buffer.shift();
            buffer.push(fallback);
            send(buffer.slice(0));
          }
        }
        return null;
      }
      had_value = true;
      buffer.shift();
      buffer.push(d);
      send(buffer.slice(0));
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$lookaround = function(settings) {
    /* Turns stream of values into stream of lists of values, each `( 2 * delta ) + 1` elements long;
    unlike `$window()`, will send exactly as many lists as there are values in the stream. Default
    is `delta: 1`, i.e. you get to see lists `[ prv, d, nxt, ]` where `prv` is the previous value
    (or the fallback which itself defaults to `null`), `d` is the current value, and `nxt` is the
    upcoming value (or `fallback` in case the stream will end after this value). */
    var center, defaults, delta, fallback, misfit, pipeline;
    defaults = {
      delta: 1,
      fallback: null
    };
    settings = assign({}, defaults, settings);
    validate.pipestreams_$lookaround_settings(settings);
    //.........................................................................................................
    if (settings.leapfrog != null) {
      throw new Error("µ77872 setting 'leapfrog' only valid for PS.lookaround(), not PS.$lookaround()");
    }
    //.........................................................................................................
    if (settings.delta === 0) {
      return this.$((d, send) => {
        return send([d]);
      });
    }
    //.........................................................................................................
    fallback = settings.fallback;
    misfit = Symbol('misfit');
    delta = center = settings.delta;
    pipeline = [];
    pipeline.push(this.$window({
      width: 2 * delta + 1,
      fallback: misfit
    }));
    pipeline.push(this.$((d, send) => {
      var x;
      if (d[center] === misfit) {
        // debug 'µ11121', rpr d
        // debug 'µ11121', rpr ( ( if x is misfit then fallback else x ) for x in d )
        return null;
      }
      send((function() {
        var i, len, results;
        results = [];
        for (i = 0, len = d.length; i < len; i++) {
          x = d[i];
          results.push(x === misfit ? fallback : x);
        }
        return results;
      })());
      return null;
    }));
    return this.pull(...pipeline);
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.window = function(settings, transform) {
    var R, arity, leapfrog, pipeline;
    switch (arity = arguments.length) {
      case 1:
        [settings, transform] = [null, settings];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ23111 expected 1 or 2 arguments, got ${arity}`);
    }
    //.........................................................................................................
    if ((leapfrog = settings != null ? settings.leapfrog : void 0) != null) {
      delete settings.leapfrog;
    }
    //.........................................................................................................
    pipeline = [];
    pipeline.push(this.$window(settings));
    pipeline.push(transform);
    R = this.pull(...pipeline);
    //.........................................................................................................
    if (leapfrog != null) {
      return this.leapfrog(leapfrog, R);
    }
    //.........................................................................................................
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.lookaround = function(settings, transform) {
    var R, arity, leapfrog, pipeline;
    switch (arity = arguments.length) {
      case 1:
        [settings, transform] = [null, settings];
        break;
      case 2:
        null;
        break;
      default:
        throw new Error(`µ23112 expected 1 or 2 arguments, got ${arity}`);
    }
    //.........................................................................................................
    if ((leapfrog = settings != null ? settings.leapfrog : void 0) != null) {
      delete settings.leapfrog;
    }
    //.........................................................................................................
    pipeline = [];
    pipeline.push(this.$lookaround(settings));
    pipeline.push(transform);
    R = this.pull(...pipeline);
    //.........................................................................................................
    if (leapfrog != null) {
      return this.leapfrog(leapfrog, R);
    }
    //.........................................................................................................
    return R;
  };

  //===========================================================================================================
  // ASYNC TRANSFORMS
  //-----------------------------------------------------------------------------------------------------------
  this.$defer = function() {
    return $paramap(function(d, handler) {
      return defer(function() {
        return handler(null, d);
      });
    });
  };

  this.$delay = function(dts) {
    return $paramap(function(d, handler) {
      return after(dts, function() {
        return handler(null, d);
      });
    });
  };

  //===========================================================================================================

  //-----------------------------------------------------------------------------------------------------------
  this.$pass = function() {
    return map((data) => {
      return data;
    });
  };

  this.$end_if = function(filter) {
    return this.$(function(d, send) {
      if (filter(d)) {
        return send.end();
      } else {
        return send(d);
      }
    });
  };

  this.$continue_if = function(filter) {
    return this.$(function(d, send) {
      if (!filter(d)) {
        return send.end();
      } else {
        return send(d);
      }
    });
  };

  this.mark_as_sink = function(method, description) {
    method[Symbol.for('sink')] = description;
    return method;
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$drain = function(on_end = null) {
    var R;
    if (on_end != null) {
      R = $pull_drain(null, function(error) {
        if (error != null) {
          throw error;
        }
        return on_end();
      });
    } else {
      R = $pull_drain();
    }
    return this.mark_as_sink(R, {
      type: '$drain',
      on_end
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.new_pausable = function() {
    return (require('pull-pause'))();
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$watch = function(settings, method) {
    /* If any `surround` feature is called for, wrap all surround values so that we can safely
    distinguish between them and ordinary stream values; this is necessary to prevent them from leaking
    into the regular stream outside the `$watch` transform: */
    var arity, key, take_second, value;
    //.........................................................................................................
    switch (arity = arguments.length) {
      //.......................................................................................................
      case 1:
        [settings, method] = [null, settings];
        //.....................................................................................................
        return this.$((d, send) => {
          method(d);
          send(d);
          return null;
        });
      //.......................................................................................................
      case 2:
        if (settings == null) {
          return this.$watch(method);
        }
        take_second = Symbol('take-second');
        settings = assign({}, settings);
        for (key in settings) {
          value = settings[key];
          settings[key] = [take_second, value];
        }
        //.....................................................................................................
        return this.$(settings, (d, send) => {
          if ((CND.isa_list(d)) && (d[0] === take_second)) {
            method(d[1]);
          } else {
            method(d);
            send(d);
          }
          return null;
        });
    }
    //.........................................................................................................
    throw new Error(`µ18244 expected one or two arguments, got ${arity}`);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.pull = function(...methods) {
    var i, idx, len, method, type;
    if (methods.length === 0) {
      return this.$pass();
    }
    for (idx = i = 0, len = methods.length; i < len; idx = ++i) {
      method = methods[idx];
      if ((type = CND.type_of(method)) === 'function') {
        continue;
      }
      if (CND.isa_pod(method)) {
        continue;
      }
      throw new /* allowing for `{ x.source, x.sink, }` duplex streams */Error(`µ25478 expected a function, got a ${type} for argument # ${idx + 1}`);
    }
    return pull(...methods);
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$collect = function(settings) {
    var collector, last_sym, ref;
    collector = (ref = settings != null ? settings.collector : void 0) != null ? ref : [];
    last_sym = Symbol('last');
    return this.$({
      last: last_sym
    }, (d, send) => {
      if (d === last_sym) {
        send(collector);
      } else {
        collector.push(d);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$spread = function() {
    return this.$((collection, send) => {
      var element, i, len;
      for (i = 0, len = collection.length; i < len; i++) {
        element = collection[i];
        send(element);
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$show = function(settings) {
    var ref, ref1, serialize, title;
    title = (ref = settings != null ? settings['title'] : void 0) != null ? ref : '-->';
    serialize = (ref1 = settings != null ? settings['serialize'] : void 0) != null ? ref1 : JSON.stringify;
    return this.$watch((data) => {
      return info(title, serialize(data));
    });
  };

  //===========================================================================================================
  // SAMPLING / THINNING OUT
  //-----------------------------------------------------------------------------------------------------------
  this.$sample = function(p = 0.5, settings) {
    var headers, is_first, ref, ref1, rnd, seed;
    validate.positive_proper_fraction(p);
    if (p === 1) {
      //.........................................................................................................
      return this.$map((d) => {
        return d;
      });
    }
    if (p === 0) {
      return this.$filter((d) => {
        return false;
      });
    }
    //.........................................................................................................
    headers = (ref = settings != null ? settings['headers'] : void 0) != null ? ref : false;
    seed = (ref1 = settings != null ? settings['seed'] : void 0) != null ? ref1 : null;
    is_first = headers;
    rnd = seed != null ? CND.get_rnd(seed) : Math.random;
    //.........................................................................................................
    return this.$((d, send) => {
      if (is_first) {
        is_first = false;
        return send(d);
      }
      if (rnd() < p) {
        return send(d);
      }
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$scramble = function(p = 0.5, settings) {
    var cache, flush, headers, is_first, last, ref, ref1, rnd, seed, send, shuffle;
    validate.positive_proper_fraction(p);
    if (p === 0) {
      //.........................................................................................................
      return this.$pass();
    }
    //.........................................................................................................
    headers = (ref = settings != null ? settings['headers'] : void 0) != null ? ref : false;
    seed = (ref1 = settings != null ? settings['seed'] : void 0) != null ? ref1 : null;
    is_first = headers;
    rnd = seed != null ? CND.get_rnd(seed) : Math.random;
    last = Symbol('last');
    cache = [];
    send = null;
    shuffle = seed != null ? CND.get_shuffle(seed, seed) : CND.shuffle.bind(CND);
    //.........................................................................................................
    flush = function() {
      shuffle(cache);
      while (cache.length > 0) {
        send(cache.pop());
      }
      cache.length = 0;
      return null;
    };
    //.........................................................................................................
    return this.$({last}, (d, send_) => {
      send = send_;
      if (d === last) {
        return flush();
      }
      //.......................................................................................................
      if (is_first) {
        is_first = false;
        return send(d);
      }
      //.......................................................................................................
      if (rnd() >= p) {
        cache.push(d);
        return flush();
      }
      //.......................................................................................................
      cache.push(d);
      return null;
    });
  };

}).call(this);
