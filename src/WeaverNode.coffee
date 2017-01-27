cuid       = require('cuid')
Weaver     = require('./Weaver')
Operation  = require('./Operation')

class WeaverNode

  constructor: (@nodeId) ->
    # Generate random id if not given
    @nodeId = cuid() if not @nodeId?

    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    # All operations that need to get saved
    @pendingWrites = [Operation.Node(@).create()]


  # Node loading from server
  @load: (nodeId, target) ->
    new Weaver.Query(target).get(nodeId)

  _loadFromQuery: (object) ->
    @nodeId     = object.nodeId
    @attributes = object.attributes

    for key, targetNodes of object.relations
      for node in targetNodes
        @relation(key).add(new WeaverNode()._loadFromQuery(node))

    @._clearPendingWrites()
    @


  # Node creating for in queries
  @get: (nodeId, Constructor) ->
    Constructor = WeaverNode if not Constructor?
    node = new Constructor(nodeId)
    node._clearPendingWrites()
    node


  # Return id
  id: ->
    @nodeId


  # Gets attributes
  get: (field) ->
    @attributes[field]


  # Update attribute
  set: (field, value) ->
    @attributes[field] = value

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).unsetAttribute(field))
    @pendingWrites.push(Operation.Node(@).setAttribute(field, value))


  # Remove attribute
  unset: (field) ->
    delete @attributes[field]

    # Save change as pending
    @pendingWrites.push(Operation.Node(@).unsetAttribute(field))


  # Create a new Relation
  relation: (key) ->
    @relations[key] = new Weaver.Relation(@, key) if not @relations[key]?
    @relations[key]


  # Go through each relation and recursively add all pendingWrites per relation AND that of the objects
  _collectPendingWrites: (collected) ->
    # Register to keep track which nodes have been collected to prevent recursive blowup
    collected  = {} if not collected?
    operations = @pendingWrites

    for key, relation of @relations
      for id, node of relation.nodes
        if not collected[node.id()]
          collected[node.id()] = true
          operations = operations.concat(node._collectPendingWrites(collected))

      operations = operations.concat(relation.pendingWrites)

    operations


  # Clear all pendingWrites, used for instance after saving or when loading a node
  _clearPendingWrites: ->
    @pendingWrites = []

    for key, relation of @relations
      for id, node of relation.nodes
        node._clearPendingWrites() if node.isDirty()

      relation.pendingWrites = []


  # Checks whether needs saving
  isDirty: ->
    @pendingWrites.length isnt 0


  # Save node and all values / relations and relation objects to server
  save: (project) ->
    coreManager = Weaver.getCoreManager()
    coreManager.executeOperations(@_collectPendingWrites(), project).then(=>
      @_clearPendingWrites()
      @
    )


  # Removes node
  destroy: (project) ->
    coreManager = Weaver.getCoreManager()
    coreManager.executeOperations([Operation.Node(@).destroy()], project).then(=>
      @destroyed = true
      @saved = false
      undefined
    )

  #
  setACL: (acl) ->
    return


# Export
module.exports = WeaverNode