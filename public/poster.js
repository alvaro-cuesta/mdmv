(function() {
  var HTMLInlineLexer, HTMLParser, Lexer, MVInlineLexer, MVParser, escape, _ref, _ref1, _ref2, _ref3, _ref4,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  escape = function(html, encode) {
    return html.replace((!encode ? /&(?!#?\w+;)/g : /&/g), '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  };

  Lexer = (function(_super) {
    __extends(Lexer, _super);

    function Lexer() {
      _ref = Lexer.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Lexer.prototype.token = function(src, top) {
      var cap;

      src = src.replace(/^ +$/gm, '');
      while (src) {
        if (cap = this.rules.newline.exec(src)) {
          src = src.slice(cap[0].length);
          if (cap[0].length > 1) {
            this.tokens.push({
              type: 'space'
            });
          }
        } else if (cap = this.rules.code.exec(src)) {
          src = src.slice(cap[0].length);
          cap = cap[0].replace(/^ {4}/gm, '');
          this.tokens.push({
            type: 'code',
            text: !this.options.pedantic ? cap.replace(/\n+$/, '') : cap
          });
        } else if (cap = this.rules.fences.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'code',
            lang: cap[2],
            text: cap[3]
          });
        }
        if (cap = this.rules.heading.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'heading',
            depth: cap[1].length,
            text: cap[2]
          });
        } else if (cap = this.rules.lheading.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'heading',
            depth: cap[2] === '=' ? 1 : 2,
            text: cap[1]
          });
        } else if (cap = this.rules.hr.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'hr'
          });
        } else if (cap = this.rules.blockquote.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'blockquote_start'
          });
          cap = cap[0].replace(/^ *> ?/gm, '');
          this.token(cap, top);
          this.tokens.push({
            type: 'blockquote_end'
          });
        } else if (cap = this.rules.html.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: this.options.sanitize ? 'paragraph' : 'html',
            pre: cap[1] === 'pre' || cap[1] === 'script',
            text: cap[0]
          });
        } else if (top && (cap = this.rules.def.exec(src))) {
          src = src.slice(cap[0].length);
          this.tokens.links[cap[1].toLowerCase()] = {
            href: cap[2],
            title: cap[3]
          };
        } else if (top && (cap = this.rules.paragraph.exec(src))) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'paragraph',
            text: cap[1][cap[1].length - 1] === '\n' ? cap[1].slice(0, -1) : cap[1]
          });
        } else if (cap = this.rules.text.exec(src)) {
          src = src.slice(cap[0].length);
          this.tokens.push({
            type: 'text',
            text: cap[0]
          });
        } else if (src) {
          throw new Error("Infinite loop on byte: " + (src.charCodeAt(0)));
        }
      }
      return this.tokens;
    };

    return Lexer;

  })(marked.Lexer);

  Lexer.lex = function(src, options) {
    return (new Lexer(options)).lex(src);
  };

  HTMLInlineLexer = (function(_super) {
    __extends(HTMLInlineLexer, _super);

    function HTMLInlineLexer() {
      _ref1 = HTMLInlineLexer.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    HTMLInlineLexer.prototype.output = function(src) {
      var cap, href, link, out, text;

      out = '';
      while (src) {
        if (cap = this.rules.escape.exec(src)) {
          src = src.slice(cap[0].length);
          out += cap[1];
        } else if (cap = /^__(?=\S)([\s\S]*?\S)__/.exec(src)) {
          src = src.slice(cap[0].length);
          out += "<span class=\"u\">" + (this.output(cap[1])) + "</span>";
        } else if (cap = this.rules.autolink.exec(src)) {
          src = src.slice(cap[0].length);
          if (cap[2] === '@') {
            text = cap[1][6] === ':' ? this.mangle(cap[1].substring(7)) : this.mangle(cap[1]);
            href = this.mangle('mailto:') + text;
          } else {
            text = escape(cap[1]);
            href = text;
          }
          out += "<a href=\"" + href + "\">" + text + "</a>";
        } else if (cap = this.rules.url.exec(src)) {
          src = src.slice(cap[0].length);
          text = escape(cap[1]);
          href = text;
          out += "<a href=\"" + href + "\">" + text + "</a>";
        } else if (cap = this.rules.tag.exec(src)) {
          src = src.slice(cap[0].length);
          out += this.options.sanitize ? escape(cap[0]) : cap[0];
        } else if (cap = this.rules.link.exec(src)) {
          src = src.slice(cap[0].length);
          out += this.outputLink(cap, {
            href: cap[2],
            title: cap[3]
          });
        } else if ((cap = this.rules.reflink.exec(src)) || (cap = this.rules.nolink.exec(src))) {
          src = src.slice(cap[0].length);
          link = (cap[2] || cap[1]).replace(/\s+/g, ' ');
          link = this.links[link.toLowerCase()];
          if (!link || !link.href) {
            out += cap[0][0];
            src = cap[0].slice(1) + src;
          } else {
            out += this.outputLink(cap, link);
          }
        } else if (cap = this.rules.strong.exec(src)) {
          src = src.slice(cap[0].length);
          out += "<strong>" + (this.output(cap[2] || cap[1])) + "</strong>";
        } else if (cap = this.rules.em.exec(src)) {
          src = src.slice(cap[0].length);
          out += "<em>" + (this.output(cap[2] || cap[1])) + "</em>";
        } else if (cap = this.rules.code.exec(src)) {
          src = src.slice(cap[0].length);
          console.log(cap[2]);
          out += "<span class=\"cmd\">" + (escape(cap[2], true)) + "</span>";
        } else if (cap = this.rules.br.exec(src)) {
          src = src.slice(cap[0].length);
          out += '<br>';
        } else if (cap = this.rules.del.exec(src)) {
          src = src.slice(cap[0].length);
          out += "<del>" + (this.output(cap[1])) + "</del>";
        } else if (cap = this.rules.text.exec(src)) {
          src = src.slice(cap[0].length);
          out += escape(cap[0]);
        } else if (src) {
          throw new Error("Infinite loop on byte: " + (src.charCodeAt(0)));
        }
      }
      return out;
    };

    HTMLInlineLexer.prototype.outputLink = function(cap, link) {
      var subtitle, title;

      if (cap[0][0] === '!') {
        title = link.title ? " title=\"" + (escape(link.title)) + "\"" : '';
        subtitle = cap[1].length ? "<br><em>" + (escape(cap[1])) + "</em>" : '';
        return "<img src=\"" + (escape(link.href)) + "\" alt=\"" + (escape(cap[1])) + "\"" + title + ">" + subtitle;
      } else {
        return "<a href=\"" + (escape(link.href)) + "\" " + (link.title ? " title=\"" + (escape(link.title)) + "\"" : '') + ">" + (this.output(cap[1])) + "</a>";
      }
    };

    return HTMLInlineLexer;

  })(marked.InlineLexer);

  HTMLInlineLexer.output = function(src, links, options) {
    return (new HTMLInlineLexer(links, options)).output(src);
  };

  HTMLParser = (function(_super) {
    __extends(HTMLParser, _super);

    function HTMLParser() {
      _ref2 = HTMLParser.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    HTMLParser.prototype.parse = function(src) {
      var out;

      this.inline = new HTMLInlineLexer(src.links, this.options);
      this.tokens = src.reverse();
      out = '';
      while (this.next()) {
        out += this.tok();
      }
      return out;
    };

    HTMLParser.prototype.tok = function() {
      var body;

      switch (this.token.type) {
        case 'space':
          return '';
        case 'hr':
          return '<hr>\n';
        case 'paragraph':
          return "" + (this.inline.output(this.token.text)) + "<br><br>\n";
        case 'text':
          return "" + (this.parseText()) + "<br><br>\n";
        case 'heading':
          body = this.inline.output(this.token.text);
          switch (this.token.depth) {
            case 1:
              return "<h4 class=\"bar\">" + body + "</h4><br><br>\n";
            case 2:
              return "<img src=\"http://tools.mediavida.com/sub.php?t=" + (encodeURIComponent(body)) + "\"><br><br>\n";
            case 3:
              return "<h4>" + body + "</h4><br><br>\n";
            case 4:
              return "<h5>" + body + "</h5><br><br>\n";
            default:
              return this.tok(body);
          }
          break;
        case 'code':
          if (!this.token.escaped) {
            this.token.text = escape(this.token.text, true);
          }
          return "<code class=\"prettyprint linenums\">" + (this.token.text.split('\n').join('<br>')) + "</code><br>\n";
        case 'blockquote_start':
          body = '';
          while (this.next().type !== 'blockquote_end') {
            body += this.tok();
          }
          return "<blockquote>\n" + body + "</blockquote>\n";
        case 'list_start':
          body = '';
          while (this.next().type !== 'list_end') {
            body += this.tok();
          }
          return "<ul class=\"flist\">" + body + "</ul>\n";
        case 'list_item_start':
          body = '';
          while (this.next().type !== 'list_item_end') {
            body += this.token.type === 'text' ? this.parseText() : this.tok();
          }
          return "<li>" + body + "</li>\n";
        case 'loose_item_start':
          body = '';
          while (this.next().type !== 'list_item_end') {
            body += this.tok();
          }
          return "<li>" + body + "</li>\n";
        case 'html':
          if (this.token.pre || this.options.pedantic) {
            return this.token.text;
          } else {
            return this.inline.output(this.token.text);
          }
      }
    };

    return HTMLParser;

  })(marked.Parser);

  HTMLParser.parse = function(src, options) {
    return (new HTMLParser(options)).parse(src);
  };

  MVInlineLexer = (function(_super) {
    __extends(MVInlineLexer, _super);

    function MVInlineLexer() {
      _ref3 = MVInlineLexer.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    MVInlineLexer.prototype.output = function(src) {
      var cap, href, link, out, text;

      out = '';
      while (src) {
        if (cap = this.rules.escape.exec(src)) {
          src = src.slice(cap[0].length);
          out += cap[1];
        } else if (cap = /^__(?=\S)([\s\S]*?\S)__/.exec(src)) {
          src = src.slice(cap[0].length);
          out += "[u]" + (this.output(cap[1])) + "[/u]";
        } else if (cap = this.rules.autolink.exec(src)) {
          src = src.slice(cap[0].length);
          if (cap[2] === '@') {
            text = cap[1][6] === ':' ? this.mangle(cap[1].substring(7)) : this.mangle(cap[1]);
            href = this.mangle('mailto:') + text;
          } else {
            text = escape(cap[1]);
            href = text;
          }
          if (text === href) {
            out += "[url]" + href + "[/url]";
          } else {
            out += "[url=" + href + "]" + text + "[/url]";
          }
        } else if (cap = this.rules.url.exec(src)) {
          src = src.slice(cap[0].length);
          out += escape(cap[1]);
        } else if (cap = this.rules.tag.exec(src)) {
          src = src.slice(cap[0].length);
          out += this.options.sanitize ? escape(cap[0]) : cap[0];
        } else if (cap = this.rules.link.exec(src)) {
          src = src.slice(cap[0].length);
          out += this.outputLink(cap, {
            href: cap[2],
            title: cap[3]
          });
        } else if ((cap = this.rules.reflink.exec(src)) || (cap = this.rules.nolink.exec(src))) {
          src = src.slice(cap[0].length);
          link = (cap[2] || cap[1]).replace(/\s+/g, ' ');
          link = this.links[link.toLowerCase()];
          if (!link || !link.href) {
            out += cap[0][0];
            src = cap[0].slice(1) + src;
          } else {
            out += this.outputLink(cap, link);
          }
        } else if (cap = this.rules.strong.exec(src)) {
          src = src.slice(cap[0].length);
          out += "[b]" + (this.output(cap[2] || cap[1])) + "[/b]";
        } else if (cap = this.rules.em.exec(src)) {
          src = src.slice(cap[0].length);
          out += "[i]" + (this.output(cap[2] || cap[1])) + "[/i]";
        } else if (cap = this.rules.code.exec(src)) {
          src = src.slice(cap[0].length);
          out += "[cmd]" + (escape(cap[2], true)) + "[/cmd]";
        } else if (cap = this.rules.br.exec(src)) {
          src = src.slice(cap[0].length);
          out += '\n';
        } else if (cap = this.rules.del.exec(src)) {
          src = src.slice(cap[0].length);
          out += "[s]" + (this.output(cap[1])) + "[/s]";
        } else if (cap = this.rules.text.exec(src)) {
          src = src.slice(cap[0].length);
          out += escape(cap[0]);
        } else if (src) {
          throw new Error("Infinite loop on byte: " + (src.charCodeAt(0)));
        }
      }
      return out;
    };

    MVInlineLexer.prototype.outputLink = function(cap, link) {
      var subtitle, title;

      if (cap[0][0] === '!') {
        title = link.title ? " title=\"" + (escape(link.title)) + "\"" : '';
        subtitle = cap[1].length ? "\n[i]" + (this.output(cap[1])) + "[/i]" : '';
        return "[img]" + (escape(link.href)) + "[/img]";
      } else {
        return "[url=" + (escape(link.href)) + "]" + (this.output(cap[1])) + "[/url]";
      }
    };

    return MVInlineLexer;

  })(marked.InlineLexer);

  MVInlineLexer.output = function(src, links, options) {
    return (new MVInlineLexer(links, options)).output(src);
  };

  MVParser = (function(_super) {
    __extends(MVParser, _super);

    function MVParser() {
      _ref4 = MVParser.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    MVParser.prototype.parse = function(src) {
      var out;

      this.inline = new MVInlineLexer(src.links, this.options);
      this.tokens = src.reverse();
      out = '';
      while (this.next()) {
        out += this.tok();
      }
      return out;
    };

    MVParser.prototype.tok = function() {
      var body;

      switch (this.token.type) {
        case 'space':
          return '';
        case 'hr':
          return '<hr>\n';
        case 'paragraph':
          return "" + (this.inline.output(this.token.text)) + "\n\n";
        case 'text':
          return "" + (this.parseText()) + "\n\n";
        case 'heading':
          body = this.inline.output(this.token.text);
          switch (this.token.depth) {
            case 1:
              return "[bar]" + body + "[/bar]\n\n";
            case 2:
              return "[img]http://tools.mediavida.com/sub.php?t=" + (encodeURIComponent(body)) + "[/img]\n\n";
            case 3:
              return "[h1]" + body + "[/h1]\n\n";
            case 4:
              return "[h2]" + body + "[/h2]\n\n";
            default:
              return this.tok(body);
          }
          break;
        case 'code':
          if (!this.token.escaped) {
            this.token.text = escape(this.token.text, true);
          }
          return "[code]" + this.token.text + "[/code]\n";
        case 'blockquote_start':
          body = '';
          while (this.next().type !== 'blockquote_end') {
            body += this.tok();
          }
          return "<blockquote>\n" + body + "</blockquote>\n";
        case 'list_start':
          body = '';
          while (this.next().type !== 'list_end') {
            body += this.tok();
          }
          return "[list]" + body.slice(0, -1) + "[/list]";
        case 'list_item_start':
          body = '';
          while (this.next().type !== 'list_item_end') {
            body += this.token.type === 'text' ? this.parseText() : this.tok();
          }
          return "* " + body + "\n";
        case 'loose_item_start':
          body = '';
          while (this.next().type !== 'list_item_end') {
            body += this.tok();
          }
          return "* " + body + "\n";
        case 'html':
          if (this.token.pre || this.options.pedantic) {
            return this.token.text;
          } else {
            return this.inline.output(this.token.text);
          }
      }
    };

    return MVParser;

  })(marked.Parser);

  MVParser.parse = function(src, options) {
    return (new MVParser(options)).parse(src);
  };

  $(function() {
    var editor, md2html, md2mv, mvcode, options, session;

    options = {
      gfm: true,
      tables: false,
      breaks: true,
      pedantic: false,
      sanitize: true,
      smartLists: true,
      smartypants: true
    };
    md2html = function(text) {
      var tokens;

      tokens = Lexer.lex(text, options);
      return HTMLParser.parse(tokens, options);
    };
    md2mv = function(text) {
      var tokens;

      tokens = Lexer.lex(text, options);
      return MVParser.parse(tokens, options);
    };
    editor = ace.edit('editor');
    editor.setTheme('ace/theme/ambiance');
    session = editor.getSession();
    session.setMode('ace/mode/markdown');
    session.setTabSize(4);
    session.setUseSoftTabs(true);
    session.setUseWrapMode(true);
    mvcode = document.getElementById('code');
    session.on('change', function() {
      var html, msg, _i, _len, _ref5;

      mvcode.innerHTML = md2mv(session.getValue());
      html = md2html(session.getValue());
      _ref5 = document.getElementsByClassName('cuerpo');
      for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
        msg = _ref5[_i];
        msg.innerHTML = html;
      }
      return window.prettyPrint();
    });
    sharejs.open(window.location.pathname.slice(1), 'text', '/channel', function(err, doc) {
      if (err) {
        return alert(err);
      }
      return doc.attach_ace(editor);
    });
    return ($('div.split-pane')).splitPane();
  });

}).call(this);
