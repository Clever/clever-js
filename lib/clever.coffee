async     = require 'async'
_         = require 'underscore'
_.str     = require('underscore.string');
_.mixin _.str.exports()
quest     = require 'quest'
dotty     = require 'dotty'

clever =
  api_key: null
  url_base: 'https://api.getclever.com'

# mongoose-like query API for an RESTful HTTP API
# TODO: stream-like interface for paging
class Query
  constructor: (@_url, @_conditions, @_options) ->
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

  exec: (cb) =>
    opts =
      method: 'get'
      uri: "#{@_url}"
      headers: { Authorization: "Basic #{new Buffer(clever.api_key).toString('base64')}" }
      query: _({ where: @_conditions }).extend @_options
      json: true
    quest opts, (err, resp, body) => cb err, body.data

# adds query-creating functions to a class: find, findOne
class Queryable
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

  @find: (conditions, fields, options, cb) -> # need to use -> to allow overriding of @path
    [conditions, fields, options, cb] = @_process_args conditions, fields, options, cb
    q = new Query "#{clever.url_base}#{@path}", conditions, options
    q.select fields
    return q if not cb
    q.exec (err, docs) =>
      results = _(docs).map (doc) =>
        match = doc.uri.match /^\/v1.1\/([a-z_]+)\/[0-9a-f]+$/
        switch match[1]
          when 'districts'
            return new District doc.data, doc.uri, doc.links
          when 'schools'
            return new School doc.data, doc.uri, doc.links
          when 'sections'
            return new Section doc.data, doc.uri, doc.links
          when 'students'
            return new Student doc.data, doc.uri, doc.links
          when 'teachers'
            return new Teacher doc.data, doc.uri, doc.links
          when 'push/events'
            return new Event doc.data, doc.uri, doc.links
          else
            throw Error("Could not get type from uri: #{doc.uri}")
      cb err, results

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

class District extends Queryable
  @path: '/v1.1/districts'

class School extends Queryable
  @path: '/v1.1/schools'

class Section extends Queryable
  @path: '/v1.1/sections'

class Student extends Queryable
  @path: '/v1.1/students'

class Teacher extends Queryable
  @path: '/v1.1/teachers'

class Event extends Queryable
  @path: '/v1.1/push/events'

_(clever).extend
  District : District
  School   : School
  Section  : Section
  Student  : Student
  Teacher  : Teacher
  Event    : Event

module.exports = clever
