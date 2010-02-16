module RoleBasedAuthorization
  # AuthorizationLogger instance that is used throughout the plugin for logging
  # events.
  AUTHORIZATION_LOGGER = AuthorizationLogger.new(File.join(RAILS_ROOT,'log','authorization.log'))
  
  module ClassMethods; end
  
  # Fires when the module is included into the controllers. It adds all class methods
  # defined in the ClassMethods sub-module and the authorize_action? and if_authorized?
  # instance methods.
  def self.included(klass)
   klass.extend(ClassMethods)
   
   klass.class_eval do
     helper_method :authorize_action?
     helper_method :if_authorized?
   end
  end

  # Defines the class methods that are to be added to the application controller
  module ClassMethods
    # Returns the set of rules defined on this controller
    def role_auth_rules
      @@rules||={}
      @@rules
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
      role_auth_rules[controller] ||= {}
      
      if options[:actions] == :all
        role_auth_rules[controller][:all] ||= []
        role_auth_rules[controller][:all] << RoleBasedAuthorization::Rule.new(options[:to], options[:if], options[:object_id])
        return
      end
    
      options[:actions].each do |action|
        action = action.to_s  # this allows for both symbols and strings to be used for action names
        role_auth_rules[controller][action] ||= []
        role_auth_rules[controller][action] << RoleBasedAuthorization::Rule.new(options[:to], options[:if], options[:object_id])
      end
    end  
  end
  
  
  # Model an authorization rule. A rule is a triplet: <roles, cond, object_id>
  # a rule match if the user role is in roles and cond (if not nil) is satisfied when objects
  # are retrieved using object_id.
  class Rule
    # rule initialization. roles is mandatory, cond is optional, object_id defaults
    # to :id if nil.
    def initialize roles, cond, object_id
      roles = [roles] unless roles.respond_to? :each
            
      @roles = roles
      @cond = cond
      @object_id = object_id || :id
    end
    
    # return true if this rule matches the given user and objects
    def match(user, objects)      
      AUTHORIZATION_LOGGER.debug('trying '+self.inspect)
      
      matching = @roles.include?(:all)
      
      # checking for right role (no need to check them if already matching)
      matching = !@roles.find { |role| role == user.role }.nil? if !matching
      
      if @cond.nil?
        return matching
      else
        # to have a proper match, also the condition must hold
        return matching && @cond.call(user,objects[@object_id])
      end
    end
    
    # string representation for this rule
    def inspect
      str =  "rule(#{self.object_id}): allow roles [" + @roles.join(',') + "]"
      str += " (only under condition object_id will be retrieved using '#{@object_id}')" if @cond
      
      str
    end
  end
    
  # Main authorization logic. opts is an hash with the following keys
  # :user, :controller, :action:: self explanatory
  # :ids:: id to be used to retrieve relevant objects
  def authorize_action? opts = {}  
    if defined?(logged_in?) && !logged_in?
      AUTHORIZATION_LOGGER.info("returning false (not logged in)")
      return false
    end
    
    opts[:ids] ||= {}
    opts[:ids].reverse_merge!( opts.reject { |k,v| k.to_s !~ /(_id\Z)|(\Aid\Z)/ } )
    
    if opts[:user].nil? && defined?(current_user)
      opts[:user] = current_user
    end
    
    if opts[:controller].nil? && defined?(controller_name)
      opts[:controller] = controller_name
    end

    AUTHORIZATION_LOGGER.info("user %s requested access to method %s:%s using ids:%s" %
        [ opts[:user] && opts[:user].description + "(id:#{opts[:user].id} role:#{opts[:user].role})" || 'none',
          opts[:controller],
          opts[:action],
          opts[:ids].inspect])
    
    rules = self.class.role_auth_rules
    AUTHORIZATION_LOGGER.debug("current set of rules: %s" % [rules.inspect])

    ([opts[:controller]] | ['application']).each do |controller|    
      if( !controller.blank? && rules[controller].nil? )
        # tries to load the controller. Rails automagically loads classes if their name
        # is used anywhere. By trying to constantize the name of the controller, we
        # force rails to load it.
        controller_klass = (controller.to_s+'_controller').camelize.constantize
      end
    
      AUTHORIZATION_LOGGER.debug("current controller: %s" % [controller])
    
      [:all, opts[:action]].each do |action|
        AUTHORIZATION_LOGGER.debug('current action: %s' % [action])
        
        raise "Action should be a string -- not a #{action.class.name}!" if action!=:all && action.class!=String
        
        next if rules[controller].nil? || rules[controller][action].nil?            
        if rules[controller][action].find { |rule| rule.match(opts[:user], opts[:ids]) }
          AUTHORIZATION_LOGGER.info('returning true (access granted)')
          return true
        end 
      end
    end
    
    AUTHORIZATION_LOGGER.info('returning false (access denied)')
    return false
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
    url_options = nil
    if opts.class == String
      path = opts
      
      url_options = ActionController::Routing::Routes.recognize_path(path)
    else
      url_options = opts.dup
    end
    
    if authorize_action? url_options
      block.call(opts)
    end
  end
  
  # Returns true if the current user is authorized to perform the current action
  # on the current controller. It is mainly used in a before_filter (usually 
  # the method implementing the authentication logic calls this method immediately
  # after checking the validity of the credentials.)
  def authorized?
    authorize_action?     :controller => controller_name,  
                          :action => action_name, 
                          :ids => params.reject { |k,v| k.to_s !~ /(_id\Z)|(\Aid\Z)/ }, 
                          :user => current_user
  end
end