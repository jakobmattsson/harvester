page
  route: '/:domain/:resource'
  middleware: [authMiddle]
  sources:
    sub: "/:resource"
    meta: "/meta/:resource"
    base: "/"
  callback: (args, done) ->
    model = serenata.createModel
      appends: if args.base.roots.contains(args.resource) then [1] else []
      items: args.sub.map (x) -> resourceToItem(args.domain, x, args.resource)

    controller =
      del: serenata.evented (ev, target) ->
        dbid = target.getAttribute("dbid")
        if (confirm("Are you sure you want to delete #{args.resource}/#{dbid}"))
          ajax
            url: "/#{args.resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: serenata.evented (ev, target) ->
        creationDialog "/#{args.resource}", args.meta, (err, newObj) ->
          model.get('items').push(resourceToItem(args.domain, newObj, args.resource))

    render('list', model, controller)
    done()
