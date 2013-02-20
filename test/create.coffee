async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'

describe 'create', ->

  before () -> @clever = Clever 'FAKE_KEY', 'http://fake_api.com'

  it 'submits post requests', (done) ->
    @timeout 30000
    scope = nock('http://fake_api.com')
      .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos'})
      .reply(
        200
        {
          data:
            name: 'Test'
            location: address: 'Tacos' # Casa Bonita
          links: [{rel: 'self', uri: '/v1.1/districts/1235'}]
        }
      )
    district = new @clever.District
      name: 'Test'
      location:
        address: 'Tacos'
    district.save (err) ->
      assert.ifError err
      assert.equal district.get('name'), 'Test'
      assert.equal district.get('location.address'), 'Tacos'
      assert.equal district._uri, '/v1.1/districts/1235'
      scope.done()
      done()
