require 'rubygems'
require 'active_support'
require 'action_controller'
require 'active_support/test_case'

# ENV['RAILS_ENV'] = 'test'
# ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '/../../../..'

RAILS_ROOT='.'
AUTH_LOG_DIR = File.join(RAILS_ROOT,'log')
Dir.mkdir(AUTH_LOG_DIR) unless File.directory?(AUTH_LOG_DIR)

require 'test/unit'
# require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))