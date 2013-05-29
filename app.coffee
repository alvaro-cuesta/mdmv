express = require 'express'
sharejs = require('share').server
crypto = require 'crypto'
stylus = require 'stylus'

PORT = process.env.PORT || 1337
SRC = "#{__dirname}/src"
PUB = "#{__dirname}/public"

# Express setup
app = express()
app.set 'view engine', 'blade'

dev = app.get('env') == 'development'

app.use express.favicon "#{PUB}/favicon.ico"
app.use express.logger if dev then 'dev'
app.use require('connect-coffee-script')
  src: SRC
  dest: PUB
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

app.get '/:id', (req, res) ->
  res.render 'editor'

app.listen port, ->
  console.log "MDMV listening on #{port}"
