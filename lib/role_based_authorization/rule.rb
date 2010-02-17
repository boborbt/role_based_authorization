module RoleBasedAuthorization

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
      matching = !@roles.find { |role| !user.nil? && role == user.role }.nil? if !matching

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

end