async     = require 'async'
fs        = require 'fs'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'
util      = require 'util'

describe 'methods', ->
  before () -> @clever = Clever 'DEMO_KEY', 'http://httpbin.org'
  it 'allows calling to_json', ->
    district = new @clever.District { name: 'Test', id: '1212121' }, '/put'
    assert.deepEqual district?.to_json?(), _(district._properties).clone()
  it 'allows calling toJSON', ->
    district = new @clever.District { name: 'Test', id: '1212121' }, '/put'
    assert.deepEqual district?.toJSON?(), _(district._properties).clone()
