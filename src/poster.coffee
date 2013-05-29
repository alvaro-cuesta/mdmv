# Monkey-patch Marked for custom output

escape = (html, encode) ->
  html
    .replace((if !encode then /&(?!#?\w+;)/g else /&/g), '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')

# "

class Lexer extends marked.Lexer
  token: (src, top) ->
    src = src.replace /^ +$/gm, ''

    while src
      # newline
      if cap = @rules.newline.exec src
        src = src[cap[0].length..]
        @tokens.push type: 'space' if cap[0].length > 1
      # code
      else if cap = @rules.code.exec src
        src = src[cap[0].length..]
        cap = cap[0].replace(/^ {4}/gm, '')
        @tokens.push
          type: 'code'
          text: if !@options.pedantic then cap.replace(/\n+$/, '') else cap
      # fences (gfm)
      else if cap = @rules.fences.exec src
        src = src[cap[0].length..]
        @tokens.push
          type: 'code'
          lang: cap[2]
          text: cap[3]
      # heading
      if cap = @rules.heading.exec src
        src = src[cap[0].length..]
        @tokens.push
          type: 'heading',
          depth: cap[1].length,
          text: cap[2]
      # lheading
      else if cap = @rules.lheading.exec src
        src = src[cap[0].length..]
        @tokens.push
          type: 'heading'
          depth: if cap[2] == '=' then 1 else 2
          text: cap[1]
      # hr
      else if cap = @rules.hr.exec src
        src = src[cap[0].length..]
        @tokens.push type: 'hr'
      # blockquote
      else if cap = @rules.blockquote.exec src
        src = src[cap[0].length..]

        @tokens.push type: 'blockquote_start'

        cap = cap[0].replace /^ *> ?/gm, ''

        # Pass `top` to keep the current
        # "toplevel" state. This is exactly
        # how markdown.pl works.
        @token cap, top

        @tokens.push type: 'blockquote_end'
      # list
      # else if cap = @rules.list.exec src
      #   src = src[cap[0].length..]
      #   bull = cap[2]

      #   @tokens.push
      #     type: 'list_start'
      #     ordered: bull.length > 1

      #   # Get each top-level item.
      #   cap = cap[0].match @rules.item

      #   next = false
      #   l = cap.length
      #   i = 0

      #   while i < l
      #     i++
      #     item = cap[i]

      #     # Remove the list item's bullet
      #     # so it is seen as the next token.
      #     space = item.length
      #     item = item.replace /^ *([*+-]|\d+\.) +/, ''

      #     # Outdent whatever the
      #     # list item contains. Hacky.
      #     if ~item.indexOf '\n '
      #       space -= item.length
      #       item = if !@options.pedantic then item.replace(new RegExp('^ {1,' + space + '}', 'gm'), '') else item.replace(/^ {1,4}/gm, '')

      #     # Determine whether the next list item belongs here.
      #     # Backpedal if it does not belong in this list.
      #     if @options.smartLists and i != l - 1
      #       b = block.bullet.exec(cap[i+1])[0]
      #       if bull != b and !(bull.length > 1 and b.length > 1)
      #         src = cap.slice(i + 1).join('\n') + src
      #         i = l - 1

      #     # Determine whether item is loose or not.
      #     # Use: /(^|\n)(?! )[^\n]+\n\n(?!\s*$)/
      #     # for discount behavior.
      #     loose = next || /\n\n(?!\s*$)/.test(item)
      #     if i != l - 1
      #       next = (item[item.length-1] == '\n')
      #       loose = next if not loose

      #     @tokens.push type: if loose then 'loose_item_start' else 'list_item_start'

      #     # Recurse.
      #     @token item, false

      #     @tokens.push type: 'list_item_end'
      #   @tokens.push
      #     type: 'list_end'
      # html
      else if cap = @rules.html.exec src
        src = src[cap[0].length..]
        @tokens.push
          type: if @options.sanitize then 'paragraph' else 'html'
          pre: cap[1] == 'pre' or cap[1] == 'script'
          text: cap[0]
      # def
      else if top and (cap = @rules.def.exec src)
        src = src[cap[0].length..]
        @tokens.links[cap[1].toLowerCase()] =
          href: cap[2]
          title: cap[3]
      # top-level paragraph
      else if top and (cap = @rules.paragraph.exec src)
        src = src[cap[0].length..]
        @tokens.push
          type: 'paragraph'
          text: if cap[1][cap[1].length-1] == '\n' then cap[1].slice(0, -1) else cap[1]
      # text
      else if cap = @rules.text.exec src
        # Top-level should never reach here.
        src = src[cap[0].length..]
        @tokens.push
          type: 'text'
          text: cap[0]
      # error
      else if src
        throw new Error "Infinite loop on byte: #{src.charCodeAt 0}"

    @tokens

Lexer.lex = (src, options) ->
  (new Lexer options).lex src

class HTMLInlineLexer extends marked.InlineLexer
  output: (src) ->
    out = ''

    while src
      # escape
      if cap = @rules.escape.exec src
        src = src[cap[0].length..]
        out += cap[1]
      # u (mv)
      else if cap = /^__(?=\S)([\s\S]*?\S)__/.exec src
        src = src[cap[0].length..]
        out += "<span class=\"u\">#{@output cap[1]}</span>"
      # autolink
      else if cap = @rules.autolink.exec src
        src = src[cap[0].length..]
        if cap[2] == '@'
          text = if cap[1][6] == ':' then @mangle(cap[1].substring(7)) else @mangle(cap[1])
          href = @mangle('mailto:') + text
        else
          text = escape cap[1]
          href = text
        out += "<a href=\"#{href}\">#{text}</a>"
      # url (gfm)
      else if cap = @rules.url.exec src
        src = src[cap[0].length..]
        text = escape cap[1]
        href = text
        out += "<a href=\"#{href}\">#{text}</a>"
      # tag
      else if cap = @rules.tag.exec src
        src = src[cap[0].length..]
        out += if @options.sanitize then escape(cap[0]) else cap[0]
      # link
      else if cap = @rules.link.exec src
        src = src[cap[0].length..]
        out += @outputLink cap,
          href: cap[2],
          title: cap[3]
      # reflink, nolink
      else if (cap = @rules.reflink.exec src) or (cap = @rules.nolink.exec src)
        src = src[cap[0].length..]
        link = (cap[2] or cap[1]).replace /\s+/g, ' '
        link = @links[link.toLowerCase()]
        if !link or !link.href
          out += cap[0][0]
          src = cap[0][1..] + src
        else
          out += @outputLink cap, link
      # strong
      else if cap = @rules.strong.exec src
        src = src[cap[0].length..]
        out += "<strong>#{@output(cap[2] or cap[1])}</strong>"
      # em
      else if cap = @rules.em.exec src
        src = src[cap[0].length..]
        out += "<em>#{@output(cap[2] or cap[1])}</em>"
      # code
      else if cap = @rules.code.exec src
        src = src[cap[0].length..]
        console.log cap[2]
        out += "<span class=\"cmd\">#{escape cap[2], true}</span>"
      # br
      else if cap = @rules.br.exec src
        src = src[cap[0].length..]
        out += '<br>'
      # del (gfm)
      else if cap = @rules.del.exec src
        src = src[cap[0].length..]
        out += "<del>#{@output cap[1]}</del>"
      # text
      else if cap = @rules.text.exec src
        src = src[cap[0].length..]
        out += escape cap[0]
      # none
      else if src
        throw new Error "Infinite loop on byte: #{src.charCodeAt 0}"

    out
  outputLink: (cap, link) ->
    if cap[0][0] == '!'
      title = if link.title then " title=\"#{escape link.title}\"" else ''
      subtitle = if cap[1].length then "<br><em>#{escape cap[1]}</em>" else ''
      "<img src=\"#{escape link.href}\" alt=\"#{escape cap[1]}\"#{title}>#{subtitle}"
    else
      "<a href=\"#{escape link.href}\" #{if link.title then " title=\"#{escape link.title}\"" else ''}>#{@output cap[1]}</a>"

HTMLInlineLexer.output = (src, links, options) ->
  (new HTMLInlineLexer links, options).output src

class HTMLParser extends marked.Parser
  parse: (src) ->
    @inline = new HTMLInlineLexer src.links, @options
    @tokens = src.reverse()

    out = ''
    out += @tok() while @next()
    out
  tok: ->
    switch @token.type
      when 'space' then ''
      when 'hr' then '<hr>\n'
      when 'paragraph' then "#{@inline.output @token.text}<br><br>\n"
      when 'text' then "#{@parseText()}<br><br>\n"
      when 'heading'
        body = @inline.output @token.text
        switch @token.depth
          when 1
            "<h4 class=\"bar\">#{body}</h4><br><br>\n"
          when 2
            "<img src=\"http://tools.mediavida.com/sub.php?t=#{encodeURIComponent body}\"><br><br>\n"
          when 3
            "<h4>#{body}</h4><br><br>\n"
          when 4
            "<h5>#{body}</h5><br><br>\n"
          else
            @tok body
      when 'code'
        @token.text = escape @token.text, true unless @token.escaped

        "<code class=\"prettyprint linenums\">#{@token.text.split('\n').join('<br>')}</code><br>\n"
      when 'blockquote_start'
        body = ''
        body += @tok() while @next().type != 'blockquote_end'

        "<blockquote>\n#{body}</blockquote>\n"
      when 'list_start'
        body = ''
        body += @tok() while @next().type != 'list_end'

        "<ul class=\"flist\">#{body}</ul>\n"
      when 'list_item_start'
        body = ''
        while @next().type != 'list_item_end'
          body += if @token.type == 'text' then @parseText() else @tok()

        "<li>#{body}</li>\n"
      when 'loose_item_start'
        body = ''
        body += @tok() while @next().type != 'list_item_end'

        "<li>#{body}</li>\n"
      when 'html'
        if @token.pre or @options.pedantic
          @token.text
        else
          @inline.output @token.text

HTMLParser.parse = (src, options) ->
  (new HTMLParser options).parse src

class MVInlineLexer extends marked.InlineLexer
  output: (src) ->
    out = ''

    while src
      # escape
      if cap = @rules.escape.exec src
        src = src[cap[0].length..]
        out += cap[1]
      # u (mv)
      else if cap = /^__(?=\S)([\s\S]*?\S)__/.exec src
        src = src[cap[0].length..]
        out += "[u]#{@output cap[1]}[/u]"
      # autolink
      else if cap = @rules.autolink.exec src
        src = src[cap[0].length..]
        if cap[2] == '@'
          text = if cap[1][6] == ':' then @mangle(cap[1].substring(7)) else @mangle(cap[1])
          href = @mangle('mailto:') + text
        else
          text = escape cap[1]
          href = text
        if text == href
          out += "[url]#{href}[/url]"
        else
          out += "[url=#{href}]#{text}[/url]"
      # url (gfm)
      else if cap = @rules.url.exec src
        src = src[cap[0].length..]
        out += escape cap[1]
      # tag
      else if cap = @rules.tag.exec src
        src = src[cap[0].length..]
        out += if @options.sanitize then escape(cap[0]) else cap[0]
      # link
      else if cap = @rules.link.exec src
        src = src[cap[0].length..]
        out += @outputLink cap,
          href: cap[2],
          title: cap[3]
      # reflink, nolink
      else if (cap = @rules.reflink.exec src) or (cap = @rules.nolink.exec src)
        src = src[cap[0].length..]
        link = (cap[2] or cap[1]).replace /\s+/g, ' '
        link = @links[link.toLowerCase()]
        if !link or !link.href
          out += cap[0][0]
          src = cap[0][1..] + src
        else
          out += @outputLink cap, link
      # strong
      else if cap = @rules.strong.exec src
        src = src[cap[0].length..]
        out += "[b]#{@output(cap[2] or cap[1])}[/b]"
      # em
      else if cap = @rules.em.exec src
        src = src[cap[0].length..]
        out += "[i]#{@output(cap[2] or cap[1])}[/i]"
      # code
      else if cap = @rules.code.exec src
        src = src[cap[0].length..]
        out += "[cmd]#{escape cap[2], true}[/cmd]"
      # br
      else if cap = @rules.br.exec src
        src = src[cap[0].length..]
        out += '\n'
      # del (gfm)
      else if cap = @rules.del.exec src
        src = src[cap[0].length..]
        out += "[s]#{@output cap[1]}[/s]"
      # text
      else if cap = @rules.text.exec src
        src = src[cap[0].length..]
        out += escape cap[0]
      # none
      else if src
        throw new Error "Infinite loop on byte: #{src.charCodeAt 0}"

    out

  outputLink: (cap, link) ->
    if cap[0][0] == '!'
      title = if link.title then " title=\"#{escape link.title}\"" else ''
      subtitle = if cap[1].length then "\n[i]#{@output cap[1]}[/i]" else ''
      "[img]#{escape link.href}[/img]"
    else
      "[url=#{escape link.href}]#{@output cap[1]}[/url]"
    # if cap[0][0] == '!'
    #   "<img src=\"#{escape link.href}\" alt=\"#{escape cap[1]}\" #{if link.title then " title=\"#{escape link.title}\"" else ''}>"
    # else
    #   "<a href=\"#{escape link.href}\" #{if link.title then " title=\"#{escape link.title}\"" else ''}>#{@output cap[1]}</a>"

MVInlineLexer.output = (src, links, options) ->
  (new MVInlineLexer links, options).output src

class MVParser extends marked.Parser
  parse: (src) ->
    @inline = new MVInlineLexer src.links, @options
    @tokens = src.reverse()

    out = ''
    out += @tok() while @next()
    out
  tok: ->
    switch @token.type
      when 'space' then ''
      when 'hr' then '<hr>\n'
      when 'paragraph' then "#{@inline.output @token.text}\n\n"
      when 'text' then "#{@parseText()}\n\n"
      when 'heading'
        body = @inline.output @token.text
        switch @token.depth
          when 1
            "[bar]#{body}[/bar]\n\n"
          when 2
            "[img]http://tools.mediavida.com/sub.php?t=#{encodeURIComponent body}[/img]\n\n"
          when 3
            "[h1]#{body}[/h1]\n\n"
          when 4
            "[h2]#{body}[/h2]\n\n"
          else
            @tok body
      when 'code'
        @token.text = escape @token.text, true unless @token.escaped

        "[code]#{@token.text}[/code]\n"
      when 'blockquote_start'
        body = ''
        body += @tok() while @next().type != 'blockquote_end'

        "<blockquote>\n#{body}</blockquote>\n"
      when 'list_start'
        body = ''
        body += @tok() while @next().type != 'list_end'

        "[list]#{body[..-2]}[/list]"
      when 'list_item_start'
        body = ''
        while @next().type != 'list_item_end'
          body += if @token.type == 'text' then @parseText() else @tok()

        "* #{body}\n"
      when 'loose_item_start'
        body = ''
        body += @tok() while @next().type != 'list_item_end'

        "* #{body}\n"
      when 'html'
        if @token.pre or @options.pedantic
          @token.text
        else
          @inline.output @token.text

MVParser.parse = (src, options) ->
  (new MVParser options).parse src

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
    tokens = Lexer.lex text, options
    HTMLParser.parse tokens, options

  md2mv = (text) ->
    tokens = Lexer.lex text, options
    MVParser.parse tokens, options

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