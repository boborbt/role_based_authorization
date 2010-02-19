
module RoleBasedAuthorization
  # AuthorizationLogger instance that is used throughout the plugin for logging
  # events.
  AUTHORIZATION_LOGGER = AuthorizationLogger.new(File.join(RAILS_ROOT,'log','authorization.log'))  
    
  # Fires when the module is included into the controllers. It adds all class methods
  # defined in the ClassAdditions sub-module and the authorize_action? and if_authorized?
  # instance methods.
  def self.included(klass)
   klass.extend(ClassAdditions)
   
   klass.class_eval do
     helper_method :authorize_action?
     helper_method :if_authorized?
   end
  end
  
  # Returns true if one of the given rules  matches the
  # given options. rules must be an hash with a list of rules for
  # each action
  def RoleBasedAuthorization.find_matching_rule rules, options
    user,actions,ids = *options.values_at(:user, :actions, :ids)

    return actions.find do |action|
      AUTHORIZATION_LOGGER.debug('current action: %s' % [action])      
      action = action.to_sym
      rules_for_action = rules[action]
      rules_for_action && rules_for_action.find { |rule| rule.match(user, ids) }
    end
  end
  
  
  # Returns an hash options amenable to be passed to authorize_action?. It takes either
  # an option hash, or a path string
  def RoleBasedAuthorization.path_or_options_to_options(opts)
    path_cleanup_regexp = %r{(#{ActionController::Base.relative_url_root})?}
       
    url_options = (opts.class == String) && ActionController::Routing::Routes.recognize_path(opts.gsub(path_cleanup_regexp,''))
    url_options ||= opts.dup
    
    url_options
  end
  
  
  # cleans options so that they are good to be passed to exists_matching_rule
  def cleanup_options(opts)
    opts.reverse_merge!( :user => current_user, :controller => controller_name, :ids => {} )
    user, controller, action, ids = opts.values_at( :user, :controller, :action, :ids )
    ids.reverse_merge!( opts.reject { |key,value| key.to_s !~ /(_id\Z)|(\Aid\Z)/ } )
    
    { :user         => user, 
      :controllers  => [controller,'application'], 
      :actions      => [:all,action], 
      :ids          => ids }    
  end
  
      
  # Returns true if one of the rules defined for this controller matches
  # the given options
  def exists_matching_rule? options
    rules = self.class.role_auth_rules
    
    # !! is an idiom for transforming any value in true/false (e.g., !!nil is exactly false)
    !!options[:controllers].find do |controller|
      AUTHORIZATION_LOGGER.debug("current controller: %s" % [controller])

      rules_for_controller = rules[controller]

      # tries to load the controller. Rails automagically loads classes if their name
      # is used anywhere. By trying to constantize the name of the controller, we
      # force rails to load it. Loading the controller class causes the insertion of the rules defined therein
      # into the object pointed by rules_for_controller.
      (controller.to_s+'_controller').camelize.constantize if( !controller.blank? && rules_for_controller.nil? )
    

      rules_for_controller && RoleBasedAuthorization.find_matching_rule(rules_for_controller, options)
    end
  end
    
  # Main authorization logic. opts is an hash with the following keys
  # :user, :controller, :action:: self explanatory
  # :ids:: id to be used to retrieve relevant objects
  def do_authorize_action? opts
    # exiting immediately if not logged in
    return false if respond_to?(:logged_in?) && !logged_in?
    
    exists_matching_rule?( cleanup_options(opts) )
  end
  
  # wraps some logging around do_authorize_action?.
  def authorize_action? opts = {}
    AUTHORIZATION_LOGGER.info("access request. options: %s" % [opts.inspect])
    result = do_authorize_action?(opts)
    AUTHORIZATION_LOGGER.info("returning #{result}")
    
    return result
  end
  
  
  # This is a helper method that provides a conditional execution syntax for
  # a block of code. It is mainly useful because in most cases the same options
  # that are needed for the authorization are also needed for url generation.
  # Since this method forward those options to the block, it allows to write 
  # something like:
  #   if_authorized? {:controller => xxx, :action => yyy} {|opts| link_to('yyy', opts) }
  # instead of:
  #   if authorized_action? {:controller => xxx, :action => yyy}
  #     link_to 'yyy', {:controller => xxx, :action => yyy}
  #   end
  # 
  # As an additional benefit, this method also accepts urls instead of parameter
  # hashes. e.g.
  #   if_authorized?( '/xxx/yyy' ) { |opts| link_to('yyy', opts) }
  # this comes particularly handy when you use resource based url generation 
  # as in the case:
  #   if_authorized?( edit_item_path ) { |opts| link_to('yyy', opts) }
  
  def if_authorized? opts, &block
    block.call(opts) if authorize_action?(RoleBasedAuthorization.path_or_options_to_options(opts))
  end
  
  # Returns true if the current user is authorized to perform the current action
  # on the current controller. It is mainly used in a before_filter (usually 
  # the method implementing the authentication logic calls this method immediately
  # after checking the validity of the credentials.)
  def authorized?
    authorize_action?     :controller => controller_name,  
                          :action => action_name, 
                          :ids => params.reject { |key,value| key.to_s !~ /(_id\Z)|(\Aid\Z)/ }
  end
end