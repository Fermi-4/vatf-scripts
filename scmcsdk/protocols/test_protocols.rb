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
  switch_from = @test_params.params_chan.switch_from[0]
  switch_to = @test_params.params_chan.switch_to[0]
  cmd_from = @test_params.params_chan.cmd_from[0]
  cmd_to = @test_params.params_chan.cmd_to[0]
  enable_switching = @test_params.params_chan.enable_switching[0]
  # ip addresses for dut1 and dut2
  dut1_eth2, dut1_eth3 = "192.168.2.10", "192.168.3.10"
  dut2_eth2, dut2_eth3 = "192.168.2.20", "192.168.3.20"
  test_comment = ""
  begin
    if switch_from == "emac"
      emac_status(dut1_eth2, dut1_eth3, dut2_eth2, dut2_eth3)
    else
      enable_feature(@equipment['dut1'], switch_from, cmd_from, dut1_eth2)
      enable_feature(@equipment['dut2'], switch_from, cmd_from, dut2_eth2)
      ping_status(@equipment['dut1'], dut2_eth2)
      ping_status(@equipment['dut2'], dut1_eth2)
      disable_feature(@equipment['dut1'], switch_from)
      disable_feature(@equipment['dut2'], switch_from)
    end
    test_comment = "Feature #{switch_from} verified."
    # switch to protocol and verify
    if enable_switching == "yes"
      if switch_to == "emac"
        emac_status(dut1_eth2, dut1_eth3, dut2_eth2, dut2_eth3)
      else
        enable_feature(@equipment['dut1'], switch_to, cmd_to, dut1_eth2)
        enable_feature(@equipment['dut2'], switch_to, cmd_to, dut2_eth2)
        ping_status(@equipment['dut1'], dut2_eth2)
        ping_status(@equipment['dut2'], dut1_eth2)
        # disable eth2 to verify redundancy
        disable_eth2(@equipment['dut1'], @equipment['dut2'])
        ping_status(@equipment['dut1'], dut2_eth2)
        ping_status(@equipment['dut2'], dut1_eth2)
      end
      test_comment = "Runtime configurabilty from #{switch_from} to #{switch_to} verified."
    end
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to verify emac
def emac_status(dut1_eth2, dut1_eth3, dut2_eth2, dut2_eth3)
  setup_eth2_eth3(@equipment['dut1'], dut1_eth2, dut1_eth3)
  setup_eth2_eth3(@equipment['dut2'], dut2_eth2, dut2_eth3)
  ping_status(@equipment['dut1'], dut2_eth2)
  ping_status(@equipment['dut1'], dut2_eth3)
  ping_status(@equipment['dut2'], dut1_eth2)
  ping_status(@equipment['dut2'], dut1_eth3)
end

# function to enable feature(hsr/prp)
def enable_feature(dut, feature, command, ipaddr)
  dut.send_cmd("export eth3_ipaddr=`cat /sys/class/net/eth3/address`", dut.prompt, 10)
  dut.send_cmd("ifconfig eth2 0.0.0.0 down", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 0.0.0.0 down", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 hw ether `cat /sys/class/net/eth2/address`", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth2 #{feature}-rx-offload on", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth3 #{feature}-rx-offload on", dut.prompt, 10)
  sleep(10)
  dut.send_cmd("ifconfig eth2 up", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 up", dut.prompt, 10)
  dut.send_cmd("#{command}", dut.prompt, 10)
  dut.send_cmd("ifconfig #{feature}0 #{ipaddr} up", dut.prompt, 10)
  dut.send_cmd("ifconfig", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(#{feature}0\s+Link\sencap:Ethernet\s+HWaddr)")) or dut.timeout?
    raise "Failed to enable #{feature}."
  end
end

# function to disable feature
def disable_feature(dut, feature)
  dut.send_cmd("ip link delete #{feature}0", dut.prompt, 10)
  dut.send_cmd("ifconfig eth2 0.0.0.0 down", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 0.0.0.0 down", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth2 #{feature}-rx-offload off", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth3 #{feature}-rx-offload off", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 hw ether $eth3_ipaddr", dut.prompt, 10)
  dut.send_cmd("ifconfig", dut.prompt, 10)
  if (dut.response =~ Regexp.new("(#{feature}0\s+Link\sencap:Ethernet\s+HWaddr)")) or dut.timeout?
    raise "Failed to disable #{feature}."
  end
end

# function to up eth2 and eth3
def setup_eth2_eth3(dut, eth2_ip, eth3_ip)
  dut.send_cmd("ifconfig eth2 #{eth2_ip}", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 #{eth3_ip}", dut.prompt, 10)
  dut.send_cmd("ifconfig", @equipment['dut1'].prompt, 10)
end

# function to verify ping
def ping_status(dut, ipaddr, count=10)
  dut.send_cmd("ping -c #{count} #{ipaddr}", dut.prompt, count)
  if dut.timeout? or !(dut.response =~ Regexp.new("(\s0%\spacket\sloss)"))
    raise "Ping failed to IP Address: #{ipaddr}."
  end
end

# function to disable eth2 for redundancy check
def disable_eth2(dut1, dut2)
  dut1.send_cmd("ifconfig eth2 down", dut1.prompt, 10)
  dut2.send_cmd("ifconfig eth2 down", dut2.prompt, 10)
end

def clean
  #super
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
