cookies = require 'jakobmattsson-client-cookies'

exports.resourceToItem = (domain, resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{domain}/#{res}/#{resourceItem.id}"

exports.auth =
  set: (domain, username, password) ->
    cookies.set("harvester-#{domain}", { username: username, password: password })
  get: (domain) -> cookies.get("harvester-#{domain}") || {}
  clear: (domain) ->
    cookies.set("harvester-#{domain}")
