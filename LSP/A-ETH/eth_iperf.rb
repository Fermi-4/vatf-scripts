require File.dirname(__FILE__)+'/../TARGET/dev_test_perf_gov'
require File.dirname(__FILE__)+'/../network_utils'

def setup
  super
  test_type = @test_params.params_control.type[0]
  interface_num = @test_params.params_control.instance_variable_defined?(:@interface_num) ? @test_params.params_control.interface_num[0] : 1
  array_of_interfaces = Array.new 
  array_of_server_ips = Array.new

  if (test_type.match(/udp/i))
    @equipment['dut1'].send_cmd("sysctl -w net.core.rmem_max=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.wmem_max=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.rmem_default=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.core.wmem_default=33554432", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.ipv4.udp_mem='4096 87380 33554432'", @equipment['dut1'].prompt, 3)
    @equipment['dut1'].send_cmd("sysctl -w net.ipv4.route.flush=1", @equipment['dut1'].prompt, 3)
  end

# this part of test application triggers throughput measurement on the specified number of interfaces simultaneously and reports sum of throughput on all interfaces
  if (interface_num.to_i > 1)
    @equipment['server1'].send_cmd_nonblock("killall iperf", @equipment['server1'].prompt, 10)
    array_of_interfaces = get_eth_interfaces
    index=0
    array_of_interfaces.each{|dut_eth|
         @equipment['dut1'].send_cmd("ifdown #{dut_eth}", @equipment['dut1'].prompt, 3)
         @equipment['dut1'].send_cmd("ifup #{dut_eth}", @equipment['dut1'].prompt, 10)
         array_of_server_ips<<get_eth_server(dut_eth)
         test_cmd = test_type.match(/udp/i) ? "iperf -s -B #{array_of_server_ips[index]} -u -w 128k &": "iperf -s -B #{array_of_server_ips[index]} &"
         @equipment['server1'].send_cmd(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)
         index=index+1
        }
   return
  end
# end of multi-interface throughput logic
         
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

def get_eth_interfaces()
  interface_arr = Array.new
  @equipment['dut1'].send_cmd("ls /sys/class/net|grep eth")
  eth_interface_list = @equipment['dut1'].response
  eth_interface_arr = eth_interface_list.split(/[\n\r]+/)
  eth_interface_arr.each{|eth|
      if (eth.match(/eth\d/))
         interface_arr << eth
      end
    }
  return interface_arr
end

def get_eth_server(interface_name)
    ip_addr = ''
    ip_addr = get_remote_ip(interface_name, 'dut1', 'server1')
    if (ip_addr == '')
       return [FrameworkConstants::Result[:fail], "Server does not have ethernet interface corresponding to dut's #{interface_name}. Please emsure host machine has an interface on subnet of each dut interface.\n"]
   end
    @equipment['dut1'].send_cmd("export IPERF#{interface_name}HOST=#{ip_addr}", @equipment['dut1'].prompt)
    ip_addr
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

