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
	runltp_fail = false
	dut_timeout = @test_params.params_control.instance_variable_defined?(:@dut_timeout) ? @test_params.params_control.dut_timeout[0].to_i : 600
	runtest_cmd = @test_params.params_control.script.join(";")
	cmd = eval(('"'+runtest_cmd.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')+"\n")
	@equipment['dut1'].send_cmd(cmd, "U-Boot", dut_timeout)
        if @equipment['dut1'].timeout?
           runltp_fail = true
        else
	   @equipment['dut1'].send_cmd(' ', @equipment['dut1'].boot_prompt, dut_timeout)
           if @equipment['dut1'].timeout?
              runltp_fail = true
           end
        end

        if !runltp_fail
           puts "Test PASS"
           set_result(FrameworkConstants::Result[:pass], "Test Passed.")
	else
           puts "Test Fail"
           set_result(FrameworkConstants::Result[:fail], "Test Failed.")
	end
end
