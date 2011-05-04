require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
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
  @equipment['server1'].send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
  sys_stats = nil
  0.upto(1) do |iter|
    start_collecting_system_stats(0.33){|cmd| send_adb_cmd("shell #{cmd}")} if iter > 0
    # Start netperf on the Target
    @test_params.params_control.buffer_size.each do |bs|
      data = send_adb_cmd "shell netperf -H #{@equipment['server1'].telnet_ip} -l #{time} -p #{port_number} -- -s #{bs}"
      bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f if iter == 0
      puts data
    end
    sys_stats = stop_collecting_system_stats if iter > 0
  end
  ensure
    if bw.length == 0
      set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf')
      puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
    else
      min_bw = @test_params.params_control.min_bw[0].to_f
      pretty_str, perfdata = get_perf_pretty_str(bw)
      perfdata.concat(sys_stats)
      @results_html_file.add_paragraph("")
      systat_names = []
      systat_vals = []
      sys_stats.each do |current_stat|
        systat_vals << current_stat['value']
        current_stat_plot = stat_plot(current_stat['value'], current_stat['name']+" plot", "sample", current_stat['units'], current_stat['name'], current_stat['name'], "system_stats")
        plot_path, plot_url = upload_file(current_stat_plot)
        systat_names << [current_stat['name']+' ('+current_stat['units']+')',nil,nil,plot_url]
      end
      @results_html_file.add_paragraph("")
      res_table2 = @results_html_file.add_table([["Sytem Stats",{:bgcolor => "336666", :colspan => "#{systat_names.length}"},{:color => "white"}]],{:border => "1",:width=>"20%"})
      @results_html_file.add_row_to_table(res_table2, systat_names)
      @results_html_file.add_rows_to_table(res_table2,systat_vals.transpose)
      if mean(bw) > min_bw 
        set_result(FrameworkConstants::Result[:pass], pretty_str, perfdata)
        puts "Test Passed: AVG Throughput=#{mean(bw)} \n #{pretty_str}"
      else
        set_result(FrameworkConstants::Result[:fail], "Performance is less than #{min_bw} Mb/s. AVG Throughput=#{mean(bw)} \n #{pretty_str}", perfdata)
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
  perfdata = []
  bsizes = @test_params.params_control.buffer_size
  result = "Buffer Size \t Throughput \n"
  bsizes.length.times {|i|
    result= result + "#{bsizes[i]}\t#{bw[i]}\n"
    perfdata << {'name'=> "Throughput_#{bsizes[i]}", 'value' => bw[i].to_f, 'units' => 'Mb/s'}
  }
  [result,perfdata]
end




