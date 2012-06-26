window.facebox = require 'modules/facebox'
window.underline = require 'modules/local_underline'
window.bunderline = require 'modules/local_underline_browser'
require 'modules/local_protoplast'

pagemod = require 'modules/page'
router = require('path-router').create()

window.resourceToItem = (domain, resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{domain}/#{res}/#{resourceItem.id}"

window.renderReplace = (id, view, model, controller) ->
  node = getSerenadeView(view).render(model, controller || {})
  underline.replaceChildren id, node

window.renderModal = (view, model, controller) ->
  markup = getSerenadeView(view).render(model, controller || {})
  facebox.show(markup, { closeButton: false })

window.safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if error
      if error.code == 401
        renderReplace('dataview', 'error', { message: 'Access not allowed' })
      else
        renderReplace('dataview', 'error', { message: error.err || error.code || 'multiGet failed' })
    else
      callback(data)







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


setTimeout ->
  domain = window.location.pathname.split('/').compact(true).first()
  ajax.baseUrl = 'http://' + domain if domain?

  authdata = auth.get(domain)
  ajax.username = authdata.username
  ajax.password = authdata.password

  router.trigger(window.location.pathname)
, 1







window.multiGet = (paths, callback) ->
  keyValuePairs = Object.keys(paths).map (key) ->
    key: key
    value: paths[key]

  async.map keyValuePairs.map((kp) -> kp.value), (item, callback) ->
    ajax({ url: item }, callback)
  , (err, data) ->
    if err
      callback(err)
      return
    callback null, keyValuePairs.reduce (acc, item, i) ->
      acc[item.key] = data[i]
      acc
    , {}



window.getSerenadeView = (name) ->
  matches = argsToArray(document.getElementsByTagName('script')).filter (x) ->
    x.getAttribute("data-path") == '/templates/' + name + '.serenade';

  x = matches.first()

  if x
    return Serenade.view(x.innerHTML)
  else
    throw "fail"


window.serenata =
  createModel: (data) ->
    model = Serenade({})
    Object.keys(data).forEach (key) ->
      if Array.isArray(data[key])
        model.set(key, new Serenade.Collection(data[key]))
      else
        model.set(key, data[key])
    model

  evented: (callback) ->
    (data, e) ->
      target = e.target || e.srcElement
      callback.call(this, null, e)





window.page = (params) -> router.register params.route, params.callback
window.page = pagemod.sourceCreator(window.page, safeMultiGet)
window.page = pagemod.middlewareCreator(window.page)
window.page = pagemod.viewCreator(window.page)





