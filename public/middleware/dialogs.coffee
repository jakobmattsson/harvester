window.loginDialog = (callback) ->

  mod = serenata.createModel
    username: ''
    password: ''

  cont =
    send: serenata.evented (ev, target) ->
      facebox.close()
      callback(null, { username: mod.username, password: mod.password })

  renderModal 'login', mod, cont



window.creationDialog = (postUrl, metaFields, callback) ->
  fields = metaFields.fields.filter (field) -> !field.readonly

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
        url: postUrl
        type: 'POST'
        data: submitData
      , (err, data) ->
        if err
          alert(if err.err? then err.err else "Could not create the item")
        else
          facebox.close()
          callback(null, data)

  renderModal('new', new_model, new_controller)
