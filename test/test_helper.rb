require 'rubygems'

ENV['RAILS_RELATIVE_URL_ROOT']='/appname'

gem 'rails', '~>3'
require 'active_support'
require 'action_controller'
require 'active_support/test_case'
require 'test/unit'
require 'rails'

RAILS_ROOT='.'
AUTH_LOG_DIR = File.join(RAILS_ROOT,'log')
Dir.mkdir(AUTH_LOG_DIR) unless File.directory?(AUTH_LOG_DIR)


module Rails
  def Rails.root  
    '.'
  end
end

Rails.application = Rails::Application.instance_exec { new }

Rails.application.routes.draw do
  match '/dummy/very_low_security', :controller => :dummy, :action => :very_low_security
end