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
  
  @equipment['dut1'].send_cmd("uname -a",@equipment['dut1'].prompt,10)
  platform = @equipment['dut1'].response.match(/ti(c\d+\w)/).captures[0].to_s

  if (platform == "c6678" or platform == "c6670")
    test_str=/C6x\sLinux\sWeb\sControl\sPanel/
  else
    test_str=/This\sis\sthe\sOut\sof\sBox\sdemo\sprototype\sfor\sLinux-c6x/
  end
  res = Net::HTTP.get_response(URI.parse("http://#{@equipment['dut1'].telnet_ip}"))
  http_str = res.body.match(test_str)
  if (http_str != nil)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass: found string #{http_str}"
  end
  puts comment
  set_result(test_done_result,comment)
end

def clean

end