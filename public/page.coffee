middlewareCreator = (page) -> (params) ->
  augmented = 
    callback: (args, done) ->
      mid = params.middleware ? []
      params.callback args, () ->
        mid.forEach (m) ->
          m.what(args)
        done(arguments...)

  page(_.extend({}, params, augmented))




sourceCreator = (page, resolver) -> (params) ->
  augmented = 
    callback: (args, done) ->
      sources = params.sources ? {}
      Object.keys(sources).forEach (key) ->
        replaced = sources[key].split('/').map (unit) ->
          args[unit.slice(1)] ? unit
        sources[key] = replaced.join('/')

      resolver sources, (data) ->
        mergedArgs = _.extend({}, args, data)
        params.callback(mergedArgs, done)

  page(_.extend({}, params, augmented))




viewCreator = (page) -> (params) ->

  if !params.serenadeReplace? || !params.serenadeView?
    return page(params)

  augmented = 
    callback: (args, done) ->
      params.callback args, (mo) ->
        dataview = document.getElementById params.serenadeReplace
        underline.removeChildren(dataview)
        node = Serenade.view(params.serenadeView).render(mo.model, mo.controller || {})
        dataview.appendChild(node)
        done(arguments...)

  page(_.extend({}, params, augmented))





window.page = (params) -> router.register params.route, params.callback
window.page = sourceCreator(window.page, safeMultiGet)
window.page = middlewareCreator(window.page)
window.page = viewCreator(window.page)
