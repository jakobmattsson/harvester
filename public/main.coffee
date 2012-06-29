require 'protoplast'
require 'modules/local_protoplast'

window.π = require 'piescore'
_.extend(π, require 'modules/local_piescore')

window.local = require 'modules/local'

pagemod = require 'modules/page'
router = require('path-router').create()

getSerenadeView = (name) ->
  matches = π.argsToArray(document.getElementsByTagName('script')).filter (x) ->
    x.getAttribute("data-path") == '/views/templates/' + name + '.serenade';

  x = matches.first()

  if x
    return Serenade.view(x.innerHTML)
  else
    throw "fail"

window.renderReplace = (id, view, model, controller) ->
  node = renderSerenade(getSerenadeView(view), model, controller)
  π.replaceChildren id, node

safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if error
      if error.code == 401
        renderReplace('dataview', 'error', { message: 'Access not allowed' })
      else
        renderReplace('dataview', 'error', { message: error.err || error.code || 'multiGet failed' })
    else
      callback(data)

multiGet = (paths, callback) ->
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




window.ajax = (params, callback) ->
  url = params.url
  qs = {
    metabody: true
  }

  if params.baseUrl && params.url.indexOf('http://') == -1
    url = params.baseUrl + params.url

  urlOrigin = π.parseOrigin(url)

  viaduct.host(urlOrigin + '/viaduct.html')


  # Add on the querystring
  querystring = Object.keys(qs).map((key) -> key + "=" + qs[key]).join("&")
  if url.indexOf('?') == -1
    querystring = "?" + querystring
  else
    querystring = "&" + querystring
  url += querystring

  # Perform the request
  viaduct.request
    json: params.data || {}
    method: params.type || 'GET'
    auth: { username: params.username, password: params.password }
    url: url
  , (err, response, body) ->
    if err || response.statusCode != 200
      callback({ msg: 'Failed' })
    else if body.code != 200
      callback({ code: body.code })
    else
      callback(null, body.body)














ajaxOld = window.ajax
window.ajax = (params, callback) ->

  domain = window.location.pathname.split('/').compact(true).first()
  authdata = local.auth.get(domain)

  username = authdata.username
  password = authdata.password
  baseUrl = 'http://' + domain if domain?

  ajaxOld(_.extend({}, params, { username: username, password: password, baseUrl: baseUrl }), callback)






setTimeout ->
  pathname = window.location.pathname
  pathname = pathname.slice(0, -1) if pathname.last() == '/' && pathname.length > 1
  router.trigger pathname
, 1









renderSerenade = (view, model, controller) ->
  view.render(model, controller || {})

window.serenadeModel = (data) ->
  model = Serenade({})
  Object.keys(data).forEach (key) ->
    if Array.isArray(data[key])
      model.set(key, new Serenade.Collection(data[key]))
    else
      model.set(key, data[key])
  model


# en "route" är något som ska exekveras när en viss route "anropas"

# en "page"-route använder urlen för att anropa
# en "dialog"-route använder en manuell funktion

# ingen av dom gör något mer än det som angivits i deras callbacks, om man inte använder en utbyggd variant



window.page = (params) -> router.register params.route, params.callback
window.page = pagemod.sourceCreator(window.page, safeMultiGet)
window.page = pagemod.middlewareCreator(window.page)
window.page = pagemod.nodeReplacer(window.page, {
  nodeIdentifier: 'serenadeReplace'
})
window.page = pagemod.viewCreator(window.page, {
  viewIdentifier: 'serenadeView'
  compileView: (text) ->
    Serenade.view(text)
  render: (compiledView, data) ->
    renderSerenade(compiledView, data.model, data.controller)
})


do ->
  dialogRouter = require('path-router').create()
  facebox = require 'modules/facebox'


  window.dialog = (params) ->
    dialogRouter.register params.route, params.callback

  window.runDialog = (name, args, done) ->
    dialogRouter.trigger name, done, args


  window.dialog = pagemod.sourceCreator(window.dialog, safeMultiGet)
  window.dialog = pagemod.modalHtml(window.dialog, {
    show: (html) -> facebox.show(html, { closeButton: false })
    close: () -> facebox.close()
  })
  window.dialog = pagemod.viewCreator(window.dialog, {
    viewIdentifier: 'serenadeView'
    compileView: (text) ->
      Serenade.view(text)
    render: (view, data) ->
      renderSerenade(view, data.model, data.controller)
  })
