# Personalizes the authorization logging by adding Auth | in front of each line.
# It also outputs the time stamp and the severity of the log message.
class AuthorizationLogger < ActiveSupport::BufferedLogger
  # Prefix for each message
  AUTHORIZATION_SYSTEM_LOG_MSG_PREFIX = 'Auth |'
  
  # overriding of the formatting message
  def format_message(severity, timestamp, progname, msg)
      "#{AUTHORIZATION_SYSTEM_LOG_MSG_PREFIX} #{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n" 
  end
end
