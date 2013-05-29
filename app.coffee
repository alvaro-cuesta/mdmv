express = require 'express'
sharejs = require('share').server
crypto = require 'crypto'
stylus = require 'stylus'
browserify = require 'connect-browserify'
coffeeify = require 'coffeeify'
mdmv = require './lib'

PORT = process.env.PORT ? 1337
SRC = "#{__dirname}/src"
PUB = "#{__dirname}/public"
MARKDOWN_OPTIONS =
  gfm: true
  tables: false
  breaks: true
  pedantic: false
  sanitize: true
  smartLists: true
  smartypants: true

# Express setup
app = express()
app.set 'view engine', 'blade'
app.set 'views', SRC

dev = app.get('env') == 'development'

app.use express.favicon "#{PUB}/favicon.ico"
app.use express.logger if dev then 'dev'
app.use '/js/mdmv.js', browserify.serve
  entry: './src/entry.coffee'
  requirements: [
    './lib/index.coffee'
    './lib/markdown-mv.coffee'
    './lib/markdown-html.coffee'
    './src/vendor/split-pane.js'
    './src/vendor/prettify.js'
  ]
  shims:
    jquery:
      path: '../src/vendor/jquery'
      exports: '$'
      depends: []
  transforms: [coffeeify]
  debug: true
  insertGlobals: true
  extensions: ['.js', '.coffee']
app.use require('stylus').middleware
  src: SRC
  dest: PUB
  compress: not dev
  firebug: dev
  linenos: dev
app.use express.static PUB

sharejs.attach app,
  db:
    type: if dev then 'none' else 'redis'

app.get '/', (req, res) ->
  crypto.randomBytes 24, (ex, buf) ->
    res.redirect '/' + buf.toString 'hex'

app.get /\/([0-9a-z_]+)\.([0-9a-z\.]+)/, (req, res) ->
  app.model.getSnapshot req.params[0], (err, doc) ->
    throw err if err?
    switch req.params[1]
      when 'txt'
        res.type 'text/plain; charset=UTF-8'
        res.send mdmv.mv.make doc.snapshot
      when 'mv.txt'
        res.type 'text/plain; charset=UTF-8'
        res.send mdmv.mv.make doc.snapshot
      when 'md'
        res.type 'text/x-markdown; charset=UTF-8'
        res.send doc.snapshot
      when 'md.txt'
        res.type 'text/plain; charset=UTF-8'
        res.send doc.snapshot
      when 'html'
        res.render 'preview',
          html: mdmv.html.make doc.snapshot, MARKDOWN_OPTIONS
      else
        throw new Error "Unknown filetype #{req.params[1]}"

app.get /\/([0-9a-z_]+)/, (req, res) ->
  res.format
    html: ->
      res.render 'editor', html: ''
    text: ->
      app.model.getSnapshot req.params.id, (err, doc) ->
        throw err if err?
        res.type 'text/plain; charset=UTF-8'
        res.send mdmv.mv.make doc.snapshot
    'text/x-markdown': ->
      app.model.getSnapshot req.params.id, (err, doc) ->
        throw err if err?
        res.type 'text/x-markdown; charset=UTF-8'
        res.send doc.snapshot

app.listen PORT, ->
  console.log "MDMV listening on #{PORT}"
