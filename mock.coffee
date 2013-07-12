sinon    = require 'sinon'
Readable = require 'readable-stream'
_        = require 'underscore'
dotty    = require 'dotty'

_.mixin require('underscore.string').exports()
_.mixin require('understream').exports()

module.exports = (api_key, data_dir) ->
  throw new Error "Must provide api_key" unless api_key?
  throw new Error "Must provide data_dir" unless data_dir?

  clever = require("./index") api_key, "localhost"

  trequire = (fp) ->
    val = null
    if fs.existsSync("#{fp}.coffee") or fs.existsSync("#{fp}.js") or fs.existsSync("#{fp}.json")
      try
        val = require(fp)
      catch err
        throw "Error loading file at #{fp}: #{err}"
    return val or []

  clever.db =
    districts: trequire("#{data_dir}/districts")
    districtproperties: trequire("#{data_dir}/districtproperties")
    students: trequire("#{data_dir}/students")
    studentproperties: trequire("#{data_dir}/studentproperties")
    teachers: trequire("#{data_dir}/teachers")
    teacherproperties: trequire("#{data_dir}/teacherproperties")
    schools: trequire("#{data_dir}/schools")
    schoolproperties: trequire("#{data_dir}/schoolproperties")
  console.log "loaded #{clever.db[key].length} #{key}" for key, val of clever.db

  sandbox = sinon.sandbox.create()

  sandbox.stub clever.Query.prototype, 'exec', (cb) ->
    resource = _.strRightBack(@._url, '/')
    cb null, _(clever.db[resource]).map (raw_json) ->
      Klass = clever[_(resource).chain().capitalize().rtrim('s').value()]
      new Klass raw_json

  sandbox.stub clever.Query.prototype, 'stream', () ->
    resource = _.strRightBack(@_url, '/')
    s = _(clever.db[resource]).stream().map (raw_json) ->
      Klass = clever[_(resource).chain().capitalize().rtrim('s').value()]
      return new Klass raw_json
    process.nextTick () -> s.run((err) ->)
    return s.stream()

  sandbox.stub clever.Resource.prototype, 'properties', (obj, cb) ->
    if arguments.length is 1
      cb = obj
      obj = undefined
    else if arguments.length isnt 2
      throw new Error("expected 1 or 2 arguments to properties")
    resource = @constructor.name.toLowerCase() + 's'
    resource_singular = _(resource).rtrim('s')
    id = @_properties.id
    return cb(new Error("404")) unless _(clever.db[resource]).findWhere({id:id})
    prop_obj = _(clever.db["#{resource_singular}properties"]).findWhere(_.object [[resource_singular, id]])
    if not prop_obj
      prop_obj = _.object [[resource_singular, id], ['data', {}]]
      clever.db["#{resource_singular}properties"].push prop_obj
    if obj
      dotty.put prop_obj.data, k, v for k, v of obj
    return cb null, prop_obj.data

  clever
