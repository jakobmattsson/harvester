page
  route: '/:domain/:resource'
  middleware: [authMiddle]
  sources:
    sub: "/:resource"
    meta: "/meta/:resource"
    base: "/"
  callback: (args, done) ->
    model = serenadeModel
      appends: if _(args.base.roots).contains(args.resource) then [1] else []
      items: args.sub.map (x) -> local.resourceToItem(args.domain, x, args.resource)

    controller =
      del: (modelItem) ->
        if (confirm("Are you sure you want to delete #{args.resource}/#{modelItem.id}"))
          ajax
            url: "/#{args.resource}/#{modelItem.id}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == modelItem.id))

      create: ->
        runDialog "creation",
          resource: args.resource
          postUrl: "/#{args.resource}"
          callback: (err, newObj) ->
            model.get('items').push(local.resourceToItem(args.domain, newObj, args.resource))

    renderReplace('dataview', 'list', model, controller)
    done()
