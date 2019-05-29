# This script is to test promisc mode and allmulti mode on any ethernet interface

require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/../network_utils'

def setup
  super
  install_nping
end

def run
  result = 0
  msg = '' 
  eth_params = {}
  @equipment['dut1'].send_cmd("ifconfig -a", @equipment['dut1'].prompt, 10, false)

  test_mode = @test_params.params_control.instance_variable_defined?(:@test_mode) ? @test_params.params_control.test_mode[0].to_s : 'promisc'
  eth_params['iface'] = @test_params.params_control.instance_variable_defined?(:@iface) ? @test_params.params_control.iface[0].to_s : 'eth0'
  @equipment['dut1'].send_cmd("ethtool -i #{eth_params['iface']}", @equipment['dut1'].prompt, 10, false)
  eth_params['dut_ip'] = get_ip_address_by_interface('dut1',eth_params['iface'])
  eth_params['dut_mac'] = get_mac_addr('dut1', eth_params['iface'])

  # get host pc ip and mac
  eth_params['server_iface'] = get_local_iface_name(@equipment['server1'],get_ip_address_by_interface('dut1',eth_params['iface']))
  eth_params['server_ip']= get_ip_address_by_interface('server1', eth_params['server_iface'])
  eth_params['server_mac'] = get_mac_addr('server1', eth_params['server_iface'])

  case test_mode
  when 'promisc'

    # When promisc mode is not enabled
    report_msg "====Case 1.1: promisc is not enabled (default behavior); dest-mac is the wrong one (not dut mac). => Should not see packets in this case "
    this_flags = {'promisc'=>false, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>false, 'set_wrong_mac'=>true}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i > 0
      result += 1
      msg += "Should not see packets when promisc is disabled with wrong dut mac"
    end

    report_msg "====Case 1.2: promisc is not enabled (default behavior); dest-mac is the right one. => Should see packets in this case"
    this_flags = {'promisc'=>false, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>false, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is disabled with the right dut mac"
    end

    report_msg "====Case 1.3: promisc is not enabled (default behavior); send broadcast packets. => Should see packets in this case "
    this_flags = {'promisc'=>false, 'allmulti'=>false, 'broadcast'=>true, 'multicast'=>false, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is disabled and broadcast packets was sent"
    end

    report_msg "====Case 1.4: promisc is not enabled (default behavior); send multicast packets. => Should not see packets in this case "
    this_flags = {'promisc'=>false, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>true, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i > 0
      result += 1
      msg += "Should not see packets when promisc is disabled and multicast packets was sent"
    end

    # Now enable promisc

    report_msg "====Case 2.1: promisc is enabled ; dest-mac is the wrong one (not dut mac). => Should see packets in this case "
    this_flags = {'promisc'=>true, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>false, 'set_wrong_mac'=>true}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is enabled and wrong dut mac"
    end

    report_msg "====Case 2.2: promisc enabled ; dest-mac is the right one. => Should see packets in this case "
    this_flags = {'promisc'=>true, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>false, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is enabled with the right dut mac"
    end

    report_msg "====Case 2.3: promisc enabled ; send broadcast packets. => Should see packets in this case "
    this_flags = {'promisc'=>true, 'allmulti'=>false, 'broadcast'=>true, 'multicast'=>false, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is enabled and broadcast packets was sent"
    end

    report_msg "====Case 2.4: promisc is enabled ; send multicast packets. => Should see packets in this case "
    this_flags = {'promisc'=>true, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>true, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when promisc is enabled and multicast packets was sent"
    end

  when 'allmulti'
    report_msg "====Case 3.1: allmulti disabled; promisc is disabled ; send multicast packets. => Should not see packets in this case "
    this_flags = {'promisc'=>false, 'allmulti'=>false, 'broadcast'=>false, 'multicast'=>true, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i > 0
      result += 1
      msg += "Should not see packets when allmulti and promisc are disabled and multicast packets was sent"
    end

    report_msg "====Case 3.2: allmulti enabled; promisc is disabled ; send multicast packets. => Should see packets in this case "
    this_flags = {'promisc'=>false, 'allmulti'=>true, 'broadcast'=>false, 'multicast'=>true, 'set_wrong_mac'=>false}
    pacnum = capture_packets(eth_params, this_flags)
    if pacnum.to_i == 0
      result += 1
      msg += "Should see packets when allmulti enabled, promisc disabled and multicast packets was sent"
    end
  else
    raise "Unsupported test mode!"
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test failed since #{msg} ")
  end

end

def capture_packets(eth_params, flags={}) 
  promisc = flags['promisc'] == true ? " promisc" : "-promisc"
  allmulti = flags['allmulti'] == true ? " allmulti" : "-allmulti"
  if flags['broadcast']
    this_dut_mac = 'FF:FF:FF:FF:FF:FF'  
  elsif flags['multicast']
    this_dut_mac = '11:22:33:44:55:66'  
  else
    this_dut_mac = flags['set_wrong_mac'] == true ? " aa:bb:cc:dd:ee:ff" : "#{eth_params['dut_mac']}"
  end
  @equipment['dut1'].send_cmd("ifconfig #{eth_params['iface']} #{promisc}", @equipment['dut1'].prompt, 10, false)
  @equipment['dut1'].send_cmd("ifconfig #{eth_params['iface']} #{allmulti}", @equipment['dut1'].prompt, 10, false)
  @equipment['dut1'].send_cmd("ip a show #{eth_params['iface']}", @equipment['dut1'].prompt, 10, false)
  raise "Promisc mode could not be enabled." if flags['promisc'] == true && !@equipment['dut1'].response.match(/PROMISC/)
  raise "Allmulti mode could not be enabled." if flags['allmulti'] == true && !@equipment['dut1'].response.match(/ALLMULTI/)
  start_cmd_on_target("tcpdump -n -p -vv -i #{eth_params['iface']} tcp and dst #{eth_params['dut_ip']} ", /listening\s+on\s+#{eth_params['iface']}/i, /DUMMY_WAIT/) do
    @equipment['server1'].send_sudo_cmd("nping --dest-mac #{this_dut_mac} --source-ip #{eth_params['server_ip']} --dest-ip #{eth_params['dut_ip']} --tcp", @equipment['server1'].prompt, 60)

  end

  # send ctrl+c to back to prompt
  @equipment['dut1'].send_cmd("\x3", @equipment['dut1'].prompt, 10)
  num_packets = @equipment['dut1'].response.match(/^(\d+)\s+packet[s]{0,1}\s+received/).captures[0]
  return num_packets
end

def start_cmd_on_target(cmd, exp1, exp2)
  Thread.abort_on_exception = true
  thr = Thread.new {
    @equipment['dut1'].send_cmd(cmd, exp1, 20)
    raise "Could not start cmd: #{cmd}! " if @equipment['dut1'].timeout?
    @equipment['dut1'].wait_for(exp2, 120)
    @equipment['dut1'].response
  }
  yield
  rtn = thr.value
end


# install nping if it is not in host
def install_nping()
  @equipment['server1'].send_cmd("which nping;echo $?", /^0[\0\n\r]+/m, 5)
  @equipment['server1'].send_sudo_cmd("apt-get -y install nmap", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which nping;echo $?", /^0[\0\n\r]+/m, 5)
  raise "Could not install nping!" if @equipment['server1'].timeout?
end


