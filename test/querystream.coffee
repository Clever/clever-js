async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"

describe 'querystream', ->

  before -> @clever = Clever 'DEMO_KEY', 'https://api.clever.com'

  it 'takes care of paging for you', (done) ->
    @timeout 40000
    async.waterfall [
      (cb_w) =>
        query = @clever.Section.find().count().exec cb_w
      (count, cb_w) =>
        query = @clever.Section.find().limit(100)
        stream = query.stream()
        cur = 0
        stream.on 'data', (section) =>
          cur += 1
          assert (section instanceof @clever.Section), "Incorrect type on section object"
        stream.on 'error', (err) -> assert false, "There shouldn't be an error: #{err}"
        stream.on 'end', (err) ->
          assert _.filter(query.links, (link) -> link.rel is 'next').length is 0,
            'No next links should remain'
          assert cur is count, "Only got #{cur}/#{count} entries!"
          done()
    ], assert.ifError


  it 'handles errors correctly', (done) ->
    clever = Clever 'INVALID_KEY', 'https://api.clever.com'
    query = clever.Section.find().limit(10)
    stream = query.stream()
    stream.on 'data', (section) ->
      assert false, "no data should be returned for INVALID_KEY"
    stream.on 'error', (err) ->
      assert (err instanceof Error) and /received statusCode 401 instead of 200/.test(err)
    stream.on 'end', (err) ->
      assert.ifError err
      done()

