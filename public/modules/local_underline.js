exports.block = function(f) {
  return f();
};
exports.toKeyValues = function(source) {
  return Object.keys(source).map(function(key) {
    return {
      key: key,
      value: source[key]
    };
  });
};
exports.attachEvent = function(obj, eventName, callback) {
  var onEventName = "on" + eventName;
  if (obj.addEventListener) {
    obj.addEventListener(eventName, callback, false);
  } else if (obj.attachEvent) {
    obj.attachEvent(onEventName, callback);
  } else {
    var currentEventHandler = obj[onEventName];
    obj[onEventName] = function() {
      if (typeof currentEventHandler == 'function') {
        currentEventHandler.apply(this, arguments);
      }
      callback.apply(this, arguments);
    };
  }
};
exports.removeChildren = function(element) {
  argsToArray(element.children).forEach(function(x) {
    element.removeChild(x);
  });
};