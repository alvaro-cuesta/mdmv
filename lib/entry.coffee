marked = require 'marked'
mdmv = require './index.coffee'

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

  md2html = (text) ->
    tokens = mdmv.lex text, options
    mdmv.html.Parser.parse tokens, options

  md2mv = (text) ->
    tokens = mdmv.lex text, options
    mdmv.mv.parse tokens, options

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
    mvcode.innerHTML = md2mv session.getValue()

    html = md2html session.getValue()
    msg.innerHTML = html for msg in document.getElementsByClassName 'cuerpo'
    window.prettyPrint()

  # Collaborative editing
  sharejs.open window.location.pathname[1..],
    'text',
    '/channel', (err, doc) ->
      return alert err if err
      doc.attach_ace editor

  ($ 'div.split-pane').splitPane()