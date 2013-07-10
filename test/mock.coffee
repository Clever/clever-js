assert = require 'assert'
Clever    = require "#{__dirname}/../index"
_     = require 'underscore'
_.mixin require('understream').exports()

describe "require('clever/mock') [API KEY] [MOCK DATA DIR]", ->
  before ->
    @clever = require("#{__dirname}/../mock") 'api key', "#{__dirname}/mock_data"

  it "supports streaming GETs", (done) ->
    _(@clever.Student.find().stream()).stream().invoke('toJSON').value (data) ->
      assert.deepEqual data, require("#{__dirname}/mock_data/students")
      done()
    .run assert.ifError

  it "supports non-streaming GETs", (done) ->
    @clever.Student.find().exec (err, data) ->
      assert.ifError err
      assert.deepEqual _(data).invoke('toJSON'), require("#{__dirname}/mock_data/students")
      done()

  it "supports GETting properties", (done) ->
    @clever.Student.find().exec (err, students) => # TODO: get findOne working
      students[0].properties (err, data) =>
        assert.ifError err
        assert.deepEqual data, _(require("#{__dirname}/mock_data/studentproperties")).findWhere({student: students[0].get('id')}).data
      done()

  it "supports PUTting properties", (done) ->
    @clever.Student.find().exec (err, students) =>
      assert.ifError err
      students[1].properties {foo: 'baz'}, (err, data) =>
        assert.ifError err
        assert.deepEqual data, {foo: 'baz'}
        @clever.Student.find().exec (err, students) =>
          assert.ifError err
          students[1].properties (err, data) =>
            assert.deepEqual data, {foo: 'baz'}
            done()
