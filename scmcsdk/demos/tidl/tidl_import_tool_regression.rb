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
  #clean up the test folder before use
  @equipment['dut1'].send_cmd("rm -rf /test/tidl_import", @equipment['dut1'].prompt, 10)

  #clone test branch to the test folder (including sub-modules)
  @equipment['dut1'].send_cmd("git clone -b import-tool-regression --recurse-submodules #{tidl_model_git} /test/tidl_import", @equipment['dut1'].prompt, 720)

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


