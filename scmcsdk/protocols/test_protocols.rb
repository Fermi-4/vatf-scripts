# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'

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
  cmd_from = @test_params.params_chan.cmd_from[0]                 # command to enable feature link
  cmd_to = @test_params.params_chan.cmd_to[0]                     # command to enable feature link
  enable_switching = @test_params.params_chan.enable_switching[0] # set 'yes' to verify runtime configurability
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
      pruicss_ports = [dan_X_1.params["#{switch_to}_port1"], dan_X_1.params["#{switch_to}_port2"]]
      emac_status(dan_X_1, dan_X_2, pruicss_ports, dan_X_1_ips, dan_X_2_ips)
    else
      # get pruicss port information
      pruicss_ports = [dan_X_1.params["#{switch_from}_port1"], dan_X_1.params["#{switch_from}_port2"]]
      enable_feature(dan_X_1, switch_from, cmd_from, dan_X_1_ips[0], pruicss_ports)
      enable_feature(dan_X_2, switch_from, cmd_from, dan_X_2_ips[0], pruicss_ports)
      ping_status(dan_X_1, dan_X_2_ips[0], default_ping_count, payloads)
      # disable any one pruicss_port and verify redundancy
      verify_redundancy(dan_X_1, dan_X_2, pruicss_ports[0], dan_X_2_ips[0])
      # disable feature
      disable_feature(dan_X_1, switch_from, pruicss_ports)
      disable_feature(dan_X_2, switch_from, pruicss_ports)
    end
    test_comment = "Feature #{switch_from} verified over interface: #{pruicss_ports}."
    test_comment += " Ping successful at payloads: #{payloads}." if payloads.length > 1
    # switch to protocol and verify
    if enable_switching == "yes"
      if switch_to == "emac"
        emac_status(dan_X_1, dan_X_2, pruicss_ports, dan_X_1_ips, dan_X_2_ips)
      else
        pruicss_ports = [dan_X_1.params["#{switch_to}_port1"], dan_X_1.params["#{switch_to}_port2"]]
        # setting offload to true as switching of feature need to
        # be done by offloading feature using ethtool utility
        offload = true
        enable_feature(dan_X_1, switch_to, cmd_to, dan_X_1_ips[0], pruicss_ports, offload)
        enable_feature(dan_X_2, switch_to, cmd_to, dan_X_2_ips[0], pruicss_ports, offload)
        ping_status(dan_X_1, dan_X_2_ips[0])
        # disable any one pruicss_port and verify redundancy
        verify_redundancy(dan_X_1, dan_X_2, pruicss_ports[0], dan_X_2_ips[0])
        # disable feature
        disable_feature(dan_X_1, switch_to, pruicss_ports)
        disable_feature(dan_X_2, switch_to, pruicss_ports)
      end
      test_comment = "Runtime configurabilty from #{switch_from} to #{switch_to} verified."
    end
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to verify emac, this function enables
# interfaces in emac mode and verifies using ping
def emac_status(dan_X_1, dan_X_2, pruicss_ports, dan_X_1_ips, dan_X_2_ips)
  setup_pruicss_ports(dan_X_1, pruicss_ports, dan_X_1_ips)
  setup_pruicss_ports(dan_X_2, pruicss_ports, dan_X_2_ips)
  ping_status(dan_X_1, dan_X_2_ips[0])
  ping_status(dan_X_2, dan_X_1_ips[1])
end

# function to enable feature(hsr/prp), this function creates
# feature(hsr/prp). The optional paramater offload can be used to
# offload feature without setting at u-boot but at the time of
# linux kernel up by using ethtool utility
def enable_feature(dan_X_n, feature, command, ipaddr, pruicss_ports, offload = false)
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
  dan_X_n.send_cmd("ifconfig #{feature}0 #{ipaddr} up", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
  if !(dan_X_n.response =~ Regexp.new("(#{feature}0\s+Link\sencap:Ethernet\s+HWaddr)")) or dan_X_n.timeout?
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
  dan_X_n.send_cmd("ping -c #{count} #{ipaddr}", dan_X_n.prompt, count)
  if dan_X_n.timeout? or !(dan_X_n.response =~ Regexp.new("(\s0%\spacket\sloss)"))
    raise "Ping failed to IP Address: #{ipaddr}."
  end
  # verify ping at various payload sizes, if specified
  if payloads.length != 1
    for psize in payloads
      dan_X_n.send_cmd("ping #{ipaddr} -c #{count} -s #{psize}", dan_X_n.prompt, count)
      if dan_X_n.timeout? or !(dan_X_n.response =~ Regexp.new("(\s0%\spacket\sloss)"))
        raise "Ping failed to IP Address: #{ipaddr} at payload size: #{psize}."
      end
    end
  end
end

# function to disable any one pruicss_port for redundancy check
def verify_redundancy(dan_X_1, dan_X_2, pruicss_port, ipaddr)
  dan_X_1.send_cmd("ifconfig #{pruicss_port} down", dan_X_1.prompt, 10)
  dan_X_2.send_cmd("ifconfig #{pruicss_port} down", dan_X_2.prompt, 10)
  ping_status(dan_X_1, ipaddr)
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
