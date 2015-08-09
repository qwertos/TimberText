require_relative 'lib/timbertext'

task :build do
  system 'gem build timbertext.gemspec'
end

task :install => :build do
  system "sudo gem install -N -l timbertext-#{TimberText::VERSION}.gem"
end

task :release => :build do
  system "gem push timbertext-#{TimberText::VERSION}.gem"
end