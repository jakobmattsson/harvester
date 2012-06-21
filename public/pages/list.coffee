router.register '/:domain/:resource', (args) ->
  resource = args.resource
  safeMultiGet
    sub: "/#{resource}"
    meta: "/meta/#{resource}"
    base: "/"
  , (data) ->
    model = serenata.createModel
      appends: if data.base.roots.contains(resource) then [1] else []
      items: data.sub.map (x) -> resourceToItem(args.domain, x, resource)

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
          model.get('items').push(resourceToItem(args.domain, newObj, resource))

    render('list', model, controller)
    
    






router.register '/:domain/apa', (args) ->
  console.log("running apa")
  resource = args.resource
  safeMultiGet
    sub: "/admins"
  , (data) ->
    console.log("data", data)
