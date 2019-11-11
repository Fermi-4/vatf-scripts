require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/jh_helpers'

include LspTestScript

def setup
    self.as(LspTestScript).setup
end

def run
    begin
        jh_host_test()
        set_result(FrameworkConstants::Result[:pass], "Test Passed.")
    rescue Exception => e
        set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
    end
end

def clean
    self.as(LspTestScript).clean
    jh_send_cmd("unset PROC_COUNT", @equipment['dut1'].params['secondary_serial_prompt'])
end

def jh_host_test()
    start_linux_demo()
    jh_send_cmd("root", @equipment['dut1'].params['secondary_serial_prompt'])
    jh_send_cmd("PROC_COUNT=$(cat /proc/cpuinfo | grep -c processor)", @equipment['dut1'].params['secondary_serial_prompt'])
    tout, resp = jh_send_cmd("echo \"Detected $PROC_COUNT processors\"", @equipment['dut1'].params['secondary_serial_prompt'])
    if resp =~ /Detected (0|1) processors/
        raise "Failed to detect more than one processor"
    end
end