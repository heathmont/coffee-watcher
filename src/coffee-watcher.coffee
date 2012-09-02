# **coffee-watcher** is a script that can watch
# a directory and recompile your [.coffee scripts](http://coffeescript.org/) if they change.
#
# It's very useful for development as you don't need to think about
# recompiling your CoffeeScript files.  Search is done in a recursive manner
# so sub-directories are handled as well.
#
#     Usage:
#       coffee-watcher -o [output directory] -d [source directory]
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
usage = "Watch a directory and recompile .coffee scripts if they change.\nUsage: coffee-watcher -o [output directory] -d [source directory]."

specs = require('optimist')
        .usage(usage)

        .default('d', '.')
        .describe('d', 'Specify which directory to scan.')

        .default('o', './')
        .describe('o', 'Output directory. Default is ./')

        .boolean('h')
        .describe('h', 'Prints help')


# Handle the special -h case
if specs.parse(process.argv).h
    specs.showHelp()
    process.exit()
else
    argv = specs.argv

fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'

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
    prefix = if argv.p == true then '' else argv.p
    fnGetOutputFile = (file) ->
        relativePath = path.relative argv.d, file
        file = path.join argv.o, relativePath;
        if not fs.existsSync path.dirname file
            mkdirp.sync path.dirname file
        file.replace(/([^\/\\]+)\.coffee/, "$1.src.js")
    watcher_lib.compileFile("coffee -p #{ file }", file, fnGetOutputFile)

# Starts a poller that polls each second in a directory that's
# either by default the current working directory or a directory that's passed through process arguments.
watcher_lib.startDirectoryPoll(argv.d, findCoffeeFiles)
