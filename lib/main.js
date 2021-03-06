(function() {
  'use strict';
  var CND, L, Multimix, Pipestreams, alert, badge, debug, declare, echo, help, info, isa, log, rpr, size_of, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'PIPESTREAMS';

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
  types = require('./_types');

  ({isa, validate, declare, size_of, type_of} = types);

  Multimix = require('multimix');

  Pipestreams = (function() {
    //-----------------------------------------------------------------------------------------------------------
    class Pipestreams extends Multimix {
      //---------------------------------------------------------------------------------------------------------
      constructor(settings = null) {
        super();
        this.settings = settings;
      }

    };

    // @extend   object_with_class_properties
    Pipestreams.include(require('./basics'));

    Pipestreams.include(require('./logging'));

    Pipestreams.include(require('./main'));

    Pipestreams.include(require('./njs-streams-and-files'));

    Pipestreams.include(require('./sort'));

    Pipestreams.include(require('./_symbols'));

    Pipestreams.include(require('./text'));

    Pipestreams.include(require('./tsv'));

    Pipestreams.include(require('./wye-tee-merge'));

    return Pipestreams;

  }).call(this);

  // @specs    = {}
  // @isa      = Multimix.get_keymethod_proxy @, isa
  // # @validate = Multimix.get_keymethod_proxy @, validate
  // declarations.declare_types.apply @

  //###########################################################################################################
  module.exports = L = new Pipestreams();

  L.Pipestreams = Pipestreams;

}).call(this);
