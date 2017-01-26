require File.dirname(__FILE__)+'/../TARGET/dev_test_perf_gov'
require File.dirname(__FILE__)+'/../network_utils'
require File.dirname(__FILE__)+'/../../lib/utils'


def run
  staf_mutex("iperf", 120*60*1000) do
    kill_process('iperf')
    super
  end
end

def setup
  super
  test_type = @test_params.params_control.type[0]
  interface_num = @test_params.params_control.instance_variable_defined?(:@interface_num) ? @test_params.params_control.interface_num[0] : 1
  kill_process('iperf', :this_equipment => @equipment['server1'], :use_sudo => true)
  array_of_interfaces = Array.new 

  if (test_type.match(/udp/i))
    set_eth_sys_control_optimize('dut1')
  end


# this part of test application triggers throughput measurement on the specified number of interfaces simultaneously and reports sum of throughput on all interfaces
  if (interface_num.to_i > 1)
    array_of_interfaces = get_eth_interfaces

    array_of_interfaces.each{|dut_eth|

         run_down_up_udhcpc('dut1', dut_eth)
         serverip=get_eth_server(dut_eth, 'dut1', 'server1')
         @equipment['dut1'].send_cmd("export IPERF#{dut_eth}HOST=#{serverip}", @equipment['dut1'].prompt)

         test_cmd = test_type.match(/udp/i) ? "iperf -s -B #{serverip} -u -w 128k &": "iperf -s -B #{serverip} &"
         @equipment['server1'].send_cmd(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)

        }
   return
# end of multi-interface throughput logic
  else
    test_cmd = test_type.match(/udp/i) ? "iperf -s -u -w 128k &" : "iperf -s &"
    if !is_iperf_running?(test_type)
      @equipment['server1'].send_cmd_nonblock(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)
    end
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
    perf_data.each{|d|
      sum = 0.0
      d['value'].each {|v| sum += v}
      d['value'] = sum
    }  
  
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

