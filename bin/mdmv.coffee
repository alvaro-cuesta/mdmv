#!/usr/bin/env coffee

express = require 'express'
sharejs = require('share').server
crypto = require 'crypto'
stylus = require 'stylus'

app = express()
port = process.env.PORT || 1337

src = "#{__dirname}/../src"
pub = "#{__dirname}/../public"

app.set 'view engine', 'blade'

app.use express.logger if app.get('env') == 'development' then 'dev'
app.use require('connect-coffee-script')
  src: src
  dest: pub
app.use require('stylus').middleware
  src: src
  dest: pub
  compress: app.get('env') != 'development'
  firebug: app.get('env') == 'development'
  linenos: app.get('env') == 'development'
app.use express.static pub

sharejs.attach app, db: type: if app.get('env') == 'development' then 'none' else 'redis'

app.get '/', (req, res) ->
  crypto.randomBytes 24, (ex, buf) ->
    res.redirect '/' + buf.toString 'hex'

app.get '/:id', (req, res) ->
  res.render 'editor'

app.listen port, ->
  console.log "MDMV listening on #{port}"