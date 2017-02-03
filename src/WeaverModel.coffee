cuid       = require('cuid')
chirql     = require('Chirql')
Weaver     = require('./Weaver')
WeaverNode = require('./WeaverNode')
util       = require('./util')

Lexer = chirql.Lexer
Parser = chirql.Parser


class WeaverModel

  lexer: new Lexer()
  parser: new Parser()

  constructor: (@name, @definitionString)->
    @inputArgs = {}

  define: (@definitionString)->

    ###

     @inputArgs looks like this: { $variableName : ['path','to','this','variable','from','root','node']

     these are the required arguments for a modelInstance instance. eg if a model definition has `<hasName>($name)`,
     then a modelInstance of that model should define a value for `$name` before saving

    ###

    @inputArgs = {}
    @definition = {}

    tokens = @lexer.lex(@definitionString)
    fragmentList = @parser.parseTokens(tokens)

    # stores and removes root node id, if specified
    if fragmentList[0] isnt 'OPEN_BLOCK'
      @inputArgs['rootId'] = fragmentList[0]
      fragmentList.shift()

    parseInnerLevel = (returnObj, fragments, start, end, path)->

      innerBlock = fragments.slice(start, end)
      preceedingSubject = fragments[parseInt(start)-1]

      returnObj[preceedingSubject.predicate] = parseOneLevel(innerBlock, path, preceedingSubject)

    parseOneLevel = (arr, path, sub)=>

      returnObj = new ModelFragment(sub, path)

      path = path.concat(sub.predicate) if sub.predicate

      openedBlocks = 0
      fragments = arr.slice(1,-1)

      for fragment,i in fragments

        if openedBlocks > 0
          ++openedBlocks if fragment is 'OPEN_BLOCK'
          --openedBlocks if fragment is 'CLOSE_BLOCK'

          if openedBlocks is 0
            endBlock = i+1

            parseInnerLevel(returnObj, fragments, startBlock, endBlock, path)
          continue

        else if fragment is 'OPEN_BLOCK'
          startBlock = i
          ++openedBlocks
          continue

        else
          if fragment.inputArg
            @inputArgs[fragment.object] = path.concat(fragment.predicate)

          returnObj[fragment.predicate] = new ModelFragment(fragment, path)

      returnObj

    root =
      id: @inputArgs['rootId'] or cuid()
      type: 'root'

    @definition = parseOneLevel(fragmentList, [], root)

  instance: ->
    new ModelInstance(@definition, @inputArgs)

  class ModelFragment

    constructor:(fragment, path)->

      path.concat(fragment.predicate) if fragment.predicate

      @_definition =
        type: fragment.type
        path: path
        props:
          isOptional: fragment.isOptional or false
          isExcluded: fragment.isExcluded or false
          cardinality: {}
      @value = fragment.object or 'empty' if fragment.type is 'Value'
      if fragment.cardinality
        @_definition.props.cardinality.min = fragment.cardinality.min
        @_definition.props.cardinality.max = fragment.cardinality.max


class ModelInstance

  constructor: (modelDefinition, @inputArgs)->

    @instance = {}
    @instance[i] = j for i, j of modelDefinition

  set: (key, value)->

    throw new Error("Value property/Attribute strings cannot contain the character '@'.") if value.indexOf('@') isnt -1
    throw new Error("Input argument strings cannot contain the character '$'.")           if value.indexOf('$') isnt -1

    key = '$' + key
    throw new Error(key + " is not a valid input argument for this model.") if not @inputArgs[key]

    checkPathValidity(@inputArgs[key], @instance, 'Value')
    path = @inputArgs[key]

    pointer = @instance
    pointer = pointer[p] for p in path.slice(0, -1)
    pointer[path.slice(-1)[0]].object = value
    @

  add: (propPath, value)->

    throw new Error(propPath + ' is not a valid input argument for this model') if not @inputArgs[propPath]
    path = @inputArgs[propPath]
    checkPathValidity(@inputArgs[propPath], @modelDefinition, 'Individual')

    pointer = @instance
    pointer = pointer[p] for p in path.slice(0, -1)
    pointer[path.slice(-1)[0]] = [] if pointer[path.slice(-1)[0]][0].indexOf('$') is 0
    pointer[path.slice(-1)[0]].push(value)
    @

  save: ->

    promises = []
    nodes = []

    new Promise((resolve,reject)=>

      throwUnsetArgsException = ->
        reject(new Error('This model instance has unset input arguments. All input arguments must be set before saving.'))

      if @inputArgs['rootId']
        root = new Weaver.Node(@inputArgs['rootId'])
      else
        root = new Weaver.Node()

      nodes.push(root)

      persistOneLevel = (parent, props)->

        for key,prop of props when key.indexOf('_') isnt 0

          if hasInnerModel(prop)

            child = new Weaver.Node()
            nodes.push(child)

            persistOneLevel(child, prop)
            parent.relation(key).add(child)

          else

            throwUnsetArgsException() if prop._definition.value.indexOf('$') isnt -1

            if util.isArray(prop)

              for id in prop

                if id is 'RANDOM'
                  indiProp = new Weaver.Node()
                  parent.relation(key).add(indiProp)

                else

                  promises.push(
                    new Promise((resolve,reject)->
                      shallowKey = key

                      Weaver.Node.load(id).then((res)->
                        parent.relation(shallowKey).add(res)
                        parent.save()
                        resolve(parent)
                      ).catch((err)->
                        reject(err)
                      )
                    )
                  )

      persistOneLevel(root, @instance)

      promises.push(node.save()) for node in nodes

      Promise.all(promises).then((res)->

        #return the root node, which should always be at index 0
        resolve(res[0])
      )

    )

  checkPathValidity = (path, model, propType)->

    pointer = model
    pointer = pointer[p] for p in path.slice(0, -1)

    loc = pointer[path.slice(-1)[0]]

    if propType is 'Individual' and not util.isArray(loc)
      throw new Error("Cannot use 'add' to set attribute. Use 'set' instead.")

    if propType is 'Value' and util.isArray(loc)
      throw new Error("Cannot use 'set' to add relation. Use 'add' instead.")

  hasInnerModel = (obj)->
    hasInner = false
    hasInner = true if prop._definition for key,prop of obj when key.indexOf('_') isnt 0
    hasInner

module.exports = WeaverModel
