# 

require File.dirname(__FILE__)+'/../network_utils'
require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript


def setup
  super
end

def run
  server_iface = get_local_iface_name(@equipment['server1'],get_ip_addr('dut1', 'eth0'))
  server_ip_address = get_ip_address_by_interface('server1', server_iface)

  puts "server_iface: " + server_iface
  puts "server_ip_address: " + server_ip_address
  smba_usrname = @equipment['server1'].smba_usrname
  smba_passwd = @equipment['server1'].smba_passwd
  smba_share_name = @equipment['server1'].smba_share_name
  smba_share_path = @equipment['server1'].smba_share_path

  mnt_point = '/mnt/smba_mnt'
  mnt_fs = 'cifs'

  @equipment['dut1'].send_cmd("mkdir #{mnt_point}", @equipment['dut1'].prompt, 10)
  puts "====="
  puts "mount -t #{mnt_fs} -o user=#{smba_usrname},password=#{smba_passwd},file_mode=0777,dir_mode=0777 //#{server_ip_address}/#{smba_share_name} #{mnt_point}"
  puts "===="
  @equipment['dut1'].send_cmd("mount -t #{mnt_fs} -o username=#{smba_usrname},password=#{smba_passwd},file_mode=0777,dir_mode=0777 //#{server_ip_address}/#{smba_share_name} #{mnt_point}", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("mount |grep #{mnt_point}", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("echo $?", /^0[\n\r]*/m, 2)
  if @equipment['dut1'].timeout?
    set_result(FrameworkConstants::Result[:fail], "Could not mount #{mnt_fs} to DUT")
    exit 1
  end

  # Do simple file transfer between server and dut
  @equipment['dut1'].send_cmd("touch #{mnt_point}/dut_testfile", @equipment['dut1'].prompt, 10) 
  @equipment['dut1'].send_cmd("ls -l #{mnt_point}", @equipment['dut1'].prompt, 10) 

  @equipment['server1'].send_cmd("ls -l #{smba_share_path}", @equipment['server1'].prompt, 10)
  if !@equipment['server1'].response.match(/dut_testfile/)
    set_result(FrameworkConstants::Result[:fail], "Server could not see the file being created in DUT")
  end
  @equipment['dut1'].send_cmd("rm #{mnt_point}/dut_testfile", @equipment['dut1'].prompt, 10) 

  @equipment['server1'].send_cmd("touch #{smba_share_path}/server_testfile", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("ls -l #{smba_share_path}", @equipment['server1'].prompt, 10)
  @equipment['dut1'].send_cmd("ls -l #{mnt_point}", @equipment['dut1'].prompt, 10) 
  if !@equipment['dut1'].response.match(/server_testfile/)
    set_result(FrameworkConstants::Result[:fail], "DUT could not see the file being created in server.")
  end
  @equipment['server1'].send_cmd("rm #{smba_share_path}/server_testfile", @equipment['server1'].prompt, 10)

  set_result(FrameworkConstants::Result[:pass], "This test passed.")

end
