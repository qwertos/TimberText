STRIP = /^(?:\t|[ ]{4})(.*$)/
TAG_GROUP = /^=(\w)= (.*\n(?:(?:[ ]{4}|\t).*\n)*)/
HEADER = /(.*)\n((?:(?:[ ]{4}|\t).*\n)*)/
LIST_GROUP = /((?:^\((#|\*)\).*(?:\n|\z))(?:(?=\(\2\)|[\t ]).*(?:\n|\z))*)/
UNORDERED_ITEM = /^\(\*\) (.*\n(?:(?!\(\*\)).*\n|\n*)*)/
ORDERED_ITEM = /^\(#\) (.*\n(?:(?!\(#\)).*\n|\n*)*)/
TABLE = /((?:(?:\|[^|\n]*)+\|\n)*)(?:(?:\|[\- ]*)+\|\n)((?:(?:\|[^|\n]*)+\|\n)*)/
TABLE_ROW = /((?:\|[^|\n]*)*)\|\n/
TABLE_CELL = /\|([^|\n]+)/
PARAGRAPH = /(^(?:(?!%%%|\||\(.\)|=\w=|[ ]{4}|\t).+\n)+)/
BREAK = /(\\\\)\n[ \t]*/
COMMENT = /^%%% (.*)$/
FORMAT = /(?<=\s)([~\^_])([\w ]*)\1/
EMPHASIS = /(?<=\s)(<(?:\g<1>|(.*?))>)(?=\s)/

module TimberText

  def self.rinse_repeat( group , level = nil)
    if group
      group.gsub!(STRIP,'\1')
      level ? parse( group , level + 1) : group
    else
      ''
    end
  end
  class << self
    alias_method :rinse, :rinse_repeat ## only call rinse without level set
  end

  def self.parse( text , level = 1)
    text.gsub!(PARAGRAPH) do
      "<p>#{rinse_repeat($1.gsub(/(?!^|\\\\)\n(?!=\n)/, ' '),level)}</p>\n"
    end
    text.gsub!(COMMENT , '<!-- \1 -->')
    text.gsub!(TAG_GROUP) do
      case $1
        when 'c'
          $2.gsub(HEADER) do
            "<pre><code#{$1 ? " class=\"#{$1}\"" : ''}>\n" + rinse($2) + '</code></pre>'
          end
        when '1','2','3','4','5','6'
          level = $1.to_i
          $2.gsub(HEADER) do
            "<h#{level}>#{$1}</h#{level}>\n" + rinse_repeat($2,level)
          end
        when 'h'
          $2.gsub(HEADER) do
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
    text.gsub!(LIST_GROUP) do
      tag = $2.eql?('*') ? 'ul' : 'ol'
      match = $2.eql?('*') ? UNORDERED_ITEM : ORDERED_ITEM
      "<#{tag}>" + $1.gsub(match) do
        '<li>' + rinse_repeat( $1, level + 1) + '</li>'
      end + "</#{tag}>"
    end
    text.gsub!(TABLE) do
      head = $1 ? $1 : ''
      body = $2 ? $2 : ''
      '<table><thead>' + head.gsub(TABLE_ROW) do
        '<tr>' + $1.gsub(TABLE_CELL, '<th>\1</th>') + '</tr>'
      end + '</thead><tbody>' + body.gsub(TABLE_ROW) do
        '<tr>' + $1.gsub(TABLE_CELL, '<td>\1</td>') + '</tr>'
      end + '</tbody></table>'
    end
    text
  end

  def self.once( text )
    text.gsub!(EMPHASIS) do
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
    text.gsub!(FORMAT) do
      case $1
        when '~'
          "<s>#{$2}</s>"
        when '_'
          "<sub>#{$2}</sub>"
        when '^'
          "<sup>#{$2}</sup>"
      end
    end
    text.gsub!(BREAK , '</br>')
    text
  end

  def self.build( text )
    text = once( text )
    parse(text , 1)
  end
end

HEADER_TEST = '    =h= Another H1
=q= here is a quote at the very beginning
=h= Header 1
    =h= Header 2
        =h= Header 3
    =h= Another H2
        =h= Another H3
            =c= ruby
                def this_is_ruby()
                    puts "Yay we have Code"
                end
    =q= this is a quote
        with multiple lines
=h= this is a header
    =h= Header 2
        =h= Header 3
    =h= Another H2
        =h= Another H3
            | column | column |
            |--------|--------|
            | item 1 | item 2 |
            | item 3 | item 4 |
=h= another group
(*) why?
    also a thing
(*) still a bullet\\\\
    this is strill a thiing
    (#) this is is ok tooo
    (#) hello there
(#) a new thing
    inside of a paragraph <emphasis> <<strong>> <<<both>>> ~strike~ ^superscript^ _subs_cript_
(*) yet another thing
%%% this is a comment
'

puts TimberText.build( HEADER_TEST )