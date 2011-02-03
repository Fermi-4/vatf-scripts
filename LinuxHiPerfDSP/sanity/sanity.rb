# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
  
def setup
  super
end

def run
  @equipment['dut1'].send_cmd("uname -a",@equipment['dut1'].prompt, 30)
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  if (/Linux/.match(@equipment['dut1'].response.to_s) != nil)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  set_result(test_done_result,comment)
end

def clean

end