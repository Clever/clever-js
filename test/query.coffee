async     = require 'async'
assert    = require 'assert'
_         = require 'underscore'
Clever    = require "#{__dirname}/../index"
nock      = require 'nock'

_([
  'DEMO_KEY'
  {api_key: 'DEMO_KEY'}
  {token: 'DEMO_TOKEN'}
]).each (auth) ->
  describe "query #{JSON.stringify auth}", ->

    before -> @clever = Clever auth, 'https://api.clever.com'

    it 'throws an error if you try to instantiate without an api key', ->
      assert.throws -> Clever()

    it 'find with no arguments', (done) ->
      @clever.District.find (err, districts) =>
        _(districts).each (district) =>
          assert (district instanceof @clever.District), "Incorrect type on district object"
          assert district.get('name')
        done()

    it 'find with conditions', (done) ->
      @clever.District.find { id: "4fd43cc56d11340000000005" }, (err, districts) =>
        assert.equal districts.length, 1
        district = districts[0]
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    it 'find with conditions and exec', (done) ->
      @clever.District.find(id: "4fd43cc56d11340000000005").exec (err, districts) =>
        assert.equal districts.length, 1
        district = districts[0]
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    it 'findOne with no arguments', (done) ->
      @clever.District.findOne (err, district) =>
        assert not _(district).isArray()
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    it 'findOne with conditions', (done) ->
      @clever.District.findOne { id: "4fd43cc56d11340000000005" }, (err, district) =>
        assert not _(district).isArray()
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    it 'findOne with conditions and exec', (done) ->
      @clever.District.findOne(id: "4fd43cc56d11340000000005").exec (err, district) =>
        assert not _(district).isArray()
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    it 'findById with no conditions throws', (done) ->
      assert.throws(
        () =>
          @clever.District.findById (err, district) -> assert false # shouldn't hit callback
        (err) ->
          ret = (err instanceof Error) and /must specify an ID/.test(err)
          setTimeout(done, 1000) if ret
          return ret
      )

    it 'findById', (done) ->
      @clever.District.findById "4fd43cc56d11340000000005", (err, district) =>
        assert not _(district).isArray()
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    # Failing because test data changed. See: https://clever.atlassian.net/browse/APPS-200
    it.skip 'findById with exec', (done) ->
      @clever.District.findById("4fd43cc56d11340000000005").exec (err, district) =>
        assert not _(district).isArray()
        assert (district instanceof @clever.District), "Incorrect type on district object"
        assert.equal district.get('name'), 'Demo District'
        done()

    # Failing because test data changed. See: https://clever.atlassian.net/browse/APPS-200
    it.skip 'find with a where condition', (done) ->
      @clever.School.find().where('name').equals('Clever High School').exec (err, schools) =>
        assert.equal schools.length, 1
        school = schools[0]
        assert (school instanceof @clever.School), "Incorrect type on school object"
        assert.equal school.get('name'), 'Clever High School'
        done()

    it 'successfully generates correct link with ending_before', (done) ->
      @timeout 30000
      clever = Clever 'FAKE_KEY', 'http://fake_api.com'
      scope = nock('http://fake_api.com')
        .get('/v1.1/students?where=%7B%7D&ending_before=last')
        .reply(401, {error: 'test succeeded'})
      clever.Student.find().ending_before('last').exec (err, students) ->
        assert not students
        assert.equal err.message, "received statusCode 401 instead of 200"
        assert.deepEqual err.body, {error: 'test succeeded'}
        scope.done()
        done()

    it 'successfully generates correct link with starting_after', (done) ->
      @timeout 30000
      clever = Clever 'FAKE_KEY', 'http://fake_api.com'
      scope = nock('http://fake_api.com')
        .get('/v1.1/students?where=%7B%7D&starting_after=12345')
        .reply(401, {error: 'test succeeded'})
      clever.Student.find().starting_after('12345').exec (err, students) ->
        assert not students
        assert.equal err.message, "received statusCode 401 instead of 200"
        assert.deepEqual err.body, {error: 'test succeeded'}
        scope.done()
        done()

    it 'find with starting_after and ending_before', (done) ->
      before_students = []
      async.waterfall [
        (cb_wf) =>
          # get the last 2 students
          @clever.Student.find().limit(2).ending_before('last').exec (err, students) =>
            before_students = students
            assert.equal students.length, 2
            assert (students[0] instanceof @clever.Student), "Incorrect type on student object"
            cb_wf()
        (cb_wf) =>
          # get the students after the second to last student
          @clever.Student.find().starting_after(before_students[0].get 'id').exec (err, students) =>
            assert.equal students.length, 1
            assert.equal students[0].get('id'), before_students[1].get('id')
            assert (students[0] instanceof @clever.Student), "Incorrect type on student object"
            cb_wf()
       ], (err) =>
        assert.ifError err
        done()

    # Failing because test data changed. See: https://clever.atlassian.net/browse/APPS-200
    it.skip 'count works', (done) ->
      @clever.School.find().where('name').equals('Clever High School').count().exec (err, count) ->
        assert.equal count, 1
        done()

    it 'supports custom resources', (done) ->
      clever = Clever "FAKE_KEY", "http://fake_api.com"
      class clever.NewResource extends clever.Resource
        @path: '/resource/path'
      scope = nock("http://fake_api.com")
        .get('/resource/path?where=%7B%7D')
        .reply(200, {data: [{uri: '/resource/path/some_id', data: {some_key: 'some_val'}}]})
      clever.NewResource.find (err, resources) ->
        assert.equal resources.length, 1
        resource = resources[0]
        assert resource instanceof clever.NewResource
        assert.equal resource.get('some_key'), 'some_val'
        scope.done()
        done err

    it 'exists true with where works', (done) ->
      @clever.School.find().where('name').exists(true).count().exec (err, count) ->
        assert.equal count, 3
        done()

    it 'exists without args works', (done) ->
      @clever.School.find().where('name').exists().count().exec (err, count) ->
        assert.equal count, 3
        done()

    it 'exists true works', (done) ->
      @clever.School.find().exists('name', true).count().exec (err, count) ->
        assert.equal count, 3
        done()

    it 'exists path works', (done) ->
      @clever.School.find().exists('name').count().exec (err, count) ->
        assert.equal count, 3
        done()

    it 'exists false with where works', (done) ->
      @clever.School.find().where('name').exists(false).count().exec (err, count) ->
        assert.equal count, 0
        done()

    it 'exists false works', (done) ->
      @clever.School.find().exists('name', false).count().exec (err, count) ->
        assert.equal count, 0
        done()

    it 'successfully handles invalid get requests that return a json', (done) ->
      @timeout 30000
      clever = Clever 'FAKE_KEY', 'http://fake_api.com'
      scope = nock('http://fake_api.com')
        .get('/v1.1/districts?where=%7B%22id%22%3A%2212345%22%7D&limit=1')
        .reply(401, {error: 'unauthorized'})
      clever.District.findById '12345', (err, district) ->
        assert not district
        assert.equal err.message, "received statusCode 401 instead of 200"
        assert.deepEqual err.body, {error: 'unauthorized'}
        scope.done()
        done()

    it 'successfully handles invalid get requests that return a json with exec', (done) ->
      @timeout 30000
      clever = Clever 'FAKE_KEY', 'http://fake_api.com'
      scope = nock('http://fake_api.com')
        .get('/v1.1/districts?where=%7B%22id%22%3A%2212345%22%7D&limit=1')
        .reply(401, {error: 'unauthorized'})
      clever.District.findById('12345').exec (err, district) ->
        assert not district
        assert.equal err.message, "received statusCode 401 instead of 200"
        assert.deepEqual err.body, {error: 'unauthorized'}
        scope.done()
        done()

    it 'successfully handles invalid get requests that return a string', (done) ->
      @timeout 30000
      clever = Clever 'FAKE_KEY', 'http://fake_api.com'
      scope = nock('http://fake_api.com')
        .get('/v1.1/districts?where=%7B%22id%22%3A%2212345%22%7D&limit=1')
        .reply(401, 'unauthorized')
      clever.District.findById '12345', (err, district) ->
        assert not district
        assert.equal err.message, "received statusCode 401 instead of 200"
        assert.equal err.body, 'unauthorized'
        scope.done()
        done()
