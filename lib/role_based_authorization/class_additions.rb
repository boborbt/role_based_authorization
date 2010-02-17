module RoleBasedAuthorization
# Defines the class methods that are to be added to the application controller
 module ClassAdditions
   # Returns the set of rules defined on this controller
   def role_auth_rules
     @@rules||={}
     @@rules
   end
   
   # Returns true if one of the given rules  matches the
   # given options. rules must be an hash with a list of rules for
   # each action
   def find_matching_rule rules, options
     user,actions,ids = *options.values_at(:user, :actions, :ids)

     return actions.find do |action|
       AUTHORIZATION_LOGGER.debug('current action: %s' % [action])      
       action = action.to_sym
       rules_for_action = rules[action]
       rules_for_action && rules_for_action.find { |rule| rule.match(user, ids) }
     end
   end
   
   
   # Defines the DSL for the authorization system. The syntax is:
   #   permit  :actions => [list of actions], 
   #       :to  => [list of roles], 
   #       :if  => lambda_expression,
   #       :object_id => object_id_symbol
   # 
   # you can add any number of these in anyone of your controller.
   # 
   # options:
   # 
   # <b>:to</b>::  
   #   the list of roles interested by this rule. The actual contents of this list depends on what your application defines to be a role. If you use integers, it could be a vector like [1,4] or as [ROOT, ADMIN], where ROOT and ADMIN are symbolic costants containing the corresponding integer values. You can specify all roles by specifying :all in place of the role list.
   # 
   # <b>:actions</b>::  
   #   the list of actions that are permitted to the mentioned roles. Actions are actual method names of the current controller and can be given as symbols or as strings. For instance ['index', 'show'] is equivalent to [:index, :show]. You can grant access to all actions by specifying :all instead of the action list. 
   # 
   # <b>:if</b>:: 
   #   a lambda expression that verifies additional conditions. The lambda expression takes two arguments: the current user and the id of an object. For instance you may want to verify that "normal" users could only modify objects that they own. You can say that by specifying: 
   #     permit :actions => [:edit, :update], 
   #       :to => [NORMAL], 
   #       :if => lambda { |user, obj_id| TheObject.find(obj_id).owner == user }
   # 
   # <b>:object_id</b>:: 
   #   normally the object id passed to the lambda expression of the :if option is retrieved from the params hash using :id (i.e. normally obj_id = params[:id]), you can specify other identifiers using this option, e.g.:
   #     :object_id => :product_id
   #   specifies that :product_id should be used instead of :id.
   
   def permit options 
     options[:controller] ||= controller_name
     controller = options[:controller]
     actions    = [*options[:actions]]  # create an array if options[:actions] is not already an array
     
     role_auth_rules[controller] ||= {}      
     
     actions.each do |action|
       action = action.to_sym  # this allows for both symbols and strings to be used for action names
       role_auth_rules[controller][action] ||= []
       role_auth_rules[controller][action] << RoleBasedAuthorization::Rule.new(options[:to], options[:if], options[:object_id])
     end
   end  
 end
end