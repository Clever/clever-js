async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"

describe 'update', ->

  before () -> @clever = Clever 'DEMO_KEY', 'http://httpbin.org'

  it 'submits put requests', (done) ->
    @timeout 30000
    district = new @clever.District { name: 'Test', id: '1212121' }, 'http://httpbin.org/put'
    district.set 'location.address', 'Tacos'
    district.save (err) ->
      assert.ifError err
      assert.equal district.get('name'), undefined # httpbin echos back the put data, so object will lose this prop
      assert.equal district.get('location.address'), 'Tacos'
      done()
