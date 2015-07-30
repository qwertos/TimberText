STRIP = /^(?:\t|[ ]{4})(.*$)/
TAG_GROUP = /^=(\w)= (.*\n(?:(?:[ ]{4}|\t).*\n)*)/
HEADER = /(.*)\n((?:(?:[ ]{4}|\t).*\n)*)/
LIST_GROUP = /((?:^\((#|\*)\).*(?:\n|\z))(?:(?=\(\2\)|[\t ]).*(?:\n|\z))*)/
UNORDERED_ITEM = /^\(\*\) (.*\n(?:(?!\(\*\)).*\n|\n*)*)/
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
    text.gsub!(TAG_GROUP) do
      case $1
        when 'c'
          $2.gsub(HEADER , "<pre><code#{$1 ? " class=\"#{$1}\"" : ''}>\n" + rinse($2) + '</code></pre>' )
        when '1','2','3','4','5','6'
          level = $1.to_i
          $2.gsub(HEADER , "<h#{level}>#{$1}</h#{level}>" + rinse_repeat($2,level) )
        when 'h'
          $2.gsub(HEADER , "<h#{level}>#{$1}</h#{level}>" + rinse_repeat($2,level) )
        when 'p'
          '<p>' + rinse_repeat($2,level) + '</p>'
        when 'q'
          '<blockquote>' + rinse_repeat( $2 , level) + '</blockquote>'
        else
          ''
      end
    end
    text.gsub!(LIST_GROUP) do
      tag = $2.eql?('*') ? 'ul' : 'ol'
      match = $2.eql?( '*') ? UNORDERED_ITEM : ORDERED_ITEM
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