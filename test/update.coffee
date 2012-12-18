async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'

describe 'update', ->

  clever = null
  before () ->
    clever = require "#{__dirname}/../index"
    clever.api_key = 'DEMO_KEY'
    clever.url_base = 'http://httpbin.org'

  it 'submits put requests', (done) ->
    @timeout 30000
    district = new clever.District { name: 'Test' }, 'http://httpbin.org/put'
    district.set 'location.address', 'Tacos'
    district.save (err) ->
      assert.ifError err
      assert.equal district.get('name'), undefined # httpbin echos back the put data, so object will lose this prop
      assert.equal district.get('location.address'), 'Tacos'
      done()
