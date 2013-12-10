assert = require 'assert'
Clever    = require "#{__dirname}/../index"
_     = require 'underscore'
_.mixin require('understream').exports()

describe "require('clever/mock') [API KEY] [MOCK DATA DIR]", ->
  before ->
    @clever = require("#{__dirname}/../mock") 'api key', "#{__dirname}/mock_data"

  it "supports streaming GETs", (done) ->
    _(@clever.Student.find().stream()).stream().invoke('toJSON').run (err, data) ->
      assert.ifError err
      assert.deepEqual data, require("#{__dirname}/mock_data/students")
      done()

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

  _.each ['51a5a56f4867bbdf51054055', '51a5a56f4867bbdf51054054'], (id) ->
    it "supports findById(#{id})", (done) ->
      @clever.Student.findById id, (err, student) ->
        assert.ifError err
        assert.equal student.get('id'), id
        done()
