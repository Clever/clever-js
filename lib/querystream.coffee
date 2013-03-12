async       = require 'async'
_           = require 'underscore'
_.str       = require 'underscore.string'
quest       = require 'quest'
dotty       = require 'dotty'
{Readable}    = require 'readable-stream'
_(_.str.exports).mixin()

# takes in a Query, runs it and emits events
class QueryStream extends Readable
  constructor: (@query) ->
    super { objectMode: true }
    @running = false

  _read: () =>
    @run()

  run: () =>
    return if @running
    @running = true
    @query.exec (err, docs) =>
      @emit 'error', err if err
      #@emit 'data', doc for doc in docs
      @push doc for doc in docs
      if not @query.paging or @query.paging.current is @query.paging.total
        @push null
      else
        @query._options.page = @query.paging.current + 1
        @running = false
        process.nextTick @run

module.exports = QueryStream