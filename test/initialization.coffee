async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'

_([
  args: ["DEMO_KEY"]
,
  args: ["DEMO_KEY", "https://fake_api.com"]
,
  args: ["DEMO_KEY", "https://fake_api.com", {headers:"X-Dont-Taze-Me": "Bro"}]
]).each ({args}) ->

  expected_api_path = args[1] or "https://api.clever.com"
  expected_headers = args[2]?.headers or {}

  describe "initialized with options #{args[0]}@#{expected_api_path} with headers: #{JSON.stringify expected_headers}", ->

    generate_nock = (method) ->
      scope = nock(expected_api_path)
      scope.matchHeader(k, v) for k, v of expected_headers
      scope.filteringPath(/.+/, "*")
      scope[method]("*").reply(200, {data: {}, paging: {}, links: [rel: "self"]})
      scope

    before ->
      @clever = Clever.apply(@, args)

    describe 'query requests', ->
      beforeEach ->
        @scope = generate_nock("get")
      afterEach ->
        @scope.done()
        nock.cleanAll()

      it "make requests with the expected path and headers", (done) ->
        @clever.District.find done

    describe 'writeback requests', ->
      beforeEach ->
        @scope = generate_nock("post")
      afterEach ->
        @scope.done()
        nock.cleanAll()

      it "make requests with the expected path and headers", (done) ->
        (new @clever.District({"name"})).save done

    describe 'property requests', ->
      beforeEach ->
        @scope = generate_nock("get")
      afterEach ->
        @scope.done()
        nock.cleanAll()

      it "make requests with the expected path and headers", (done) ->
        d = new @clever.District {"name"}
        d.properties done























































    # describe 'submits writeback requests', ->

    # describe 'submits property requests', ->

    #   assert_correct_district_save = (district, done) ->
    #     district.save (err) ->
    #       assert.ifError err
    #       assert.equal district.get('name'), 'Test'
    #       assert.equal district.get('location.address'), 'Tacos'
    #       assert.equal district.get('location.city'), 'Burritos'
    #       assert.deepEqual district.get('location'), {address: 'Tacos', city: 'Burritos'}
    #       assert.equal district._uri, '/v1.1/districts/1235'
    #       done()

    #   it 'when created using the constructor', (done) ->
    #     district = new @clever.District
    #       name: 'Test'
    #       location:
    #         address: 'Tacos'
    #         city: 'Burritos'
    #     assert_correct_district_save district, done

    #   it 'when created using .set()', (done) ->
    #     district = new @clever.District({})
    #     district.set("name", "Test")
    #     district.set("location.address", "Tacos")
    #     district.set("location.city", "Burritos")
    #     assert_correct_district_save district, done

    #   it 'when created using .set() and the constructor', (done) ->
    #     district = new @clever.District
    #       name: "Test"
    #       location:
    #         address: "Tacos"
    #         city: "Tostada" #No one likes tostadas
    #     district.set("location.city", "Burritos")
    #     assert_correct_district_save district, done

    # it 'successfully handles invalid post requests that return a json', (done) ->
    #   @timeout 30000
    #   scope = nock('http://fake_api.com')
    #     .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos'})
    #     .reply(401, {error: 'unauthorized'})
    #   district = new @clever.District
    #     name: 'Test'
    #     location:
    #       address: 'Tacos'
    #   district.save (err) ->
    #     assert.equal err?.message, "received statusCode 401 instead of 200"
    #     assert.deepEqual err.body, {error: 'unauthorized'}
    #     scope.done()
    #     done()

    # it 'successfully handles invalid post requests that return a string', (done) ->
    #   @timeout 30000
    #   scope = nock('http://fake_api.com')
    #     .post('/v1.1/districts', {name: 'Test', location: address: 'Tacos'})
    #     .reply(401, 'unauthorized')
    #   district = new @clever.District
    #     name: 'Test'
    #     location:
    #       address: 'Tacos'
    #   district.save (err) ->
    #     assert.equal err?.message, "received statusCode 401 instead of 200"
    #     assert.equal err.body, 'unauthorized'
    #     scope.done()
    #     done()
