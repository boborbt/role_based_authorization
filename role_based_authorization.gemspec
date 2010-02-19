# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{role_based_authorization}
  s.version = "0.1.16"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Roberto Esposito"]
  s.date = %q{2010-02-19}
  s.description = %q{Provides a simple DSL for specifying the authorization logic of your application. Install the gem, add a role attribute to your user model and your almost ready to go.}
  s.email = %q{boborbt@gmail.com}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/role_based_authorization.rb",
     "lib/role_based_authorization/authorization_logger.rb",
     "lib/role_based_authorization/class_additions.rb",
     "lib/role_based_authorization/role_based_authorization.rb",
     "lib/role_based_authorization/rule.rb",
     "rails/init.rb",
     "role_based_authorization.gemspec",
     "test/authorization_logger_test.rb",
     "test/role_based_authorization_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/boborbt/role_based_authorization}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Basic authorization module for rails}
  s.test_files = [
    "test/authorization_logger_test.rb",
     "test/role_based_authorization_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 2.2"])
      s.add_runtime_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<rails>, [">= 2.2"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, [">= 2.2"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end

