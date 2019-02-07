# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'
require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/../common_utils/common_functions'

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

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']

  # get ip addresses for dut1 and dut2 from bench file
  dan_X_1_ips = [dan_X_1.params['dut1_if'], dan_X_1.params['dut1_if2'],
                 dan_X_1.params['dut1_if4'], dan_X_1.params['dut1_if5']]
  dan_X_2_ips = [dan_X_2.params['dut2_if'], dan_X_2.params['dut2_if2'],
                 dan_X_2.params['dut2_if4'], dan_X_2.params['dut2_if5']]

  vlan_filter = @test_params.params_chan.instance_variable_defined?(:@vlan_filter) ? @test_params.params_chan.vlan_filter[0].to_i : 0
  mc_filter = @test_params.params_chan.instance_variable_defined?(:@mc_filter) ? @test_params.params_chan.mc_filter[0].to_i : 0
  mc_cli_ser_bins = @test_params.params_chan.instance_variable_defined?(:@mc_cli_ser_bins) ? @test_params.params_chan.mc_filter[0] : ""
  vlan_tag = @test_params.params_chan.instance_variable_defined?(:@vlan_tag) ? @test_params.params_chan.vlan_tag[0].to_i : 0

  test_comment = ""
  begin
    # get pruicss port information
    dan_X_1_pruicss_ports = [dan_X_1.params["#{feature}_port1"], dan_X_1.params["#{feature}_port2"]]
    dan_X_2_pruicss_ports = [dan_X_2.params["#{feature}_port1"], dan_X_2.params["#{feature}_port2"]]
    if feature == "emac"
      enable_vlan_over_emac(dan_X_1, dan_X_1_pruicss_ports[0], dan_X_1_ips[0], dan_X_1_ips[1], 2 , 3)
      enable_vlan_over_emac(dan_X_1, dan_X_1_pruicss_ports[1], dan_X_1_ips[2], dan_X_1_ips[3], 4 , 5)
      enable_vlan_over_emac(dan_X_2, dan_X_2_pruicss_ports[0], dan_X_2_ips[0], dan_X_2_ips[1], 2 , 3)
      enable_vlan_over_emac(dan_X_2, dan_X_2_pruicss_ports[1], dan_X_2_ips[2], dan_X_2_ips[3], 4 , 5)
      ping_status(dan_X_1, dan_X_2_ips[0])
      ping_status(dan_X_1, dan_X_2_ips[1])
      ping_status(dan_X_2, dan_X_1_ips[2])
      ping_status(dan_X_2, dan_X_1_ips[3])
    else
      cmd = get_cmd(feature, dan_X_1_pruicss_ports)
      enable_feature(dan_X_1, feature, cmd, dan_X_1_ips[0], dan_X_1_pruicss_ports)
      cmd = get_cmd(feature, dan_X_2_pruicss_ports)
      enable_feature(dan_X_2, feature, cmd, dan_X_2_ips[0], dan_X_2_pruicss_ports)

      ping_status(dan_X_1, dan_X_2_ips[0])
      enable_vlan(dan_X_1, feature, dan_X_1_ips[0], dan_X_1_ips[1])
      enable_vlan(dan_X_2, feature, dan_X_2_ips[0], dan_X_2_ips[1], dan_X_2_ips[3], mc_filter)
      ping_status(dan_X_1, dan_X_2_ips[0])
      ping_status(dan_X_2, dan_X_1_ips[1])
      verify_packets(dan_X_1, feature)
      verify_packets(dan_X_2, feature)
    end
    test_comment += "VLAN over #{feature} verified."

    if vlan_tag == 1
      verify_vlan_tag(dan_X_1, dan_X_2, dan_X_1_pruicss_ports[0], dan_X_1_ips[0])
      verify_vlan_tag(dan_X_1, dan_X_2, dan_X_1_pruicss_ports[1], dan_X_1_ips[3]) if feature == "emac"
      test_comment += " Verified the frames are VLAN tagged."
    end

    # verify vlan filtering if vlan_filter set to 1
    if vlan_filter == 1
      is_vlan_filter_enabled(dan_X_1, feature)
      is_vlan_filter_enabled(dan_X_2, feature)
      verify_vlan_filtering(dan_X_1, dan_X_2, dan_X_1_ips[0], dan_X_1_pruicss_ports[0], dan_X_2_pruicss_ports[0])
      # passing invalid vlan ip and  dropped as true to verify dropped count
      verify_vlan_filtering(dan_X_1, dan_X_2, dan_X_2_ips[3], dan_X_1_pruicss_ports[0], dan_X_2_pruicss_ports[0], true)
      test_comment += " Verified VLAN filtering support."
    end
    # verify multicast filtering if mc_filter set to 1
    if mc_filter == 1 and mc_cli_ser_bins != ""
      setup_mc_cli_ser(dan_X_1, dan_X_2, mc_cli_ser_bins)
      is_mc_filter_enabled(dan_X_1, feature)
      is_mc_filter_enabled(dan_X_2, feature)
      # passing invalid vlan ip and dropped as true to verify dropped count
      verify_mc_filtering(dan_X_1, dan_X_2, dan_X_1_ips[0], dan_X_2_ips[3], feature, dan_X_1_pruicss_ports[0], true)
      verify_mc_filtering(dan_X_1, dan_X_2, dan_X_1_ips[0], dan_X_2_ips[0], feature, dan_X_1_pruicss_ports[0])
      test_comment += " Verified Multicast filtering support."
    end
    # disable vlan and feature
    if feature == "emac"
      disable_vlan_over_emac(dan_X_1, dan_X_1_pruicss_ports[0], 2, 3)
      disable_vlan_over_emac(dan_X_1, dan_X_1_pruicss_ports[1], 4, 5)
      disable_vlan_over_emac(dan_X_2, dan_X_2_pruicss_ports[0], 2, 3)
      disable_vlan_over_emac(dan_X_2, dan_X_2_pruicss_ports[1], 4, 5)
    else
      disable_vlan(dan_X_1, feature)
      disable_vlan(dan_X_2, feature)
      disable_feature(dan_X_1, feature, dan_X_1_pruicss_ports)
      disable_feature(dan_X_2, feature, dan_X_2_pruicss_ports)
    end

    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to enable vlan, this function enables vlan links over hsr/prp
# it creates prp/hsr0.2, prp/hsr0.3 and prp/hsr0.5 using id 2, 3, and 5 resp.
# these hard coded values are used for demo purpose, it can be replaced with
# other values too
def enable_vlan(dut, feature, dut_if02, dut_if03, dut_if05 = "", mc_filter = 0)
  dut.send_cmd("ifconfig #{feature}0 0.0.0.0", dut.prompt, 10)
  dut.send_cmd("ip link add link #{feature}0 name #{feature}0.2 type vlan id 2", dut.prompt, 10)
  dut.send_cmd("ip link add link #{feature}0 name #{feature}0.3 type vlan id 3", dut.prompt, 10)
  dut.send_cmd("ifconfig #{feature}0.2 #{dut_if02}", dut.prompt, 10)
  dut.send_cmd("ifconfig #{feature}0.3 #{dut_if03}", dut.prompt, 10)
  dut.send_cmd("ip link set #{feature}0.2 type vlan egress 0:0", dut.prompt, 10)
  dut.send_cmd("ip link set #{feature}0.3 type vlan egress 0:7", dut.prompt, 10)
  if mc_filter == 1
    # create extra link with id 0.5(id can be anything ex. 0.x) to verify dropped count
    dut.send_cmd("ip link add link #{feature}0 name #{feature}0.5 type vlan id 5", dut.prompt, 10)
    dut.send_cmd("ifconfig #{feature}0.5 #{dut_if05}", dut.prompt, 10)
  end
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

# function to disable vlan interfaces
def disable_vlan(dut, feature)
  dut.send_cmd("ip link delete #{feature}0.2", dut.prompt, 10)
  dut.send_cmd("ip link delete #{feature}0.3", dut.prompt, 10)
  dut.send_cmd("ip link delete #{feature}0.5", dut.prompt, 10)
  dut.send_cmd("lsmod", dut.prompt, 10)
  dut.send_cmd("rmmod 8021q", dut.prompt, 10)
  dut.send_cmd("ifconfig", dut.prompt, 10)
end

# function to check vlan filter enabled or not
def is_vlan_filter_enabled(dut, feature)
  dut.send_cmd("ls /sys/kernel/debug/", dut.prompt, 10)
  dut.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/vlan_filter ", dut.prompt, 10)
  if !( dut.response =~ /VLAN\sFilter\s:\senabled[\n\s\S]*0:\s+0011/ )
    raise "Failed to enable vlan filter."
  end
end

# function to check multicast filter enabled or not
def is_mc_filter_enabled(dut, feature)
  dut.send_cmd("ls /sys/kernel/debug/", dut.prompt, 10)
  dut.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/mc_filter", dut.prompt, 10)
  if !( dut.response =~ /MC\sFilter\s:\senabled/ )
    raise "Failed to enable multicast filter."
  end
end

# function to verify vlan filtering, this function pings to invalid vlan
# interface(0.5) and verifies vlan dropped count using ethtool utility.
def verify_vlan_filtering(dut, dut_sec, ipaddr, dan_X_1_pruicss_port, dan_X_2_pruicss_port, dropped = false)
  dut.send_cmd("ethtool -S #{dan_X_1_pruicss_port}", dut.prompt, 10)
  lrevlandropped = dut.response[/(lreVlanDropped:\s*\d*)/]
  dut_sec.send_cmd("ping -c 20 #{ipaddr}", dut_sec.prompt, 30)
  sleep(5)
  dut.send_cmd("ethtool -S #{dan_X_1_pruicss_port}", dut.prompt, 10)
  lrevlandropped_n = dut.response[/(lreVlanDropped:\s*\d*)/]
  dut_sec.send_cmd("cat /sys/kernel/debug/prueth-#{dan_X_2_pruicss_port}/stats", dut_sec.prompt, 10)
  if dropped == true and lrevlandropped == lrevlandropped_n
    raise "Failed to verify dropped count for vlan."
  end
end

# function to setup multicast client server
def setup_mc_cli_ser(dut_client, dut_server, bins_path)
  download_package("#{bins_path}/mc_client", '/tftpboot/mc_bins/')
  download_package("#{bins_path}/mc_server", '/tftpboot/mc_bins/')
  transfer_to_dut("mc_bins/mc_client", @equipment['server1'].telnet_ip, dut_client)
  transfer_to_dut("mc_bins/mc_server", @equipment['server1'].telnet_ip, dut_server)
  dut_client.send_cmd("chmod +x mc_client; ls -l", dut_client.prompt, 10)
  dut_server.send_cmd("chmod +x mc_server; ls -l", dut_server.prompt, 10)
end

# function to verify multicast filtering, this function runs multicast
# server for invalid vlan interface(0.5) and client application and verifies
# vlan dropped and multicast dropped count using ethtool utility.
def verify_mc_filtering(dut_client, dut_server, cli_ipaddr, ser_ipaddr, feature, pruicss_port, dropped = false)
  dut_client.send_cmd("ethtool -S #{pruicss_port}", dut_client.prompt, 10)
  # get mc and vlan dropped count to compare further
  lremcdropped = dut_client.response[/(lreMulticastDropped:\s*\d*)/]
  lrevlandropped = dut_client.response[/(lreVlanDropped:\s*\d*)/]
  dut_client.send_cmd("./mc_client 224.1.1.5 #{cli_ipaddr} > mc_client.log 2>&1 &", dut_client.prompt, 10) if not dropped
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_client.send_cmd("cat mc_client.log", dut_client.prompt, 10) if not dropped
  if dropped == false
    if !( dut_client.response =~ /Multicast\stest\smessage\slol!/ )
      raise "Failed to verify multicast filtering."
    end
  end
  # print pru stats
  dut_server.send_cmd("cat /sys/kernel/debug/prueth-#{pruicss_port}/stats", dut_server.prompt, 10)
  sleep(5)
  dut_client.send_cmd("ethtool -S #{pruicss_port}", dut_client.prompt, 10)
  # get updated mc and vlan dropped count
  lremcdropped_n = dut_client.response[/(lreMulticastDropped:\s*\d*)/]
  lrevlandropped_n = dut_client.response[/(lreVlanDropped:\s*\d*)/]
  if dropped == true and (lremcdropped == lremcdropped_n or lrevlandropped == lrevlandropped_n)
    raise "Failed to verify dropped count for multicast or vlan."
  end
end

# function to verify frames are vlan tagged, this function dumps ICMP frames using
# tcpdump utility and checks for 4 addition bytes available or not
def verify_vlan_tag(dut1, dut2, pruicss_port, ipaddr)
  dut2.send_cmd("ping -c 40 #{ipaddr} &", dut2.prompt, 10)
  dut1.send_cmd("tcpdump -i #{pruicss_port} -xx icmp > tcpdump.log 2>&1 & sleep 10 ; killall tcpdump", dut1.prompt, 30)
  dut1.send_cmd("cat tcpdump.log", dut1.prompt, 10)
  if !( dut1.response =~ /ICMP\secho\s(request|reply)[\s\S\n]*0x0060:\s+\w{4}\s\w{4}\s\w{4}/ ) or \
      ( dut1.response =~ /ICMP\secho\s(request|reply)[\s\S\n]*0x0060:\s+\w{4}\s\w{4}\s\w{4}\s\w{4}/ )
    raise "Failed to verify vlan tag, received frames are not VLAN tagged."
  end
end

# function to enable vlan over emac, this function enables vlan links over eth2/eth3
# it creates eth2.2, eth2.3, eth3.4 and eth3.5 using id 2, 3, 4 and 5 respectively
# these hard coded vlan id values are used for demo purpose, it can be replaced with
# other values too
def enable_vlan_over_emac(dut, pru_port, dut_ip1, dut_ip2, id1, id2)
  dut.send_cmd("ifconfig #{pru_port} 0.0.0.0", dut.prompt, 10)
  dut.send_cmd("ip link add link #{pru_port} name #{pru_port}.#{id1} type vlan id #{id1}", dut.prompt, 10)
  dut.send_cmd("ip link add link #{pru_port} name #{pru_port}.#{id2} type vlan id #{id2}", dut.prompt, 10)
  dut.send_cmd("ifconfig #{pru_port}.#{id1} #{dut_ip1}", dut.prompt, 10)
  dut.send_cmd("ifconfig #{pru_port}.#{id2} #{dut_ip2}", dut.prompt, 10)
  dut.send_cmd("ifconfig", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(#{pru_port}.[#{id1}-#{id2}]\s+Link\sencap:Ethernet\s+HWaddr)"))
    raise "Failed to enable VLAN over #{pru_port}."
  end
end

# function to disable vlan interfaces over emac
def disable_vlan_over_emac(dut, pru_port, id1, id2)
  dut.send_cmd("ip link delete #{pru_port}.#{id1}", dut.prompt, 10)
  dut.send_cmd("ip link delete #{pru_port}.#{id2}", dut.prompt, 10)
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
