var ajax = function(params, callback) {
  var $ = require('commonjs-jquery');
  var url = params.url;

  if (ajax.baseUrl) {
    url = ajax.baseUrl + params.url;
  }

  $.ajax({
    type: params.type || 'GET',
    cache: false,
    url: url,
    data: params.data || {},
    dataType: 'json',
    xhrFields: {
      withCredentials: true
    },
    beforeSend : function(req) {
      if (params.username || params.password) {
        var str = (params.username || '') + ':' + (params.password || '');
        req.setRequestHeader('Authorization', "Basic " + btoa(str));
      }
    },
    success: function(data) {
      callback(null, data);
    },
    error: function(xhr) {
      if (!xhr.responseText) {
        callback("failed")
      } else {
        callback(JSON.parse(xhr.responseText));
      }
    }
  });
};

var multiGet = function(paths, callback) {
  var keyValuePairs = Object.keys(paths).map(function(key) {
    return { key: key, value: paths[key] };
  });

  async.map(keyValuePairs.map(function(kp) { return kp.value; }), function(item, callback) {
    ajax({ url: item }, callback);
  }, function(err, data) {
    if (err) {
      callback(err);
      return;
    }
    callback(null, keyValuePairs.reduce(function(acc, item, i) {
      acc[item.key] = data[i];
      return acc;
    }, {}));
  });
};

var getSerenadeView = function(name) {
  var x = argsToArray(document.getElementsByTagName('script')).filter(function(x) {
    return x.dataset.path == '/templates/' + name + '.serenade';
  }).first();

  if (x) {
    return Serenade.view(x.innerHTML);
  }
  throw "fail";
};

var serenata = {
  createModel: function(data) {
    var model = {};
    Serenade.extend(model, Serenade.Properties);
    Object.keys(data).forEach(function(key) {
      if (Array.isArray(data[key])) {
        model.set(key, new Serenade.Collection(data[key]));
      } else {
        model.set(key, data[key]);
      }
    });
    return model;
  },
  evented: function(callback) {
    return function(data, e) {
      target = e.target || e.srcElement
      callback.call(this, null, e);
    };
  }
};
