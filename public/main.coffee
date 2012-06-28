window.underline = require 'modules/local_underline'
window.bunderline = require 'modules/local_underline_browser'
require 'modules/local_protoplast'

pagemod = require 'modules/page'
router = require('path-router').create()

getSerenadeView = (name) ->
  matches = argsToArray(document.getElementsByTagName('script')).filter (x) ->
    x.getAttribute("data-path") == '/templates/' + name + '.serenade';

  x = matches.first()

  if x
    return Serenade.view(x.innerHTML)
  else
    throw "fail"

window.renderReplace = (id, view, model, controller) ->
  node = renderSerenade(getSerenadeView(view), model, controller)
  underline.replaceChildren id, node

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








setTimeout ->
  domain = window.location.pathname.split('/').compact(true).first()
  ajax.baseUrl = 'http://' + domain if domain?

  authdata = auth.get(domain)
  ajax.username = authdata.username
  ajax.password = authdata.password

  router.trigger(window.location.pathname)
, 1









wrapController = (ctrl) ->
  Object.keys(ctrl).forEach (key) ->
    callback = ctrl[key]
    ctrl[key] = (data, e) ->
      callback.call(this, null, e)
  ctrl

renderSerenade = (view, model, controller) ->
  view.render(model, wrapController(controller || {}))

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
  dialogRouter = require('modules/router').create() # replace with path-router
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
