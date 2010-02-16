class AuthorizationLogger < Logger
  AUTHORIZATION_SYSTEM_LOG_MSG_PREFIX = 'Auth |'
  
  def format_message(severity, timestamp, progname, msg)
      "#{AUTHORIZATION_SYSTEM_LOG_MSG_PREFIX} #{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n" 
  end
end
