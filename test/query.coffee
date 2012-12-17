async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'

describe 'query', ->

  clever = null
  before () ->
    clever = require "#{__dirname}/../index"
    clever.api_key = 'DEMO_KEY'

  it 'find with no arguments', (done) ->
    clever.District.find (err, districts) ->
      _(districts).each (district) ->
        assert (district instanceof clever.District), "Incorrect type on district object"
        assert district.get('name')
      done()

  it 'find with conditions', (done) ->
    clever.District.find { id: "4fd43cc56d11340000000005" }, (err, districts) ->
      assert.equal districts.length, 1
      district = districts[0]
      assert (district instanceof clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findOne with no arguments', (done) ->
    clever.District.findOne (err, district) ->
      assert not _(district).isArray()
      assert (district instanceof clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findOne with conditions', (done) ->
    clever.District.findOne { id: "4fd43cc56d11340000000005" }, (err, district) ->
      assert not _(district).isArray()
      assert (district instanceof clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()

  it 'findById with no conditions throws', (done) ->
    assert.throws(
      () ->
        clever.District.findById (err, district) -> assert false # shouldn't hit callback
      (err) ->
        ret = (err instanceof Error) and /must specify an ID/.test(err)
        setTimeout(done, 1000) if ret
        return ret
    )

  it 'findById', (done) ->
    clever.District.findById "4fd43cc56d11340000000005", (err, district) ->
      assert not _(district).isArray()
      assert (district instanceof clever.District), "Incorrect type on district object"
      assert.equal district.get('name'), 'Demo District'
      done()
