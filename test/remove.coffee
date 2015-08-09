# vim: set sw=2 ts=2 softtabstop=2 expandtab tw=120 :
assert    = require 'assert'
Clever    = require "#{__dirname}/../index"
_         = require 'underscore'

describe 'update', ->

  before () -> @clever = Clever 'DEMO_KEY', 'http://httpbin.org'

  it 'submits delete requests', (done) ->
    @timeout 30000
    district = new @clever.District { name: 'Test', id: '1212121' }, '/delete'
    district.remove (err, data) ->
      assert.ifError err
      assert.equal arguments.length, 2
      assert _.isUndefined(data), 'Unexpected data'
      done()
