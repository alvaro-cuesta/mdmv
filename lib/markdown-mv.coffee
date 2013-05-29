marked = require 'marked'
escape = require('./utils.coffee').escape
Lexer = require './Lexer.coffee'

#
# InlineLexer
#

module.exports.InlineLexer = class MVInlineLexer extends marked.InlineLexer
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

MVInlineLexer.output = (src, links, options) ->
  (new MVInlineLexer links, options).output src

#
# Parser
#

module.exports.Parser = class MVParser extends marked.Parser
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

module.exports.parse = MVParser.parse = (src, options) ->
  (new MVParser options).parse src

module.exports.make = (text, options) ->
  MVParser.parse (Lexer.lex text, options), options