# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/../demos/dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]
  cmd = @test_params.params_chan.cmd[0]
  constraint = @test_params.params_chan.constraint[0]
  pcap_loc = @test_params.params_chan.pcap_loc[0]
  # get ip address
  dut_if = @equipment['dut1'].params['dut1_if']

  # get prucss port information
  pruicss_ports = [@equipment['dut1'].params["#{feature}_port1"], @equipment['dut1'].params["#{feature}_port2"]]

  test_comment = ""
  begin
    enable_feature(@equipment['dut1'], feature, cmd, dut_if, pruicss_ports)
    download_package(pcap_loc,'/tftpboot/')
    verify_node_table(@equipment['dut1'], feature, dut_if, constraint)
    test_comment += "Support of 256 node table entries for #{feature} verified."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def clean
  self.as(LspTestScript).clean
end

# function to verify node table entries
def verify_node_table(dut, feature, dut_if, constraint)
  dut.send_cmd("snmpwalk -v 2c -c public #{dut_if} iec62439", dut.prompt, 60)
  @equipment['server1'].send_sudo_cmd("tcpreplay --intf1=eth1 /tftpboot/256_MAC_IDs_#{feature}_SupFrame.pcap",\
                                       @equipment['server1'].prompt, 60)
  dut.send_cmd("snmpwalk -v 2c -c public #{dut_if} iec62439", dut.prompt, 60)
  if !(dut.response =~ Regexp.new("(#{constraint})")) or dut.timeout?
    raise "Failed to match criteria: #{constraint} or test timed out."
  end
  sleep(60)
  dut.send_cmd("snmpwalk -v 2c -c public #{dut_if} iec62439", dut.prompt, 60)
  if (dut.response =~ Regexp.new("(#{constraint})")) or dut.timeout?
    raise "Failed to remove expired records from node table or test timed out."
  end
end
