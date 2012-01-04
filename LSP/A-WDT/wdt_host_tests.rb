# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  #super
  #self.as(LspTestScript).run
  watchdog_timer_test
end

def clean
  #super
  self.as(LspTestScript).clean
end

def watchdog_timer_test
	dut_timeout = @test_params.params_control.instance_variable_defined?(:@dut_timeout) ? @test_params.params_control.dut_timeout[0].to_i : 600
	@equipment['dut1'].send_cmd('cd /opt/ltp', @equipment['dut1'].prompt,1)
	@equipment['dut1'].send_cmd("./runltp -P #{@test_params.platform} -s #{@test_params.params_chan.cmd[0].to_s}", @equipment['dut1'].login_prompt,dut_timeout)
	@equipment['dut1'].send_cmd("#{@equipment['dut1'].login}", @equipment['dut1'].prompt,1)
	@equipment['dut1'].send_cmd('uname -a', @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
	if response.include?("#{@test_params.platform}")
		puts "Test PASS"
		set_result(FrameworkConstants::Result[:pass], "Test Passed.")
	else
		puts "Test Fail"
		set_result(FrameworkConstants::Result[:fail], "Test Failed.")
	end
end
