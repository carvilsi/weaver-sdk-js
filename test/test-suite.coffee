require("./globalize")
Weaver = require("../src/Weaver.coffee")

weaver = new Weaver()


# Runs before all tests (even across files)
before (done) ->
  weaver.connect(WEAVER_ENDPOINT).then(-> done())
  return

# Runs after each test in each file
beforeEach (done) ->

  weaver.wipe()
  .then(->
    weaver.signInWithUsername('admin', 'admin')
  )
  .then(->
    new Weaver.Project().create()
  )
  .then((project) ->
    weaver.useProject(project)
    done()
  )
  .catch(console.log)
  return
