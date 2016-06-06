_           = require 'underscore'
dotty       = require 'dotty'
fs          = require 'fs'
Readable    = require 'readable-stream'
sinon       = require 'sinon'
highland    = require 'highland'
_.mixin require('underscore.string').exports()
_.mixin require('underscore.deep')

# This is still an unstable interface.
module.exports = (api_key, data_dir) ->
  throw new Error "Must provide api_key" unless api_key?
  throw new Error "Must provide data_dir" unless data_dir?

  clever = require("./index") api_key, "localhost"

  trequire = (fp) ->
    val = []
    if fs.existsSync("#{fp}.coffee") or fs.existsSync("#{fp}.js") or fs.existsSync("#{fp}.json")
      try
        val = require(fp)
      catch err
        throw new Error "Error loading file at #{fp}: #{err}"
    val

  # clever.db[resource] are arrays of resources
  clever.db =
    districts: trequire("#{data_dir}/districts")
    students: trequire("#{data_dir}/students")
    teachers: trequire("#{data_dir}/teachers")
    schools: trequire("#{data_dir}/schools")

  # clever.map[resources] are maps from ids to resources (for faster lookup)
  # This doesn't just replace clever.db for compatibility reasons..for now..
  clever.refresh_map = ->
    map_id_to_val = (db, resource, id_key) ->
      map = {}
      map[obj[id_key]] = obj for i, obj of db[resource]
      map
    clever.map =
      districts: map_id_to_val clever.db, 'districts', 'id'
      students: map_id_to_val clever.db, 'students', 'id'
      teachers: map_id_to_val clever.db, 'teachers', 'id'
      schools: map_id_to_val clever.db, 'schools', 'id'
  clever.refresh_map()

  sandbox = sinon.sandbox.create()

  apply_query = (highlandsomething, conditions, resource) ->
    return highlandsomething.filter (obj) ->
      for key, val of conditions
        return false unless obj[key] is val
      return true
    .map (obj) ->
      if obj._shadow? then  _.extend({}, obj, obj._shadow) else obj
    .map (raw_json) ->
      Klass = clever[_(resource).chain().capitalize().rtrim('s').value()]
      return new Klass _.deepClone raw_json

  sandbox.stub clever.Query.prototype, 'exec', (cb) ->
    resource = _.strRightBack(@_url, '/')
    s = apply_query highland(clever.db[resource]), @_conditions, resource
    s.collect().toCallback (err, data) =>
      return setImmediate cb err if err?
      return setImmediate cb, null, data.length if @_options.count
      setImmediate cb, null, data

  sandbox.stub clever.Query.prototype, 'stream', ->
    resource = _.strRightBack(@_url, '/')
    s = apply_query highland(clever.db[resource]), @_conditions, resource
    return s

  clever
