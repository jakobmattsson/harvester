var ajax = function(params, callback) {
  var url = params.url;
  var currentOrigin = location.protocol + '//' + location.host;

  var baseUrl = params.baseUrl || ajax.baseUrl;

  if (ajax.username) {
    params.username = ajax.username;
    params.password = ajax.password;
  }

  if (baseUrl && params.url.indexOf('http://') === -1) {
    url = baseUrl + params.url;
  }

  var reqMet = null;

  if (parseOrigin(url) == currentOrigin) {
    reqMet = request;
  } else {
    if (baseUrl) {
      viaduct.host(baseUrl + '/viaduct.html');
    }
    reqMet = viaduct.request;
  }

  var qs = {
    metabody: true
  };

  var querystring = Object.keys(qs).map(function(key) { return key + "=" + qs[key]; }).join("&");
  if (url.indexOf('?') === -1) {
    querystring = "?" + querystring;
  } else {
    querystring = "&" + querystring;
  }

  url += querystring;

  reqMet({ // maybe use browser-request directly
    json: params.data || {},
    method: params.type || 'GET',
    auth: { username: params.username, password: params.password },
    url: url
  }, function(err, response, body) {
    console.log(response);
    if (err || response.statusCode != 200) {
      callback({ msg: 'Failed' });
    } else if (body.code != 200) {
      callback({ code: body.code })
    } else {
      callback(null, body.body);
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
    return x.getAttribute("data-path") == '/templates/' + name + '.serenade';
  }).first();

  if (x) {
    return Serenade.view(x.innerHTML);
  }
  throw "fail";
};

var serenata = {
  createModel: function(data) {
    var model = Serenade({});
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
