#!/usr/bin/env coffee

express = require 'express'
sharejs = require('share').server
coffee =
crypto = require 'crypto'
stylus = require 'stylus'

app = express()
port = process.env.PORT || 1337
env = 'dev'

src = "#{__dirname}/../src"
pub = "#{__dirname}/../public"

app.set 'view engine', 'blade'
app.set 'views', src

app.use express.logger env
app.use require('connect-coffee-script')
  src: src
  dest: pub
app.use require('stylus').middleware
  src: src
  dest: pub
  compress: env != 'dev'
  firebug: env == 'dev'
  linenos: env == 'dev'
app.use express.static pub

sharejs.attach app, db: type: 'none'

app.get '/', (req, res) ->
  crypto.randomBytes 24, (ex, buf) ->
    res.redirect '/' + buf.toString 'hex'

app.get '/:id', (req, res) ->
  res.render 'index'

app.listen port
console.log "MV Poster listening on #{port}"