window.onload = ->

  mv = (converter) ->
    [
      type: 'html'
      regex: '<h1.*>(.*)</h1>'
      replace: '<h4 class="bar"><span>$1</span></h4>'
    ,
      type: 'html'
      regex: '<h2.*>(.*)</h2>'
      replace: (match, content, num, text) ->
        "<img src=\"http://tools.mediavida.com/sub.php?t=#{encodeURIComponent content}\">"
    ,
      type: 'html'
      regex: '<code>'
      replace: '<code class="prettyprint linenums">'
    ,
      type: 'html'
      regex: '\n</code>'
      replace: '</code>'
    ,
      type: 'html'
      regex: '\n<(/)?(li|ul)>'
      replace: '<$1$2>'
    ,
      type: 'html'
      regex: '<(/)?(li|ul)>\n'
      replace: '<$1$2>'
    ,
      type: 'html'
      regex: '\n'
      replace: '<br/>'
    ,
      type: 'html'
      regex: '</?pre>'
      replace: ''
    ,
      type: 'html'
      regex: '</?p>'
      replace: ''
    ,
      type: 'html'
      regex: '<ul>'
      replace: '<ul class="flist">'
    ,
      type: 'html'
      regex: '<ol>'
      replace: '<ul class="flist">'
    ,
      type: 'html'
      regex: '</ol>'
      replace: '</ul>'
    ]

  bbcode = (converter) ->
    [
      type: 'html'
      regex: '<h1.*>(.*)</h1>'
      replace: '[bar]$1[/bar]'
    ,
      type: 'html'
      regex: '<h2.*>(.*)</h2>'
      replace: (match, content, num, text) ->
        "[img]http://tools.mediavida.com/sub.php?t=#{encodeURIComponent content}[/img]"
    ,
      type: 'html'
      regex: '<img.*src="(.*)" alt.*>'
      replace: (match, content, num, text) ->
        "[img]#{content}[/img]"
    ,
      type: 'html'
      regex: '\n?<(/)?code>'
      replace: '[$1code]'
    ,
      type: 'html'
      regex: '</?pre>'
      replace: ''
    ,
      type: 'html'
      regex: '</?p>'
      replace: ''
    ,
      type: 'html'
      regex: '<(/)?strong>'
      replace: '[$1b]'
    ,
      type: 'html'
      regex: '<(/)?em>'
      replace: '[$1i]'
    ,
      type: 'html'
      regex: '<a href="(.*)">(.*)</a>'
      replace: '[url=$1]$2[/url]'
    ,
      type: 'html'
      regex: '\n<(/)?(u|o)l>\n'
      replace: '[$1list]'
    ,
      type: 'html'
      regex: '<li>'
      replace: '* '
    ,
      type: 'html'
      regex: '</li>'
      replace: ''
    ]

  render = new Showdown.converter extensions: [mv]
  mvcode = new Showdown.converter extensions: [bbcode]

  generated = document.getElementById 'code'

  editor = ace.edit 'editor'
  editor.setTheme 'ace/theme/ambiance'

  session = editor.getSession()
  session.setMode 'ace/mode/markdown'
  session.setTabSize 4
  session.setUseSoftTabs true
  session.setUseWrapMode true

  session.on 'change', (e) ->
    txt = render.makeHtml session.getValue()
    generated.innerHTML = mvcode.makeHtml session.getValue()
    msg.innerHTML = txt for msg in document.getElementsByClassName 'cuerpo'
    window.prettyPrint()

  sharejs.open window.location.pathname[1..],
    'text',
    '/channel', (err, doc) ->
      doc.attach_ace editor
