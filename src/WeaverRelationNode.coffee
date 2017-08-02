cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
WeaverNode  = require('./WeaverNode')

class WeaverRelationNode extends WeaverNode

  constructor: (@nodeId) ->
    throw new Error("Please always supply a relId when constructing WeaverRelationNode") if not @nodeId?
    @_stored = false       # if true, available in database, local node can hold unsaved changes
    @_loaded = false       # if true, all information from the database was localised on construction

    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    @toNode = null        # Wip, this is fairly impossible to query this from the server currently
    @fromNode = null      # Wip, this is fairly impossible to query this from the server currently


  to: ->
    @toNode

  from: ->
    @fromNode

# Export
module.exports = WeaverRelationNode
