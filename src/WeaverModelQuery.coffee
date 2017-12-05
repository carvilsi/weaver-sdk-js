cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelQuery extends Weaver.Query

  constructor: (@model = Weaver.currentModel(), target) ->
    super(target)

    # Define constructor function
    @useConstructor((node) =>
      if node.relation(@prototypeKey()).first()?
        [modelName, className] = node.relation(@prototypeKey()).first().id().split(":")
        @model[className]
      else
        Weaver.Node
    )

  prototypeKey: ->
    @model.definition.prototype or '_prototype'

  class: (modelClass) ->
    @hasRelationOut(@prototypeKey(), modelClass.classId())

  # Key is composed of Class.modelAttribute
  _mapKeys: (keys, source) ->
    databaseKeys = []
    for key in keys
      if [@prototypeKey(), '*'].includes(key)
        databaseKeys.push(key)
      else
        if key.indexOf(".") is -1
          throw new Error("Key should be in the form of ModelClass.key")

        [className, modelKey] = key.split(".")
        modelClass = @model[className]
        defintion  = modelClass.classDefinition

        databaseKeys.push(defintion[source]?[modelKey]?.key or modelKey)

    databaseKeys

  _mapKey: (key, source) ->
    @_mapKeys([key], source)[0]

  _addAttributeCondition: (key, condition, value) ->
    super(@_mapKey(key, "attributes"), condition, value)

  _addRelationCondition: (key, condition, value) ->
    super(@_mapKey(key, "relations"), condition, value)

  _addRecursiveCondition: (op, relation, node, includeSelf) ->
    super(op, @_mapKey(relation, "relations"), node, includeSelf)

  equalTo: (key, value) ->
    super(@_mapKey(key, "attributes"), value)

  order: (keys, ascending) ->
    super(@_mapKeys(keys, "attributes"), ascending)

  select: (keys...) ->
    super(key) for key in @_mapKeys(keys, "attributes")

  selectOut: (keys...) ->
    super(key) for key in @_mapKeys(keys, "relations")

  selectRecursiveOut: (keys...) ->
    super(key) for key in @_mapKeys(keys, "relations")

  find: (Constructor) ->
    # Always get the prototype relation to map to the correct modelclass
    @alwaysLoadRelations(@prototypeKey())

    super(Constructor)

module.exports = WeaverModelQuery
