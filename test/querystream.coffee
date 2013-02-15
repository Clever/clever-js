async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"

describe 'querystream', ->

  clever = null
  before ->
    clever = Clever 'DEMO_KEY', 'https://api.getclever.com'

  it 'takes care of paging for you', (done) ->
    @timeout 40000
    query = clever.Section.find().limit(10)
    stream = query.stream()
    cnt = 0
    stream.on 'data', (section) ->
      cnt += 1
      assert (section instanceof clever.Section), "Incorrect type on section object"
    stream.on 'error', (err) -> assert false, "There shouldn't be an error"
    stream.on 'end', (err) ->
      assert.equal query.paging.count, cnt
      done()
