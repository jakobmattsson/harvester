router.register '/:domain/:resource/:baseid', (args) ->
  domain = args.domain
  resource = args.resource
  dbid = args.baseid
  safeMultiGet
    data: "/#{resource}/#{dbid}"
    meta: "/meta/#{resource}"
  , (dd) ->

    metaMap = dd.meta.fields.toMap('name')
    pairs = underline.toKeyValues(dd.data).filter (x) -> !metaMap[x.key].readonly

    model = serenata.createModel
      item: JSON.stringify(dd.data)
      pairs: pairs
      updateDisplay: 'none'
      updateDisplayInv: 'block'
      owned: dd.meta.owns.map (x) ->
        name: x
        dst: "/#{domain}/#{resource}/#{dbid}/#{x}"

    controller =
      startUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'block'
        model.set 'updateDisplayInv', 'none'

      cancelUpdate: serenata.evented (ev, target) ->
        model.set 'updateDisplay', 'none'
        model.set 'updateDisplayInv', 'block'

      submitUpdate: serenata.evented (ev, target) ->
        ajax
          url: "/#{resource}/#{dbid}"
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
            url: "/#{resource}/#{dbid}"
            type: 'DELETE'
          , (err, data) ->
            if err
              alert(err.err)
            else
              router.trigger("/#{domain}/#{resource}")

    render('get', model, controller)

