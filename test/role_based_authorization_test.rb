
require 'test_helper'
require 'role_based_authorization'

class DummyUser
  def id()                  return (@id || 1) end
  def id=(new_id)           @id = new_id end
  def login()               return 'test'  end  
  def role()                return  @role end
  def role=(new_role)       @role = new_role end
  def description()         return "user" end
end

class DummyController < ActionController::Base
  include RoleBasedAuthorization
  
  def initialize()          return @user = DummyUser.new end
  def logged_in?()          return true end
  def current_user()        return @user end    
  def current_user=(user)   @user = user end
  
  permit  :actions => 'very_low_security',
          :to => :all
          
  permit :actions => 'high_security',
         :to => 3

  permit :actions => 'medium_security',
         :to => [2,3]
         
  permit :actions => 'low_security_with_param',
         :to => :all,
         :if => lambda { |user, object| 
           # to simplify things we directly compare object with a string
           # in real life, we probably want to retrieve the object value
           # using the provided object. e.g.
           #    Product.find(object).user == user
           object == 'object_id' 
        }
        
  permit :actions => 'low_security_with_param_identified_by_other_id',
         :to => :all,
         :if => lambda { |user, object| object == 'object_id' },
         :object_id => :other_id
  
end


class RoleBasedAuthorizationTest < ActiveSupport::TestCase
  def setup
    @controller = DummyController.new
  end
  
  test "Should permit action very_low_security to everyone" do
    assert_equal true, @controller.authorize_action?(:action => 'very_low_security')
  end
  
  test "Should permit action high_security only to root (role 3)" do
    assert_equal false, @controller.authorize_action?(:action => 'high_security')
    @controller.current_user.role=3
    assert_equal true, @controller.authorize_action?(:action => 'high_security')
  end
  
  test "Should permit action medium_security only to roles 2 and 3" do
    assert_equal false, @controller.authorize_action?(:action => 'medium_security')
    @controller.current_user.role=2
    assert_equal true, @controller.authorize_action?(:action => 'medium_security')    
    @controller.current_user.role=3
    assert_equal true, @controller.authorize_action?(:action => 'medium_security')    
  end
  
  test "Should permit action low_security_with_param only if the runtime check holds" do
    assert_equal false, @controller.authorize_action?(:action => 'low_security_with_param')
    assert_equal true, @controller.authorize_action?(:action => 'low_security_with_param', 
                                                     :id => 'object_id')
  end  


  test "Should permit action low_security_with_param_identified_by_other_id only if the runtime check holds" do
    assert_equal false, @controller.authorize_action?(:action => 'low_security_with_param_identified_by_other_id')
    assert_equal true, @controller.authorize_action?(:action => 'low_security_with_param_identified_by_other_id', 
                                                     :other_id => 'object_id')
  end  

  
end