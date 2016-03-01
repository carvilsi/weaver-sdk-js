io      = require('socket.io-client')
cuid    = require('cuid')
Promise = require('bluebird')

Entity  = require('./entity')
  
module.exports =
class Repository
  
  constructor: (@weaver) ->
    @entities  = {}
    @listeners = {}
    
  contains: (id) ->
    @entities[id]?
    
  isEmpty: ->
    @size() is 0  
    
  size: ->
    (key for own key of @entities).length

  get: (id) ->
    @entities[id]
    
  clear: ->
    @entities = {}
    
  add: (entity) ->
    @entities[entity.id()] = entity
    entity

  store: (entity) ->
    connections = []    
    added = {}
    addConnections = (parent) ->
      added[parent.id()] = true 
      for child in parent.entities()
        connections.push({subject: parent, predicate: child.key, object: child.value})
        
        if not added[child.value.id()]?
          addConnections(child.value)
        
    addConnections(entity)
    
    
    # Might have no connections, in which case we just add and return
    if connections.length is 0
      if not @contains(entity.id())
        @track(@add(entity))

    # Process
    processing = {}
    for connection in connections

      # Not yet in repository
      if not @contains(connection.subject.id())
        repoSubject = connection.subject.withoutEntities()
        processing[repoSubject.id()] = true
        @track(@add(repoSubject))
      else
        repoSubject = @get(connection.subject.id())
        repoObject = @get(connection.object.id())

        if repoSubject.$.fetched and repoObject? and repoObject.$.fetched and not processing[repoSubject.id()]
          continue
        else
          processing[repoSubject.id()] = true

          # Transfer state to repo subject
          if connection.subject.$.fetched
            repoSubject.$.fetched = true


      # Process object
      if not @contains(connection.object.id())
        repoObject = connection.object.withoutEntities()
        @track(@add(repoObject))
        processing[repoObject.id()] = true
      else
        repoObject = @get(connection.object.id())
        processing[repoObject.id()] = true

        # Transfer state to repo object
        if connection.object.$.fetched
          repoObject.$.fetched = true
  
          
      # Create link
      repoSubject[connection.predicate] = repoObject
      
    
    # Return entity
    @get(entity.id())
        
    
  track: (entity) ->

    # Updates
    @weaver.socket.on(entity.$.id + ':updated', (payload) ->
      if payload.value?
        entity[payload.attribute] = payload.value
      else
        delete entity[payload.attribute]
    )

    # Links
    @weaver.socket.on(entity.$.id + ':updated', (payload) ->
      if payload.value?
        entity[payload.attribute] = payload.value
      else
        delete entity[payload.attribute]
    )
    
    entity