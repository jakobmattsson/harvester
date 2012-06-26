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

  if (bunderline.parseOrigin(url) == currentOrigin) {
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
