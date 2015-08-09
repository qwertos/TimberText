TT_STRIP = /^(?:\t|[ ]{4})(.*$)/
TT_TAG_GROUP = /^=(\w)= (.*\n(?:(?:[ ]{4}|\t).*\n)*)/
TT_HEADER = /(.*)\n((?:(?:[ ]{4}|\t).*\n)*)/
TT_LIST_GROUP = /((?:^\((#|\*)\).*(?:\n|\z))(?:(?=\(\2\)|[\t ]).*(?:\n|\z))*)/
TT_UNORDERED_ITEM = /^\(\*\) (.*\n(?:(?!\(\*\)).*\n|\n*)*)/
TT_ORDERED_ITEM = /^\(#\) (.*\n(?:(?!\(#\)).*\n|\n*)*)/
TT_TABLE = /((?:(?:\|[^|\n]*)+\|\n)*)(?:(?:\|[\- ]*)+\|\n)((?:(?:\|[^|\n]*)+\|\n)*)/
TT_TABLE_ROW = /((?:\|[^|\n]*)*)\|\n/
TT_TABLE_CELL = /\|([^|\n]+)/
TT_PARAGRAPH = /(^(?:(?!%%%|\||\(.\)|=\w=|[ ]{4}|\t).+\n)+)/
TT_BREAK = /(\\\\)\n[ \t]*/
TT_COMMENT = /^%%% (.*)$/
TT_FORMAT = /(?<=\s)([~\^_])([\w ]*)\1/
TT_EMPHASIS = /(?<=\s)(<(?:\g<1>|(.*?))>)(?=\s)/
TT_NORMAL_LINK = /(?<=\s|\A)(?:\[(.+?)\])?\[(.+?)\](?=\s|\z)/
TT_REF_LINK = /(?<=\s|\A)(?:\[(.+?)\])?\{(.+?)\}(?=\s|\z)/
TT_NUMBERED_REF = /\{(.*)\}/
TT_REF_DECLARATION = /\{(.+?)\}(?:\[(.+?)\])?\[(.+?)\]\n/
TT_NAMESPACE = /(.+):(.+)/

$NAMESPACE_ROOT = '/edge'

module TimberText
  VERSION = '0.1.2'

  def self.rinse_repeat( group , level = nil)
    if group
      group.gsub!(TT_STRIP,'\1')
      level ? parse( group , level + 1) : group
    else
      ''
    end
  end
  class << self
    alias_method :rinse, :rinse_repeat ## only call rinse without level set
  end

  def self.parse( text , level = 1)
    text.gsub!(TT_PARAGRAPH) do
      "<p>#{rinse_repeat($1.gsub(/(?!^|\\\\)\n(?!=\n)/, ' '),level)}</p>\n"
    end
    text.gsub!(TT_COMMENT , '<!-- \1 -->')
    text.gsub!(TT_TAG_GROUP) do
      case $1
        when 'c'
          $2.gsub(TT_HEADER) do
            "<pre><code#{$1 ? " class=\"#{$1}\"" : ''}>\n" + rinse($2) + '</code></pre>'
          end
        when '1','2','3','4','5','6'
          level = $1.to_i
          $2.gsub(TT_HEADER) do
            "<h#{level}>#{$1}</h#{level}>\n" + rinse_repeat($2,level)
          end
        when 'h'
          $2.gsub(TT_HEADER) do
            "<h#{level}>#{$1}</h#{level}>\n" + rinse_repeat($2,level)
          end
        when 'p'
          '<p>' + rinse_repeat($2,level) + '</p>\n'
        when 'q'
          '<blockquote>' + rinse_repeat( $2 , level) + '</blockquote>\n'
        else
          ''
      end
    end
    text.gsub!(TT_LIST_GROUP) do
      tag = $2.eql?('*') ? 'ul' : 'ol'
      match = $2.eql?('*') ? TT_UNORDERED_ITEM : TT_ORDERED_ITEM
      "<#{tag}>" + $1.gsub(match) do
        '<li>' + rinse_repeat( $1, level + 1) + '</li>'
      end + "</#{tag}>"
    end
    text.gsub!(TT_TABLE) do
      head = $1 ? $1 : ''
      body = $2 ? $2 : ''
      '<table><thead>' + head.gsub(TT_TABLE_ROW) do
        '<tr>' + $1.gsub(TT_TABLE_CELL, '<th>\1</th>') + '</tr>'
      end + '</thead><tbody>' + body.gsub(TT_TABLE_ROW) do
        '<tr>' + $1.gsub(TT_TABLE_CELL, '<td>\1</td>') + '</tr>'
      end + '</tbody></table>'
    end
    text
  end

  def self.build_link_source( match )
    case match
      when TT_NAMESPACE
        "#{$NAMESPACE_ROOT}/#{$1}/#{$2}"
      else
        match
    end
  end

  def self.once( text )
    text.gsub!(TT_EMPHASIS) do
      inside = $2
      case $1.match(/(<*)/)[0].length
        when 1
          "<em>#{inside}</em>"
        when 2
          "<strong>#{inside}</strong>"
        when 3
          "<em><strong>#{inside}</strong></em>"
        else
          inside
      end
    end
    text.gsub!(TT_FORMAT) do
      case $1
        when '~'
          "<s>#{$2}</s>"
        when '_'
          "<sub>#{$2}</sub>"
        when '^'
          "<sup>#{$2}</sup>"
      end
    end
    text.gsub!(TT_BREAK , '</br>')
    text.gsub!(TT_NORMAL_LINK) do
      label = $1 ? $1 : ''
      src = build_link_source( $2 )
      "<a href=\"#{src}\">#{label}</a>"
    end
    text.gsub!(TT_REF_LINK) do
      label = $1 ? $1 : ''
      ref = $2
      case ref
        when TT_NUMBERED_REF
          $REF_COUNT += 1
          $USED_REFS << $1
          "<a href=\"#REF#{$REF_COUNT}\">[#{$REF_COUNT}]</a>"
        else
          "<a href=\"#{$REFS[ref][:src]}\">#{label}</a>"
      end
    end
    text
  end

  def self.extract_refs( text )
    $REFS = {}
    text.gsub(TT_REF_DECLARATION) do
      src = build_link_source($3)
      label = $2 ? $2 : src
      $REFS[$1] = {label: label , src: src }
      ''
    end
  end

  def self.add_references( text )
    text += '<span>References</span><ul>'
    $USED_REFS.each_with_index do |k,i|
      puts k
      text += "\n<li><a id=\"REF#{i+1}\" href=\"#{$REFS[k][:src]}\">[#{i+1}] #{$REFS[k][:label]}</a></li>"
    end
    text += '</ul>'
    text
  end

  def self.build( text )
    $REF_COUNT = 0
    $USED_REFS = []
    text = extract_refs(text)
    text = once(text)
    text = parse(text , 1)
    add_references( text )
  end
end