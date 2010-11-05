require "rexml/document"
require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  response = ''
  test_data = run_test
  perfdata = []
  location = @test_params.params_chan.test_option[0].match(/-e\s*location\s*([\S]+)/i).captures[0]
  file_size = @test_params.params_chan.test_option[0].match(/-e\s*fileSize\s*([\S]+)/i).captures[0]
  blk_size = @test_params.params_chan.test_option[0].match(/-e\s*blkSize\s*([\S]+)/i).captures[0]
  current_test = 'storageio_'+blk_size
  if !test_data['perf_data'].empty?
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([[current_test,{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    
    test_data['perf_data'].each do |rege, raw_data|
      data = get_stats(raw_data)
      perfdata << {'name' => data[0][0].downcase.gsub(/\s+/,'_')+'_'+blk_size, 'value' => data[0][1].to_f, 'units' => data[0][2]}
      @results_html_file.add_row_to_table(res_table,[data[0][0], data[0][1], data[0][2]])
    end
  end
  @results_html_file.add_paragraph(test_data['response'],nil,nil,nil)
  ensure
    if test_data['perf_data']
      set_result(FrameworkConstants::Result[:pass], "StorageIO performance data collected successfully", perfdata)
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




