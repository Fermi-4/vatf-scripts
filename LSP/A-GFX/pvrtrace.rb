require File.dirname(__FILE__)+'/../default_target_test'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || /etc/init.d/weston start; sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib',@equipment['dut1'].prompt,10)
end

def run
  test_string = ''
  dut_profile_path = "#{@linux_dst_dir}/systest.pvrtrace"
  local_profile_path = File.join(@linux_temp_folder, 'systest.pvrtrace')
  pvrtrace_config_path = "~/pvrtraceconfig.json"
  @equipment['server1'].send_cmd("ls #{local_profile_path} && rm #{local_profile_path}", @equipment['server1'].prompt)
  @equipment['dut1'].send_cmd("ls #{pvrtrace_config_path} && rm #{pvrtrace_config_path}", @equipment['dut1'].prompt)
  dut_ip = get_ip_addr()
  @equipment['dut1'].send_cmd("ls #{@linux_dst_dir} &>/dev/null || mkdir -p #{@linux_dst_dir}", @equipment['dut1'].prompt) #Make sure test folder exists
  @equipment['dut1'].send_cmd("rm -f #{@linux_dst_dir}/*", @equipment['dut1'].prompt) #Make sure that test file is new
  create_json(pvrtrace_config_path, dut_profile_path, @equipment['dut1'])
  @equipment['dut1'].send_cmd("cd", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("cat #{pvrtrace_config_path}", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("export LD_LIBRARY_PATH=/opt/img-powervr-sdk/PVRHub/PVRTrace/Recorder/ PVRHUB_DIR=/opt/img-powervr-sdk/PVRHub", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("timeout -t 30 -s 2 weston-simple-egl", @equipment['dut1'].prompt, 120)
  begin
    scp_pull_file(dut_ip, dut_profile_path, local_profile_path)
    @equipment['server1'].send_cmd("ls -l #{local_profile_path}", @equipment['server1'].prompt)
    if !File.size?(local_profile_path) || File.size?(local_profile_path) < 400000
      test_string = "Profile operation failed, data not captured. #{@equipment['server1'].response}"
    end
    @equipment['server1'].send_cmd("cd #{@linux_temp_folder} && tar -Jcvf #{local_profile_path}.tar.xz pvrtrace.dat")
    profile_data = upload_file("#{local_profile_path}.tar.xz")
    @results_html_file.add_paragraph("#{File.basename(local_profile_path)}.tar.xz",nil,nil,profile_data[1]) if profile_data
  rescue Exception => e
    @equipment['dut1'].send_cmd("ls -l #{dut_profile_path}", @equipment['dut1'].prompt)
    test_string = "scp operations failed. Data not captured? #{@equipment['dut1'].response}"
  end
  if test_string == ''
    set_result(FrameworkConstants::Result[:pass], "PVRTrace profile Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "PVRTrace Test failed: " + test_string)
  end
end

def create_json(json_path, trace_path, dut=@equipment['dut1'])

json_data='
{
  "*": {
    "Debug": {
      "Level": 1
    },
    "Tracing": {
      "OutputFilename": "'+trace_path+'",
      "RecordData": true,
      "StartFrame": 0,
      "EndFrame": 1000,
      "ExitOnLastFrame": true
    },
    "Host": {
      "Es2LibraryPath": "/usr/lib/libGLESv2.so",
      "Es1LibraryPath": "/usr/lib/libGLESv1_CM.so",
      "EglLibraryPath": "/usr/lib/libEGL.so"
    },
    "Network": {
      "Wait": true,
      "Enabled": false,
      "BufferSize": 256
    },
    "Profiling": {
      "Enabled": false,
      "SoftwareCounters": true,
      "FunctionTimelineLevel": 2,
      "RenderstateOverride": false
    }
  }
} 
'

  json_data.each_line { |line| dut.send_cmd("echo '#{line.rstrip()}' >> #{json_path}", dut.prompt) }

end