_           = require 'underscore'
assert      = require 'assert'
async       = require 'async'
Clever      = require "#{__dirname}/../index"
highland    = require 'highland'

describe "require('clever/mock') [API KEY] [MOCK DATA DIR]", ->
  before ->
    @clever = require("#{__dirname}/../mock") 'api key', "#{__dirname}/mock_data"

  it "supports streaming GETs", (done) ->
    highland(@clever.Student.find().stream()).invoke("toJSON").collect().toCallback (err, data) ->
      assert.ifError err
      assert.deepEqual data, require("#{__dirname}/mock_data/students")
      done()

  it "supports count", (done) ->
    @clever.Student.find().count().exec (err, count) ->
      assert.ifError err
      assert.equal count, require("#{__dirname}/mock_data/students").length
      done()

  it "supports non-streaming GETs", (done) ->
    @clever.Student.find().exec (err, data) ->
      assert.ifError err
      assert.deepEqual _(data).invoke('toJSON'), require("#{__dirname}/mock_data/students")
      done()

  it "deep copies data", (done) ->
    async.waterfall [
      (cb_wf) =>
        @clever.Student.find().exec (err, students) ->
          assert.ifError err
          name = students[0].get 'name'
          assert.equal name.first, "John"
          name.first = 'WRONG NAME'
          cb_wf()
      (cb_wf) =>
        @clever.Student.find().exec (err, students) ->
          assert.ifError err
          name = students[0].get 'name'
          assert.equal name.first, "John"
          cb_wf()
    ], done

  describe 'findById', ->
    _.each ['51a5a56f4867bbdf51054055', '51a5a56f4867bbdf51054054'], (id) ->
      it "finds a student", (done) ->
        @clever.Student.findById id, (err, student) ->
          assert.ifError err
          assert.equal student.get('id'), id
          done()

    it "returns undefined if the id is not found", (done) ->
      @clever.Student.findById 'not an existing id', (err, student) ->
        assert.ifError err
        assert not student, 'Expected student to be undefined'
        done()
