require_relative 'lib/timbertext'

task :build do
  system 'gem build timbertext.gemspec'
end

task :release => :build do
  system "gem push timbertext-#{TimberText::VERSION}.gem"
end