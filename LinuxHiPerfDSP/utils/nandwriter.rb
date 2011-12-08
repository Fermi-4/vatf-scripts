# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
  
def setup
  super
end

def run
  @equipment['dut1'].send_cmd("cat /proc/version",@equipment['dut1'].prompt, 30)
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  
  partition = @test_params.params_chan.instance_variable_get("@partition")[0].to_s
  flags = @test_params.params_chan.instance_variable_get("@flags")[0].to_s.gsub( /\A[\\]"/, "" ).gsub( /[\\]"\Z/, "" )
  @nfs_root_path = C6xTestScript.nfs_root_path
  @equipment['dut1'].send_cmd("cd /opt",@equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("ls -s image.bin",@equipment['dut1'].prompt, 30)
  bytes = @equipment['dut1'].response.scan(/(\d+)\s+image\.bin/)[0][0].to_i*1024
  puts "Writing #{bytes} bytes"
  @equipment['dut1'].send_cmd("flash_eraseall #{partition}",/100 % complete/, 30)
  @equipment['dut1'].send_cmd("nandwrite #{flags} #{partition} image.bin",@equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("rm image-out.bin",@equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("nanddump -o #{partition} -l #{bytes+1} -f image-out.bin",@equipment['dut1'].prompt, 30)
  @equipment['server1'].send_cmd("cd #{@nfs_root_path}/opt",@equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("cmp -n #{bytes+1} image.bin image-out.bin",/EOF on image.bin/, 30)
  
  if (!@equipment['dut1'].timeout? and !@equipment['server1'].timeout?)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end
  set_result(test_done_result,comment)
end

def clean

end