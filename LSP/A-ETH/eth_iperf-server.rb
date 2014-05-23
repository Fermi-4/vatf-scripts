require 'net/ftp'
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'

include LspTestScript
include ParsePerfomance

initial_interval=0
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
  if (test_type.match(/tcp/i) && @test_params.params_control.instance_variable_defined?(:@interrupt_pacing_interval)
)
   response = @equipment['dut1'].send_cmd("ethtool -c #{@test_params.params_control.iface[0]}",@equipment['dut1'].prompt, 3)
   # to get the initial setting of rx-usecs if required
   initial_interval = response.scan(/rx-usecs:*\s\d*/m)[0].split(/:/)[1].strip
   puts "Initial setting is #{initial_interval}\n"
   @equipment['dut1'].send_cmd("set_ethtool_coalesce_options.sh -d #{@test_params.params_control.iface[0]} -p 'rx-usecs' -n #{@test_params.params_control.interrupt_pacing_interval[0]}", @equipment['dut1'].prompt, 3)
  end
  test_cmd = test_type.match(/udp/i) ? "iperf -s -u -w 128k &" : "iperf -s &"
  # If iperf is already running on the DUT, it could possibly interfere with our results, kill it.
  kill_process('iperf')
  puts "Send iperf command"
  @equipment['dut1'].send_cmd(test_cmd, /Server\s+listening.*?#{test_type}\sport/i, 10)
  # iperf server process needs some time
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  if !is_iperf_running?(test_type)
    raise "iperf can not be started. Please make sure iperf is installed in the DUT"    
  end
end

def run
  dut_ip_addr = get_ip_addr('dut1',@test_params.params_control.iface[0])
  run_start_stats
  test_type = @test_params.params_control.type[0]
  if (test_type.match(/udp/i))
  @equipment['server1'].send_cmd("iperf -c #{dut_ip_addr} -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{@test_params.params_control.time[0]} -b #{@test_params.params_control.bandwidth[0]} -w 128k", 
                                 @equipment['server1'].prompt,
                                 @test_params.params_control.timeout[0].to_i)
  elsif (test_type.match(/tcp/i))
   direction = @test_params.params_control.direction[0].match(/bi/i)? '-d':''
   @equipment['server1'].send_cmd("iperf -c #{dut_ip_addr} -m -M  #{@test_params.params_control.packet_size[0]} -f M #{direction} -t #{@test_params.params_control.time[0]} -w  #{@test_params.params_control.window[0]}",@equipment['server1'].prompt,@test_params.params_control.timeout[0].to_i)
  end
  run_stop_stats                               
  if (test_type.match(/tcp/i) && @test_params.params_control.instance_variable_defined?(:@interrupt_pacing_interval)
)
   @equipment['dut1'].send_cmd("set_ethtool_coalesce_options.sh -d #{@test_params.params_control.iface[0]} -p 'rx-usecs' -n 16", @equipment['dut1'].prompt, 3)
end
  run_data = @equipment['server1'].response                                 
  @equipment['server1'].send_cmd("echo $?",/^0/m, 2)
  return_non_zero = @equipment['server1'].timeout?
  perf_data = get_performance_data(run_data, get_perf_metrics)
  test_type = @test_params.params_control.type[0]
  if test_type.match(/tcp/i)
    perf_data.each{|d|
      sum = 0.0
      d['value'].each {|v| sum += v}
      d['value'] = sum
    }  
  end
  
  if return_non_zero
    set_result(FrameworkConstants::Result[:fail], 
            "iperf returned non-zero value. \n",
            perf_data)
  else
    perf_data = perf_data.concat(@target_sys_stats) if @target_sys_stats 
    set_result(FrameworkConstants::Result[:pass],
            "Test passed. iperf returned zero. \n",
            perf_data)
  end
  
end

# Default implementation to return empty array
def get_perf_metrics
  if @test_params.params_control.instance_variable_defined?(:@perf_metrics_file)
    require File.dirname(__FILE__)+"/../../#{@test_params.params_control.perf_metrics_file[0].sub(/\.rb$/,'')}" #Dummy comment to show code propely in eclipse"
    get_metrics 
  else
    return nil
  end
end

def is_iperf_running?(type)
  is_iperf_detected = false
  test_regex = /iperf/
  @equipment['dut1'].send_cmd("ps", @equipment['dut1'].prompt, 10)
  is_iperf_detected = true if (@equipment['dut1'].response.match(test_regex))
  return is_iperf_detected
end

