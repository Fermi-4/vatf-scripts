# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../demos/dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
   clone_opencv_extra(@test_params.params_chan.opencv_extra_git[0])
   @equipment['dut1'].send_cmd("rm -r opencv_extra*", @equipment['dut1'].prompt, 20)
   transfer_to_dut("opencv_extra.tar.gz", @equipment['server1'].telnet_ip, 600)
   begin
     opencv_stereobm_implementation(@test_params.params_chan.constraints[0])
     set_result(FrameworkConstants::Result[:pass], "Test Passed. OpenCV stereoBM implementation test passed.")
   rescue Exception => e
     set_result(FrameworkConstants::Result[:fail], "#{e}")
   end
end

def clean
  self.as(LspTestScript).clean
  @equipment['dut1'].send_cmd("cd /usr/share/OpenCV/titestsuite;cp setupEnv_bk.sh setupEnv.sh", \
                             @equipment['dut1'].prompt, 40)
end

# function to run OpenCV stereoBM implementation test
def opencv_stereobm_implementation(pass_crit)
  @equipment['dut1'].send_cmd("tar -xvf opencv_extra.tar.gz",@equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("cd opencv_extra;cp -r testdata /usr/share/OpenCV",@equipment['dut1'].prompt, 120)
  @equipment['dut1'].send_cmd("cd /usr/share/OpenCV/titestsuite", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cat setupEnv.sh", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cd /usr/share/OpenCV/titestsuite;cp setupEnv.sh setupEnv_bk.sh", \
                             @equipment['dut1'].prompt, 40)
  @equipment['dut1'].send_cmd("echo \"export TI_OCL_LOAD_KERNELS_ONCHIP=Y\" >> setupEnv.sh", \
                             @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo \"export TI_OCL_KEEP_FILES=Y\" >> setupEnv.sh", \
                             @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo \"export TI_OCL_CACHE_KERNELS=Y\" >> setupEnv.sh", \
                             @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cat setupEnv.sh", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("source /usr/share/OpenCV/titestsuite/setupEnv.sh;cd",@equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("$OPENCV_BUILDDIR/bin/opencv_test_calib3d --gtest_filter=OCL_StereoMatcher/*", \
                             @equipment['dut1'].prompt, 1800)
  @equipment['dut1'].send_cmd("$OPENCV_BUILDDIR/bin/opencv_test_calib3d --gtest_filter=OCL_StereoMatcher/*", \
                             @equipment['dut1'].prompt, 150)
  dut_log = @equipment['dut1'].response

  if !(dut_log =~ /(#{pass_crit})/)
     raise "Failed to run OpenCV stereoBM implementation test."
  end
end

# function to download OpenCV test data
def clone_opencv_extra(opencv_extra_git)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/opencv_extra", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{opencv_extra_git} /tftpboot/opencv_extra", \
                                @equipment['server1'].prompt, 1200)
  @equipment['server1'].send_cmd("cd /tftpboot;tar -cvzf opencv_extra.tar.gz opencv_extra", \
                                @equipment['server1'].prompt, 300)
  @equipment['server1'].send_sudo_cmd("chmod 777 /tftpboot/opencv_extra.tar.gz", \
                                     @equipment['server1'].prompt, 20)
end
