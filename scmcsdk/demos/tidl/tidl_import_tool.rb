# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
   timeout = @test_params.params_chan.instance_variable_defined?(:@timeout) ? @test_params.params_chan.timeout[0].to_i : 60
   download_cafe(@test_params.params_chan.cafe_jacinto_model_git[0])
   @equipment['dut1'].send_cmd("rm -r caffe-jacinto-models", @equipment['dut1'].prompt, 20)
   transfer_to_dut("caffe-jacinto-models.tar.gz", @equipment['server1'].telnet_ip, 300)
   begin
     import_TIDL_ARM(@test_params.params_chan.constraints[0],@test_params.params_chan.constraints[1],timeout)
     import_TIDL_linux_x86(@test_params.params_chan.tidl_model_git[0],@test_params.params_chan.constraints[0],\
@test_params.params_chan.constraints[1], timeout)
     set_result(FrameworkConstants::Result[:pass], "Test Passed. Import tool operation successful.")
   rescue Exception => e
     set_result(FrameworkConstants::Result[:fail], "#{e}")
   end

end

def clean
  #super
  self.as(LspTestScript).clean
end

def import_TIDL_ARM(pass_crit,fail_crit,timeout)
  @equipment['dut1'].send_cmd("mv caffe-jacinto-models.tar.gz /usr/share/ti/tidl/utils/test/testvecs/config",\
                             @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("cd /usr/share/ti/tidl/utils/test/testvecs/config", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("tar -xvf caffe-jacinto-models.tar.gz",@equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("cd /usr/share/ti/tidl/utils", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("rm -r ./test/testvecs/config/tidl_models",@equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("mkdir ./test/testvecs/config/tidl_models", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("tidl_model_import.out ./test/testvecs/config/import/tidl_import_j11_v2.txt",\
                             @equipment['dut1'].prompt, timeout)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !(dut_log =~ /(#{pass_crit})/) or (dut_log =~ /(#{fail_crit})/)
     raise "Failed to import TIDL on ARM."
  end
end

def import_TIDL_linux_x86(tidl_model_git,pass_crit,fail_crit,timeout)
  nfs_root_path = LspTestScript.nfs_root_path
  config_root_path = "#{nfs_root_path}/usr/share/ti/tidl/utils/test/testvecs/config"
  utils_root_path = "#{nfs_root_path}/usr/share/ti/tidl/utils"
  download_copy_tidl_binaries(tidl_model_git, utils_root_path)
  @equipment['server1'].send_sudo_cmd("rm -r #{config_root_path}/caffe-jacinto-models && \
mkdir #{config_root_path}/caffe-jacinto-models && chmod -R 777 #{config_root_path}/caffe-jacinto-models",\
                        @equipment['server1'].prompt, 100)
  @equipment['server1'].send_cmd("cp -r /tftpboot/caffe-jacinto-models/. #{config_root_path}/caffe-jacinto-models/",\
                        @equipment['server1'].prompt, 600)
  @equipment['server1'].send_sudo_cmd("chmod -R ugo+rw #{nfs_root_path}/usr/share/ti/tidl/utils",@equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("cd #{utils_root_path} && ./tidl_model_import.out \
./test/testvecs/config/import/tidl_import_j11_v2.txt", @equipment['server1'].prompt, timeout)
  server_log = @equipment['server1'].response
  clean_up(utils_root_path)
 if @equipment['dut1'].timeout? or !(server_log =~ /(#{pass_crit})/) or (server_log =~ /(#{fail_crit})/)
    raise "Failed to import TIDL on linux x86."
 end
end

# function to download caffe-jacinto-models
def download_cafe(cafe_jacinto_model_git)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/caffe-jacinto-models", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{cafe_jacinto_model_git} /tftpboot/caffe-jacinto-models", \
                                @equipment['server1'].prompt, 600)
  @equipment['server1'].send_cmd("cd /tftpboot; tar -cvzf caffe-jacinto-models.tar.gz caffe-jacinto-models", \
                                @equipment['server1'].prompt, 60)
  @equipment['server1'].send_sudo_cmd("chmod 777 /tftpboot/caffe-jacinto-models.tar.gz", \
                                     @equipment['server1'].prompt, 20)
 # @equipment['server1'].send_sudo_cmd("chown nobody /tftpboot/caffe-jacinto-models.tar.gz", \
  #                                   @equipment['server1'].prompt, 20)
end

# function to download and copy tidl binaries
def download_copy_tidl_binaries(tidl_model_git, path)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/tidl_model", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{tidl_model_git} /tftpboot/tidl_model", \
                                @equipment['server1'].prompt, 600)
  @equipment['server1'].send_sudo_cmd("cp /tftpboot/tidl_model/x86/bin/eve_test_dl_algo_ref.out /usr/bin/", \
                                      @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("cp /tftpboot/tidl_model/x86/bin/tidl_model_import.out #{path}/", \
                                      @equipment['server1'].prompt, 10)
end

# function to remove old binaries
def clean_up(path)
 @equipment['server1'].send_sudo_cmd("rm /usr/bin/eve_test_dl_algo_ref.out",@equipment['server1'].prompt, 10)
 @equipment['server1'].send_sudo_cmd("rm /#{path}/tidl_model_import.out",@equipment['server1'].prompt, 10)
end

