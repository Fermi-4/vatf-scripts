# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'
require File.dirname(__FILE__)+'/test_vlan'

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
  switch_from = @test_params.params_chan.switch_from[0]           # feature to load initially
  switch_to = @test_params.params_chan.switch_to[0]               # feature to switch to

  enable_switching = @test_params.params_chan.enable_switching[0] # set 'yes' to verify runtime configurability
  mc_filter = @test_params.params_chan.instance_variable_defined?(:@mc_filter) ? @test_params.params_chan.mc_filter[0].to_i : 0
  mc_cli_ser_bins = @test_params.params_chan.instance_variable_defined?(:@mc_cli_ser_bins) ? @test_params.params_chan.mc_cli_ser_bins[0] : ""
  # specify payloads in case of ping required at various payload sizes
  payloads = @test_params.params_chan.instance_variable_defined?(:@payloads) ? @test_params.params_chan.payloads : [""]

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']

  # set defaults
  default_ping_count = 10
  pruicss_ports = ["eth2", "eth3"]

  # get ip addresses for DAN-X-1 and DAN-X-2
  dan_X_1_ips = [dan_X_1.params['dut1_if'], dan_X_1.params['dut1_if2']]
  dan_X_2_ips = [dan_X_2.params['dut2_if'], dan_X_2.params['dut2_if2']]

  test_comment = ""
  begin
    if switch_from == "emac"
      # get pruicss port information
      dan_X_1_pruicss_ports = [dan_X_1.params["#{switch_to}_port1"], dan_X_1.params["#{switch_to}_port2"]]
      dan_X_2_pruicss_ports = [dan_X_2.params["#{switch_from}_port1"], dan_X_2.params["#{switch_from}_port2"]]
      emac_status(dan_X_1, dan_X_2, dan_X_1_pruicss_ports, dan_X_2_pruicss_ports, dan_X_1_ips, dan_X_2_ips)
    else
      # get pruicss port information
      dan_X_1_pruicss_ports = [dan_X_1.params["#{switch_from}_port1"], dan_X_1.params["#{switch_from}_port2"]]
      cmd = get_cmd(switch_from, dan_X_1_pruicss_ports)
      enable_feature(dan_X_1, switch_from, cmd, dan_X_1_ips[0], dan_X_1_pruicss_ports)
      dan_X_2_pruicss_ports = [dan_X_2.params["#{switch_from}_port1"], dan_X_2.params["#{switch_from}_port2"]]
      cmd = get_cmd(switch_from, dan_X_2_pruicss_ports)
      enable_feature(dan_X_2, switch_from, cmd, dan_X_2_ips[0], dan_X_2_pruicss_ports)
      ping_status(dan_X_1, dan_X_2_ips[0], default_ping_count, payloads)
      # verify multicast filtering
      if mc_filter == 1 and mc_cli_ser_bins != ""
        setup_mc_cli_ser(dan_X_1, dan_X_2, mc_cli_ser_bins)
        is_mc_filter_enabled(dan_X_1, switch_from)
        is_mc_filter_enabled(dan_X_2, switch_from)
        verify_mcast_filtering(dan_X_1, dan_X_2, dan_X_1_ips[0], dan_X_2_ips[0], switch_from, dan_X_1_pruicss_ports[0])
      end
      # disable any one pruicss_port and verify redundancy
      verify_redundancy(dan_X_1, dan_X_2, dan_X_1_pruicss_ports[1], dan_X_2_ips[0])
      # disable feature
      disable_feature(dan_X_1, switch_from, dan_X_1_pruicss_ports)
      disable_feature(dan_X_2, switch_from, dan_X_2_pruicss_ports)
    end
    test_comment = "Feature #{switch_from} verified over interface: #{dan_X_1_pruicss_ports}/#{dan_X_2_pruicss_ports}."
    test_comment += " Ping successful at payloads: #{payloads}." if payloads.length > 1
    test_comment += " Verified Multicast filtering support." if mc_filter == 1
    # switch to protocol and verify
    if enable_switching == "yes"
      if switch_to == "emac"
        emac_status(dan_X_1, dan_X_2, dan_X_1_pruicss_ports, dan_X_2_pruicss_ports, dan_X_1_ips, dan_X_2_ips)
      else
        dan_X_1_pruicss_ports = [dan_X_1.params["#{switch_to}_port1"], dan_X_1.params["#{switch_to}_port2"]]
        dan_X_2_pruicss_ports = [dan_X_2.params["#{switch_to}_port1"], dan_X_2.params["#{switch_to}_port2"]]
        disable_feature(dan_X_1, switch_from, pruicss_ports)
        disable_feature(dan_X_2, switch_from, pruicss_ports)
        # setting offload to true as switching of feature need to
        # be done by offloading feature using ethtool utility
        offload = true
        cmd = get_cmd(switch_to, dan_X_1_pruicss_ports)
        enable_feature(dan_X_1, switch_to, cmd, dan_X_1_ips[0], dan_X_1_pruicss_ports, offload)
        cmd = get_cmd(switch_to, dan_X_2_pruicss_ports)
        enable_feature(dan_X_2, switch_to, cmd, dan_X_2_ips[0], dan_X_2_pruicss_ports, offload)
        ping_status(dan_X_1, dan_X_2_ips[0])
        # disable any one pruicss_port and verify redundancy
        verify_redundancy(dan_X_1, dan_X_2, dan_X_1_pruicss_ports[1], dan_X_2_ips[0])
        # disable feature
        disable_feature(dan_X_1, switch_to, dan_X_1_pruicss_ports)
        disable_feature(dan_X_2, switch_to, dan_X_2_pruicss_ports)
      end
      test_comment = "Runtime configurabilty from #{switch_from} to #{switch_to} verified."
    end
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to generate and return ip link command
def get_cmd(feature, pruicss_ports, id = "0")
  cmd = "ip link add name #{feature}#{id} type #{feature} slave1 #{pruicss_ports[0]} slave2 #{pruicss_ports[1]} supervision 45"
  cmd += " version 1" if feature == "hsr"
  return cmd
end

# function to verify emac, this function enables
# interfaces in emac mode and verifies using ping
def emac_status(dan_X_1, dan_X_2, dan_X_1_pruicss_ports, dan_X_2_pruicss_ports, dan_X_1_ips, dan_X_2_ips)
  setup_pruicss_ports(dan_X_1, dan_X_1_pruicss_ports, dan_X_1_ips)
  setup_pruicss_ports(dan_X_2, dan_X_2_pruicss_ports, dan_X_2_ips)
  sleep(10) # give time to initialize ports
  ping_status(dan_X_1, dan_X_2_ips[0])
end

# function to enable feature(hsr/prp), this function creates
# feature(hsr/prp). The optional paramater offload can be used to
# offload feature without setting at u-boot but at the time of
# linux kernel up by using ethtool utility
def enable_feature(dan_X_n, feature, command, ipaddr, pruicss_ports, offload = false, id = 0)
  dan_X_n.send_cmd("export #{pruicss_ports[1]}_ipaddr=`cat /sys/class/net/#{pruicss_ports[1]}/address`", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[0]} 0.0.0.0 down", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} 0.0.0.0 down", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} hw ether `cat /sys/class/net/#{pruicss_ports[0]}/address`", dan_X_n.prompt, 10)
  # check if offload is true, if yes offload feature using ethtool
  if offload == true
    dan_X_n.send_cmd("ethtool -K #{pruicss_ports[0]} #{feature}-rx-offload on", dan_X_n.prompt, 10)
    dan_X_n.send_cmd("ethtool -K #{pruicss_ports[1]} #{feature}-rx-offload on", dan_X_n.prompt, 10)
  end
  sleep(10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[0]} up", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} up", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("#{command}", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{feature}#{id} #{ipaddr} up", dan_X_n.prompt, 10)
  sleep(10) # give time to initialize link
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
  if !(dan_X_n.response =~ Regexp.new("(#{feature}#{id}\s+Link\sencap:Ethernet\s+HWaddr)")) or dan_X_n.timeout?
    raise "Failed to enable #{feature}."
  end
end

# function to disable feature, this function deletes all
# created links and restores mac address of interface
def disable_feature(dan_X_n, feature, pruicss_ports)
  dan_X_n.send_cmd("ip link delete #{feature}0", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[0]} 0.0.0.0 down", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} 0.0.0.0 down", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ethtool -K #{pruicss_ports[0]} #{feature}-rx-offload off", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ethtool -K #{pruicss_ports[1]} #{feature}-rx-offload off", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} hw ether $#{pruicss_ports[1]}_ipaddr", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
  if (dan_X_n.response =~ Regexp.new("(#{feature}0\s+Link\sencap:Ethernet\s+HWaddr)")) or dan_X_n.timeout?
    raise "Failed to disable #{feature}."
  end
end

# function to setup pruicss_ports
def setup_pruicss_ports(dan_X_n, pruicss_ports, dan_X_n_ips)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[0]} #{dan_X_n_ips[0]}", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig #{pruicss_ports[1]} #{dan_X_n_ips[1]}", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
end

# function to verify ping, this function pings and verifies 0% loss
# it also has capability to ping at various payload sizes if specified
def ping_status(dan_X_n, ipaddr, count=10, payloads=[""])
  dan_X_n.send_cmd("ping -c #{count} #{ipaddr}", dan_X_n.prompt, count+10)
  if dan_X_n.timeout? or !(dan_X_n.response =~ Regexp.new("(\s0%\spacket\sloss)"))
    raise "Ping failed to IP Address: #{ipaddr}."
  end
  # verify ping at various payload sizes, if specified
  if payloads.length != 1
    for psize in payloads
      dan_X_n.send_cmd("ping #{ipaddr} -c #{count} -s #{psize}", dan_X_n.prompt, count+10)
      if dan_X_n.timeout? or !(dan_X_n.response =~ Regexp.new("(\s0%\spacket\sloss)"))
        raise "Ping failed to IP Address: #{ipaddr} at payload size: #{psize}."
      end
    end
  end
end

# function to disable any one pruicss_port for redundancy check
def verify_redundancy(dan_X_1, dan_X_2, pruicss_port, ipaddr)
  dan_X_1.send_cmd("ifconfig #{pruicss_port} down", dan_X_1.prompt, 10)
  ping_status(dan_X_1, ipaddr)
end

# function to verify multicast filtering, this function runs multicast
# server for invalid multicast address and client application and verifies
# multicast dropped count using ethtool utility.
def verify_mcast_filtering(dut_client, dut_server, cli_ipaddr, ser_ipaddr, feature, pruicss_port)
  dut_client.send_cmd("ethtool -S #{pruicss_port}", dut_client.prompt, 10)
  # get mcast dropped count to compare further
  lremcdropped = dut_client.response[/(lreMulticastDropped:\s*\d*)/]
  dut_client.send_cmd("./mc_client 224.1.1.4 #{cli_ipaddr} > mc_client.log 2>&1 &", dut_client.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.4 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_client.send_cmd("cat mc_client.log", dut_client.prompt, 10)
  if !( dut_client.response =~ /Multicast\stest\smessage\slol!/ )
    raise "Failed to verify multicast filtering."
  end
  dut_client.send_cmd("./mc_client 224.1.1.4 #{cli_ipaddr} > mc_client.log 2>&1 &", dut_client.prompt, 10)
  # run mc server with invalid arguments to verify dropped mc packet
  dut_server.send_cmd("./mc_server 224.10.1.4 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.10.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.5 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_server.send_cmd("./mc_server 224.1.1.4 #{ser_ipaddr}", dut_server.prompt, 10)
  dut_client.send_cmd("cat mc_client.log", dut_client.prompt, 10)
  if !( dut_client.response =~ /Multicast\stest\smessage\slol!/ )
    raise "Failed to verify multicast filtering."
  end
  # print pru stats
  dut_server.send_cmd("cat /sys/kernel/debug/prueth-#{pruicss_port}/stats", dut_server.prompt, 10)
  sleep(5)
  dut_client.send_cmd("ethtool -S #{pruicss_port}", dut_client.prompt, 10)
  # get updated mc dropped count
  lremcdropped_n = dut_client.response[/(lreMulticastDropped:\s*\d*)/]
  if (lremcdropped == lremcdropped_n)
    raise "Failed to verify dropped count for multicast filtering."
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
