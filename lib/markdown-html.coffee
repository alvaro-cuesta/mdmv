marked = require 'marked'
escape = require('./utils.coffee').escape

#
# InlineLexer
#

module.exports.InlineLexer = class HTMLInlineLexer extends marked.InlineLexer
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

#
# Parser
#

module.exports.Parser = class HTMLParser extends marked.Parser
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

module.exports.parse = HTMLParser.parse = (src, options) ->
  (new HTMLParser options).parse src
