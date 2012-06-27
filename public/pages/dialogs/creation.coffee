dialog
  route: 'creation'
  serenadeView: '''
    div
  
      h3 "Required fields"
      - collection @required
        div
          span @title
          input[type="text" binding:keyup=@value]
  
      h3 "Optional fields"
      - collection @optional
        div
          span @title
          input[type="text" binding:keyup=@value]
  
      div
        button[event:click=send!] "submit"
  '''
  sources:
    meta: "/meta/:resource"
  callback: (args, done) ->
    fields = args.meta.fields.filter (field) -> !field.readonly

    new_model = serenata.createModel
      required: fields.filter((field) -> field.required).map (field) ->
        title: field.name
        value: field.default
      optional: fields.filter((field) -> !field.required).map (field) ->
        title: field.name
        value: field.default

    new_controller =
      send: serenata.evented (ev, target) ->

        reqArray = argsToArray(new_model.get('required'))
        optArray = argsToArray(new_model.get('optional'))

        all = reqArray.concat(optArray)
        submitData = all.toMap('title', 'value')

        ajax
          url: args.postUrl
          type: 'POST'
          data: submitData
        , (err, data) ->
          if err
            alert(if err.err? then err.err else "Could not create the item")
          else
            args.callback(null, data)

    done({ model: new_model, controller: new_controller })
