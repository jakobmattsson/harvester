page
  route: '/:domain'
  middleware: [authMiddle]
  sources:
    url: '/'
  callback: (args, done) ->
    model = serenata.createModel
      roots: args.url.roots.map (x) ->
        name: x
        dst: "/#{args.domain}/#{x}"

    render('root', model)
    done()
