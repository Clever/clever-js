async     = require 'async'
assert    = require 'assert'
_         = require 'underscore'
nock      = require 'nock'
Clever    = require "#{__dirname}/../index"

describe 'get/set properties', ->

  before -> @clever = Clever 'DEMO_KEY', 'https://api.clever.com'

  after -> nock.cleanAll()

  it 'can hit second-level for properties', (done) ->
    nock('https://api.clever.com:443')
      .get('/v1.1/districts?where=%7B%22id%22%3A%224fd43cc56d11340000000005%22%7D&limit=1').reply(200,
        data: [
          data:
            name: 'Test District'
            id: '4fd43cc56d11340000000005'
          uri: '/v1.1/districts/4fd43cc56d11340000000005'
        ]
      ).get('/v1.1/districts/4fd43cc56d11340000000005/properties').reply(200,
        data:
          some: { really: { nested: 'property' } }
      ).patch('/v1.1/districts/4fd43cc56d11340000000005/properties', { test: 'data' }).reply(200,
        data:
          some: { really: { nested: 'property' } }
          test: 'data'
      )
    district = null
    async.waterfall [
      (cb_wf) =>
        @clever.District.findById '4fd43cc56d11340000000005', cb_wf
      (_district, cb_wf) =>
        district = _district
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Test District'
        district.properties cb_wf
      (properties, cb_wf) ->
        assert.deepEqual { some: { really: { nested: 'property' } } }, properties
        district.properties { test: 'data' }, cb_wf
      (properties, cb_wf) ->
        assert.deepEqual { test: 'data', some: { really: { nested: 'property' } } }, properties
        cb_wf()
    ], done

  it 'checks response codes on properties', (done) ->
    scope = nock('https://api.clever.com')
      .get('/v1.1/districts/1212121/properties')
      .reply(504, {error: 'trolling'})
    district = new @clever.District { name: 'Test', id: '1212121' }
    district.properties (err, props) ->
      assert not props, "found properties"
      assert err, "didn't find an error"
      assert.equal err.message, "received statusCode 504 instead of 200"
      scope.done()
      done()
