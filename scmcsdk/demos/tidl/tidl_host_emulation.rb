require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  begin
     tidl_host_emulation(@test_params.params_chan.tidl_model_git[0],@test_params.params_chan.constraints[0],\
                         @test_params.params_chan.constraints[1])
     set_result(FrameworkConstants::Result[:pass], "Test Passed. TIDL Host Emualtion Passed.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def clean
  self.as(LspTestScript).clean
end

# function to run TIDL host emulation on Linux x86
def tidl_host_emulation(tidl_model_git,pass_crit,fail_crit)
  nfs_root_path = LspTestScript.nfs_root_path
  binary_path = "#{nfs_root_path}/usr/share/ti/tidl/examples/test/"
  download_copy_tidl_binaries(tidl_model_git,binary_path)
  @equipment['server1'].send_cmd("cd #{binary_path} && touch sim.txt", @equipment['server1'].prompt, 15)
  @equipment['server1'].send_cmd("echo \"1 ./testvecs/config/infer/tidl_config_j11_v2.txt\n0\" > \
                                #{binary_path}sim.txt", @equipment['server1'].prompt, 15)
  @equipment['server1'].send_cmd("cd #{binary_path} && ./eve_test_dl_algo.out sim.txt",\
                                @equipment['server1'].prompt, 15)
  server_log = @equipment['server1'].response
   if !(server_log =~ /#{pass_crit}/) or (server_log =~ /(#{fail_crit})/)
    raise "TIDL Host Emulation Failed."
  end
end

# function to download and copy tidl binaries
def download_copy_tidl_binaries(tidl_model_git,binary_path)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/tidl_model", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{tidl_model_git} /tftpboot/tidl_model", \
                                @equipment['server1'].prompt, 600)
  @equipment['server1'].send_sudo_cmd("cp /tftpboot/tidl_model/x86/bin/eve_test_dl_algo.out #{binary_path}", \
                                      @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chmod -R ugo+rw #{binary_path}",@equipment['server1'].prompt, 10)
end
