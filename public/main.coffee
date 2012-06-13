resourceToItem = (resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{res}/#{resourceItem.id}"

render = (view, model, controller) ->
  removeChildren(document.body)
  document.body.appendChild(getSerenadeView(view).render(model, controller || {}))

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


handlers.list = (resource) ->
  safeMultiGet
    sub: "#{baseUrl}/#{resource}"
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
        # alert("ask for some data to put in to the object here... bla bla bla")

        ajax
          url: "#{baseUrl}/#{resource}"
          type: 'POST'
        , (err, data) ->
          if (err)
            alert("could not create the item")
          else
            model.get('items').push(resourceToItem(data, resource))

    render('list', model, controller)



handlers.sublist = (resource, baseid, subresource) ->
  safeMultiGet
    sub: "#{baseUrl}/#{resource}/#{baseid}/#{subresource}"
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
        # alert("ask for some data to put in to the object here... bla bla bla");

        ajax
          url: "#{baseUrl}/#{resource}/#{baseid}/#{subresource}"
          type: 'POST'
          data: { }
        , (err, data) ->
          if (err)
            alert("could not create the item")
          else
            model.get('items').push(resourceToItem(data, subresource))

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
