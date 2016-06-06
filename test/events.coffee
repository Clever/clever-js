assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"

##
# Tests the Events functionality
##
describe '/events endpoint', ->

  # Build Clever API tool, only Tokens are supported
  beforeEach -> @clever = Clever  {token: 'DEMO_TOKEN'}

  it 'can get Events', (done)->
    @clever.Event.find().limit(1).exec (err, events)->
      assert _.isArray(events), "Expected returned events to be an array, got #{typeof events} = #{JSON.stringify events}"
      #assert.equal events.length, 1
      done()
