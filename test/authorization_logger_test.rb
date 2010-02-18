require 'test_helper'
require 'role_based_authorization'

class AuthorizationLoggerTest < ActiveSupport::TestCase
  def setup
    @logger = AuthorizationLogger.new(nil)
  end
  
  
  test "Should include the log prefix string to each log entry" do
    assert_match /#{AuthorizationLogger::AUTHORIZATION_SYSTEM_LOG_MSG_PREFIX}/, @logger.format_message(:info, Time.now, "progname", "msg")
  end

  test "Should include the current time in the db format" do
    time = Time.now
    assert_match /#{time.to_s(:db)}/, @logger.format_message(:info, time, "progname", "msg")
  end
  
  test "Should include the log level" do
    assert_match /INFO/, @logger.format_message('INFO', Time.now, "progname", "msg")    
  end


  test "Should include the output msg" do
    assert_match /msg/, @logger.format_message('INFO', Time.now, "progname", "msg")    
  end
  
  test "Should not include the program name" do
    assert ! /progname/.match(@logger.format_message('INFO', Time.now, "progname", "msg"))
  end
  
end
