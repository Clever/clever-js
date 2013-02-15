async       = require 'async'
_           = require 'underscore'
_.str       = require 'underscore.string'
quest       = require 'quest'
dotty       = require 'dotty'
{Stream}    = require 'stream'
_(_.str.exports()).mixin()

# takes in a Query, runs it and emits events
class QueryStream extends Stream
  constructor: (@query) ->
    @readable = true
    @paused = false
    process.nextTick @run

  run: () =>
    @query.exec (err, docs) =>
      @emit 'error', err if err
      @emit 'data', doc for doc in docs
      if (not @query.paging) or (@query.paging.current is @query.paging.total)
        @emit 'end'
      else
        @query._options.page = @query.paging.current + 1
        @run()

module.exports = QueryStream