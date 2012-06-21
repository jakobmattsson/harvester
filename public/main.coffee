window.facebox = require 'modules/facebox'
window.underline = require 'modules/local_underline'
require 'modules/local_protoplast'
window.router = require('path-router').create()

window.resourceToItem = (domain, resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{domain}/#{res}/#{resourceItem.id}"

window.render = (view, model, controller) ->
  dataview = document.getElementById 'dataview'
  underline.removeChildren(dataview)
  dataview.appendChild(getSerenadeView(view).render(model, controller || {}))

window.renderModal = (view, model, controller) ->
  markup = getSerenadeView(view).render(model, controller || {})
  facebox.show(markup, { closeButton: false })

window.safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if (error)
      render('error', { message: error.err || 'multiGet failed' })
    else
      callback(data)






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







setTimeout ->
  domain = window.location.pathname.split('/').compact(true).first()
  ajax.baseUrl = 'http://' + domain if domain?
  router.trigger(window.location.pathname)
, 1