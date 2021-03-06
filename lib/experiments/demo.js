(function() {
  'use strict';
  var $, $watch, CND, L, PS, after, alert, badge, before, between, debug, echo, first, help, info, last, log, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS/DEMO';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  PS = require('../..');

  ({$, $watch} = PS.export());

  first = Symbol('first');

  last = Symbol('last');

  first = Symbol('first');

  last = Symbol('last');

  between = Symbol('between');

  after = Symbol('after');

  before = Symbol('before');

  //-----------------------------------------------------------------------------------------------------------
  this.$show_signals = function() {
    return $({first, last, between, after, before}, (d, send) => {
      info(d);
      return send(d);
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_signals = function() {
    return new Promise((resolve, reject) => {
      var i, idx, pipeline, source;
      source = PS.new_push_source();
      pipeline = [];
      pipeline.push(source);
      pipeline.push(this.$show());
      pipeline.push(PS.$drain(resolve));
      PS.pull(...pipeline);
      for (idx = i = 1; i <= 5; idx = ++i) {
        source.send(idx);
      }
      source.end();
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.$wrapsignals = function() {
    /* NOTE: this functionality has been implemented in PipeDreams */
    var is_first, prv_d;
    is_first = true;
    prv_d = null;
    return $({last}, (d, send) => {
      if (d === last) {
        if (prv_d != null) {
          if (is_first) {
            prv_d.first = true;
          }
          prv_d.last = true;
          send(prv_d);
        }
      } else {
        if (prv_d != null) {
          send(prv_d);
        }
        prv_d = {
          value: d
        };
        if (is_first) {
          prv_d.first = true;
        }
        is_first = false;
      }
      return null;
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  this.demo_wrapsignals = function() {
    return new Promise((resolve, reject) => {
      var i, idx, n, pipeline, ref, source;
      source = PS.new_push_source();
      pipeline = [];
      pipeline.push(source);
      pipeline.push(PS.$wrapsignals());
      pipeline.push(PS.$show());
      pipeline.push(PS.$drain(resolve));
      PS.pull(...pipeline);
      n = 5;
      for (idx = i = 1, ref = n; (1 <= ref ? i <= ref : i >= ref); idx = 1 <= ref ? ++i : --i) {
        source.send(idx);
      }
      source.end();
      return null;
    });
  };

  //###########################################################################################################
  if (module.parent == null) {
    L = this;
    (async function() {
      // await L.demo_signals()
      await L.demo_wrapsignals();
      return help('ok');
    })();
  }

}).call(this);
