(function() {
  window.onload = function() {
    var bbcode, editor, generated, mv, mvcode, render, session;

    mv = function(converter) {
      return [
        {
          type: 'html',
          regex: '<h1.*>(.*)</h1>',
          replace: '<h4 class="bar"><span>$1</span></h4>'
        }, {
          type: 'html',
          regex: '<h2.*>(.*)</h2>',
          replace: function(match, content, num, text) {
            return "<img src=\"http://tools.mediavida.com/sub.php?t=" + (encodeURIComponent(content)) + "\">";
          }
        }, {
          type: 'html',
          regex: '<code>',
          replace: '<code class="prettyprint linenums">'
        }, {
          type: 'html',
          regex: '\n</code>',
          replace: '</code>'
        }, {
          type: 'html',
          regex: '\n<(/)?(li|ul)>',
          replace: '<$1$2>'
        }, {
          type: 'html',
          regex: '<(/)?(li|ul)>\n',
          replace: '<$1$2>'
        }, {
          type: 'html',
          regex: '\n',
          replace: '<br/>'
        }, {
          type: 'html',
          regex: '</?pre>',
          replace: ''
        }, {
          type: 'html',
          regex: '</?p>',
          replace: ''
        }, {
          type: 'html',
          regex: '<ul>',
          replace: '<ul class="flist">'
        }, {
          type: 'html',
          regex: '<ol>',
          replace: '<ul class="flist">'
        }, {
          type: 'html',
          regex: '</ol>',
          replace: '</ul>'
        }
      ];
    };
    bbcode = function(converter) {
      return [
        {
          type: 'html',
          regex: '<h1.*>(.*)</h1>',
          replace: '[bar]$1[/bar]'
        }, {
          type: 'html',
          regex: '<h2.*>(.*)</h2>',
          replace: function(match, content, num, text) {
            return "[img]http://tools.mediavida.com/sub.php?t=" + (encodeURIComponent(content)) + "[/img]";
          }
        }, {
          type: 'html',
          regex: '<img.*src="(.*)" alt.*>',
          replace: function(match, content, num, text) {
            return "[img]" + content + "[/img]";
          }
        }, {
          type: 'html',
          regex: '\n?<(/)?code>',
          replace: '[$1code]'
        }, {
          type: 'html',
          regex: '</?pre>',
          replace: ''
        }, {
          type: 'html',
          regex: '</?p>',
          replace: ''
        }, {
          type: 'html',
          regex: '<(/)?strong>',
          replace: '[$1b]'
        }, {
          type: 'html',
          regex: '<(/)?em>',
          replace: '[$1i]'
        }, {
          type: 'html',
          regex: '<a href="(.*)">(.*)</a>',
          replace: '[url=$1]$2[/url]'
        }, {
          type: 'html',
          regex: '\n<(/)?(u|o)l>\n',
          replace: '[$1list]'
        }, {
          type: 'html',
          regex: '<li>',
          replace: '* '
        }, {
          type: 'html',
          regex: '</li>',
          replace: ''
        }
      ];
    };
    render = new Showdown.converter({
      extensions: [mv]
    });
    mvcode = new Showdown.converter({
      extensions: [bbcode]
    });
    generated = document.getElementById('code');
    editor = ace.edit('editor');
    editor.setTheme('ace/theme/ambiance');
    session = editor.getSession();
    session.setMode('ace/mode/markdown');
    session.setTabSize(4);
    session.setUseSoftTabs(true);
    session.setUseWrapMode(true);
    session.on('change', function(e) {
      var msg, txt, _i, _len, _ref;

      txt = render.makeHtml(session.getValue());
      generated.innerHTML = mvcode.makeHtml(session.getValue());
      _ref = document.getElementsByClassName('cuerpo');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        msg = _ref[_i];
        msg.innerHTML = txt;
      }
      return window.prettyPrint();
    });
    return sharejs.open(window.location.pathname.slice(1), 'text', '/channel', function(err, doc) {
      return doc.attach_ace(editor);
    });
  };

}).call(this);
