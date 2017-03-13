Weaver = require('./Weaver')
cuid   = require('cuid')

class WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name) ->
    @name = @name or 'unnamed'
    @projectId = cuid()
    @_created = false

  id: ->
    @projectId

  create: ->
    coreManager = Weaver.getCoreManager()

    coreManager.createProject(@projectId, @name).then(=>  # Wait till project gets read
      new Promise((resolve) =>

        checkReady = =>
          coreManager.readyProject(@projectId).then((res) =>
            if not res.ready
              setTimeout(checkReady, WeaverProject.READY_RETRY_TIMEOUT) # Check again after some time
            else
              resolve()
          )

        checkReady()
      )
    )
    .then(=> # Project is ready
      @_created = true
      @
    )

  destroy: ->
    super().then(=>
      Weaver.getCoreManager().deleteProject(@id())
    )

  getAllNodes: (attributes)->
    Weaver.getCoreManager().getAllNodes(attributes, @id())

  getAllRelations:->
    Weaver.getCoreManager().getAllRelations(@id())

  wipe: ->
    coreManager = Weaver.getCoreManager()
    coreManager.wipe(@id())

  getACL: ->
    coreManager = Weaver.getCoreManager()
    coreManager.getACL(@projectId)

  @list: ->
    Promise.resolve([])

module.exports = WeaverProject

