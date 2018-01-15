# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'
require File.dirname(__FILE__)+'/test_protocols'

include LspTestScript
def setup
  # dut2 board setup
  add_equipment('dut2', @equipment['dut1'].params['dut2']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut2'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)
  # boot 1st EVM
  setup_boards('dut1')
  # boot 2nd EVM
  # check if both dut's not same
  if @equipment['dut1'].name != @equipment['dut2'].name
    params2 = {'platform'=>@equipment['dut2'].name}
    boot_params2 = translate_params2(params2)
    setup_boards('dut2', boot_params2)
  else
    setup_boards('dut2')
  end
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]
  cmd = @test_params.params_chan.cmd[0]
  # ip addresses for dut1 and dut2
  dut1_if02, dut1_if03 = "192.168.2.10", "192.168.3.10"
  dut2_if02, dut2_if03 = "192.168.2.20", "192.168.3.20"
  test_comment = ""
  begin
    enable_feature(@equipment['dut1'], feature, cmd, dut1_if02)
    enable_feature(@equipment['dut2'], feature, cmd, dut2_if02)
    ping_status(@equipment['dut1'], dut2_if02)
    ping_status(@equipment['dut2'], dut1_if02)
    enable_vlan(@equipment['dut1'], feature, dut1_if02, dut1_if03)
    enable_vlan(@equipment['dut2'], feature, dut2_if02, dut2_if03)
    ping_status(@equipment['dut1'], dut2_if02)
    ping_status(@equipment['dut2'], dut1_if02)
    ping_status(@equipment['dut1'], dut2_if03)
    ping_status(@equipment['dut2'], dut1_if03)
    verify_packets(@equipment['dut1'], feature)
    verify_packets(@equipment['dut2'], feature)
    test_comment += "VLAN over #{feature} verified."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to enable vlan
def enable_vlan(dut, feature, dut_if02, dut_if03)
  dut.send_cmd("ifconfig #{feature}0 0.0.0.0", dut.prompt, 10)
  dut.send_cmd("ip link add link #{feature}0 name #{feature}0.2 type vlan id 2", dut.prompt, 10)
  dut.send_cmd("ip link add link #{feature}0 name #{feature}0.3 type vlan id 3", dut.prompt, 10)
  dut.send_cmd("ifconfig #{feature}0.2 #{dut_if02}", dut.prompt, 10)
  dut.send_cmd("ifconfig #{feature}0.3 #{dut_if03}", dut.prompt, 10)
  dut.send_cmd("ip link set #{feature}0.2 type vlan egress 0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0", dut.prompt, 10)
  dut.send_cmd("ip link set #{feature}0.3 type vlan egress 0:7 1:7 2:7 3:7 4:7 5:7 6:7 7:7", dut.prompt, 10)
  dut.send_cmd("ifconfig", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(#{feature}0.[2-3]\s+Link\sencap:Ethernet\s+HWaddr)"))
    raise "Failed to enable VLAN over #{feature}."
  end
end

# function to verify packets received over vlan
def verify_packets(dut, feature)
  dut.send_cmd("cat /proc/net/vlan/#{feature}0.2", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(total\sframes\sreceived\s+[1-9]\\d+)"))
    raise "Failed to receive packets."
  end
  dut.send_cmd("cat /proc/net/vlan/#{feature}0.3", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(total\sframes\sreceived\s+[1-9]\\d+)"))
    raise "Failed to receive packets."
  end
end

def clean
  #super
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
