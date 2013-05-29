module.exports.escape = (html, encode) ->
  html
    .replace((if !encode then /&(?!#?\w+;)/g else /&/g), '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')