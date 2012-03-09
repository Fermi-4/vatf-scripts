require File.dirname(__FILE__)+'/android_test_module'


module EthernetModule
include AndroidTest

def run_ethernet_test(server = @equipment['server1'],initial_bw,flag)  
  pass_fail = 0
  send_events_for("__home__")
  bw =[]
  time        = @test_params.params_control.time[0]
  port_number = @test_params.params_control.port_number[0].to_i
  ip_ver      = @test_params.params_control.ip_version[0]
  # Start netserver on the Host on a tcp port with following conditions:
  #   1) It is equal or higher that port_number specified in the test matrix
  #   2) It is not being used
  while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
    port_number = port_number + 2
  end
  server.send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
  sys_stats = nil
  0.upto(1) do |iter|
    start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd| send_adb_cmd("shell #{cmd}")} if iter > 0 && @test_params.params_control.instance_variable_defined?(:@collect_stats)
    # Start netperf on the Target
    @test_params.params_control.buffer_size.each do |bs|
      data = send_adb_cmd "shell netperf -H #{server.telnet_ip} -l #{time} -p #{port_number} -- -s #{bs}"
      bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f if iter == 0
      puts data
    end
  end
  ensure
    if bw.length == 0
      set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf')
      puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
    else
      min_bw = @test_params.params_control.min_bw[0].to_f
      pretty_str, perfdata = get_perf_pretty_str(bw)
      mean_bw = mean(bw)
      if flag == true 
        if mean_bw > initial_bw  
          puts "Test Passed: On presuspend BW=#{mean_bw} greater than minimum  BW=#{initial_bw} " 
          pass_fail = 1 
        else
          puts puts "Test Fail: On presuspend BW=#{mean_bw} less than minimum  BW=#{initial_bw} "
         end
      else 
        if mean_bw > (initial_bw -2)  
           puts "Test Passed: On resume BW=#{mean_bw} equal presuspend BW=#{initial_bw} " 
           pass_fail = 1 
        else
           puts puts "Test Fail: On resume BW=#{mean_bw} is less than presuspend BW=#{initial_bw} "
        end
      end 
    end
    # Kill netserver process on the host
    procs = send_host_cmd "ps ax | grep netserver"
    procs.scan(/^\s*(\d+)\s+.+?netserver\s+\-p\s+#{port_number}\s+\-#{ip_ver}/i) {|pid|
      server.send_sudo_cmd("kill -9 #{pid[0]}") 
    }
 return [mean_bw,pass_fail]
end

private 
def mean(a)
 a.sum.to_f / a.size
end

def get_perf_pretty_str(bw)
  perfdata = []
  bsizes = @test_params.params_control.buffer_size
  result = "Buffer Size \t Throughput \n"
  bsizes.length.times {|i|
    result= result + "#{bsizes[i]}\t#{bw[i]}\n"
    perfdata << {'name'=> "Throughput_#{bsizes[i]}", 'value' => bw[i].to_f, 'units' => 'Mb/s'}
  }
  [result,perfdata]
end

end 
