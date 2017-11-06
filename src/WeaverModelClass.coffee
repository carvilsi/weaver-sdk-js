cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  constructor: (nodeId) ->
    super(nodeId)
    @totalClassDefinition = @_collectFromSupers()

    # Add type definition to model class
    @relation("_proto").add(Weaver.Node.get(@classId()))

  classId: ->
    "#{@definition.name}:#{@className}"

  # Returns a definition where all super definitions are collected into
  _collectFromSupers: ->
    addFromSuper = (classDefinition, totalDefinition = {attributes: {}, relations: {}}) =>

      # Start with supers so lower specifications override the super ones
      if classDefinition.super?
        superDefinition = @definition.classes[classDefinition.super]
        addFromSuper(superDefinition, totalDefinition)

      transfer = (source) ->
        totalDefinition[source][k] = v for k, v of classDefinition[source] if classDefinition[source]?

      transfer('attributes')
      transfer('relations')

      totalDefinition

    addFromSuper(@classDefinition)


  _getAttributeKey: (field) ->
    if not @totalClassDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")

    if not @totalClassDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @totalClassDefinition.attributes[field].key or field

  # TODO: check max cardinality
  _getRelationKey: (key) ->
    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")

    if not @totalClassDefinition.relations[key]?
      throw new Error("Relation #{key} is not valid on this #{@className} model")

    @totalClassDefinition.relations[key].key or key

  get: (field) ->
    super(@_getAttributeKey(field))

  set: (field, value) ->
    super(@_getAttributeKey(field), value)

  relation: (key) ->
    # Return when using a special relation like _proto
    return super(key) if ["_proto"].includes(key)

    databaseKey = @_getRelationKey(key)

    # Based on the key, construct a specific Weaver.ModelRelation
    modelKey             = key
    model                = @model
    relationDefinition   = @totalClassDefinition.relations[key]
    className            = @className
    definition           = @definition
    totalClassDefinition = @totalClassDefinition

    classRelation = class extends Weaver.ModelRelation
      constructor:(parent, key) ->
        super(parent, key)
        @modelKey           = modelKey
        @model              = model
        @className          = className
        @definition         = totalClassDefinition
        @relationDefinition = relationDefinition

    super(databaseKey, classRelation)

  save: (project) ->
    # TODO Check if all required attributes are set
    # TODO Check min card on relations
    super(project)


module.exports = WeaverModelClass
