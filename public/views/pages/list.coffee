page
  route: '/:domain/:resource'
  middleware: [authMiddle]
  sources:
    sub: "/:resource"
    meta: "/meta/:resource"
    base: "/"
  callback: (args, done) ->
    model = serenadeModel
      appends: if args.base.roots.contains(args.resource) then [1] else []
      items: args.sub.map (x) -> resourceToItem(args.domain, x, args.resource)

    controller =
      del: (ev, target) ->
        dbid = target.getAttribute("data-dbid")
        if (confirm("Are you sure you want to delete #{args.resource}/#{dbid}"))
          ajax
            url: "/#{args.resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == dbid))

      create: ->
        runDialog "creation",
          resource: args.resource
          postUrl: "/#{args.resource}"
          callback: (err, newObj) ->
            model.get('items').push(resourceToItem(args.domain, newObj, args.resource))

    renderReplace('dataview', 'list', model, controller)
    done()
