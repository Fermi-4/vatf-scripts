# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  download_package("#{@test_params.params_chan.jailhouse_inmate[0]}",'/tftpboot/jailhouse_inmates/')
  transfer_to_dut("jailhouse_inmates/led_test.bin",@equipment['server1'].telnet_ip)
  setup_jailhouse_hypervisor()
  result = run_led_test(@test_params.params_chan.constraint[0],\
                        @test_params.params_chan.timeout[0].to_i)
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Passed.")
  else
    set_result(FrameworkConstants::Result[:fail], "Failed to match contraints:\
#{@test_params.params_chan.constraint[0]}, or Test timed out after \
#{@test_params.params_chan.timeout[0]} seconds.")
  end
end

def clean
  self.as(LspTestScript).clean
end

#Function to run led_test with Jailhouse Hypervisor
def run_led_test(constraint,timeout)
  @equipment['dut1'].send_cmd("`jailhouse cell start 1 &`;sleep 10;jailhouse cell shutdown 1;\
jailhouse cell destroy 1;jailhouse disable", "any other character to indicate failure:",20)
  @equipment['dut1'].send_cmd("y\n", "Releasing CPU", timeout)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !(dut_log =~ Regexp.new("(#{constraint})"))
    return 1
  else
    return 0
  end
end

#Function to setup Jailhouse Hypervisor
def setup_jailhouse_hypervisor()
  @equipment['dut1'].send_cmd("cp led_test.bin /usr/share/jailhouse/inmates/",\
                                @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cd /usr/share/jailhouse/", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("modprobe jailhouse", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("jailhouse enable ./cells/am57xx-evm.cell", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("jailhouse cell create ./cells/am57xx-pdk-leddiag.cell", @equipment['dut1'].prompt,60)
  @equipment['dut1'].send_cmd("jailhouse cell load 1 ./inmates/led_test.bin", @equipment['dut1'].prompt,10)
end
