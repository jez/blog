require 'rouge'
require 'fileutils'
require 'digest/md5'

module HighlightCode
  def self.highlight(str, lang)
    lang = 'ruby' if lang == 'ru'
    lang = 'objc' if lang == 'm'
    lang = 'perl' if lang == 'pl'
    lang = 'yaml' if lang == 'yml'
    str = pygments(str, lang)
    tableize_code(str, lang)
  end

  def self.pygments(code, lang)
    Rouge.highlight(code, lang, 'html')
  end

  def self.tableize_code (str, lang = '')
    table = '<div class="highlight"><table><tr>'
    code = ''
    str.lines.each_with_index do |line,index|
      code  += "<span class='line'>#{line}</span>"
    end
    table += "</pre></td><td class='code'><pre><code class='#{lang}'>#{code}</code></pre></td></tr></table></div>"
  end
end
