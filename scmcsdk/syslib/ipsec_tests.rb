# -*- coding: ISO-8859-1 -*-
require 'fileutils'

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/ipsec_connect_module'
require File.dirname(__FILE__)+'/utilities.rb'

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

# IPSEC connection implementation
include IpsecConnectionScript

def setup
  # Stop ipsec running on Linux PC (Server)
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)

  self.as(LspTestScript).setup
  # Create keys, certificates and then establish the IPSEC connection between EVM and Linux PC
  result |= self.as(IpsecConnectionScript).establish_ipsec_connection(@equipment, @test_params)
end

def run
  # instantiate iperf utility set
  iperfUtils = IperfUtilities.new
  
  # Set default settings
  is_clear_previous_result = true
  result = 0
  comments = ""
  connection_comments = ""
  test_secs = 60
  crypto_mode = "" 
  udp_bandwidth = ""
  packet_size = "1400"
  test_headline = ""

  
  # Get IPSEC connection result  (The result will be set from running establish_ipsec_connection in the setup)
  result |= IpsecConnectionScript.result.to_i

  # Create test headline for IPERF test
  test_headline = "#{IpsecConnectionScript.protocol}_#{IpsecConnectionScript.esp_encryption}_#{IpsecConnectionScript.esp_integrity}"

  # Run iperf test only if IPSEC connection was successful
  if result != 0
    connection_comments += " IPSEC Connection failed for test: #{test_headline}\r\n"
  else
    # Get control information from test case
    test_secs = get_variable_value(@test_params.params_chan.test_secs[0]).to_i if @test_params.params_chan.instance_variable_defined?(:@test_secs)
    crypto_mode = get_variable_value(@test_params.params_chan.crypto[0])  if @test_params.params_chan.instance_variable_defined?(:@crypto)
    packet_size = get_variable_value(@test_params.params_chan.pkt_size[0])  if @test_params.params_chan.instance_variable_defined?(:@pkt_size)
    udp_bandwidth = get_variable_value(@test_params.params_chan.udp_bw[0])  if @test_params.params_chan.instance_variable_defined?(:@udp_bw)
    if udp_bandwidth == ""
      # Set udp bandwith to use with iperf based on crypto_mode if not specified in test case
      case "#{crypto_mode}"
        when "inflow"
          udp_bandwidth = "300M"
        when "hardware", "sideband"
          #udp_bandwidth = "205M"
          udp_bandwidth = "300M"
        when "software"
          udp_bandwidth = "150M"
        else
          udp_bandwidth = "1000M"
      end
    end

    # Set IP addresses for iperf to use
    iperfUtils.iperf_typical_config(@equipment)
      
    # Run iperf on established connection and get result
    result |= iperfUtils.test_linux_to_evm(IpsecConnectionScript.protocol, test_secs, udp_bandwidth, packet_size, test_headline, crypto_mode)
  end

  # Set overall test result and comments text
  if result == 0
    test_done_result = FrameworkConstants::Result[:pass]
    comments += "Test passed. #{iperfUtils.display_memfree_info()}\r\n"
  else
    test_done_result = FrameworkConstants::Result[:fail]
    comments += "Test failed. #{iperfUtils.display_memfree_info()}\r\n"
    comments += connection_comments
  end
  comments += "\r\n"
  comments += iperfUtils.result_text
  comments += ".\r\n"
  comments += IpsecConnectionScript.comment_text
  comments += ".\r\n"

  # Fix dash display for webpage. The dashes are half the size when displayed on the web page so double them to keep the display line size correct.
  comments = comments.gsub("----", "--------")

  # Set test result and result comments
  set_result(test_done_result, comments)
end

def clean
  # Stop ipsec on both sides to be friendly to other tests
  self.as(IpsecConnectionScript).stop_offload_indices()
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)
  self.as(IpsecConnectionScript).stop_ipsec_evm(@equipment)
end
