# This test aims to bring up the CPSW9G interface with modprobe then
# find the new CPSW9G interface and get the ip address of the server 
# it is connected to 

require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/../network_utils'

def setup
  super
  # Get the cpsw9g iface name and export
  cpsw9g_iface = get_cpsw9g_iface_name()
  @equipment['dut1'].send_cmd("export cpsw9g_iface=#{cpsw9g_iface}",@equipment['dut1'].prompt, 1)

  # Debug
  @equipment['dut1'].send_cmd("ifconfig -a",@equipment['dut1'].prompt, 1)
  @equipment['dut1'].send_cmd("lsmod",@equipment['dut1'].prompt, 1)

  # Find server ip that cpsw9g is connected to and export
  host_env_name = cpsw9g_iface+"_SERVER"
  ip_addr =  get_ip_address_by_interface('dut1', cpsw9g_iface)
  server_iface = get_local_iface_name(@equipment['server1'], ip_addr)
  server_ip_address = get_ip_address_by_interface('server1', server_iface)
  @equipment['dut1'].send_cmd("export #{host_env_name}=#{server_ip_address}",@equipment['dut1'].prompt, 1)
end

def get_cpsw9g_iface_name(device='dut1') 
  pre_up = get_eth_interfaces(device)
  
  @equipment[device].send_cmd("modprobe rpmsg_kdrv_switch && sleep 3", @equipment[device].prompt, 10, false)  
  
  post_up = get_eth_interfaces(device)

  diff = pre_up + post_up - (pre_up & post_up)

  raise "Could not bring up CPSW9G iface" if diff.length == 0

  return diff[0]
end
