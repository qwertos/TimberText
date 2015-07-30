STRIP = /^(?:\t|[ ]{4})(.*$)/
TAG_GROUP = /^=(\w)= .*\n(?:.+\n)*?\n*(?==\w=|\z)/
CODE_GROUP = /^=c= (.*)\n((?:.+\n)*?)\n*(?==\w=|\z)/
HEADER_GROUP = /^=h= (.*)\n((?:.+\n)*?)\n*(?==\w=|\z)/
QUOTE_GROUP = /^=q= ((?:.+\n)*?)\n*(?==\w=|\z)/
LIST_GROUP = /^(\((\*)\) .*(?:\n|\z)(?:(?!\(#\)).+(?:\n|\z))*)|^(\((#)\) .*(?:\n|\z)(?:(?!\(\*\)).+(?:\n|\z))*)/
UNORDERED_GROUP = /^(\((\*)\) .*(?:\n|\z)(?:(?!\(#\)).+(?:\n|\z))*)/
UNORDERED_ITEM = /^\(\*\) (.*\n(?:(?!\(\*\)).*\n|\n*)*)/
ORDERED_GROUP = /^(\((#)\) .*(?:\n|\z)(?:(?!\(\*\)).+(?:\n|\z))*)/
ORDERED_ITEM = /^\(#\) (.*\n(?:(?!\(#\)).*\n|\n*)*)/
TABLE = /((?:(?:\|[^|\n]*)+\|\n)*)(?:(?:\|[\- ]*)+\|\n)((?:(?:\|[^|\n]*)+\|\n)*)/
TABLE_ROW = /((?:\|[^|\n]*)*)\|\n/
TABLE_CELL = /\|([^|\n]+)/

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
    text.gsub!(TAG_GROUP) do |m|
      case m
        when CODE_GROUP
          "<pre><code#{$1 ? " class=\"#{$1}\"" : ''}>\n" + rinse($2) + '</code></pre>'
        when HEADER_GROUP
          "<h#{level}>#{$1}</h#{level}>" + rinse_repeat($2,level)
        when QUOTE_GROUP
          '<blockquote>' + rinse_repeat( $1 , level) + '</blockquote>'
        else
          ''
      end
    end
    text.gsub!(LIST_GROUP) do
      if $2
        '<ul>' + $1.gsub(UNORDERED_ITEM) do
          '<li>' + rinse_repeat( $1, level + 1) + '</li>'
        end + '</ul>'
      else
        'ol' + $3.gsub(ORDERED_ITEM) do
          '<li>' + rinse_repeat( $1, level + 1) + '</li>'
        end + '</ol>'
      end
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
(*) still a bullet
    this is strill a thiing
    (#) this is is ok tooo
    (#) hello there
(#) a new thing
(*) yet another thing
'

puts TimberText.parse( HEADER_TEST , 1)