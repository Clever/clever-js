async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'

describe 'update', ->

  before () -> @clever = Clever 'DEMO_KEY', 'http://httpbin.org'

  it 'submits put requests', (done) ->
    @timeout 30000
    district = new @clever.District { name: 'Test', id: '1212121' }, '/put'
    district.set 'location.address', 'Tacos'
    district.save (err) ->
      assert.ifError err
      assert.equal district.get('name'), undefined # httpbin echos back the put data, so object will lose this prop
      assert.equal district.get('location.address'), 'Tacos'
      done()

  it 'successfully handles invalid put requests that return a json', (done) ->
    @timeout 30000
    clever = Clever 'FAKE_KEY', 'http://fake_api.com'
    scope = nock('http://fake_api.com')
      .put('/v1.1/districts/12121', {some_prop: "some_val"})
      .reply(401, {error: 'unauthorized'})
    district = new clever.District
      name: 'Test'
      location:
        address: 'Tacos'
      id: '12121'
    , "/v1.1/districts/12121"
    district.set 'some_prop', 'some_val'
    district.save (err) ->
      assert.equal err?.message, "received statusCode 401 instead of 200"
      assert.deepEqual err.body, {error: 'unauthorized'}
      scope.done()
      done()

  it 'successfully handles invalid put requests that return a string', (done) ->
    @timeout 30000
    clever = Clever 'FAKE_KEY', 'http://fake_api.com'
    scope = nock('http://fake_api.com')
      .put('/v1.1/districts/12121', {some_prop: "some_val"})
      .reply(401, 'unauthorized')
    district = new clever.District
      name: 'Test'
      location:
        address: 'Tacos'
      id: '12121'
    , "/v1.1/districts/12121"
    district.set 'some_prop', 'some_val'
    district.save (err) ->
      assert.equal err?.message, "received statusCode 401 instead of 200"
      assert.equal err.body, 'unauthorized'
      scope.done()
      done()