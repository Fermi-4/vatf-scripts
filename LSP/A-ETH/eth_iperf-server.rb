require 'net/ftp'
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'

include LspTestScript
include ParsePerfomance


def setup
  super
  test_type = @test_params.params_control.type[0]
  test_cmd = test_type.match(/udp/i) ? "iperf -s -u -w 128k &" : "iperf -s &"
  if !is_iperf_running?(test_type)
    @equipment['dut1'].send_cmd(test_cmd, /Server\s+listening.*?#{test_type}\sport/i, 10)
  end
  if !is_iperf_running?(test_type)
    raise "iperf can not be started. Please make sure iperf is installed in the DUT"    
  end
end

def run
  dut_ip_addr = get_ip_addr(@test_params.params_control.iface[0])
  run_start_stats
  @equipment['server1'].send_cmd("iperf -c #{dut_ip_addr} -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{@test_params.params_control.time[0]} -b #{@test_params.params_control.bandwidth[0]} -w 128k", 
                                 @equipment['server1'].prompt,
                                 @test_params.params_control.timeout[0].to_i)
  run_stop_stats                               
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

# Start collecting system metrics (i.e. cpu load, mem load)
  def self.run_start_stats
    @eth_ip_addr = get_ip_addr(@test_params.params_control.iface[0])
    if @eth_ip_addr
      @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
      @equipment['dut1'].target.platform_info.telnet_port = 23
      @equipment['dut1'].connect({'type'=>'telnet'})
      @equipment['dut1'].target.telnet.send_cmd("pwd", @equipment['dut1'].prompt , 3)    
      start_collecting_stats(@collect_stats, @collect_stats_interval) do |cmd|
        if cmd
          @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
          @equipment['dut1'].target.telnet.response
        end
      end
      @equipment['dut1'].target.telnet.send_cmd("cd /sys/class/net/eth0/statistics", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec basename {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec cat {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", /.*/, 3)
    end
    
  end
  
  # Stop collecting system metrics 
  def self.run_stop_stats
    if @eth_ip_addr
      @target_sys_stats = stop_collecting_stats(@collect_stats) do |cmd| 
        if cmd
          @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
          @equipment['dut1'].target.telnet.response
        end
      end
      @equipment['dut1'].target.telnet.send_cmd("cd /sys/class/net/eth0/statistics", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec basename {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec cat {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", /.*/, 3)
    end
     @equipment['dut1'].send_cmd("find /sys/class/net/eth0/statistics -type f -exec basename {} \\;", @equipment['dut1'].prompt, 3)
     @equipment['dut1'].send_cmd("find /sys/class/net/eth0/statistics -type f -exec cat {} \\;", @equipment['dut1'].prompt, 3)
     @equipment['dut1'].send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", @equipment['dut1'].prompt, 3)
     
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
  test_regex = type.match(/udp/i) ? /iperf\s+\-s\s+\-u/i : /iperf\s+\-s\s*$/i
  @equipment['dut1'].send_cmd("ps", @equipment['dut1'].prompt, 10)
  if !(@equipment['dut1'].response.match(test_regex))
    return false
  else
    return true
  end
end

# Get ip address assgined to ethernet interface
def get_ip_addr(iface='eth0', eq=@equipment['dut1'])
  eq.send_cmd("ifconfig #{iface}", eq.prompt)
  dut_ip = (/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(eq.response)).captures[0] 
  dut_ip
end

