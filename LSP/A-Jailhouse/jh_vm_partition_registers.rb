require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/jh_helpers'

include LspTestScript

def setup
    self.as(LspTestScript).setup
end

def run
    begin
        jh_host_test()
    rescue Exception => e
        set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
    end
end

def clean
    self.as(LspTestScript).clean
end

def jh_host_test()
    start_linux_demo()
    jh_send_cmd("root", @equipment['dut1'].params['secondary_serial_prompt'])
    # 0x11c1f8 is a register that J721E Jailhouse inmate should be able to read
    tout, resp = jh_send_cmd("devmem2 0x11c1f8", @equipment['dut1'].params['secondary_serial_prompt'])
    # Match any non-zero hex pattern
    if resp =~ /: 0x0*[1-9a-fA-F][0-9a-fA-F]*/
        set_result(FrameworkConstants::Result[:pass], "Test Passed.")
    else
        raise "Could not read non-zero value of register 0x11c1f8."
    end
end