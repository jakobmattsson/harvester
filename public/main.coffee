resourceToItem = (resourceItem, res) ->
  id: resourceItem.id
  string: JSON.stringify(resourceItem)
  dst: "/#{res}/#{resourceItem.id}"

render = (view, model, controller) ->
  removeChildren(document.body)
  document.body.appendChild(getSerenadeView(view).render(model, controller || {}))

handlers = {}
baseUrl = 'http://localhost:3000'

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
        alert("ask for some data to put in to the object here... bla bla bla")

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
        alert("ask for some data to put in to the object here... bla bla bla");

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
    model = serenata.createModel
      item: JSON.stringify(dd.data)
      owned: dd.meta.owns.map (x) ->
        name: x
        dst: "/#{resource}/#{dbid}/#{x}"

    controller =
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


historyReplace = (method, args) ->
  history.replaceState(null, "Harvester", '/' + args.join('/'))
  handlers[method].apply(null, args)




parts = window.location.pathname.split('/').filter (x) -> x

if parts.length == 0
  historyReplace 'start', []
else if parts.length == 1
  historyReplace 'list', parts
else if parts.length == 2
  historyReplace 'get', parts
else if parts.length == 3
  historyReplace 'sublist', parts
else
  alert("Invalid case")
