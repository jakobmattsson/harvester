window.π = require 'piescore'
_.mixin(require 'underscore.plus')

window.local = require 'modules/local'





# Common helpers for the setup below
pagemod = require 'path-router-decorator'
router = require('path-router').create()
Serenade = require('jakobmattsson-serenade')
renderSerenade = (view, model, controller) -> view.render(model, controller || {})
nextTick = (f) -> setTimeout(f, 1)
safeMultiGet = (paths, callback) ->
  f = (item, callback) -> ajax((if typeof item == 'string' then { url: item } else item), callback)
  π.mapObjectAsync paths, f, (error, data) ->
    if error
      if error.code == 401
        renderReplace('dataview', 'error', { message: 'Access not allowed' })
      else
        renderReplace('dataview', 'error', { message: error.err || error.code || 'multiGet failed' })
    else
      callback(data)



# The method "serenadeModel"
window.serenadeModel = π.submodules.serenade(Serenade).serenadeModel



# The method "renderReplace"
do ->
  getSerenadeView = (name) ->
    matches = _(document.getElementsByTagName('script')).toArray().filter (x) ->
      x.getAttribute("data-path") == '/views/templates/' + name + '.serenade';

    x = _(matches).first()

    if x
      return Serenade.view(x.innerHTML)
    else
      throw "fail"

  window.renderReplace = (id, view, model, controller) ->
    node = renderSerenade(getSerenadeView(view), model, controller)
    π.replaceChildren id, node



# The method "ajax"
do ->
  viaduct = require 'viaduct-client'
  viaductRequest = π.submodules.viaduct(viaduct).request
  window.ajax = (params, callback) ->

    domain = _(window.location.pathname.split('/')).chain().compact().first().value()
    authdata = local.auth.get(domain)

    username = authdata.username
    password = authdata.password
    baseUrl = 'http://' + domain if domain?

    viaductRequest(_.extend({}, params, { username: username, password: password, origin: baseUrl }), callback)



# The method "page"
do ->
  window.page = (params) -> router.register params.route, params.callback
  window.page = pagemod.source(window.page, safeMultiGet)
  window.page = pagemod.middleware(window.page)
  window.page = pagemod.nodeReplacer(window.page, {
    nodeIdentifier: 'serenadeReplace'
  })
  window.page = pagemod.view(window.page, {
    viewIdentifier: 'serenadeView'
    compileView: (text) ->
      Serenade.view(text)
    render: (compiledView, data) ->
      renderSerenade(compiledView, data.model, data.controller)
  })



# The methods "dialog" and "runDialog"
do ->
  dialogRouter = require('path-router').create()
  facebox = require 'modules/facebox'

  window.runDialog = (name, args, done) -> dialogRouter.trigger name, done, args

  window.dialog = (params) -> dialogRouter.register params.route, params.callback
  window.dialog = pagemod.source(window.dialog, safeMultiGet)
  window.dialog = pagemod.modalHtml(window.dialog, {
    show: (html) -> facebox.show(html, { closeButton: false })
    close: () -> facebox.close()
  })
  window.dialog = pagemod.view(window.dialog, {
    viewIdentifier: 'serenadeView'
    compileView: (text) ->
      Serenade.view(text)
    render: (view, data) ->
      renderSerenade(view, data.model, data.controller)
  })



# Starting the URL-routing
nextTick ->
  pathname = window.location.pathname
  pathname = pathname.slice(0, -1) if _(pathname).last() == '/' && pathname.length > 1
  router.trigger pathname
