require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def run
  begin
    params = {'platform' => @equipment['dut1'].name}
    @equipment['dut1'].send_cmd('uname -r', @equipment['dut1'].prompt)
    params['version'] = @equipment['dut1'].response.match(/^([\d\.]+)/i).captures[0]
    platform_string = get_platform_string(params)
        
    # Check platform string
    if !@equipment['dut1'].boot_log.match(/#{platform_string}/mi)
      set_result(FrameworkConstants::Result[:fail], "SoC was not properly detected. Could not find #{platform_string} in boot logs")
      return
    end
    
    # Check max OPP is available if cpufreq is enabled
    if check_cmd?("zcat /proc/config.gz |grep  _CPUFREQ=y") or check_cmd?("zcat /proc/config.gz |grep  _CPUFREQ=m")
      @equipment['dut1'].send_cmd('cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq', @equipment['dut1'].prompt)
      max_opp_string = get_max_opp_string(params)
      if !@equipment['dut1'].response.match(/#{max_opp_string}/i)
        set_result(FrameworkConstants::Result[:fail], "Max OPP is not available. Expected #{max_opp_string}")
        return
      end
    else
      set_result(FrameworkConstants::Result[:pass], "SoC was properly detected but Max OPP was not verified because cpufreq is not enabled")
      return
    end
    set_result(FrameworkConstants::Result[:pass], "SoC was properly detected and Max OPP is #{max_opp_string}")
  rescue Exception => e  
    puts e.message 
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Linux version not found")
  end
end