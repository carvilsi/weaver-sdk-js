Weaver           = require('./Weaver')
writeFile        = require('fs-writefile-promise')
Error            = require('./Error')
WeaverError      = require('./WeaverError')
WeaverSystemNode = require('./WeaverSystemNode')
readFile         = require('fs-readfile-promise')
fs               = require('fs')



class WeaverFile extends Weaver.SystemNode

  constructor: (@nodeId) ->
    super(@nodeId)

  @get: (nodeId) ->
    super(nodeId, WeaverFile)

  saveFile: (path, fileName, project, accessToken) ->
    coreManager = Weaver.getCoreManager()
    formData = {
      file: fs.createReadStream(path)
      accessToken
      target:project
      fileName
    }
    coreManager.uploadFile(formData)

  getFile: (path, fileName, project, accessToken) ->
    coreManager = Weaver.getCoreManager()
    new Promise((resolve, reject) =>
      try
        payload = {
          fileName
          target: project
          accessToken
        }
        fileStream = fs.createWriteStream(path)
        coreManager.downloadFile(JSON.stringify(payload))
        .pipe(fileStream)
        fileStream.on('finish', ->
          resolve(fileStream.path)
        )
      catch error
        reject(Error WeaverError.OTHER_CAUSE,"Something went wrong")
    )

  getFileByID: (path, id, project, accessToken) ->
    coreManager = Weaver.getCoreManager()
    new Promise((resolve, reject) =>
      try
        payload = {
          id
          target: project
          accessToken
        }
        fileStream = fs.createWriteStream(path)
        coreManager.downloadFileByID(JSON.stringify(payload))
        .pipe(fileStream)
        fileStream.on('finish', ->
          resolve(fileStream.path)
        )
      catch error
        reject(Error WeaverError.OTHER_CAUSE,"Something went wrong")
    )

  deleteFile: (fileName, project, accessToken) ->
    coreManager = Weaver.getCoreManager()
    file = {
      fileName
      target: project
      accessToken
    }
    coreManager.deleteFile(file)

  deleteFileByID: (id, project, accessToken) ->
    coreManager = Weaver.getCoreManager()
    file = {
      id
      target: project
      accessToken
    }
    coreManager.deleteFileByID(file)

module.exports = WeaverFile
