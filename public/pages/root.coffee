page
  route: '/:domain'
  middleware: [authMiddle]
  serenadeReplace: 'dataview'
  serenadeView: '''
    div
      div "Start with one of these"
      ul
        - collection @roots
          li
            a[href=@dst] @name
  '''
  sources:
    url: '/'
  callback: (args, done) ->
    model = serenata.createModel
      roots: args.url.roots.map (x) ->
        name: x
        dst: "/#{args.domain}/#{x}"
    done({ model: model })
