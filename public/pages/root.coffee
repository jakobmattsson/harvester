router.register '/:domain', (args) ->
  safeMultiGet
    url: '/'
  , (data) ->
    model = serenata.createModel
      roots: data.url.roots.map (x) ->
        name: x
        dst: "/#{args.domain}/#{x}"

    render('root', model)
