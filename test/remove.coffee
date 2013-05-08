assert    = require 'assert'
Clever    = require "#{__dirname}/../index"

describe 'update', ->

  before () -> @clever = Clever 'DEMO_KEY', 'http://httpbin.org'

  it 'submits delete requests', (done) ->
    @timeout 30000
    district = new @clever.District { name: 'Test', id: '1212121' }, '/delete'
    district.remove (err) ->
      assert.ifError err
      assert.equal arguments.length, 1
      done()
