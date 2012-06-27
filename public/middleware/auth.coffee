window.authMiddle = 
  when: 'any'
  what: (args) ->
    model2 = serenata.createModel
      username: auth.get(args.domain).username

    cont =
      login: serenata.evented () ->

        runDialog 'login',
          callback: (err, data) ->
            auth.set(args.domain, data.username, data.password)
            model2.username = data.username

      logout: serenata.evented () ->
        auth.clear(args.domain)
        model2.username = null

    renderReplace('auth', 'auth', model2, cont)
