Array.prototype.toMap = function(keySelector, valueSelector) {
  if (typeof keySelector == 'string') {
    var keySelectorString = keySelector;
    keySelector = function(e) {
      return e[keySelectorString];
    };
  }

  if (typeof valueSelector == 'string') {
    var valueSelectorString = valueSelector;
    valueSelector = function(e) {
      return e[valueSelectorString];
    };
  }

  if (typeof valueSelector == 'undefined') {
    valueSelector = function(e) {
      return e;
    };
  }

  var result = {};
  this.forEach(function(e) {
    result[keySelector(e)] = valueSelector(e);
  });
  return result;
};
