// Generated by CoffeeScript 2.4.1
(function() {
  'use strict';
  var CND, Intertype, alert, badge, debug, help, info, intertype, jr, rpr, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPEDREAMS/_TYPES';

  debug = CND.get_logger('debug', badge);

  alert = CND.get_logger('alert', badge);

  whisper = CND.get_logger('whisper', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  info = CND.get_logger('info', badge);

  jr = JSON.stringify;

  Intertype = (require('intertype')).Intertype;

  intertype = new Intertype(module.exports);

  //-----------------------------------------------------------------------------------------------------------
  this.declare('pipestreams_$window_settings', {
    tests: {
      "x is an object": function(x) {
        return this.isa.object(x);
      },
      "x.width is a positive": function(x) {
        return this.isa.positive(x.width);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('pipestreams_$lookaround_settings', {
    tests: {
      "x is an object": function(x) {
        return this.isa.object(x);
      },
      "x.delta is a count": function(x) {
        return this.isa.count(x.delta);
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  this.declare('positive_proper_fraction', function(x) {
    return (0 <= x && x <= 1);
  });

  this.declare('pipestreams_number_or_text', function(x) {
    return (this.isa.number(x)) || (this.isa.text(x));
  });

}).call(this);

//# sourceMappingURL=_types.js.map
