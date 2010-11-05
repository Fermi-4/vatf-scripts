require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  bw =[]
  i =0 
  time        = @test_params.params_control.time[0]
  port_number = @test_params.params_control.port_number[0].to_i
  ip_ver      = @test_params.params_control.ip_version[0]
  # Start netserver on the Host on a tcp port with following conditions:
  #   1) It is equal or higher that port_number specified in the test matrix
  #   2) It is not being used
  while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
    port_number = port_number + 2
  end
  @equipment['server1'].send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
  
  # Start netperf on the Target
  @test_params.params_control.buffer_size.each do |bs|
    data = send_adb_cmd "shell netperf -H #{@equipment['server1'].telnet_ip} -l #{time} -p #{port_number} -- -s #{bs}"
    bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f
    puts data
    i = i+1  
  end

  ensure
    if i < @test_params.params_control.buffer_size.length
      set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf')
      puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
    else
      min_bw = @test_params.params_control.min_bw[0].to_f
      if mean(bw) > min_bw 
        pretty_str = get_perf_pretty_str(bw)
        set_result(FrameworkConstants::Result[:pass], pretty_str)
        puts "Test Passed: AVG Throughput=#{mean(bw)} \n #{pretty_str}"
      else
        set_result(FrameworkConstants::Result[:fail], "Performance is less than #{min_bw} Mb/s. AVG Throughput=#{mean(bw)} \n #{pretty_str}")
        puts "Test Failed: Performance is less than #{min_bw} Mb/s. AVG Throughput=#{mean(bw)} \n #{pretty_str}"
      end
    end
    # Kill netserver process on the host
    procs = send_host_cmd "ps ax | grep netserver"
    procs.scan(/^\s*(\d+)\s+.+?netserver\s+\-p\s+#{port_number}\s+\-#{ip_ver}/i) {|pid|
      @equipment['server1'].send_sudo_cmd("kill -9 #{pid[0]}") 
    }
end


private 
def mean(a)
 a.sum.to_f / a.size
end

def get_perf_pretty_str(bw)
  bsizes = @test_params.params_control.buffer_size
  result = "Buffer Size \t Throughput \n"
  bsizes.length.times {|i|
    result= result + "#{bsizes[i]}\t#{bw[i]}\n"
  }
  result
end




