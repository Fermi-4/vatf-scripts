# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript

def run
  #define a temporary folder for the test
  tidl_install_folder = '/tmp/tidl'

  #check if linux installer path is setup in build description
  if @test_params.instance_variable_defined?(:@linux_installer)
    #create test directory
    @equipment['server1'].send_cmd("mkdir #{tidl_install_folder}_$$ && cd #{tidl_install_folder}_$$ && pwd", @equipment['server1'].prompt, 10)

    #get newly created test folder path
    @dir = @equipment['server1'].response.strip()

    #fetch linux SDK installer
    @equipment['server1'].send_cmd("cd #{@dir} && cp -f #{@test_params.linux_installer} linux_installer.bin", @equipment['server1'].prompt, 100)

    #unpack installer
    @equipment['server1'].send_cmd("cd #{@dir} && chmod +x linux_installer.bin && ./linux_installer.bin --mode unattended --prefix  #{@dir}", @equipment['server1'].prompt, 1000)

    #clone tidl test branch (including sub-modules)
    @equipment['server1'].send_cmd("cd #{@dir}/linux-devkit && git clone -b import-tool-regression --recurse-submodules #{@test_params.params_chan.tidl_model_git[0]}", @equipment['server1'].prompt, 1000)

    #setup environment and run the test
    @equipment['server1'].send_cmd("cd #{@dir}/linux-devkit/tidl-utils && source ../environment-setup && ./importToolRegression.sh", @equipment['server1'].prompt, 1000)

    #verify test result
    if (@equipment['server1'].response.scan(/test.*passed/))
      set_result(FrameworkConstants::Result[:pass], "Test Passed. Import tool operation successful.")
    else
      set_result(FrameworkConstants::Result[:fail], "Import tool test failed.")
    end
  else #return error if linux installer is not available
    set_result(FrameworkConstants::Result[:fail], "required software asset linux_installer was not found")
  end
end

def setup
  #super
  self.as(LspTestScript).setup
end
def clean
  if @dir.match(/tidl_\d+/)
    @equipment['server1'].send_sudo_cmd("rm -r #{@dir}", @equipment['server1'].prompt, 60)
  end
  #super
  self.as(LspTestScript).clean
end
