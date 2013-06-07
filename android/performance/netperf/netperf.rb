require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../connectivity_module'

include AndroidTest
include ConnectivityModule
def setup
    self.as(AndroidTest).setup
    enable_ethernet
end 

def run
  bw = {}
  time        = @test_params.params_control.time[0]
  port_number = @test_params.params_control.port_number[0].to_i
  ip_ver      = @test_params.params_control.ip_version[0]
  measured_bw = nil
  # Start netserver on the Host on a tcp port with following conditions:
  #   1) It is equal or higher that port_number specified in the test matrix
  #   2) It is not being used
  while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
    port_number = port_number + 2
  end
  @equipment['server1'].send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
  sys_stats = nil
  0.upto(1) do |iter|
    start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd| send_adb_cmd("shell #{cmd}")} if iter > 0 && @test_params.params_control.instance_variable_defined?(:@collect_stats)
    # Start netperf on the Target
    @test_params.params_control.buffer_size.each do |bs|
      data=''
      if @test_params.params_control.instance_variable_defined?(:@stream_type)
        data = send_adb_cmd "shell netperf -H #{@equipment['server1'].telnet_ip} -l #{time} -p #{port_number} -t #{@test_params.params_control.stream_type[0]} -- -s #{bs}"
      else
        data = send_adb_cmd "shell netperf -H #{@equipment['server1'].telnet_ip} -l #{time} -p #{port_number} -- -s #{bs}"   
      end
      puts data
      if iter == 0
          test_type = @test_params.params_control.instance_variable_defined?(:@stream_type) ? @test_params.params_control.stream_type[0] : "TCP"
          bw[bs] = case test_type
          when /udp/i
            measured_bw = /^\s*\d+\s+[\d\.]+\s+\d+\s+([\d\.]+)/m.match(data).captures[0].to_f
            {'receive' => measured_bw,
             'send' => /^\s*\d+\s+\d+\s+[\d\.]+\s+\d+\s+\d+\s+([\d\.]+)/m.match(data).captures[0].to_f}
          when /tcp/i 
            measured_bw = /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f
            {'' => measured_bw}
          end
      end
    end
    sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats) if iter > 0 && @test_params.params_control.instance_variable_defined?(:@collect_stats)
  end
  ensure
    if bw.empty?
      set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf')
      puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
    else
      min_bw = @test_params.params_control.min_bw[0].to_f
      pretty_str, perfdata = get_perf_pretty_str(bw)
      if sys_stats
        @results_html_file.add_paragraph("")
        sys_stats.each do |current_stats|
        perfdata.concat(current_stats)
        current_stats.each do |current_stat|
          current_stat_plot = stat_plot(current_stat['value'], current_stat['name']+" plot", "sample", current_stat['units'], current_stat['name'], current_stat['name'], "system_stats")
          plot_path, plot_url = upload_file(current_stat_plot)
          @results_html_file.add_paragraph("")
          res_table2 = @results_html_file.add_table([[current_stat['name']+' ('+current_stat['units']+')',{:bgcolor => "33CC66", :colspan => "#{current_stat['name'].length}"},{:color => "blue"},plot_url]],{:border => "1",:width=>"20%"})
          @results_html_file.add_rows_to_table(res_table2,[current_stat['value']].transpose)
          end
        end
      end
      if measured_bw > min_bw 
        set_result(FrameworkConstants::Result[:pass], pretty_str, perfdata)
        puts "Test Passed: AVG Throughput=#{measured_bw} \n #{pretty_str}"
      else
        set_result(FrameworkConstants::Result[:fail], "Performance is less than #{min_bw} Mb/s. AVG Throughput=#{measured_bw} \n #{pretty_str}", perfdata)
        puts "Test Failed: Performance is less than #{min_bw} Mb/s. AVG Throughput=#{measured_bw} \n #{pretty_str}"
      end
    end
    # Kill netserver process on the host
    procs = send_host_cmd "ps ax | grep netserver"
    procs.scan(/^\s*(\d+)\s+.+?netserver\s+\-p\s+#{port_number}\s+\-#{ip_ver}/i) {|pid|
      @equipment['server1'].send_sudo_cmd("kill -9 #{pid[0]}") 
    }
end


private 

def get_perf_pretty_str(bw)
  perfdata = []
  bsizes = @test_params.params_control.buffer_size
  result = "Buffer Size \t Throughput \n"
  bw.each { |bsize, throughput|
    result= result + "#{bsizes}\t#{throughput.to_s}\n"
    perf_name = @test_params.params_control.instance_variable_defined?(:@stream_type) ? @test_params.params_control.stream_type[0] : "TCP_STREAM_"
    throughput.each do |type, tp|
      perfdata << {'name'=> "#{perf_name}_Throughput_#{bsize}_#{type}", 'value' => tp.to_f, 'units' => 'Mb/s'}
    end
  }
  [result,perfdata]
end




