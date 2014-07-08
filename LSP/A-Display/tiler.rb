# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/result_forms'  

include LspTestScript

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  test_result = false
  perf_data = []
  plane_format=@test_params.params_chan.format[0]
  tile_type=@test_params.params_chan.tile_type[0]
            
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Test",{:bgcolor => "4863A0"}], 
											["Result", {:bgcolor => "4863A0"}],
											["Comment", {:bgcolor => "4863A0"}]])
  
  test_result, results = run_test(plane_format, tile_type)
  results.each do |test_str, res|
    @results_html_file.add_rows_to_table(res_table,[[test_str, 
									    			res['rc'] == FrameworkConstants::Result[:pass] ? 
									    			["Passed",{:bgcolor => "green"}] : 
									                ["Failed",{:bgcolor => "red"}],
									                res['comment']]])
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Tiler Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Tiler Test failed")
  end
end

def get_result(test_string)
  res_win = ResultWindow.new(test_string)
  res_win.show()
  return res_win.get_result()
end

#Function to run the drm mode tests supported by modetest, takes
#  plane_format, string containing the format to test the plane with,i.e  XR24, RA24, etc
#  tile_type, bo tile container type 8, 16 or 32. Should match the size of plane_format
#Returns an array containing [boolean, result] where the boolean signals if
#the test passed (true) or failed (false); and result is a hash whose keys
#are strings containing the tiler feature tested and values are hashes with
#dictionaries: 'rc' => FrameworkConstants::Result[:pass] or FrameworkConstants::Result[:fail],
#              'comment' => <string with path of failed comment>
def run_test(plane_format, tile_type)
  test_cmd ="tiler_test -f #{plane_format} -t #{tile_type}"
  test_result = true
  result={}
  timeout = @equipment['dut1'].send_cmd(test_cmd, /Press\s*any\s*key\s*to\s*continue..../im, 7)
  while(!@equipment['dut1'].timeout?)
    test_string = @equipment['dut1'].response.match(/Trying\s*0x[\dA-F]+\s*([^\s]+)/i)[1]
    win_res = get_result(test_string)
    result[test_string] = {'rc' => win_res[0], 'comment' => win_res[1]}
    test_result &= win_res[0] == FrameworkConstants::Result[:pass]
    @equipment['dut1'].send_cmd('', /Press\s*any\s*key\s*to\s*continue..../im, 7)
  end

  [test_result, result]
end




