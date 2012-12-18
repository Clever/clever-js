async       = require 'async'
_           = require 'underscore'
_.str       = require('underscore.string');
_.mixin _.str.exports()
quest       = require 'quest'
dotty       = require 'dotty'
QueryStream = require "#{__dirname}/querystream"

clever =
  api_key: null
  url_base: 'https://api.getclever.com'

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
    @_curr_path = null

    # TODO: all
    _('gt gte lt lte ne in nin regex size').chain().words().each (conditional) =>
      @[conditional] = (path, val) =>
        if (arguments.length is 1)
          val = path
          path = @_curr_path
        path_conds = @_conditions[path] or (@_conditions[path] = {})
        path_conds["$#{conditional}"] = val
        @

    # TODO: skip (need support in api)
    _('limit page').chain().words().each (method) =>
      @[method] = (val) =>
        @_options[method] = val
        @

  where: (path, val) =>
    throw Error('path in where must be a string') if not _(path).isString()
    @_curr_path = path
    @_conditions[path] = val if arguments.length is 2
    @

  equals: (val) =>
    throw Error('must use equals() after where()') if not @_curr_path
    @_conditions[@_curr_path] = val
    @

  exists: (path, val) =>
    if not arguments.length
      path = @_curr_path
      val = true
    else if arguments.length is 1
      if _(path).isBoolean()
        path = @_curr_path
        val = true
      else
        val = true
    path_conds = @_conditions[path] or (@_conditions[path] = {})
    path_conds.$exists = val
    @

  select: (arg) =>
    if arg
      console.log 'WARNING: TODO: select fields in the API'
    @

  count: () =>
    @_options.count = true
    @

  exec: (cb) =>
    opts =
      method: 'get'
      uri: "#{@_url}"
      headers: { Authorization: "Basic #{new Buffer(clever.api_key).toString('base64')}" }
      qs: _({ where: @_conditions }).extend @_options
      json: true
    # convert stringify nested query params
    for key, val of opts.qs
      continue if not _(val).isObject()
      opts.qs[key] = JSON.stringify(val)
    #console.log opts
    waterfall = [ async.apply(quest, opts) ].concat(@_post['exec'] or [])
    async.waterfall waterfall, cb

  stream: () => new QueryStream @

class Update extends Middlewareable
  constructor: (@_url, @_values) ->
    super()
  exec: (cb) =>
    opts =
      method: 'put'
      uri: "#{@_url}"
      headers: { Authorization: "Basic #{new Buffer(clever.api_key).toString('base64')}" }
      json: @_values
    #console.log opts
    waterfall = [ async.apply(quest, opts) ].concat(@_post['exec'] or [])
    async.waterfall waterfall, cb

# adds query-creating functions to a class: find, findOne, etc.
class Resource
  @path: null

  @_process_args: (conditions, fields, options, cb) ->
    if _(conditions).isFunction()
      cb = conditions
      conditions = {}
      fields = null
      options = {}
    else if _(fields).isFunction()
      cb = fields
      fields = null
      options = {}
    else if _(options).isFunction()
      cb = options
      options = {}
    [ conditions, fields, options, cb ]

  @_create_from_resp: (resp) ->
    klasses =
      'districts'   : District
      'schools'     : School
      'students'    : Student
      'sections'    : Section
      'teachers'    : Teacher
      'push/events' : Event
    match = resp.uri.match /^\/v1.1\/([a-z_]+)\/[0-9a-f]+$/
    Klass = klasses[match?[1]]
    throw Error("Could not get type from uri: #{resp.uri}, #{match}") if not Klass
    new Klass resp.data, resp.uri, resp.links

  @find: (conditions, fields, options, cb) ->
    [conditions, fields, options, cb] = @_process_args conditions, fields, options, cb
    q = new Query "#{clever.url_base}#{@path}", conditions, options
    q.select fields
    q.post 'exec', (resp, body, cb_post) =>
      q.paging = body.paging
      if body.data
        results = _(body.data).map (doc) => @_create_from_resp doc
        cb_post null, results
      else if body.count
        cb_post null, body.count
      else
        throw Error "Could not parse query response: #{body}, #{JSON.stringify q, undefined, 2}"
    return q if not cb
    q.exec cb

  @findOne: (conditions, fields, options, cb) ->
    [ conditions, fields, options, cb ] = @_process_args conditions, fields, options, cb
    _(options).extend { limit: 1 }
    @find conditions, fields, options, (err, docs) ->
      cb err, docs[0]

  @findById: (id, fields, options, cb) ->
    throw Error('must specify an ID for findById') if not id or not _(id).isString()
    conditions = { id: id }
    [ conditions, fields, options, cb ] = @_process_args conditions, fields, options, cb
    @findOne conditions, fields, options, cb

  constructor: (@_properties, @_uri, @_links) ->
    @_unsaved_values = {}

  get: (key) =>
    dotty.get @_properties, key

  set: (key, val) =>
    dotty.put @_unsaved_values, key, val

  save: (cb) =>
    return cb(null) if not _(@_unsaved_values).keys().length
    u = new Update "#{@_uri}", @_unsaved_values
    u.post 'exec', (resp, body, cb_post) =>
      @_properties = if _(body.data).isString()? then JSON.parse(body.data) else body.data # httpbin doesn't return json
      @_unsaved_values = {} if not err?
      cb_post()
    u.exec cb

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
  District : District
  School   : School
  Section  : Section
  Student  : Student
  Teacher  : Teacher
  Event    : Event

module.exports = clever
