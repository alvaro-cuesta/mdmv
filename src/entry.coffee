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

  # Collaborative editing
  sharejs.open window.location.pathname[1..],
    'text',
    '/channel', (err, doc) ->
      return alert err if err

      # Editor
      editor = ace.edit 'editor'
      editor.setTheme 'ace/theme/ambiance'
      doc.attach_ace editor

      session = editor.getSession()
      session.setMode 'ace/mode/markdown'
      session.setTabSize 4
      session.setUseSoftTabs true
      session.setUseWrapMode true

      update = ->
        text = session.getValue()
        $('#code').val mdmv.mv.make text, options
        html = mdmv.html.make text, options
        msg.innerHTML = html for msg in document.getElementsByClassName 'cuerpo'
        window.prettyPrint()

      session.on 'change', update

      ($ 'div.split-pane').splitPane()

      mousedown = false
      ($ '#my-divider').mousedown ->
        mousedown = true
      ($ document).mouseup ->
        mousedown = false
      ($ document).mousemove ->
        if mousedown
          editor.resize()

      update()

      htmlVisible = true

      $html = $ '#html'
      $mvbbcode = $ '#mvbbcode'

      $('#toggle').click ->
        if htmlVisible
          $html.fadeOut 500, ->
            $mvbbcode.fadeIn 500, ->
              htmlVisible = false
        else
          $mvbbcode.fadeOut 500, ->
            $html.fadeIn 500, ->
              htmlVisible = true
        false

      $('#everything').fadeIn 2000