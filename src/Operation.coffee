Weaver = require('./Weaver')
cuid   = require('cuid')
util   = require('./util')

NodeOperation = (node) ->
  if Weaver.instance?
    timestamp = Weaver.getCoreManager().serverTime()
  else
    timestamp = new Date().getTime()

  createNode: ->
    {
      timestamp
      action: "create-node"
      id: node.id()
      graph: node.getGraph()
    }

  removeNode: ->
    {
      timestamp
      cascade: true
      action: "remove-node"
      id: node.id()
      graph: node.getGraph()
      removeId: cuid()
      removeGraph: node.getGraph()
    }

  removeNodeUnrecoverable: ->
    {
      timestamp
      cascade: true
      action: "remove-node-unrecoverable"
      id: node.id()
      removeId: cuid()
      graph: node.getGraph()
    }

  createAttribute: (key, value, datatype, replaces, ignoreConcurrentReplace, graph) ->
    graph = node.getGraph() if !graph? # keep same graph is no update is emitted
    replaceId = null
    replaceId = cuid() if replaces?
    replaces.graph = 'default-graph' if !replaces.graph? if replaces?
    {
      timestamp
      action: "create-attribute"

      # This object (attribute)
      id: cuid()
      graph: node.getGraph()

      # Node it belongs to
      sourceId: node.id()
      sourceGraph: node.getGraph()

      key
      value
      datatype

      # Old attribute
      replacesId: replaces.nodeId if replaces
      replacesGraph: replaces.graph if replaces

      # Node of the new attribute
      replaceId
      replaceGraph: graph if graph?

      traverseReplaces: ignoreConcurrentReplace if replaces? and ignoreConcurrentReplace?

      # New attribute
      replaced: 'hi0' # yes
      replacedId: 'hi1' # yes
      replacedGraph: graph if graph?
    }

  removeAttribute: (id) ->
    {
      timestamp
      cascade: true
      action: "remove-attribute"
      id: id
      removeId: cuid()
      graph: node.getGraph()
    }

  createRelation: (key, to, id, replaces, ignoreConcurrentReplace) ->
    replaces.graph = 'default-graph' if !replaces.graph? if replaces?
    replacesId = replaces.id() if !util.isString(replaces) if replaces?
    replacesId = replaces if util.isString(replaces) if replaces?
    replaceId = null
    replaceId = cuid() if replaces?
    throw new Error("Unable to set relation #{key} from #{node.id()} to null node") if !to?
    {
      timestamp
      action: "create-relation"
      id
      graph: node.getGraph()
      sourceId: node.id()
      sourceGraph: node.getGraph()
      key
      targetId: to.id()
      targetGraph: to.getGraph()
      replacesId: replacesId
      replacesGraph: replaces.graph if replaces
      replaceId
      replaceGraph: node.getGraph()
      traverseReplaces: ignoreConcurrentReplace if replaces? and ignoreConcurrentReplace?
    }

  removeRelation: (id) ->
    {
      timestamp
      cascade: true
      action: "remove-relation"
      id
      removeId: cuid()
      graph: node.getGraph()
    }

module.exports=
  Node: NodeOperation
