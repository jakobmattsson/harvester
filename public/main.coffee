window.facebox = require 'modules/facebox'
window.underline = require 'modules/local_underline'
require 'modules/local_protoplast'
window.router = require('path-router').create()

window.parseOrigin = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.protocol + '//' + a.host

window.parsePath = (url) ->
  a = window.document.createElement 'a'
  a.href = url
  a.pathname + a.search + a.hash

window.resourceToItem = (domain, resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{domain}/#{res}/#{resourceItem.id}"

window.stringToNodes = (s) ->
  div = document.createElement('div')
  div.innerHTML = s
  div.childNodes

window.renderHTML = (nodes) ->
  dataview = document.getElementById 'dataview'
  underline.removeChildren(dataview)
  dataview.appendChild(nodes[0])

window.render = (view, model, controller) ->
  dataview = document.getElementById 'dataview'
  underline.removeChildren(dataview)
  dataview.appendChild(getSerenadeView(view).render(model, controller || {}))

window.renderReplace = (id, view, model, controller) ->
  dataview = document.getElementById id
  underline.removeChildren(dataview)
  dataview.appendChild(getSerenadeView(view).render(model, controller || {}))

window.renderModal = (view, model, controller) ->
  markup = getSerenadeView(view).render(model, controller || {})
  facebox.show(markup, { closeButton: false })

window.safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if error
      if error.code == 401
        render('error', 'Access not allowed')
      else
        render('error', { message: error.err || error.code || 'multiGet failed' })
    else
      callback(data)


window.loginDialog = (callback) ->

  mod = serenata.createModel
    username: ''
    password: ''

  cont =
    send: serenata.evented (ev, target) ->
      facebox.close()
      callback(null, { username: mod.username, password: mod.password })

  renderModal 'login', mod, cont






window.creationDialog = (postUrl, metaFields, callback) ->
  fields = metaFields.fields.filter (field) -> !field.readonly

  new_model = serenata.createModel
    required: fields.filter((field) -> field.required).map (field) ->
      title: field.name
      value: field.default
    optional: fields.filter((field) -> !field.required).map (field) ->
      title: field.name
      value: field.default

  new_controller =
    send: serenata.evented (ev, target) ->

      reqArray = argsToArray(new_model.get('required'))
      optArray = argsToArray(new_model.get('optional'))

      all = reqArray.concat(optArray)
      submitData = all.toMap('title', 'value')

      ajax
        url: postUrl
        type: 'POST'
        data: submitData
      , (err, data) ->
        if err
          alert(if err.err? then err.err else "Could not create the item")
        else
          facebox.close()
          callback(null, data)

  renderModal('new', new_model, new_controller)






window.auth =
  set: (domain, username, password) ->
    cookies.set("harvester-#{domain}", { username: username, password: password })
    ajax.username = username
    ajax.password = password
  get: (domain) -> cookies.get("harvester-#{domain}") || {}
  clear: (domain) -> cookies.set("harvester-#{domain}")


setTimeout ->
  domain = window.location.pathname.split('/').compact(true).first()
  ajax.baseUrl = 'http://' + domain if domain?

  authdata = auth.get(domain)
  ajax.username = authdata.username
  ajax.password = authdata.password

  router.trigger(window.location.pathname)
, 1