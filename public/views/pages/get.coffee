page
  route: '/:domain/:resource/:baseid'
  middleware: [authMiddle]
  sources:
    data: "/:resource/:baseid"
    meta: "/meta/:resource"
  serenadeReplace: 'dataview'
  serenadeView: '''
    div
      div "Here is the item"
      div @item
      button[event:click=del!] "delete"

      ul
        - collection @owned
          li
            a[href=@dst] @name

      button[event:click=startUpdate! style:display=@updateDisplayInv] "change"

      div[style:display=@updateDisplay]
        div
          - collection @pairs
            div
              span @key
              input[type="text" binding:keyup=@value]

        button[event:click=cancelUpdate!] "cancel"
        button[event:click=submitUpdate!] "submit"
  '''
  callback: (args, done) ->
    metaMap = args.meta.fields.toMap('name')
    pairs = π.toKeyValues(args.data).filter (x) -> !metaMap[x.key].readonly

    model = serenadeModel
      item: JSON.stringify(args.data)
      pairs: pairs
      updateDisplay: 'none'
      updateDisplayInv: 'block'
      owned: args.meta.owns.map (x) ->
        name: x
        dst: "/#{args.domain}/#{args.resource}/#{args.baseid}/#{x}"

    controller =
      startUpdate: ->
        model.set 'updateDisplay', 'block'
        model.set 'updateDisplayInv', 'none'

      cancelUpdate: ->
        model.set 'updateDisplay', 'none'
        model.set 'updateDisplayInv', 'block'

      submitUpdate: ->
        ajax
          url: "/#{args.resource}/#{args.baseid}"
          type: 'PUT'
          data: pairs.toMap('key', 'value')
        , (err, data) ->
          if (err)
            alert(err.err)
          else
            model.set('item', JSON.stringify(data))

      del: ->
        if (confirm("Are you sure you want to delete #{args.resource}/#{args.baseid}"))
          ajax
            url: "/#{args.resource}/#{args.baseid}"
            type: 'DELETE'
          , (err, data) ->
            if err
              alert(err.err)
            else
              window.location = "/#{args.domain}/#{args.resource}"

    done({ model: model, controller: controller })
