async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'

describe 'create', ->

  before () -> @clever = Clever 'FAKE_KEY', 'http://fake_api.com'

  describe 'submits post requests', ->

    beforeEach ->
      @scope = nock('http://fake_api.com')
      .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos', city: "Burritos"})
      .reply(
        200
        {
          data:
            name: 'Test'
            location: address: 'Tacos' # Casa Bonita
          links: [{rel: 'self', uri: '/v1.1/districts/1235'}]
        }
      )
    afterEach -> @scope.done()

    it 'when created using the constructor', (done) ->
      district = new @clever.District
        name: 'Test'
        location:
          address: 'Tacos'
          city: 'Burritos'
      district.save (err) ->
        assert.ifError err
        assert.equal district.get('name'), 'Test'
        assert.equal district.get('location.address'), 'Tacos'
        assert.equal district._uri, '/v1.1/districts/1235'
        done()

    it 'when created using .set()', (done) ->
      district = new @clever.District({})
      district.set("name", "Test")
      district.set("location.address", "Tacos")
      district.set("location.city", "Burritos")
      district.save (err) ->
        assert.ifError err
        assert.equal district.get('name'), 'Test'
        assert.equal district.get('location.address'), 'Tacos'
        assert.equal district._uri, '/v1.1/districts/1235'
        done()

    it 'when created using .set() and the constructor', (done) ->
      district = new @clever.District
        name: "Test"
        location:
          address: "Tacos"
          city: "Tostada" #No one likes tostadas
      district.set("location.city", "Burritos")
      district.save (err) ->
        assert.ifError err
        assert.equal district.get('name'), 'Test'
        assert.equal district.get('location.address'), 'Tacos'
        assert.equal district._uri, '/v1.1/districts/1235'
        done()

  it 'successfully handles invalid post requests that return a json', (done) ->
    @timeout 30000
    scope = nock('http://fake_api.com')
      .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos'})
      .reply(401, {error: 'unauthorized'})
    district = new @clever.District
      name: 'Test'
      location:
        address: 'Tacos'
    district.save (err) ->
      assert.equal err?.message, "received statusCode 401 instead of 200"
      assert.deepEqual err.body, {error: 'unauthorized'}
      scope.done()
      done()

  it 'successfully handles invalid post requests that return a string', (done) ->
    @timeout 30000
    scope = nock('http://fake_api.com')
      .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos'})
      .reply(401, 'unauthorized')
    district = new @clever.District
      name: 'Test'
      location:
        address: 'Tacos'
    district.save (err) ->
      assert.equal err?.message, "received statusCode 401 instead of 200"
      assert.equal err.body, 'unauthorized'
      scope.done()
      done()