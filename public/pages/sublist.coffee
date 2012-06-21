router.register '/:domain/:resource/:baseid/:subresource', (args) ->
  resource = args.resource
  baseid = args.baseid
  subresource = args.subresource
  safeMultiGet
    sub: "/#{resource}/#{baseid}/#{subresource}"
    meta: "/meta/#{subresource}"
  , (data) ->
    model = serenata.createModel
      appends: [1]
      items: data.sub.map (x) -> resourceToItem(args.domain, x, subresource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.getAttribute("dbid")
        if (confirm("Are you sure you want to delete #{subresource}/#{dbid}"))
          ajax
            url: "/#{subresource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "/#{resource}/#{baseid}/#{subresource}", data.meta, (err, result) ->
          model.get('items').push(resourceToItem(args.domain, result, subresource))

    render('list', model, controller)
