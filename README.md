# Clever Javascript Library

[![Build Status](https://secure.travis-ci.org/Clever/clever-js.png)](http://travis-ci.org/Clever/clever-js)

## Installation

Via npm:

```bash
npm install clever
```

## Usage

```javascript
Clever = require('clever');
var clever = Clever({token: 'YOUR_BEARER_TOKEN'});
```
If you'd like to play around with our test data, please use the token: `DEMO_TOKEN`.
See [our developer guide](https://clever.com/developers/docs) for more information.

To use the outdated API key authentication method (not recommended!) pass the key when instantiating:
```javascript
var clever = Clever('YOUR_API_KEY');
```

The `clever` package exposes objects corresponding to resources:

* District
* School
* Section
* Student
* Teacher
* Event

Each exposes a query API that closely resembles that of [Mongoose](http://mongoosejs.com/docs/queries.html). The available methods are `find`, `findOne`, and `findById`:

```javascript
clever.District.find({}, function(error, districts) {
  assert(Array.isArray(districts));
  assert(districts[0] instanceof clever.District);
  assert.equal(district.get('name'), 'Demo District');
});

clever.School.findOne({ name: "Clever Academy" }, function(error, school) {
  assert(school instanceof clever.School);
  assert.equal(school.get('name'), 'Clever Academy');
});

clever.School.findById('4fee004cca2e43cf27000001', function(error, school) {
  assert(school instanceof clever.School);
  assert.equal(school.get('name'), 'Clever Academy');
});
```

When no callback is passed, the methods return a query object that allows you to build up a query over time:

```javascript
clever.School
.find()
.where('name').equals('Clever Academy')
.exec(callback);
```

Query objects also support a [stream](http://nodejs.org/api/stream.html) interface for auto-pagination:

```javascript
// pull sections 10 at a time
var count = 0;
var stream = clever.Section.find().limit(10).stream();
stream.on('data', function(section) {
  count += 1;
  assert(section instanceof clever.Section);
});
stream.on('end', function() {
  console.log(count, 'sections loaded');
});
```

## Feedback

Questions, feature requests, or feedback of any kind is always welcome! We're available at [tech-support@clever.com](mailto:tech-support@clever.com).
