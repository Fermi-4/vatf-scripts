require File.dirname(__FILE__)+'/../TARGET/dev_test2'

def setup
  super
  test_type = @test_params.params_control.type[0]

  if (test_type.match(/udp/i))
    @equipment['dut1'].send_cmd("sysctl -w net.core.rmem_max=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.wmem_max=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.rmem_default=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.wmem_default=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.ipv4.udp_mem='4096 87380 33554432'", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.ipv4.route.flush=1", @equipment['dut1'].prompt, 3)
  end
  test_cmd = test_type.match(/udp/i) ? "iperf -s -u -w 128k &" : "iperf -s &"
  if !is_iperf_running?(test_type)
    @equipment['server1'].send_cmd_nonblock(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)
  end
  if !is_iperf_running?(test_type)
    raise "iperf can not be started. Please make sure iperf is installed at the #{@equipment['server1'].telnet_ip} server"    
  end
end

def is_iperf_running?(type)
  test_regex = type.match(/udp/i) ? /iperf\s+\-s\s+\-u/i : /iperf\s+\-s\s*$/i
  @equipment['server1'].send_cmd("ps ax", @equipment['server1'].prompt, 10)
  if !(@equipment['server1'].response.match(test_regex))
    return false
  else
    return true
  end
end

# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?
  perf_data = get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)
  test_type = @test_params.params_control.type[0]
  if test_type.match(/tcp/i)
    perf_data.each{|d|
      sum = 0.0
      d['value'].each {|v| sum += v}
      d['value'] = sum
    }  
  end
  
  if return_non_zero
    return [FrameworkConstants::Result[:fail], 
            "Application exited with non-zero value. \n",
            perf_data]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n",
            perf_data]
  else
    return [FrameworkConstants::Result[:pass],
            "Test passed. Application exited with zero. \n",
            perf_data]
  end
end

