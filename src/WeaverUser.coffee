# Libs
cuid   = require('cuid')
Weaver = require('./Weaver')
loki   = require('lokijs')
Error        = require('weaver-commons').Error
WeaverError  = require('weaver-commons').WeaverError

class WeaverUser
  
  constructor: (@email, @username, @password) ->
    @emailVerified = false
    
    
  logIn: (user, password) ->
    credentials = {user,password}
    coreManager = Weaver.getCoreManager()
    users = Weaver.getUsersDB()
    coreManager.logIn(credentials)
    .then((res) ->
      try
        users.insert({user:user,token:res.token})
      catch error
      res
    )
    
  permission: (user) ->
    coreManager = Weaver.getCoreManager()
    users = Weaver.getUsersDB()
    @current(user).then((access_token) ->
      userPayload = {user,access_token}
      coreManager.permission(userPayload)
    )
  
  signUp: (currentUsr,userName,userEmail,userPassword,directoryName) ->
    newUserCredentials = {userName,userEmail,userPassword,directoryName}
    coreManager = Weaver.getCoreManager()
    @current(currentUsr).then((access_token) ->
      newUserPayload = {newUserCredentials,access_token}
      coreManager.signUp(newUserPayload)
    )
    
  
  signOff: (currentUsr, user) ->
    coreManager = Weaver.getCoreManager()
    @current(currentUsr).then((access_token) ->
      userPayload = {user,access_token}
      coreManager.signOff(userPayload)
    )
    
    
  # Returns the "valid" token from current user, null if not loggedin
  current: (usr) ->
    new Promise((resolve, reject) =>
      try
        users = Weaver.getUsersDB()
        resolve(users.findOne({user:usr}).token)
      catch error
        reject(null)
    )
  
  ###
  # log out action, will remove the jwt at the current user
  # passing a user is optional
  ###
  
  logOut: (usr) ->
    new Promise((resolve, reject) =>
      try
        users = Weaver.getUsersDB()
        if usr?
          userFound = users.find({$and:[{user:usr},{token:{$ne:undefined}}]})
          if userFound.length is 0
            reject(Error WeaverError.USERNAME_NOT_FOUND,'USERNAME_NOT_FOUND')
          else
            users.remove(userFound)
            resolve()
        else
          userFound = users.find({token:{$ne:undefined}})
          if userFound.length is 0
            reject(Error WeaverError.USERNAME_NOT_FOUND,'USERNAME_NOT_FOUND')
          else
            users.remove(userFound)
            resolve()
      catch error
        reject(error)
          
    )
    
    
# Export
Weaver.User    = WeaverUser
module.exports = WeaverUser






