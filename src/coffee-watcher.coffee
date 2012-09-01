# **coffee-watcher** is a script that can watch
# a directory and recompile your [.coffee scripts](http://coffeescript.org/) if they change.
#
# It's very useful for development as you don't need to think about
# recompiling your CoffeeScript files.  Search is done in a recursive manner
# so sub-directories are handled as well.
#
#     Usage:
#       coffee-watcher -p [prefix] -d [directory]
#
#     Options:
#       -d  Specify which directory to scan.                                                                              [default: "."]
#       -p  Which prefix should the compiled files have? Default is script.coffee will be compiled to .coffee.script.js.  [default: ".coffee."]
#       -h  Prints help                                                                                                   [boolean]
#
# Installing coffee-watcher is easy with [npm](http://npmjs.org/):
#
#       sudo npm install coffee-watcher
#
# Run this to watch for changes in the current working directory:
#
#       coffee-watcher
#
# Run this to watch for changes in a specified directory:
#
#       coffee-watcher -d ~/Desktop/my_project
#
# coffee-watcher requires:
#
# * [node.js](http://nodejs.org/)
# * [find](http://en.wikipedia.org/wiki/Find)
# * [watcher_lib](https://github.com/amix/watcher_lib)
# * [commander.js](https://github.com/visionmedia/commander.js)


# Specify the command line arguments for the script (using commander)
usage = "Watch a directory and recompile .coffee scripts if they change.\nUsage: coffee-watcher -p [prefix] -d [directory]."

program = require 'commander'
mkdirp = require 'mkdirp'

program
	.version('1.5.0')
	.usage(usage)

	.option('-d, --directory <path>',
	'Specify which directory to scan. [Default: .]')

	.option('-o, --output <path>',
	'Specify which directory to put the compiled javascripts. [Default: .]')

	.parse(process.argv)

# Set defaults
program.directory = program.directory or '.'
program.output = program.output or '.'

# Use `watcher-lib`, a library that abstracts away most of the implementation details.
# This library also makes it possible to implement any watchers (see coffee-watcher for an example).
watcher_lib = require 'watcher_lib'


# Searches through a directory structure for *.coffee files using `find`.
# For each .coffee file it runs `compileIfNeeded` to compile the file if it's modified.
findCoffeeFiles = (dir) ->
	watcher_lib.findFiles('*.coffee', dir, compileIfNeeded)

# Keeps a track of modified times for .coffee files in a in-memory object,
# if a .coffee file is modified it recompiles it using compileCoffeeScript.
#
# When starting the script all files will be recompiled.
WATCHED_FILES = {}
compileIfNeeded = (file) ->
	watcher_lib.compileIfNeeded(WATCHED_FILES, file, compileCoffeeScript)

# Compiles a file using `coffee -p`. Compilation errors are printed out to stdout.
compileCoffeeScript = (file) ->
	fnGetOutputFile = (file) ->
		relativePath = path.relative argv.d, file
		file = path.join argv.o, relativePath;
		if not path.existsSync path.dirname file
			mkdirp.sync path.dirname file
		file.replace(/([^\/\\]+)\.coffee/, "#{prefix}$1.src.js")
	watcher_lib.compileFile("coffee -p #{ file }", file, fnGetOutputFile)


# Starts a poller that polls each second in a directory that's
# either by default the current working directory or a directory that's passed through process arguments.
watcher_lib.startDirectoryPoll(program.directory, findCoffeeFiles)
