async     = require 'async'
assert    = require 'assert'
_         = require 'underscore'
nock      = require 'nock'

describe 'get/set properties', ->

  clever = null
  before ->
    clever = require "#{__dirname}/../index"
    clever.api_key = 'DEMO_KEY'
    clever.url_base = 'https://api.getclever.com'

  it 'can hit second-level for properties', (done) ->
    nock('https://api.getclever.com:443')
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
      ).put('/v1.1/districts/4fd43cc56d11340000000005/properties', { test: 'data' }).reply(200,
        data:
          some: { really: { nested: 'property' } }
          test: 'data'
      )
    district = null
    async.waterfall [
      (cb_wf) ->
        clever.District.findById '4fd43cc56d11340000000005', cb_wf
      (_district, cb_wf) ->
        district = _district
        assert (district instanceof clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Test District'
        district.properties cb_wf
      (properties, cb_wf) ->
        assert.deepEqual { some: { really: { nested: 'property' } } }, properties
        district.properties { test: 'data' }, cb_wf
      (properties, cb_wf) ->
        assert.deepEqual { test: 'data', some: { really: { nested: 'property' } } }, properties
        cb_wf()
    ], done
