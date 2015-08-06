require_relative 'lib/timbertext'

Gem::Specification.new do |s|
  s.name        = 'timbertext'
  s.version     = TimberText::VERSION
  s.date        = '2015-08-06'
  s.summary     = 'TimberText'
  s.description = 'TimberText is a tree-based markup language that is designed for sectioned documents'
  s.authors     = ['Bryan T. Meyers']
  s.email       = 'bmeyers@datadrake.com'
  s.files       = %w(lib/timbertext.rb LICENSE README.md)
  s.homepage    = 'http://rubygems.org/gems/timbertext'
  s.license     = 'MIT'
end