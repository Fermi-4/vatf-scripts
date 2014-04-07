# -*- coding: ISO-8859-1 -*-
require 'fileutils'

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/ipsec_connect_module'
require File.dirname(__FILE__)+'/utilities.rb'

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

# IPSEC connection implementation
include IpsecConnectionScript

DOWNLOAD_SPEED_INDEX = 0
UPLOAD_SPEED_INDEX = 1

DIRECTION_BOTH = "both"
DIRECTION_INGRESS = "ingress"
DIRECTION_EGRESS = "egress"

CONNECTION_NO_IPSEC = "eth-only"

# K2 defaults
SOFTWARE_CRYPTO_PERF_MBPS = "1000M"
SIDEBAND_CRYPTO_PERF_MBPS = "1000M"
INFLOW_CRYPTO_PERF_MBPS = "1000M"
PASS_THROUGH_PERF_MBPS = "1000M"
ETH_ONLY_PERF_MBPS = "1000M"
FULL_RATE_PERF_MBPS = "1000M"

def setup
  # Stop ipsec running on Linux PC (Server)
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)

  self.as(LspTestScript).setup
  # Create keys, certificates and then establish the IPSEC connection between EVM and Linux PC
  result |= self.as(IpsecConnectionScript).establish_ipsec_connection(@equipment, @test_params)
end

def throughput_mbps_select(conn_type, crypto_mode, current_rate)
  udp_bandwidth = current_rate
  mode = (conn_type == "tunnel" ? crypto_mode : conn_type)
  # Set udp bandwith to use with perf based on conn_type and crypto_mode if not specified or is "*"
  if udp_bandwidth == "" || udp_bandwidth.downcase == "*"
    case "#{mode}"
      when "inflow"
        udp_bandwidth = INFLOW_CRYPTO_PERF_MBPS
      when "hardware", "sideband"
        udp_bandwidth = SIDEBAND_CRYPTO_PERF_MBPS
      when "software"
        udp_bandwidth = SOFTWARE_CRYPTO_PERF_MBPS
      when "pass"
        udp_bandwidth = PASS_THROUGH_PERF_MBPS
      when "eth-only"
        udp_bandwidth = ETH_ONLY_PERF_MBPS
      when "no"
        udp_bandwidth = udp_bandwidth
      else
        udp_bandwidth = FULL_RATE_PERF_MBPS
    end
  end
  return udp_bandwidth
end

def throughput_mbps_select_based_on_packet_size(pkt_size, current_rate)
  udp_bandwidth = "850M"
  if pkt_size < 768
    udp_bandwidth = "600M"
  end
  if pkt_size < 512
    udp_bandwidth = "400M"
  end
  if pkt_size < 256
    udp_bandwidth = "200M"
  end
  return udp_bandwidth
end

def get_bw_info(protocol, specified_bandwidth, auto_bandwidth_detect)
  bw_info = ""
  if protocol.downcase == "udp"
    bw_info = "-#{specified_bandwidth}"
    bw_info += "-abwd" if auto_bandwidth_detect
  end
  return bw_info
end

def run
  # instantiate perf utility set
  perfUtils = PerfUtilities.new
  
  # Set default settings
  is_clear_previous_result = true
  result = 0
  comments = ""
  connection_comments = ""
  test_secs = 60
  auto_bw_test_secs = 5
  auto_bandwidth_detect = true
  crypto_mode = "" 
  udp_bandwidth = ""
  udp_bandwidth_array = Array.new
  packet_size = "1400"
  test_headline = ""
  test_direction = DIRECTION_INGRESS
  dev = 'dut1'
  eth_port = ""
  iface_type = 'eth'
  perf_app = perfUtils.IPERF_APP()
  default_mtu_size = "1500"
  mtu_size = default_mtu_size
  auto_bw = "yes"
  min_tput = ""
  jumbo_frames = "no"
  
  # Get IPSEC connection result  (The result will be set from running establish_ipsec_connection in the setup)
  result |= IpsecConnectionScript.result.to_i

  # Create test headline for PERF test
  test_headline = "#{IpsecConnectionScript.protocol}_#{IpsecConnectionScript.esp_encryption}_#{IpsecConnectionScript.esp_integrity}"

  # Run perf test only if IPSEC connection was successful
  if result != 0
    connection_comments += " IPSEC Connection failed for test: #{test_headline}\r\n"
  else
    # Get control information from test case
    test_secs = get_variable_value(@test_params.params_chan.test_secs[0]).to_i if @test_params.params_chan.instance_variable_defined?(:@test_secs)
    crypto_mode = get_variable_value(@test_params.params_chan.crypto[0])  if @test_params.params_chan.instance_variable_defined?(:@crypto)
    packet_size = get_variable_value(@test_params.params_chan.pkt_size[0])  if @test_params.params_chan.instance_variable_defined?(:@pkt_size)
    conn_type = get_variable_value(@test_params.params_chan.conn[0])  if @test_params.params_chan.instance_variable_defined?(:@conn)
    udp_bandwidth = get_variable_value(@test_params.params_chan.udp_bw[0])  if @test_params.params_chan.instance_variable_defined?(:@udp_bw)
    auto_bw = get_variable_value(@test_params.params_chan.auto_bw[0])  if @test_params.params_chan.instance_variable_defined?(:@auto_bw)
    eth_port = get_variable_value(@test_params.params_chan.eth_port[0])  if @test_params.params_chan.instance_variable_defined?(:@eth_port)
    perf_app = get_variable_value(@test_params.params_chan.perf_server[0])  if @test_params.params_chan.instance_variable_defined?(:@perf_server)
    mtu_size = get_variable_value(@test_params.params_chan.mtu_size[0])  if @test_params.params_chan.instance_variable_defined?(:@mtu_size)
    min_tput = get_variable_value(@test_params.params_chan.min_tput[0])  if @test_params.params_chan.instance_variable_defined?(:@min_tput)
    jumbo_frames = get_variable_value(@test_params.params_chan.jumbo_frames[0])  if @test_params.params_chan.instance_variable_defined?(:@jumbo_frames)

    if min_tput.include?("/")
      min_tput_array = min_tput.split("/")
      ingress_min_tput = min_tput_array[DOWNLOAD_SPEED_INDEX].to_i
      egress_min_tput = min_tput_array[UPLOAD_SPEED_INDEX].to_i
    else
      ingress_min_tput = (min_tput == "" ? 0 : min_tput.to_i)
      egress_min_tput = ingress_min_tput
    end

    if jumbo_frames.downcase.include?("yes") || jumbo_frames.downcase.include?("true")
      jumbo_frames = "yes"
    end
    #jumbo_frames = "yes"

    # For debug only
    #test_secs = 5

    if perf_app.downcase.include?("netperf")
      perfUtils.set_perf_app(perfUtils.NETPERF_APP())
    end

    iface_type = "eth#{eth_port}"

    if auto_bw == "no" || auto_bw == "false"
      auto_bandwidth_detect = false
    end
    if udp_bandwidth.include?("/")
      udp_bandwidth_array = udp_bandwidth.split("/")
      # If upd_bandwidth specified as /XXM then test egress direction otherwise test both directions 
      test_direction = (udp_bandwidth_array[DOWNLOAD_SPEED_INDEX].downcase == "no" ? DIRECTION_EGRESS : DIRECTION_BOTH)
      test_direction = (udp_bandwidth_array[UPLOAD_SPEED_INDEX].downcase == "no" ? DIRECTION_INGRESS : test_direction)
      udp_bandwidth_array[DOWNLOAD_SPEED_INDEX] = throughput_mbps_select(conn_type, crypto_mode, udp_bandwidth_array[DOWNLOAD_SPEED_INDEX])
      udp_bandwidth_array[UPLOAD_SPEED_INDEX] = throughput_mbps_select(conn_type, crypto_mode, udp_bandwidth_array[UPLOAD_SPEED_INDEX])
      if test_direction == DIRECTION_BOTH
        auto_bandwidth_detect = false
      end
    else
      # If a single bandwidth value is specified then push it to the udp_bandwidth_array
      udp_bandwidth_array.push(throughput_mbps_select(conn_type, crypto_mode, udp_bandwidth))
      test_direction = DIRECTION_INGRESS
    end

    # Set IP addresses for perf to use
    perfUtils.perf_typical_config(@equipment, dev, iface_type)

    # Set mtu for Jumbo packets if needed
    if jumbo_frames == "yes" && packet_size.to_i > 1500
      perfUtils.set_mtu_size(packet_size, eth_port)
    end
      
    case test_direction
      when DIRECTION_BOTH
        udp_bandwidth_ingress = udp_bandwidth_array[DOWNLOAD_SPEED_INDEX]
        udp_bandwidth_egress = udp_bandwidth_array[UPLOAD_SPEED_INDEX]
        ingress_bw = get_bw_info(IpsecConnectionScript.protocol, udp_bandwidth_ingress, auto_bandwidth_detect)
        egress_bw = get_bw_info(IpsecConnectionScript.protocol, udp_bandwidth_egress, auto_bandwidth_detect)
        test_headline_both = "#{test_headline}_#{DIRECTION_INGRESS}#{ingress_bw}_#{DIRECTION_EGRESS}#{egress_bw}"
        result |= perfUtils.test_linux_to_evm_and_evm_to_linux(IpsecConnectionScript.protocol, test_secs, udp_bandwidth_ingress, udp_bandwidth_egress, packet_size, test_headline_both, crypto_mode, ingress_min_tput, egress_min_tput)
      when DIRECTION_INGRESS
        udp_bandwidth_ingress = udp_bandwidth_array[DOWNLOAD_SPEED_INDEX]
        specified_bandwidth = udp_bandwidth_ingress
        # Currently the 10G interface does not get anywhere near 10G and will cause lower rates if stating at 10000M so start it at 1000M
        udp_bandwidth_ingress = "1400M" if udp_bandwidth_array[DOWNLOAD_SPEED_INDEX] == "10000M"
        #udp_bandwidth_ingress = throughput_mbps_select_based_on_packet_size(packet_size.to_i, udp_bandwidth_ingress)
        # If UDP use binary search to get the best MBPS
        if IpsecConnectionScript.protocol.downcase == "udp" && auto_bandwidth_detect
          udp_bandwidth_ingress = perfUtils.test_linux_to_evm_mbps_detect(IpsecConnectionScript.protocol, auto_bw_test_secs, udp_bandwidth_ingress, packet_size, "auto detect mbps", crypto_mode)
          if udp_bandwidth_ingress == 0
            result = 1
            comments += "Error: Automated throughput measurement detected 0 Mbps. UDP packets are not passing accross this connection."
          end
        end
        test_headline_ingress = "#{test_headline}_#{DIRECTION_INGRESS}#{get_bw_info(IpsecConnectionScript.protocol, specified_bandwidth, auto_bandwidth_detect)}"
        if result == 0
          result |= perfUtils.test_linux_to_evm(IpsecConnectionScript.protocol, test_secs, udp_bandwidth_ingress, packet_size, test_headline_ingress, crypto_mode, ingress_min_tput, egress_min_tput)
        end
      when DIRECTION_EGRESS
        udp_bandwidth_egress = udp_bandwidth_array[UPLOAD_SPEED_INDEX]
        specified_bandwidth = udp_bandwidth_egress
        # Currently the 10G interface does not get anywhere near 10G and will cause lower rates if stating at 10000M so start it at 1000M
        udp_bandwidth_egress = "1400M" if udp_bandwidth_array[UPLOAD_SPEED_INDEX] == "10000M"
        if IpsecConnectionScript.protocol.downcase == "udp" && auto_bandwidth_detect
          udp_bandwidth_egress = perfUtils.test_evm_to_linux_mbps_detect(IpsecConnectionScript.protocol, auto_bw_test_secs, udp_bandwidth_egress, packet_size, "auto detect mbps", crypto_mode)
          if udp_bandwidth_ingress == 0
            result = 1
            comments += "Error: Automated throughput measurement detected 0 Mbps. UDP packets are not passing accross this connection."
          end
        end
        test_headline_egress = "#{test_headline}_#{DIRECTION_EGRESS}#{get_bw_info(IpsecConnectionScript.protocol, specified_bandwidth, auto_bandwidth_detect)}"
        if result == 0
          result |= perfUtils.test_evm_to_linux(IpsecConnectionScript.protocol, test_secs, udp_bandwidth_egress, packet_size, test_headline_egress, crypto_mode, ingress_min_tput, egress_min_tput)
        end
      else
        result = 1
        comments += "Test Case ERROR: Unable to determine throughput direction.\r\n"
    end
  end

  # Set mtu back to default
  if jumbo_frames == "yes" && packet_size.to_i > 1500
    perfUtils.set_mtu_size(default_mtu_size, eth_port)
  end

  # Set overall test result and comments text
  if result == 0
    test_done_result = FrameworkConstants::Result[:pass]
    comments += "Test passed. #{perfUtils.display_memfree_info()}\r\n"
  else
    test_done_result = FrameworkConstants::Result[:fail]
    comments += "Test failed. #{perfUtils.display_memfree_info()}\r\n"
    comments += connection_comments
  end
  comments += "\r\n"
  comments += perfUtils.result_text
  comments += ".\r\n"
  comments += IpsecConnectionScript.comment_text
  comments += ".\r\n"

  # Fix dash display for webpage. The dashes are half the size when displayed on the web page so double them to keep the display line size correct.
  comments = comments.gsub("----", "--------")

  # Set test result and result comments
  set_result(test_done_result, comments)

  # Stop ipsec on both sides to be friendly to other tests
  if conn_type != CONNECTION_NO_IPSEC
    self.as(IpsecConnectionScript).stop_offload_indices()
  end
  self.as(IpsecConnectionScript).stop_ipsec(@equipment)
  self.as(IpsecConnectionScript).stop_ipsec_evm(@equipment)
end

def clean
  super
end
