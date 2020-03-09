# This script is to test unicast, promisc mode, and allmulti mode on any ethernet interface

require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/../network_utils'

UNICAST = "unicast"
PROMISC = "promisc"
ALLMULTI = "allmulti"

FALSE_MAC_ADDR = "aa:bb:cc:dd:ee:ff"
MULTI_MAC_ADDR = "11:22:33:44:55:66"

def setup
  super
  @dut1 = @equipment['dut1']
  @linux_server = @equipment['server1']
  install_nping
end

def run
  # Test params from testlink
  driver    = @test_params.params_chan.instance_variable_defined?(:@driver) ? @test_params.params_chan.driver[0] : 'cpsw'
  test_mode = @test_params.params_chan.instance_variable_defined?(:@test_mode) ? @test_params.params_chan.test_mode[0] : 'promisc'

  # Get an active interface of type driver for test
  iface = get_interfaces_by_driver(@dut1, driver)[0]
  
  # Random port for test
  port = check_port_in_use(31982) 

  # Debug
  @dut1.send_cmd("ifconfig -a", @dut1.prompt)
  @dut1.send_cmd("ethtool -i #{iface}", @dut1.prompt)
  @dut1.send_cmd("switch-config -d", @dut1.prompt)

  # Get DUT ip and mac
  dut_ip = get_ip_address_by_interface('dut1', iface)
  dut_mac = get_mac_addr('dut1', iface)

  # Get server ip 
  server_ip = get_remote_ip(iface, 'dut1', 'server1')

  # Dictionary for test params
  eth_params = {
    'iface' => iface,
    'port' => port,  
    'dut_ip' => dut_ip,
    'dut_mac' => dut_mac,
    'server_ip' => server_ip
  }

  # Run tests based on test mode: unicast | promisc | allmulti
  case test_mode
    when UNICAST
      result, msg = run_unicast_test(eth_params)
    when PROMISC
      result, msg = run_promisc_test(eth_params)
    when ALLMULTI
      result, msg = run_allmulti_test(eth_params)
    else
      raise "Unsupported test mode!"
  end
     
  # If result is true, pass testcase, else report failure messages 
  if (result)
    set_result(FrameworkConstants::Result[:pass], "All tests passed")
  else
    set_result(FrameworkConstants::Result[:fail], "#{msg}")
  end
end

# Function to carry out unicast test:
# Case 1: Send unicast packets to a false MAC address (not that of the DUT), verify no packets seen
# Case 2: Send unicast packets to DUT MAC address, verify packets seen
def run_unicast_test(eth_params)
  result = true
  msg = ""

  # Case 1
  report_msg("====Case 1: Send unicast packets to a false MAC address (not that of the DUT), verify no packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, FALSE_MAC_ADDR)
  if (packet_count > 0)
    result = false
    msg += "Unicast Case 1 Failed: Should not see packets when sent with the wrong dut mac\n"
  end

  # Case 2
  report_msg("====Case 2: Send unicast packets to DUT MAC address, verify packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, eth_params['dut_mac'])
  if (packet_count == 0)
    result = false
    msg += "Unicast Case 2 Failed: Should see packets when sent with the right dut mac\n"
  end

  return result, msg
end

# Function to carry out promiscuous test:
# Case 1: Promisc disabled, send unicast packets to a false MAC address (not that of the DUT), verify no packets seen
# Case 2: Promisc disabled, send unicast packets to DUT MAC address, verify packets seen
# Case 3: Promisc disabled, send multicast packets to unregistered multicast MAC address, verify no packets seen
# Case 4: Promisc enabled, send unicast packets to a false MAC address (not that of the DUT), verify packets seen
# Case 5: Promisc enabled, send unicast packets to DUT MAC address, verify packets seen
# Case 6: Promisc enabled, send multicast packets to unregistered multicast MAC address, verify packets seen
def run_promisc_test(eth_params)
  result = true
  msg = ""

  # Case 1
  report_msg("====Case 1: Promisc disabled, send unicast packets to a false MAC address (not that of the DUT), verify no packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, FALSE_MAC_ADDR)
  if (packet_count > 0)
    result = false
    msg += "Promisc Case 1 Failed: Should not see packets when promisc disabled and sent with the wrong dut mac\n"
  end

  # Case 2
  report_msg("====Case 2: Promisc disabled, send unicast packets to DUT MAC address, verify packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, eth_params['dut_mac'])
  if (packet_count == 0)
    result = false
    msg += "Promisc Case 2 Failed: Should see packets when promisc disabled and sent with the right dut mac\n"
  end
  
  # Case 3
  report_msg("====Case 3: Promisc disabled, send multicast packets to unregistered multicast MAC address, verify no packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, MULTI_MAC_ADDR)
  if (packet_count > 0)
    result = false
    msg += "Promisc Case 3 Failed: Should not see packets when promisc disabled and sent with unregistered multicast mac\n"
  end
  
  # Case 4
  report_msg("====Case 4: Promisc enabled, send unicast packets to a false MAC address (not that of the DUT), verify packets seen")
  set_scenario(eth_params['iface'], true, false)
  packet_count = capture_packets(eth_params, FALSE_MAC_ADDR)
  if (packet_count == 0)
    result = false
    msg += "Promisc Case 4 Failed: Should see packets when promisc is enabled and wrong dut mac\n"
  end
  
  # Case 5
  report_msg("====Case 5: Promisc enabled, send unicast packets to DUT MAC address, verify packets seen")
  set_scenario(eth_params['iface'], true, false)
  packet_count = capture_packets(eth_params, eth_params['dut_mac'])
  if (packet_count == 0)
    result = false
    msg += "Promisc Case 5 Failed: Should see packets when promisc enabled and sent with the right dut mac\n"
  end
  
  # Case 6
  report_msg("====Case 6: Promisc enabled, send multicast packets to unregistered multicast MAC address, verify packets seen")
  set_scenario(eth_params['iface'], true, false)
  packet_count = capture_packets(eth_params, MULTI_MAC_ADDR)
  if (packet_count == 0)
    result = false
    msg += "Promisc Case 6 Failed: Should see packets when promisc enabled and sent with unregistered multicast mac\n"
  end

  return result, msg
end

# Function to carry out allmulti test:
# Case 1: Promisc disabled, allmulti disabled, send multicast packets to unregistered multicast MAC address, verify no packets seen
# Case 2: Promisc disabled, allmulti enabled, send multicast packets to unregistered multicast MAC address, verify packets seen
def run_allmulti_test(eth_params)
  result = true
  msg = ""

  # Case 1
  report_msg("====Case 1: Promisc disabled, allmulti disabled, send multicast packets to unregistered multicast MAC address, verify no packets seen")
  set_scenario(eth_params['iface'], false, false)
  packet_count = capture_packets(eth_params, MULTI_MAC_ADDR)
  if (packet_count > 0)
    result = false
    msg += "Allmulti Case 1 Failed: Should not see packets when allmulti and promisc are disabled and multicast packets were sent\n"
  end

  # Case 2
  report_msg("====Case 2: Promisc disabled, allmulti enabled, send multicast packets to unregistered multicast MAC address, verify packets seen")
  set_scenario(eth_params['iface'], false, true)
  packet_count = capture_packets(eth_params, MULTI_MAC_ADDR)
  if (packet_count == 0)
    result = false
    msg += "Allmulti Case 2 Failed: Should see packets when allmulti enabled and promisc disabled and multicast packets were sent\n"
  end

  return result, msg
end

# Function to run tcpdump and capture packets from linux server 
def capture_packets(eth_params, test_mac) 
  start_cmd_on_target("tcpdump -n -p -vv -xx -i #{eth_params['iface']} tcp port #{eth_params['port']} and dst #{eth_params['dut_ip']}", /listening\s+on\s+#{eth_params['iface']}/i, /DUMMY_WAIT/) do
    @linux_server.send_sudo_cmd("nping --dest-mac #{test_mac} --source-ip #{eth_params['server_ip']} --dest-ip #{eth_params['dut_ip']} --tcp -p #{eth_params['port']}", @linux_server.prompt, 60)
  end

  # Send ctrl+c to back to prompt
  @dut1.send_cmd("\x3", @dut1.prompt, 10)
  num_packets = @dut1.response.scan(/^(\d+)\s+packet[s]{0,1}\s+captured/)[0][0].to_i
  return num_packets
end

def start_cmd_on_target(cmd, exp1, exp2)
  Thread.abort_on_exception = true
  thr = Thread.new {
    @dut1.send_cmd(cmd, exp1, 20)
    raise "Could not start cmd: #{cmd}! " if @dut1.timeout?
    @dut1.wait_for(exp2, 120)
    @dut1.response
  }
  yield
  rtn = thr.value
end

# Function sets up DUT for a certain scenario
def set_scenario(iface, promisc, allmulti)
  set_promisc(iface, promisc)
  set_allmulti(iface, allmulti)
  @dut1.send_cmd("ip a show #{iface}", @dut1.prompt)
  raise "Promisc mode could not be enabled." if promisc && !@dut1.response.match(/PROMISC/)
  raise "Allmulti mode could not be enabled." if allmulti && !@dut1.response.match(/ALLMULTI/)
end

# Enables or disables promisc on iface
def set_promisc(iface, flag)
  promisc = flag ? "promisc" : "-promisc"
  @dut1.send_cmd("ifconfig #{iface} #{promisc}", @dut1.prompt) 
end

# Enables or disables allmulti on iface
def set_allmulti(iface, flag)
  allmulti = flag ? "allmulti" : "-allmulti"
  @dut1.send_cmd("ifconfig #{iface} #{allmulti}", @dut1.prompt) 
end

# Checks if port is already in use, tries 5 ports before giving up
def check_port_in_use(port)
  (1..5).each do
    # If port is in use, add 7 to port and try again
    @dut1.send_cmd("netstat -atun | grep #{port}", @dut1.prompt)
    if (@dut1.response.match(/"#{port}"/))
      port += 7
    else 
      return port
    end 
  end
  raise "Could not find an open port for test!"
end


# Install nping if it is not in host
def install_nping()
  @linux_server.send_cmd("which nping;echo $?", /^0[\0\n\r]+/m, 5)
  @linux_server.send_sudo_cmd("apt-get update", @linux_server.prompt, 120) if @linux_server.timeout?
  @linux_server.send_sudo_cmd("apt-get -y install nmap", @linux_server.prompt, 600) if @linux_server.timeout?
  @linux_server.send_cmd("which nping;echo $?", /^0[\0\n\r]+/m, 5)
  raise "Could not install nping!" if @linux_server.timeout?
end