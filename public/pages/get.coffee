page
  route: '/:domain/:resource/:baseid'
  sources:
    data: "/:resource/:baseid"
    meta: "/meta/:resource"
  callback: (args, done) ->
    metaMap = args.meta.fields.toMap('name')
    pairs = underline.toKeyValues(args.data).filter (x) -> !metaMap[x.key].readonly

    model = serenata.createModel
      item: JSON.stringify(args.data)
      pairs: pairs
      updateDisplay: 'none'
      updateDisplayInv: 'block'
      owned: args.meta.owns.map (x) ->
        name: x
        dst: "/#{args.domain}/#{args.resource}/#{args.baseid}/#{x}"

    controller =
      startUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'block'
        model.set 'updateDisplayInv', 'none'

      cancelUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'none'
        model.set 'updateDisplayInv', 'block'

      submitUpdate: serenata.evented (ev, target) ->
        ajax
          url: "/#{args.resource}/#{args.baseid}"
          type: 'PUT'
          data: pairs.toMap('key', 'value')
        , (err, data) ->
          if (err)
            alert(err.err)
          else
            model.set('item', JSON.stringify(data))

      del: serenata.evented (ev, target) ->
        if (confirm("Are you sure you want to delete #{args.resource}/#{args.baseid}"))
          ajax
            url: "/#{args.resource}/#{args.baseid}"
            type: 'DELETE'
          , (err, data) ->
            if err
              alert(err.err)
            else
              router.trigger("/#{args.domain}/#{args.resource}")

    render('get', model, controller)
    done()
