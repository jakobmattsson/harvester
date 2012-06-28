window.resourceToItem = (domain, resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{domain}/#{res}/#{resourceItem.id}"

window.auth =
  set: (domain, username, password) ->
    cookies.set("harvester-#{domain}", { username: username, password: password })
    ajax.username = username
    ajax.password = password
  get: (domain) -> cookies.get("harvester-#{domain}") || {}
  clear: (domain) ->
    cookies.set("harvester-#{domain}")
    ajax.username = null
    ajax.password = null