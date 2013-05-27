window.onload = ->
  converter = new Showdown.converter()
  generated = document.getElementById 'code'

  editor = ace.edit 'editor'
  editor.setTheme 'ace/theme/ambiance'

  session = editor.getSession()
  session.setMode 'ace/mode/markdown'
  session.setTabSize 2
  session.setUseSoftTabs true
  session.setUseWrapMode true

  session.on 'change', (e) ->
    txt = converter.makeHtml session.getValue()
    generated.innerHTML = txt
    for msg in document.getElementsByClassName 'cuerpo'
      msg.innerHTML = txt

  sharejs.open window.location.pathname[1..],
    'text',
    '/channel', (err, doc) ->
      doc.attach_ace editor
