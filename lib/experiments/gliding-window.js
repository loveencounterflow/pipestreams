// Generated by CoffeeScript 2.3.1
(function() {
  //-----------------------------------------------------------------------------------------------------------
  this.$gliding_window = function(width, method) {
    var push, section, send;
    if ((CND.type_of(width)) !== 'number') {
      throw new Error(`µ32363 expected a number, got a ${type}`);
    }
    section = [];
    send = null;
    //.........................................................................................................
    push = function(x) {
      var R;
      section.push(x);
      R = (function() {
        var results;
        results = [];
        while (section.length > width) {
          results.push(send(section.shift()));
        }
        return results;
      })();
      return null;
    };
    //.........................................................................................................
    return this.$('null', (new_data, send_) => {
      send = send_;
      if (new_data != null) {
        push(new_data);
        if (section.length >= width) {
          method(section);
        }
      } else {
        while (section.length > 0) {
          send(section.shift());
        }
        send(null);
      }
      return null;
    });
  };

}).call(this);

//# sourceMappingURL=gliding-window.js.map