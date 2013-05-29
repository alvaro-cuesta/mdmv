marked = require 'marked'
mdmv = require '../lib'
$ = require 'jquery'
require './vendor/split-pane'
require './vendor/prettify'

$ ->
  # Markdown
  options =
    gfm: true
    tables: false
    breaks: true
    pedantic: false
    sanitize: true
    smartLists: true
    smartypants: true

  # Editor
  editor = ace.edit 'editor'
  editor.setTheme 'ace/theme/ambiance'

  session = editor.getSession()
  session.setMode 'ace/mode/markdown'
  session.setTabSize 4
  session.setUseSoftTabs true
  session.setUseWrapMode true

  mvcode = document.getElementById 'code'
  session.on 'change', ->
    text = session.getValue()
    mvcode.innerHTML = mdmv.mv.make text, options
    html = mdmv.html.make text, options
    msg.innerHTML = html for msg in document.getElementsByClassName 'cuerpo'
    window.prettyPrint()

  # Collaborative editing
  sharejs.open window.location.pathname[1..],
    'text',
    '/channel', (err, doc) ->
      return alert err if err
      doc.attach_ace editor

  ($ 'div.split-pane').splitPane()