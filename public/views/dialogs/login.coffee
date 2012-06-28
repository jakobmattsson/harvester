dialog
  route: 'login'
  serenadeView: '''
    div

      h3 "Login data"
      div
        span "Username"
        input[type="text" binding:keyup=@username]
      div
        span "Password"
        input[type="text" binding:keyup=@password]

      div
        button[event:click=send!] "Log in"
  '''
  callback: (args, done) ->
    mod = serenadeModel
      username: ''
      password: ''

    cont =
      send: ->
        args.callback(null, { username: mod.username, password: mod.password })

    done({ model: mod, controller: cont })
