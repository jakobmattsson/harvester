exports.parseOrigin = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.protocol + '//' + a.host

exports.parsePath = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.pathname + a.search + a.hash
