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

window.replaceHTML = (id, node) ->
  dataview = document.getElementById id
  underline.removeChildren(dataview)
  dataview.appendChild(node)

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
        render('error', { message: 'Access not allowed' })
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
