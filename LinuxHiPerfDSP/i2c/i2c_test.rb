# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript

def setup
  super
end

def run
  @equipment['dut1'].send_cmd("uname -a",@equipment['dut1'].prompt, 30)
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"

  @equipment['dut1'].send_cmd("EEPROM=/sys/devices/platform/i2c_davinci.1/i2c-1/1-0050/eeprom",@equipment['dut1'].prompt, 30)
  if (@test_params.platform.to_s == "curie" || @test_params.platform.to_s == "faraday-lite")
    skip_index = "32K"
  else
    skip_index = "16K"
  end
  id = Time.now.strftime("%m_%d_%Y_%H_%M_%S")
  test_str = "This is an i2c test " + id
  @equipment['dut1'].send_cmd("cd /var/local/",@equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("rm -rf myfile.txt mydata.bin", @equipment['dut1'].prompt, 30)
  
  @equipment['server1'].send_cmd("cd #{C6xTestScript.nfs_root_path}/var", @equipment['server1'].prompt, 30)
  @equipment['server1'].send_sudo_cmd("chmod 777 *", @equipment['server1'].prompt, 30)

  f = File.new("#{C6xTestScript.samba_root_path}/var/local/myfile.txt","w+")
  f.puts test_str
  f.close
  
  #Write to EEPROM
  @equipment['dut1'].send_cmd("dd if=/var/local/myfile.txt of=$EEPROM bs=1 seek=#{skip_index}",@equipment['dut1'].prompt, 30)
  #Read from EEPROM
  @equipment['dut1'].send_cmd("dd if=$EEPROM of=/var/local/mydata.bin bs=1 count=8K skip=#{skip_index}",@equipment['dut1'].prompt, 30)
  
  @equipment['dut1'].send_cmd("cat /var/local/mydata.bin | grep \"#{id}\"",@equipment['dut1'].prompt, 30)
  if (@equipment['dut1'].response.match(test_str) != nil)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  set_result(test_done_result,comment)
end

def clean

end 