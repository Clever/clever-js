test-cov:
	rm -rf lib-js lib-js-cov
	coffee -c -o lib-js lib
	jscoverage lib-js lib-js-cov
	NODE_ENV=test TEST_COV_CLEVERJS=1 node_modules/mocha/bin/mocha -R html-cov --ignore-leaks --compilers coffee:coffee-script test/query.coffee | tee coverage.html
	open coverage.html

test:
	NODE_ENV=test node_modules/mocha/bin/mocha --ignore-leaks --compilers coffee:coffee-script test/query.coffee

clean:
	rm -rf lib-js lib-js-cov
