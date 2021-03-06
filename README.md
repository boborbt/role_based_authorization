# RoleBasedAuthorization 


This library provide a very simple authorization system. It should work fine with most of the authentication plugins (and gems) out there, even though little testing has been done in this regard. There are a lot of similar plugin/gems and probably this is not better than any others (see http://steffenbartsch.com/blog/2008/08/rails-authorization-plugins/ for a nice review). I already used it in several small projects and it worked great
for my needs. 

Installation:

* install the role_based_authorization by issuing:
        gem install role_based_authorization
  or by adding
        config.gem "role_based_authorization"
  to your rails config file and then running 'rake gems:install'

  
* in your application controller: include the module RoleBasedAuthorization:

```ruby

  class ApplicationController < ActionController::Base
     [...]
     include RoleBasedAuthorization
     [...]
  end
```

			
* in your controller classes: use the permission statements (described below) to grant and deny authorizations to the controller methods.


The inclusion of RoleBasedAuthorization serves three purposes: it allows subclasses of the application controller to use the 'permit' method during their definition, it provides an "authorized?" method that implements the authorization logic, and it creates an helper method to be used in views.

## Requirements


The library poses few and very reasonable constraints on your application. Namely, it requires:


* that your controllers provide a 'current_user' method 
* that the user object (returned by the 'current_user' method)  implements the following two methods:
  * role: returning the role of the current user; roles can be anything (I personally use integers). This is usually implemented by adding a 'role' column to your model.

## Permission statements


You can specify your authorization logic by adding a number of 'permit' calls to your controllers. Permissions granted in a controller apply to all its subclasses. Since usually all controllers inherit from the application controller, this allows one to authorize all actions for the 'admin' role by telling it so in the application controller.

An important thing to keep in mind is that role_based_authorization assumes that EVERYTHING IS FORBIDDEN unless otherwise specified. Then, if you do not specify any permission rule, you will end up with a very secure (though useless) application.

The permission statement takes the form:
```ruby
         permit :actions => [list of actions], 
                 :to  => [list of roles], 
                 :if  => lambda_expression,
                 :object_id => object_id_symbol
```

you can add any number of these in anyone of your controller.

### permit options:

<b>:to</b>::
  the list of roles interested by this rule. The actual contents of this list depends on what your application defines to be a role. If you use integers, it could be a vector like [1,4] or as [ROOT, ADMIN], where ROOT and ADMIN are symbolic costants containing the corresponding integer values. You can specify all roles by specifying :all in place of the role list.


<b>:actions</b>::  
  the list of actions that are permitted to the mentioned roles. Actions are actual method names of the current controller and can be given as symbols or as strings. For instance ['index', 'show'] is equivalent to [:index, :show]. You can grant access to all actions by specifying :all instead of the action list. 


<b>:if</b>:: 
  a lambda expression that verifies additional conditions. The lambda expression takes two arguments: the current user and the id of an object. For instance you may want to verify that "normal" users could only modify objects that they own. You can say that by specifying: 
```ruby
        permit :actions => [:edit, :update], 
               :to => [NORMAL], 
               :if => lambda { |user, obj_id| TheObject.find(obj_id).owner == user }
```
<b>:object_id</b>:: 
  normally the object id passed to the lambda expression of the <tt>:if</tt> option is retrieved from the params hash using <tt>:id</tt> (i.e. normally <tt>obj_id = params[:id]</tt>), you can specify other identifiers using this option, e.g.: 
     <tt>:object_id => :product_id</tt>
  specifies that :product_id should be used instead of :id.

## authorized?

The library adds an authorized? method to your application controller. The method returns false if one of the following conditions occur:
* your controller defines a logged_in? method and the method returns false
* no permit rule matches the current settings
	
## authorize_action?

This is a more general version of :authorized?. The difference between the two is that authorized? uses the current environment (action called, controller name, etc.) to decide whether the current action is to be authorized, authorize_action? instead gets an hash of options containing an action name, a controller name, and some other optional parameters and returns if the specified action on the given controller is authorized for the current user (or for the user specified in the option hash).


## if_authorized? helper method	

It often happens that parts of a view is to be displayed only if a given action is authorized. This clutters your view with code like:
```ruby
   if authorize_action?(:controller => xxx, :action => yyy) .... link_to 'zzz', :controller => xxx, :action => yyy end
```
clearly there is a lot of duplication in this code. if_authorized? takes the same parameters as authorize_action? and a block. The block is called only if authorize_action? returns true and the parameters are passed to the block. This allows to clean up your view as follows:
```ruby
  if_authorized?(:controller => xxx, :action => yyy) do |opts|
     ...
     link_to 'zzz', opts
  end
```	
This works also if you use resource paths as in:
```ruby
  if_authorized?( edit_product_path ) do |opts|
     link_to 'zzz', opts
  end
```	

## Logging

The authorization system logs each access attempt to #{Rails.root}/log/authorization.log. If the log level is high enough, you will also view an explanation of what is happening and why.


## Examples

I usually add a Roles class to my project (I place it in the model directory even though it is not connected to any db table). It's definition is:

```ruby
class Role
  # define below valid roles for your application
  ROLES = { :user => 1, :administrator => 2, :root => 3 }
  
  # call this function in your permit actions 
  def Role.[](role)
    role = ROLES[role]
    raise "given role '#{role}' is not valid" if role.nil?
    return role
  end
end
```
This allows me to write <tt>Role[:root]</tt> to specify the root role.

<b>Example 1:</b> Grant all powers to the root role (this rule is usually found in your application controller)
```ruby
        permit :actions => :all, :to => Role[:root]
```	
<b>Example 2:</b> Grant view actions to normal users, edit actions to administrators
```ruby
        permit :actions => [:index, :show],
               :to => Role[:user]
        permit :actions => [:edit, :update, :destroy],
               :to => Role[:admin]
```		
<b>Example 3:</b> Adding a rule to allow users to edit their own data (let us assume that the controller manages objects of type Product):
```ruby
        permit :actions => [:edit, :update],
               :to => Role[:user].
               :if => lambda { |user, obj_id| Product.find(obj_id).owner == user }
```		 
<b>Example 4:</b> Let us assume that the current controller does not manage products, but that you want to check for the product owner anyway. In this case, the product id will not be passed as the :id object into your params hash and the above rule will fail. Amend this problem by telling the permit action how to retrieve the correct id:
```ruby
        permit :actions => [:edit, :update],
               :to => Role[:user].
               :if => lambda { |user, obj_id| Product.find(obj_id).owner == user },
               :object_id => :product_id
```		    

Copyright (c) 2010 Roberto Esposito, released under the MIT license
