page
  route: '/:domain/:resource/:baseid/:subresource'
  middleware: [authMiddle]
  sources:
    sub: "/:resource/:baseid/:subresource"
    meta: "/meta/:subresource"
  callback: (args, done) ->
    model = serenata.createModel
      appends: [1]
      items: args.sub.map (x) -> resourceToItem(args.domain, x, args.subresource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.getAttribute("dbid")
        if (confirm("Are you sure you want to delete #{args.subresource}/#{dbid}"))
          ajax
            url: "/#{args.subresource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "/#{args.resource}/#{args.baseid}/#{args.subresource}", args.meta, (err, result) ->
          model.get('items').push(resourceToItem(args.domain, result, args.subresource))

    render('list', model, controller)
    done()
