Array.prototype.toMap = (keySelector, valueSelector) ->
  if typeof keySelector == 'string'
    keySelectorString = keySelector
    keySelector = (e) -> e[keySelectorString]

  if typeof valueSelector == 'string'
    valueSelectorString = valueSelector
    valueSelector = (e) -> e[valueSelectorString]

  if typeof valueSelector == 'undefined'
    valueSelector = (e) -> e

  result = {}
  this.forEach (e) ->
    result[keySelector(e)] = valueSelector(e)

  result
