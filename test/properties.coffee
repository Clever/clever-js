async     = require 'async'
assert    = require 'assert'
_         = require 'underscore'
nock      = require 'nock'
Clever    = require "#{__dirname}/../index"

_.each ['District', 'Student', 'Teacher', 'Section', 'School'], (resource_name) ->

  describe 'get/set properties', ->

    before -> @clever = Clever 'DEMO_KEY', 'https://api.getclever.com'

    after -> nock.cleanAll()

    endpoint = resource_name.toLowerCase() + 's'
    it "can hit second-level for properties - #{resource_name}", (done) ->
      nock('https://api.getclever.com:443')
        .get("/v1.1/#{endpoint}?where=%7B%22id%22%3A%224fd43cc56d11340000000005%22%7D&limit=1").reply(200,
          data: [
            data:
              name: "Test #{resource_name}"
              id: '4fd43cc56d11340000000005'
            uri: "/v1.1/#{endpoint}/4fd43cc56d11340000000005"
          ]
        ).get("/v1.1/#{endpoint}/4fd43cc56d11340000000005/properties").reply(200,
          data:
            some: { really: { nested: 'property' } }
        ).patch("/v1.1/#{endpoint}/4fd43cc56d11340000000005/properties", { test: 'data' }).reply(200,
          data:
            some: { really: { nested: 'property' } }
            test: 'data'
        )
      resource = null
      async.waterfall [
        (cb_wf) =>
          @clever[resource_name].findById '4fd43cc56d11340000000005', cb_wf
        (_resource, cb_wf) =>
          resource = _resource
          assert (resource instanceof @clever[resource_name]), "Incorrect type on #{resource_name} object"
          assert.equal resource.get('name'), "Test #{resource_name}"
          resource.properties cb_wf
        (properties, cb_wf) ->
          assert.deepEqual { some: { really: { nested: 'property' } } }, properties
          resource.properties { test: 'data' }, cb_wf
        (properties, cb_wf) ->
          assert.deepEqual { test: 'data', some: { really: { nested: 'property' } } }, properties
          cb_wf()
      ], done
