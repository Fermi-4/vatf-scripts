require 'net/ftp'
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'
require File.dirname(__FILE__)+'/../../lib/utils'
require File.dirname(__FILE__)+'/../network_utils'

include LspTestScript
include ParsePerfomance

def setup
  super

end

def run  
  process_name='iperf'
  iperf_version=get_iperf_version

  staf_mutex("iperf", 240000) do
    test_type = @test_params.params_control.type[0]
    interface_num = @test_params.params_control.instance_variable_defined?(:@interface_num) ? @test_params.params_control.interface_num[0] : 1
    array_of_interfaces = Array.new

    if (test_type.match(/udp/i))
      set_eth_sys_control_optimize('dut1')
    end

  
    pkill_process(process_name)
    if (interface_num.to_i > 1)
      array_of_interfaces = get_eth_interfaces
    else
      array_of_interfaces = [@test_params.params_control.iface[0]] 
    end

    array_of_interfaces.each{|dut_eth|
         if (dut_eth != 'eth0')
            run_down_up_udhcpc('dut1', dut_eth)
         end
         ip_addr=get_ip_addr('dut1', dut_eth)
         if (iperf_version==3)
            test_cmd = "iperf3 -s -B #{ip_addr} -i 0 &"
         else
            test_cmd = test_type.match(/udp/i) ? "iperf -s -B #{ip_addr} -u -w 128k &": "iperf -s -B #{ip_addr} &"
         end
         @equipment['dut1'].send_cmd(test_cmd, /Server\s+listening\s*\w*/i, 10)
         @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
         if !is_iperf_running?(test_type)
             raise "iperf can not be started. Please make sure iperf is installed in the DUT"    
         end
        }
    pkill_process(process_name, :this_equipment => @equipment['server1'], :use_sudo => true)
    if @test_params.params_control.type.length > 1
      test_vars = @test_params.params_control.type[1]
    else
      test_vars = nil
    end
    if test_vars != nil && test_vars.match(/stress/i)
      start_genload()
    end

    run_start_stats

    array_of_interfaces.each{|dut_eth|
        dut_ip=get_ip_addr('dut1', dut_eth)
        if (test_type.match(/udp/i))
           if (iperf_version==3)
              @equipment['server1'].send_cmd("iperf3 -c #{dut_ip} -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{@test_params.params_control.time[0]} -b #{@test_params.params_control.bandwidth[0]} -w 128k -i 0 &", @equipment['server1'].prompt, @test_params.params_control.timeout[0].to_i)
           else
              @equipment['server1'].send_cmd("iperf -c #{dut_ip} -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{@test_params.params_control.time[0]} -b #{@test_params.params_control.bandwidth[0]} -w 128k &", 
                                 @equipment['server1'].prompt,
                                 @test_params.params_control.timeout[0].to_i)
           end
        elsif (test_type.match(/tcp/i))
           if (iperf_version==3)
             @equipment['server1'].send_cmd("iperf3 -c #{dut_ip} -M #{@test_params.params_control.packet_size[0]} -f M -t #{@test_params.params_control.time[0]} -w  #{@test_params.params_control.window[0]} -i 0 &",@equipment['server1'].prompt,@test_params.params_control.timeout[0].to_i)
           else
             direction = @test_params.params_control.direction[0].match(/bi/i)? '-d':''
             @equipment['server1'].send_cmd("iperf -c #{dut_ip} -m -M  #{@test_params.params_control.packet_size[0]} -f M #{direction} -t #{@test_params.params_control.time[0]} -w  #{@test_params.params_control.window[0]} &",@equipment['server1'].prompt,@test_params.params_control.timeout[0].to_i)
           end
        end
     
       }
    sleep @test_params.params_control.time[0].to_i
    run_stop_stats 
    if test_vars != nil && test_vars.match(/stress/i)
      stop_genload  
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
  #iperf_version=get_iperf_version
  #test_regex = iperf_version==3? \iperf3\:\iperf\
  test_regex =  /iperf\d*\s*\w*/i
  @equipment['dut1'].send_cmd("ps", @equipment['dut1'].prompt, 10)
  is_iperf_detected = true if (@equipment['dut1'].response.match(test_regex))
  return is_iperf_detected
end


def start_genload()
  @equipment['dut1'].send_cmd("/opt/ltp/testcases/bin/genload -m 4 &", /genload: info:/i, 10)
end

def stop_genload()
  kill_process('genload')
end


