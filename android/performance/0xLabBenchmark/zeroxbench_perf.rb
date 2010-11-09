require "rexml/document"
require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  response = ''
  test_data = run_test
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




