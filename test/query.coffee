async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"

describe 'query', ->

  before -> @clever = Clever 'DEMO_KEY', 'https://api.getclever.com'

  it 'find with no arguments', (done) ->
    @clever.District.find (err, districts) =>
      _(districts).each (district) =>
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert district.get('name')
      done()

  it 'find with conditions', (done) ->
    @clever.District.find { id: "4fd43cc56d11340000000005" }, (err, districts) =>
      assert.equal districts.length, 1
      district = districts[0]
      assert (district instanceof @clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findOne with no arguments', (done) ->
    @clever.District.findOne (err, district) =>
      assert not _(district).isArray()
      assert (district instanceof @clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findOne with conditions', (done) ->
    @clever.District.findOne { id: "4fd43cc56d11340000000005" }, (err, district) =>
      assert not _(district).isArray()
      assert (district instanceof @clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findById with no conditions throws', (done) ->
    assert.throws(
      () =>
        @clever.District.findById (err, district) -> assert false # shouldn't hit callback
      (err) ->
        ret = (err instanceof Error) and /must specify an ID/.test(err)
        setTimeout(done, 1000) if ret
        return ret
    )

  it 'findById', (done) ->
    @timeout 20000
    @clever.District.findById "4fd43cc56d11340000000005", (err, district) =>
      assert not _(district).isArray()
      assert (district instanceof @clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'find with a where condition', (done) ->
    @clever.School.find().where('name').equals('Clever Academy').exec (err, schools) =>
      assert.equal schools.length, 1
      school = schools[0]
      assert (school instanceof @clever.School), "Incorrect type on school object"
      assert.equal school.get('name'), 'Clever Academy'
      done()

  it 'count works', (done) ->
    @clever.School.find().where('name').equals('Clever Academy').count().exec (err, count) ->
      assert.equal count, 1
      done()

  it 'exists true with where works', (done) ->
    @clever.School.find().where('name').exists(true).count().exec (err, count) ->
      assert.equal count, 4
      done()

  it 'exists without args works', (done) ->
    @clever.School.find().where('name').exists().count().exec (err, count) ->
      assert.equal count, 4
      done()

  it 'exists true works', (done) ->
    @clever.School.find().exists('name', true).count().exec (err, count) ->
      assert.equal count, 4
      done()

  it 'exists false with where works', (done) ->
    @clever.School.find().where('name').exists(false).count().exec (err, count) ->
      assert.equal count, 0
      done()

  it 'exists false works', (done) ->
    @clever.School.find().exists('name', false).count().exec (err, count) ->
      assert.equal count, 0
      done()