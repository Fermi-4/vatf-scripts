# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  download_package("#{@test_params.params_chan.bin_path[0]}",'/tftpboot/')
  transfer_to_dut("echo_testd.out",@equipment['server1'].telnet_ip)
  download_package("#{@test_params.params_chan.bin_path[1]}",'/tftpboot/')
  transfer_to_dut("rpmsg_proto_socket_test",@equipment['server1'].telnet_ip)
  setup_openamp()
  self.as(LspTestScript).setup
  result = run_openamp_test(@test_params.params_chan.constraints[0],\
                        @test_params.params_chan.timeout[0].to_i)
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Passed: OpenAMP test run successfully on target.")
  else
    set_result(FrameworkConstants::Result[:fail], "Failed to match contraints:\
#{@test_params.params_chan.constraints[0]}, or Test timed out after \
#{@test_params.params_chan.timeout[0]} seconds.")
  end
end

def clean
  self.as(LspTestScript).clean
end

# Function to run openAMP test
def run_openamp_test(constraints,timeout)
  @equipment['dut1'].send_cmd("chmod +x rpmsg_proto_socket_test",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("./rpmsg_proto_socket_test",@equipment['dut1'].prompt, timeout)
  if @equipment['dut1'].timeout? or !(@equipment['dut1'].response =~ Regexp.new("(#{constraints})"))
    return 1
  else
    return 0
  end
end

# Function to setup openAMP
def setup_openamp()
  @equipment['dut1'].send_cmd("cp echo_testd.out /home/root/",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cp rpmsg_proto_socket_test /home/root/",@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("systemctl disable ti-mct-daemon.service", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("ln -sf /home/root/echo_testd.out /lib/firmware/dra7-dsp1-fw.xe66",\
                               @equipment['dut1'].prompt,10)
end
