async       = require 'async'
_           = require 'underscore'
quest       = require 'quest'
dotty       = require 'dotty'
certs       = require "#{__dirname}/data/clever.com_ca_bundle"
QueryStream = require "#{__dirname}/querystream"
_.mixin(require 'underscore.deep')

handle_errors = (resp, body, cb) ->
  return cb null, resp, body if resp.statusCode is 200
  err = new Error "received statusCode #{resp.statusCode} instead of 200"
  err.body = body
  err.resp = resp
  cb err

apply_auth = (auth, http_opts) ->
  if auth.api_key?
    _(http_opts).extend auth: "#{auth.api_key}:"
  else if auth.token?
    http_opts.headers ?= {}
    _(http_opts.headers).extend Authorization: "Bearer #{auth.token}"

module.exports = (auth, url_base='https://api.clever.com', options={}) ->
  throw new Error 'Must provide auth' if not auth
  auth = {api_key: auth} if _.isString auth
  clever =
    auth: auth
    url_base: url_base

  # adds pre/post function queues to an object
  class Middlewareable
    constructor: () ->
      @_pre  = {}
      @_post = {}
    pre:  (event, fn) => (@_pre[event]  ?= []).push fn
    post: (event, fn) => (@_post[event] ?= []).push fn

  # mongoose-like query API for an RESTful HTTP API
  # TODO: stream-like interface for paging
  class Query extends Middlewareable
    constructor: (@_url, @_conditions={}, @_options={}) ->
      super()
      @post 'exec', handle_errors
      @_curr_path = null

      # TODO: all
      _(['gt', 'gte', 'lt', 'lte', 'ne', 'in', 'nin', 'regex', 'size']).each (conditional) =>
        @[conditional] = (path, val) =>
          if arguments.length is 1
            val = path
            path = @_curr_path
          @_conditions[path] ?= {}
          @_conditions[path]["$#{conditional}"] = val
          @

      # TODO: skip (need support in api)
      _(['limit', 'page']).each (method) =>
        @[method] = (val) =>
          @_options[method] = val
          @

    where: (path, val) =>
      throw new Error 'path in where must be a string' if not _(path).isString()
      @_curr_path = path
      @_conditions[path] = val if arguments.length is 2
      @

    equals: (val) =>
      throw new Error 'must use equals() after where()' if not @_curr_path
      @_conditions[@_curr_path] = val
      @

    exists: (path, val) =>
      if not arguments.length
        path = @_curr_path
        val = true
      else if arguments.length is 1
        if _(path).isBoolean()
          val = path
          path = @_curr_path
        else
          val = true
      @_conditions[path] ?= {}
      @_conditions[path].$exists = val
      @

    select: (arg) =>
      console.log 'WARNING: TODO: select fields in the API' if arg
      @

    count: () =>
      @_options.count = true
      @

    exec: (cb) =>
      opts =
        method: 'get'
        uri: @_url
        qs: _({where: @_conditions}).extend @_options
        json: true
        ca: certs
      _(opts).extend(headers: options.headers) if options.headers
      apply_auth clever.auth, opts
      # convert stringify nested query params
      opts.qs[key] = JSON.stringify val for key, val of opts.qs when _(val).isObject()
      waterfall = [async.apply quest, opts].concat(@_post.exec or [])
      async.waterfall waterfall, cb

    stream: () => new QueryStream @

  class Writeback extends Middlewareable
    _method: null
    constructor: (@_uri, @_values) ->
      super()
      @post 'exec', handle_errors
    exec: (cb) =>
      opts =
        method: @_method
        uri: @_uri
        json: @_values
        ca: certs
      _(opts).extend(headers: options.headers) if options.headers
      apply_auth clever.auth, opts
      waterfall = [async.apply quest, opts].concat(@_post['exec'] or [])
      async.waterfall waterfall, cb
  class Update extends Writeback
    _method: 'patch'
  class Create extends Writeback
    _method: 'post'
  class Remove extends Writeback
    _method: 'delete'

  # adds query-creating functions to a class: find, findOne, etc.
  class Resource
    @path: null

    @_process_args: (conditions, fields, find_options={}, cb) ->
      if _(conditions).isFunction()
        cb = conditions
        conditions = {}
        fields = null
        find_options = {}
      else if _(fields).isFunction()
        cb = fields
        fields = null
        find_options = {}
      else if _(find_options).isFunction()
        cb = find_options
        find_options = {}
      [conditions, fields, find_options, cb]

    @_uri_to_class: (uri) ->
      klasses = _(clever).filter (val, key) -> val.path? # Filter out properties that aren't resources (e.g. api_path)
      Klass = _(klasses).find (Klass) -> uri.match new RegExp "^#{Klass.path}"
      throw new Error "Could not get type from uri: #{uri}, #{JSON.stringify klasses, undefined, 2}" if not Klass
      Klass

    @find: (conditions, fields, find_options, cb) ->
      [conditions, fields, find_options, cb] = @_process_args conditions, fields, find_options, cb
      q = new Query "#{clever.url_base}#{@path}", conditions, find_options
      q.select fields
      q.post 'exec', (resp, body, cb_post) =>
        q.links = body.links
        if body.data
          results = _(body.data).map (doc) =>
            Klass = @_uri_to_class doc.uri
            new Klass doc.data, doc.uri, doc.links
          cb_post null, results
        else if body.count?
          cb_post null, body.count
        else
          throw new Error "Could not parse query response: #{body}, #{JSON.stringify q, undefined, 2}"
      return q if not cb
      q.exec cb

    @findOne: (conditions, fields, find_options, cb) ->
      [conditions, fields, find_options, cb] = @_process_args conditions, fields, find_options, cb
      _(find_options).extend {limit: 1}
      if not cb
        q = @find conditions, fields, find_options
        q.post 'exec', (results, cb_post) -> cb_post null, results[0]
        q
      else
        @find conditions, fields, find_options, (err, docs) -> cb err, docs?[0]

    @findById: (id, fields, find_options, cb) ->
      throw new Error 'must specify an ID for findById' unless _(id).isString()
      conditions = id: id
      [conditions, fields, find_options, cb] = @_process_args conditions, fields, find_options, cb
      @findOne conditions, fields, find_options, cb

    constructor: (@_properties, @_uri, @_links) -> @_unsaved_values = {}

    get: (key) => dotty.get @_properties, key

    set: (key, val) => dotty.put @_unsaved_values, key, val

    save: (cb) =>
      update = @_properties.id?
      if update
        return cb null if not _(@_unsaved_values).keys().length
        w = new Update "#{clever.url_base}#{@_uri}", @_unsaved_values
      else
        #Create with the combination of @_properties and @_unsaved_values.
        w = new Create "#{clever.url_base}#{@constructor.path}", _.deepExtend(@_properties, @_unsaved_values)
        w.post 'exec', (resp, body, cb_post) =>
          self_link = _(body.links).find (link) -> link.rel is 'self'
          return cb_post new Error 'no self link' if not self_link?
          @_uri = self_link.uri
          cb_post null, resp, body
      w.post 'exec', (resp, body, cb_post) =>
        @_properties = if _(body.data).isString() then JSON.parse body.data else body.data # httpbin doesn't return json
        @_unsaved_values = {} if not err?
        cb_post null # No error if we got this far
      w.exec cb

    remove: (cb) =>
      r = new Remove "#{clever.url_base}#{@_uri}"
      r.post 'exec', (resp, body, cb_post) -> cb_post null # No error if we got this far
      r.exec cb

    to_json: => _(@_properties).clone()

    toJSON: => @to_json()

    properties: (obj, cb) =>
      opts =
        method: 'patch'
        uri: "#{clever.url_base}#{@constructor.path}/#{@_properties.id}/properties"
        json: obj
        ca: certs
      _(opts).extend(headers: options.headers) if options.headers
      apply_auth clever.auth, opts
      if _(obj).isFunction()
        cb = obj
        _(opts).extend { method: 'get', json: true }
      quest opts, (err, resp, body) =>
        return cb err if err
        handle_errors resp, body, (err, resp, body) ->
          return cb err if err
          cb err, body?.data

  class District extends Resource
    @path: '/v1.1/districts'
  class School extends Resource
    @path: '/v1.1/schools'
  class Section extends Resource
    @path: '/v1.1/sections'
  class Student extends Resource
    @path: '/v1.1/students'
  class Teacher extends Resource
    @path: '/v1.1/teachers'
  class Event extends Resource
    @path: '/v1.1/push/events'

  _(clever).extend
    Resource : Resource
    District : District
    School   : School
    Section  : Section
    Student  : Student
    Teacher  : Teacher
    Event    : Event
    Query    : Query

module.exports.handle_errors = handle_errors
