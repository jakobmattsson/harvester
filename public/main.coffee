window.facebox = require 'modules/facebox'

resourceToItem = (resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{res}/#{resourceItem.id}"

render = (view, model, controller) ->
  removeChildren(document.body)
  document.body.appendChild(getSerenadeView(view).render(model, controller || {}))

renderModal = (view, model, controller) ->
  markup = getSerenadeView(view).render(model, controller || {})
  facebox.show(markup, { closeButton: false })

window.oldAjax = window.ajax
window.ajax = (params, callback) ->
  # params.username = 'admin'
  # params.password = 'admin'
  oldAjax.call(this, params, callback)
  




handlers = {}
baseUrl = 'http://sally.jdevab.com'
# baseUrl = 'http://localhost:3000'

safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if (error)
      render('error', { message: error.err })
    else
      callback(data)

handlers.start = () ->
  safeMultiGet
    url: baseUrl
  , (data) ->
    model = serenata.createModel
      roots: data.url.roots.map (x) ->
        name: x
        dst: "/#{x}"

    render('start', model)


creationDialog = (postUrl, metaFields, callback) ->
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


handlers.list = (resource) ->
  safeMultiGet
    sub: "#{baseUrl}/#{resource}"
    meta: "#{baseUrl}/meta/#{resource}"
    base: "#{baseUrl}"
  , (data) ->
    model = serenata.createModel
      appends: if data.base.roots.contains(resource) then [1] else []
      items: data.sub.map (x) -> resourceToItem(x, resource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.dataset.dbid
        if (confirm("Are you sure you want to delete #{resource}/#{dbid}"))
          ajax
            url: "#{baseUrl}/#{resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "#{baseUrl}/#{resource}", data.meta, (err, newObj) ->
          model.get('items').push(resourceToItem(newObj, resource))

    render('list', model, controller)



handlers.sublist = (resource, baseid, subresource) ->
  safeMultiGet
    sub: "#{baseUrl}/#{resource}/#{baseid}/#{subresource}"
    meta: "#{baseUrl}/meta/#{subresource}"
  , (data) ->
    model = serenata.createModel
      appends: [1]
      items: data.sub.map (x) -> resourceToItem(x, subresource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.dataset.dbid
        if (confirm("Are you sure you want to delete #{subresource}/#{dbid}"))
          ajax
            url: "#{baseUrl}/#{subresource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "#{baseUrl}/#{resource}/#{baseid}/#{subresource}", data.meta, (err, result) ->
          model.get('items').push(resourceToItem(result, subresource))

    render('list', model, controller)


handlers.get = (resource, dbid) ->
  safeMultiGet
    data: "#{baseUrl}/#{resource}/#{dbid}"
    meta: "#{baseUrl}/meta/#{resource}"
  , (dd) ->

    metaMap = dd.meta.fields.toMap('name')
    pairs = toKeyValues(dd.data).filter (x) -> !metaMap[x.key].readonly

    model = serenata.createModel
      item: JSON.stringify(dd.data)
      pairs: pairs
      updateDisplay: 'none'
      updateDisplayInv: 'block'
      owned: dd.meta.owns.map (x) ->
        name: x
        dst: "/#{resource}/#{dbid}/#{x}"

    controller =
      startUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'block'
        model.set 'updateDisplayInv', 'none'

      cancelUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'none'
        model.set 'updateDisplayInv', 'block'

      submitUpdate: serenata.evented (ev, target) ->
        ajax
          url: "#{baseUrl}/#{resource}/#{dbid}"
          type: 'PUT'
          data: pairs.toMap('key', 'value')
        , (err, data) ->
          if (err)
            alert(err.err)
          else
            model.set('item', JSON.stringify(data))

      del: serenata.evented (ev, target) ->
        if (confirm("Are you sure you want to delete #{resource}/#{dbid}"))
          ajax
            url: "#{baseUrl}/#{resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            if err
              alert(err.err)
            else
              historyReplace('list', [resource])

    render('get', model, controller)


goto = (method, args) ->
  handlers[method].apply(null, args)

historyReplace = (method, args) ->
  history.replaceState(null, "Harvester", '/' + args.join('/'))
  goto(method, args)




# opraTags = argsToArray(document.getElementsByTagName('script')).filter (x) ->
#   x.type == 'text/x-opra'
# 
# opraTags.forEach (x) ->
#   path = x.dataset.path
#   name = path.replace('/templates/', '').replace('.serenade', '')
#   Serenade.view(name, x.innerHTML)


parts = window.location.pathname.split('/').filter (x) -> x

if parts.length == 0
  goto 'start', []
else if parts.length == 1
  goto 'list', parts
else if parts.length == 2
  goto 'get', parts
else if parts.length == 3
  goto 'sublist', parts
else
  alert("Invalid case")
