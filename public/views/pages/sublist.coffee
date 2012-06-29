page
  route: '/:domain/:resource/:baseid/:subresource'
  middleware: [authMiddle]
  sources:
    sub: "/:resource/:baseid/:subresource"
    meta: "/meta/:subresource"
  callback: (args, done) ->
    model = serenadeModel
      appends: [1]
      items: args.sub.map (x) -> local.resourceToItem(args.domain, x, args.subresource)

    controller =
      del: (modelItem)->
        if (confirm("Are you sure you want to delete #{args.subresource}/#{modelItem.id}"))
          ajax
            url: "/#{args.subresource}/#{modelItem.id}"
            type: 'DELETE'
          , (err, data) ->
            alert(err.err) if err
            model.get('items')['delete'](model.get('items').find((x) -> x.id == modelItem.id))

      create: () ->
        runDialog "creation",
          resource: args.subresource
          postUrl: "/#{args.resource}/#{args.baseid}/#{args.subresource}"
          callback: (err, result) ->
            model.get('items').push(local.resourceToItem(args.domain, result, args.subresource))

    renderReplace('dataview', 'list', model, controller)
    done()
