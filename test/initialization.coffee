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

    generate_nock = ->
      scope = nock(expected_api_path)
      scope.matchHeader(k, v) for k, v of expected_headers
      scope.filteringPath(/.+/, "*")
      scope.get("*").reply(200, {data: {}, paging: {}, links: [rel: "self"]})
      scope

    before ->
      @clever = Clever.apply(@, args)

    describe 'query requests', ->
      beforeEach ->
        @scope = generate_nock()
      afterEach ->
        @scope.done()
        nock.cleanAll()

      it "make requests with the expected path and headers", (done) ->
        @clever.District.find done
