# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/common_functions'

include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  dut_ip = get_ip_addr()
  test_tm = Time.now.strftime("%d_%m_%y_%H_%M_%S")
  @equipment['server1'].send_sudo_cmd("mkdir -p -m 777 /tftpboot/dlp_packages", \
@equipment['server1'].prompt, 10)
  download_package(@equipment['dut1'].params['dlp_sdk_pkg'],'/tftpboot/dlp_packages/')
  download_package(@equipment['dut1'].params['flycapture_pkg'],'/tftpboot/dlp_packages/')
  download_package(@equipment['dut1'].params['mono_pkg'],'/tftpboot/dlp_packages/')
  transfer_to_dut("dlp_packages/#{(@equipment['dut1'].params['dlp_sdk_pkg']).split('/')[-1]}",\
@equipment['server1'].telnet_ip)
  transfer_to_dut("dlp_packages/#{(@equipment['dut1'].params['flycapture_pkg']).split('/')[-1]}",\
@equipment['server1'].telnet_ip)
  transfer_to_dut("dlp_packages/#{(@equipment['dut1'].params['mono_pkg']).split('/')[-1]}",\
@equipment['server1'].telnet_ip)
  setup_dlp_sdk()
  result = run_dlp_sdk(@test_params.params_chan.algorithm_type[0],@test_params.params_chan.cont_scan[0],\
@test_params.params_chan.dlp_cmd[0],@test_params.params_chan.timeout[0].to_i)
  copy_dlpsdk_scan_file_to_server('/usr/share/ti/dlp-sdk/output/scan_data','_color_map.bmp',dut_ip)
  copy_dlpsdk_scan_file_to_server('/usr/share/ti/dlp-sdk/output/scan_data','_point_cloud.xyz',dut_ip)
  copy_dlpsdk_scan_file_to_server('/usr/share/ti/dlp-sdk/output/scan_images','scan_capture_0.bmp',dut_ip)
  result_msg = "Click <a href=\"http://#{copy_dlpsdk_scan_file_to_server('/usr/share/ti/dlp-sdk/output/scan_images'\
,'scan_capture_35.bmp', dut_ip)}/\">here</a> to go to verify scan files."
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{result_msg}")
  elsif result == 1
    set_result(FrameworkConstants::Result[:fail], "Failed to match constraint: \
#{@test_params.params_chan.constraint[0]} or\n Test timed out after \
#{@test_params.params_chan.timeout[0]} seconds. #{result_msg}")
  else
    set_result(FrameworkConstants::Result[:fail], "Log contains: #{@test_params.params_chan.constraint[1]}")
  end
end

def clean
  #super
  self.as(LspTestScript).clean
end

def run_dlp_sdk(algorithm_type,cont_scan,dlp_cmd,timeout)
  @equipment['dut1'].send_cmd("cd /usr/share/ti/dlp-sdk", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("sed -i \'s\/ALGORITHM_TYPE\\s*= ./ALGORITHM_TYPE     = #{algorithm_type}\/g\' \
DLP_LightCrafter_3D_Scan_AM57xx_Config.txt", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("sed -i \'s\/CONTINUOUS_SCANNING\\s*= ./CONTINUOUS_SCANNING     = #{cont_scan}\/g\' \
DLP_LightCrafter_3D_Scan_AM57xx_Config.txt", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cat DLP_LightCrafter_3D_Scan_AM57xx_Config.txt", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("#{dlp_cmd}", @equipment['dut1'].prompt,timeout)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !(dut_log =~ Regexp.new("(#{@test_params.params_chan.constraint[0]})"))
    return 1
  elsif (dut_log =~ Regexp.new("(#{@test_params.params_chan.constraint[1]})"))
    return 2
  else
    @equipment['dut1'].send_cmd("ls -l /usr/share/ti/dlp-sdk/output/scan_data", @equipment['dut1'].prompt,10)
    @equipment['dut1'].send_cmd("ls -l /usr/share/ti/dlp-sdk/output/scan_images", @equipment['dut1'].prompt,10)
    return 0
  end
end

def setup_dlp_sdk()
  @equipment['dut1'].send_cmd("tar -xvzf #{(@equipment['dut1'].params['flycapture_pkg']).split('/')[-1]}", \
@equipment['dut1'].prompt,30)
  @equipment['dut1'].send_cmd("cd ~/flycapture*_armhf/lib/C", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cp libflycapture* /usr/lib", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cd ..", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cp libflycapture* /usr/lib", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cd ~/", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("opkg install --force-depends #{(@equipment['dut1'].params['dlp_sdk_pkg'])\
.split('/')[-1]}", @equipment['dut1'].prompt,60)
  @equipment['dut1'].send_cmd("cd ~/", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("tar -xvzf ~/#{(@equipment['dut1'].params['mono_pkg']).split('/')[-1]} \
-C /usr/share/ti/dlp-sdk", @equipment['dut1'].prompt,30)
  @equipment['dut1'].send_cmd("rm /usr/share/ti/dlp-sdk/output/scan_data/*.bmp /usr/share/ti/dlp-sdk/\
output/scan_data/*.xyz", @equipment['dut1'].prompt,10)
end
