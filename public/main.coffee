window.facebox = require 'modules/facebox'
underline = require 'modules/local_underline'
require 'modules/local_protoplast'

resourceToItem = (resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: localUrl "/#{res}/#{resourceItem.id}"

render = (view, model, controller) ->
  dataview = document.getElementById 'dataview'
  underline.removeChildren(dataview)
  dataview.appendChild(getSerenadeView(view).render(model, controller || {}))

renderModal = (view, model, controller) ->
  markup = getSerenadeView(view).render(model, controller || {})
  facebox.show(markup, { closeButton: false })

localUrl = (url) ->
  url


handlers = {}

safeMultiGet = (paths, callback) ->
  multiGet paths, (error, data) ->
    if (error)
      render('error', { message: error.err })
    else
      callback(data)

handlers.root = () ->
  safeMultiGet
    url: '/'
  , (data) ->
    model = serenata.createModel
      roots: data.url.roots.map (x) ->
        name: x
        dst: localUrl "/#{x}"

    render('root', model)


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
    sub: "/#{resource}"
    meta: "/meta/#{resource}"
    base: "/"
  , (data) ->
    model = serenata.createModel
      appends: if data.base.roots.contains(resource) then [1] else []
      items: data.sub.map (x) -> resourceToItem(x, resource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.dataset.dbid
        if (confirm("Are you sure you want to delete #{resource}/#{dbid}"))
          ajax
            url: "/#{resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "/#{resource}", data.meta, (err, newObj) ->
          model.get('items').push(resourceToItem(newObj, resource))

    render('list', model, controller)



handlers.sublist = (resource, baseid, subresource) ->
  safeMultiGet
    sub: "/#{resource}/#{baseid}/#{subresource}"
    meta: "/meta/#{subresource}"
  , (data) ->
    model = serenata.createModel
      appends: [1]
      items: data.sub.map (x) -> resourceToItem(x, subresource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.dataset.dbid
        if (confirm("Are you sure you want to delete #{subresource}/#{dbid}"))
          ajax
            url: "/#{subresource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "/#{resource}/#{baseid}/#{subresource}", data.meta, (err, result) ->
          model.get('items').push(resourceToItem(result, subresource))

    render('list', model, controller)


handlers.get = (resource, dbid) ->
  safeMultiGet
    data: "/#{resource}/#{dbid}"
    meta: "/meta/#{resource}"
  , (dd) ->

    metaMap = dd.meta.fields.toMap('name')
    pairs = underline.toKeyValues(dd.data).filter (x) -> !metaMap[x.key].readonly

    model = serenata.createModel
      item: JSON.stringify(dd.data)
      pairs: pairs
      updateDisplay: 'none'
      updateDisplayInv: 'block'
      owned: dd.meta.owns.map (x) ->
        name: x
        dst: localUrl "/#{resource}/#{dbid}/#{x}"

    controller =
      startUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'block'
        model.set 'updateDisplayInv', 'none'

      cancelUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'none'
        model.set 'updateDisplayInv', 'block'

      submitUpdate: serenata.evented (ev, target) ->
        ajax
          url: "/#{resource}/#{dbid}"
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
            url: "/#{resource}/#{dbid}"
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
  goto(method, args)




underline.block () ->

  all = window.location.pathname.split('/').filter (x) -> x

  if all.length == 0
    alert("nothing here")
    return

  domain = all[0]
  ajax.baseUrl = 'http://' + domain
  localUrl = (url) ->
    '/' + domain + url

  parts = all.slice(1)

  if parts.length == 0
    goto 'root', []
  else if parts.length == 1
    goto 'list', parts
  else if parts.length == 2
    goto 'get', parts
  else if parts.length == 3
    goto 'sublist', parts
  else
    alert("Invalid case")
