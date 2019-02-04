# This script is intended to be generic enough to run tests on any ethernet
# interface. Its main function is to set the host network interface corresponding to the interface on the dut.

require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/../network_utils'

def setup
  super
  iface = @test_params.params_control.instance_variable_defined?(:@iface) ? @test_params.params_control.iface[0].to_s : 'eth0'
  host_env_name = iface+"_SERVER"
  server_iface = get_local_iface_name(@equipment['server1'],get_ip_address_by_interface('dut1',iface))
  server_ip_address = get_ip_address_by_interface('server1', server_iface)
  @equipment['dut1'].send_cmd("export #{host_env_name}=#{server_ip_address}")
  @equipment['dut1'].send_cmd("ifconfig -a")
end
