require File.dirname(__FILE__)+'/../default_target_test'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTargetTestScript

def run
  test_string = ''
  dut_profile_path = "#{@linux_dst_dir}/profile.dat"
  local_profile_path = File.join(@linux_temp_folder, 'profile.dat')
  @equipment['server1'].send_cmd("rm #{local_profile_path}", @equipment['server1'].prompt)
  tool_url = @test_params.params_chan.tool[0]
  tool = "/usr/bin/#{File.basename(tool_url)}"
  profile_duration = @test_params.params_chan.duration[0].to_i
  dut_ip = get_ip_addr()
  @equipment['dut1'].send_cmd("ls #{@linux_dst_dir} &>/dev/null || mkdir -p #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm -f #{@linux_dst_dir}/*", @equipment['dut1'].prompt) #Make sure that test file is new
  @equipment['dut1'].send_cmd("wget #{tool_url} -O #{tool} && chmod 755 #{tool}", @equipment['dut1'].prompt, 240)
  @equipment['dut1'].send_cmd("#{tool} --sendto=#{dut_profile_path} --qat=#{profile_duration}", /.*?Quit!.*?#{@equipment['dut1'].prompt}/im, profile_duration + 10)
  begin
    scp_pull_file(dut_ip, dut_profile_path, local_profile_path)
    @equipment['server1'].send_cmd("ls -l #{local_profile_path}", @equipment['server1'].prompt)
    if !File.size?(local_profile_path) || File.size?(local_profile_path) < 700000
      test_string = "Profile operation failed, data not captured. #{@equipment['server1'].response}"
    end
    @equipment['server1'].send_cmd("cd #{@linux_temp_folder} && tar -Jcvf #{local_profile_path}.tar.xz profile.dat")
    profile_data = upload_file("#{local_profile_path}.tar.xz")
    @results_html_file.add_paragraph("#{File.basename(local_profile_path)}.tar.xz",nil,nil,profile_data[1]) if profile_data
  rescue Exception => e
    @equipment['dut1'].send_cmd("ls -l #{dut_profile_path}", @equipment['dut1'].prompt)
    test_string = "scp operations failed. Data not captured? #{@equipment['dut1'].response}"
  end
  if test_string == ''
    set_result(FrameworkConstants::Result[:pass], "PVRTune profile Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "PVRTune Test failed: " + test_string)
  end
end
