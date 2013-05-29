marked = require 'marked'

module.exports.Lexer = class Lexer extends marked.Lexer
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
      else if cap = @rules.list.exec src
        src = src[cap[0].length..]
        bull = cap[2]

        @tokens.push
          type: 'list_start'
          ordered: bull.length > 1

        # Get each top-level item.
        cap = cap[0].match @rules.item

        next = false
        l = cap.length
        i = 0

        while i < l
          item = cap[i]

          # Remove the list item's bullet
          # so it is seen as the next token.
          space = item.length
          item = item.replace /^ *([*+-]|\d+\.) +/, ''

          # Outdent whatever the
          # list item contains. Hacky.
          if ~item.indexOf '\n '
            space -= item.length
            item = if not @options.pedantic then item.replace(new RegExp("^ {1,#{space}}", 'gm'), '') else item.replace(/^ {1,4}/gm, '')

          # Determine whether the next list item belongs here.
          # Backpedal if it does not belong in this list.
          if @options.smartLists and i != l - 1
            b = /(?:[*+-]|\d+\.)/.exec(cap[i+1])[0]
            if bull != b and not (bull.length > 1 and b.length > 1)
              src = cap.slice(i + 1).join('\n') + src
              i = l - 1

          # Determine whether item is loose or not.
          # Use: /(^|\n)(?! )[^\n]+\n\n(?!\s*$)/
          # for discount behavior.
          loose = next || /\n\n(?!\s*$)/.test(item)
          if i != l - 1
            next = (item[item.length-1] == '\n')
            loose = next if not loose

          @tokens.push type: if loose then 'loose_item_start' else 'list_item_start'

          # Recurse.
          @token item, false

          @tokens.push type: 'list_item_end'

          i++
        @tokens.push type: 'list_end'
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

module.exports.lex = Lexer.lex = (src, options) ->
  (new Lexer options).lex src

module.exports.mv = require './markdown-mv.coffee'
module.exports.html = mdhtml = require './markdown-html.coffee'