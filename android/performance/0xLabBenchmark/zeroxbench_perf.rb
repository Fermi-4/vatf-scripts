require "rexml/document"
require File.dirname(__FILE__)+'/../../android_test_module'  

include AndroidTest

def setup
  super
  if @test_params.params_chan.test_option[0].include?("testNativeLibMicro ") || @test_params.params_chan.test_option[0].include?("testNativeUnixBench")
    bins_list = send_host_cmd("find #{File.join(@test_params.var_test_libs_root,"armeabi-v7a/0xBench_binaries/*")}").split(/[\n\r]+/)
    bins_list.each do |curr_bin|
      send_adb_cmd("push #{curr_bin} /system/bin/")
    end
  end
end

def run
  response = ''
  test_data = nil
  sys_stats = nil
  0.upto(1) do |iter|
    if iter == 0
      test_data = run_test
    elsif @test_params.params_control.instance_variable_defined?(:@collect_stats)
       start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd, stat| 
        if stat == 'proc_mem'
          send_adb_cmd("shell #{cmd} org.zeroxlab.benchmark")
        else
          send_adb_cmd("shell #{cmd}")
        end
      }
      run_test
      sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats)
    end
  end
  perfdata = []
  current_test = @test_params.params_chan.test_option[0].match(/org.zeroxlab.benchmark.test.BenchmarkTest#(\S+)/).captures[0].gsub('test','')
  if test_data['res_file']
    doc = REXML::Document.new File.new(test_data['res_file'])
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([[current_test,{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    doc.elements.each("result/scenario") do |res|
      perf_vals = res.text.split(/\s+/)
      perf_val = perf_vals[0].to_f       
      if perf_vals.length > 1
        perf_sum = 0
        perf_vals.each {|cur_val| perf_sum+=cur_val.to_f}
        perf_val = perf_sum/perf_vals.length
      end
      perfdata << {'name' => res.attributes["benchmark"].downcase.gsub(/\s+/,'_'), 'value' => perf_vals, 'units' => res.attributes["unit"]}
      @results_html_file.add_row_to_table(res_table,[res.attributes["benchmark"],perf_val.to_s,res.attributes["unit"]])
    end
  end
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
  @results_html_file.add_paragraph(test_data['response'],nil,nil,nil)  
  ensure
    if test_data['res_file']
      set_result(FrameworkConstants::Result[:pass], "#{current_test} performance data collected successfully", perfdata)
    else
      set_result(FrameworkConstants::Result[:fail], response+'data is missing')
    end
end


def get_stats(data)
  cur_match = data[0]
  cur_stat = ''
  current_stats = []
  1.upto((data.length)-1) do |i|
    if cur_match.include?(data[i])
      cur_stat += '_' if cur_stat != ''
      cur_stat += data[i] 
    else
      if(cur_stat != '')
        current_stats << cur_stat
        cur_stat = ''
      else
        current_stats << cur_match
      end
      cur_match = data[i]
    end
  end
  if(cur_stat != '')
    current_stats << cur_stat
    cur_stat = ''
  else
    current_stats << cur_match
  end
  current_stats
end




