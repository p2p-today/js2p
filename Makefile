#This help message was taken from https://gist.github.com/rcmachado/af3db315e31383502660
## Show this help.
help:
	@printf "Available targets\n\n"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-20s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

## Initialize submodules
submodules:
	@git submodule update --init --recursive

jsver = $(shell node -p "require('./package.json').version")

## Install Javascript dependencies, preferring to use yarn, but using npm if it must
jsdeps: LICENSE
	@mv npm-shrinkwrap.json .npm-shrinkwrap.json; \
	yarn || npm install; \
	mv .npm-shrinkwrap.json npm-shrinkwrap.json

## Copying documentation from C-like language into the proper Restructred Text files
jsdocs:
	@echo "Copying documentation comments..."
	@node src/docs_test.js

## Run Javascript test code
jstest: jsdeps
	@node node_modules/istanbul/lib/cli.js cover node_modules/mocha/bin/_mocha src/test/*

## Run Javascript tests AND upload results to codecov (testing services only)
js_codecov: jstest
	@node node_modules/codecov/bin/codecov -f coverage/coverage.json --token=d89f9bd9-27a3-4560-8dbb-39ee3ba020a5

## Package Javascript code into browser bundles
browser: jsdeps
	@mkdir -p build/browser
	@echo "Building browser version..."
	@cd src;\
	node ../node_modules/browserify/bin/cmd.js -r ./base.js -o ../build/browser/js2p-browser-$(jsver)-base.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../node_modules/browserify/bin/cmd.js -x ./base.js -r ./mesh.js -o ../build/browser/js2p-browser-$(jsver)-mesh.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -r ./sync.js -o ../build/browser/js2p-browser-$(jsver)-sync.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -r ./chord.js -o ../build/browser/js2p-browser-$(jsver)-chord.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -x ./sync.js -x ./chord.js -e ./js2p.js -o ../build/browser/js2p-browser-$(jsver).js -s js2p

## Package Javascript code into browser bundles and minify them
browser-min: browser
	@mkdir -p build/browser-min
	@echo "Minifying..."
	@node node_modules/babel-cli/bin/babel.js ./build/browser/js2p-browser-$(jsver).js       -o ./build/browser-min/js2p-browser-$(jsver).min.js       --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser/js2p-browser-$(jsver)-base.js  -o ./build/browser-min/js2p-browser-$(jsver)-base.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser/js2p-browser-$(jsver)-mesh.js  -o ./build/browser-min/js2p-browser-$(jsver)-mesh.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser/js2p-browser-$(jsver)-sync.js  -o ./build/browser-min/js2p-browser-$(jsver)-sync.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser/js2p-browser-$(jsver)-chord.js -o ./build/browser-min/js2p-browser-$(jsver)-chord.min.js --minified --no-comments --no-babelrc

## Transpile Javascript code into a non ES6 format, for older browsers or Node.js v4
js-compat: jsdeps
	@mkdir -p build/browser-compat build/babel
	@echo "Transpiling..."
	@node node_modules/babel-cli/bin/babel.js src -d build/babel

## Transpile Javascript code into a non ES6 format, for older browsers or Node.js v4 AND test this code
js_compat_test: js-compat
	@echo "Testing transpilation..."
	@node node_modules/istanbul/lib/cli.js cover node_modules/mocha/bin/_mocha build/babel/test/*

## Transpile Javascript code into a non ES6 format, for older browsers or Node.js v4 AND test this code AND upload it to codecov (testing services only)
js_compat_codecov: js_compat_test
	@node node_modules/codecov/bin/codecov -f coverage/coverage.json --token=d89f9bd9-27a3-4560-8dbb-39ee3ba020a5

## Transpile Javascript code into a non ES6 format, for older browsers or Node.js v4 AND package it into browser bundles
browser-compat: js-compat
	@echo "Building browser version..."
	@cd build/babel;\
	node ../../node_modules/browserify/bin/cmd.js -r ./base.js -o ../browser-compat/js2p-browser-$(jsver)-base.babel.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../../node_modules/browserify/bin/cmd.js -x ./base.js -r ./mesh.js -o ../browser-compat/js2p-browser-$(jsver)-mesh.babel.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -r ./sync.js -o ../browser-compat/js2p-browser-$(jsver)-sync.babel.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -r ./chord.js -o ../browser-compat/js2p-browser-$(jsver)-chord.babel.js -u snappy -u nodejs-websocket -u node-forge;\
	node ../../node_modules/browserify/bin/cmd.js -x ./base.js -x ./mesh.js -x ./sync.js -x ./chord.js -e ./js2p.js -o ../browser-compat/js2p-browser-$(jsver).babel.js -s js2p

## Transpile Javascript code into a non ES6 format, for older browsers or Node.js v4 AND package it into browser bundles, then minify it
browser-compat-min: browser-compat
	@mkdir -p build/browser-compat-min
	@echo "Minifying..."
	@node node_modules/babel-cli/bin/babel.js ./build/browser-compat/js2p-browser-$(jsver).babel.js       -o ./build/browser-compat-min/js2p-browser-$(jsver).babel.min.js       --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser-compat/js2p-browser-$(jsver)-base.babel.js  -o ./build/browser-compat-min/js2p-browser-$(jsver)-base.babel.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser-compat/js2p-browser-$(jsver)-mesh.babel.js  -o ./build/browser-compat-min/js2p-browser-$(jsver)-mesh.babel.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser-compat/js2p-browser-$(jsver)-sync.babel.js  -o ./build/browser-compat-min/js2p-browser-$(jsver)-sync.babel.min.js  --minified --no-comments --no-babelrc
	@node node_modules/babel-cli/bin/babel.js ./build/browser-compat/js2p-browser-$(jsver)-chord.babel.js -o ./build/browser-compat-min/js2p-browser-$(jsver)-chord.babel.min.js --minified --no-comments --no-babelrc

## Alias for the above
browser-min-compat: browser-compat-min

## Clean up local folders, including Javascript depenedencies
clean:
	rm -rf node_modules build

## Run all Javascript-related build recipes
all: LICENSE ES5 html browser browser-min browser-compat browser-compat-min
