express = require 'express'
sharejs = require('share').server
crypto = require 'crypto'
stylus = require 'stylus'

PORT = process.env.PORT ? 1337
SRC = "#{__dirname}/src"
PUB = "#{__dirname}/public"

# Express setup
app = express()
app.set 'view engine', 'blade'

dev = app.get('env') == 'development'

app.use express.favicon "#{PUB}/favicon.ico"
app.use express.logger if dev then 'dev'
app.use require('browserify-express')
  entry: __dirname + '/lib/entry.coffee',
  watch: __dirname + '/lib/',
  mount: '/js/mdmv.js',
  verbose: dev,
  minify: not dev,
  bundle_opts: debug: dev
  watch_opts: recursive: false
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

app.get /\/([0-9a-f]+)\.txt/, (req, res) ->
  app.model.getSnapshot req.params[0], (err, doc) ->
    throw err if err?
    res.type 'text/plain; charset=UTF-8'
    res.send doc.snapshot

app.get /\/([0-9a-f]+)\.md/, (req, res) ->
  app.model.getSnapshot req.params[0], (err, doc) ->
    throw err if err?
    res.type 'text/x-markdown; charset=UTF-8'
    res.send doc.snapshot

app.get /\/([0-9a-f]+)\.html/, (req, res) ->
  res.render 'editor'

app.get /\/([0-9a-f]+)/, (req, res) ->
  res.format
    html: ->
      res.render 'editor'
    text: ->
      app.model.getSnapshot req.params.id, (err, doc) ->
        throw err if err?
        res.type 'text/plain; charset=UTF-8'
        res.send doc.snapshot
    'text/x-markdown': ->
      app.model.getSnapshot req.params.id, (err, doc) ->
        throw err if err?
        res.type 'text/x-markdown; charset=UTF-8'
        res.send doc.snapshot

app.listen PORT, ->
  console.log "MDMV listening on #{PORT}"
