require 'rubygems'
require 'active_support'
require 'action_controller'
require 'active_support/test_case'
require 'test/unit'

RAILS_ROOT='.'
AUTH_LOG_DIR = File.join(RAILS_ROOT,'log')
Dir.mkdir(AUTH_LOG_DIR) unless File.directory?(AUTH_LOG_DIR)

ActionController::Routing::Routes.draw do |map|
  map.dummy_low_action '/dummy/very_low_security', :controller => :dummy, :action => :very_low_security
end