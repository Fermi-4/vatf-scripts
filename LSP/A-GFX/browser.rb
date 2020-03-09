# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/matrix-gui-2.0 stop',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || /etc/init.d/weston start && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || echo "weston failed"',@equipment['dut1'].prompt,10)
  if @equipment['dut1'].response.scan(/weston\s*failed/im).length > 1
    @equipment['dut1'].send_cmd('cat /var/log/weston.log', @equipment['dut1'].prompt, 10)
    raise "Weston did not start, test requires weston"
  end
end

def run
  start_cmd = @test_params.params_chan.browser_cmd[0]
  timeout = @test_params.params_chan.timeout[0].to_i
  
  @equipment['dut1'].send_cmd("timeout #{timeout} #{start_cmd}", @equipment['dut1'].prompt, timeout + 10)
  if @equipment['dut1'].response.match(/error/im)
    set_result(FrameworkConstants::Result[:fail], "Test failed:\n#{@equipment['dut1'].response}")
  else
    set_result(FrameworkConstants::Result[:pass], "Browser test passed")
  end
end
