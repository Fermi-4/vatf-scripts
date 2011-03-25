# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
require 'net/http'
require 'uri'

  
def setup
  super
end

def run
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}"))
  http_str = res.body.match(/This is the Out of Box demo prototype for Linux-c6x/)
  if (http_str != nil)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass: found string #{http_str}"
  end
  puts comment
  set_result(test_done_result,comment)
end

def clean

end