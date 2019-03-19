# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  import_TIDL_arm(@test_params.params_chan.tidl_model_git[0],@test_params.params_chan.constraints[0])
  set_result(FrameworkConstants::Result[:pass], "Test Passed. Import tool operation successful.")
  rescue Exception => e
     set_result(FrameworkConstants::Result[:fail], "#{e}")
end

def clean
  #super
  self.as(LspTestScript).clean
end

def import_TIDL_arm(tidl_model_git,pass_crit)
  #get file system root path
  nfs_root_path = LspTestScript.nfs_root_path
  bin_root_path = "#{nfs_root_path}/usr/bin"

  #select the path for clone test source files
  share_root_path = "#{nfs_root_path}/test"

  #clean up the test folder before use
  @equipment['server1'].send_cmd("cd #{share_root_path}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("rm -r #{share_root_path}/tidl_import", @equipment['server1'].prompt, 10)

  #clone test branch to the test folder (including sub-modules)
  @equipment['server1'].send_sudo_cmd("git clone -b import-tool-regression --recurse-submodules #{tidl_model_git} #{share_root_path}/tidl_import", @equipment['server1'].prompt, 700)

  #go to the test directory on ARM
  @equipment['dut1'].send_cmd("cd /test/tidl_import", @equipment['dut1'].prompt, 10)

  #run the test on ARM
  @equipment['dut1'].send_cmd("./importToolRegression.sh",@equipment['dut1'].prompt, 240)

  #verify test result
  server_log = @equipment['dut1'].response
  if !(server_log =~ /(#{pass_crit})/)
    raise "TIDL Import Tool Test FAILED."
  end

end


