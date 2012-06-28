window.authMiddle = 
  callback: (args, done) ->
    model2 = serenadeModel
      username: auth.get(args.domain).username

    cont =
      login: ->
        runDialog 'login',
          callback: (err, data) ->
            auth.set(args.domain, data.username, data.password)
            model2.username = data.username

      logout: ->
        auth.clear(args.domain)
        model2.username = null

    renderReplace('auth', 'auth', model2, cont)
    done()
