require 'rake'
require 'rake/testtask'
require 'rdoc/task'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the role_based_authorization plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the role_based_authorization plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'RoleBasedAuthorization'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "role_based_authorization"
    gemspec.summary = "Basic authorization module for rails"
    gemspec.description = "Provides a simple DSL for specifying the authorization logic" +
                          " of your application. Install the gem, add a role attribute" +
                          " to your user model and your almost ready to go."
    gemspec.email = "boborbt@gmail.com"
    gemspec.homepage = "http://github.com/boborbt/role_based_authorization"
    gemspec.authors = ["Roberto Esposito"]
    gemspec.add_dependency('rails', '~> 3')
    gemspec.add_dependency('mocha', '~> 0')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
