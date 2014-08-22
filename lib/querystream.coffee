async       = require 'async'
_           = require 'underscore'
quest       = require 'quest'
dotty       = require 'dotty'
url         = require 'url'
{Readable}    = require 'readable-stream'

# takes in a Query, runs it and emits events
class QueryStream extends Readable
  constructor: (@query) ->
    super { objectMode: true }
    @running = false

  _read: =>
    @run()

  run: =>
    return if @running
    @running = true
    @query.exec (err, docs) =>
      if err?
        @emit 'error', err
        return @push null

      @push doc for doc in docs

      next_link = _(@query.links).findWhere rel: 'next'
      if next_link?
        {host, pathname, query} = url.parse next_link.uri, true

        @query._options = query
        @running = false
        process.nextTick @run
      else
        @push null

module.exports = QueryStream
