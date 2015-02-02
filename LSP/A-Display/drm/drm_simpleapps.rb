# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/../../../lib/result_forms'

include LspTestScript

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  test_result = true
  result_string = ''
  apps = ['db', 'modesetter', 'onoff']
  
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["App",{:bgcolor => "4863A0"}], 
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])

  apps.each do |c_app|
    res, res_string = run_test(c_app)
    test_result &= res
    @results_html_file.add_rows_to_table(res_table,[[c_app, 
                                         res ? ["Passed",{:bgcolor => "green"}] : 
                                         ["Failed",{:bgcolor => "red"}],
                                         res_string]])

    result_string += ", #{c_app}: #{res_string}" if !res
  end

  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Test failed #{result_string}")
  end
end

#Function to run the drm mode tests supported by modetest, takes
#  app, drm test command to run
#  dut, driver instance used to send the command
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test  
def run_test(app, dut=@equipment['dut1'])
  test_result = true
  result_string = ''
  mode_result = FrameworkConstants::Result[:nry]
 
  while(mode_result == FrameworkConstants::Result[:nry])
    dut.send_cmd("#{app} & sleep 10; killall #{app}", @equipment['dut1'].prompt)
    res_win = ResultWindow.new("#{app} drm test")
    res_win.show()
    mode_result, result_string = res_win.get_result()
    if dut.response.match(/error|warning|(?:not\s*found)/im)
      mode_result = FrameworkConstants::Result[:fail]
      result_string += dut.response
    end
  end
  
  [mode_result == FrameworkConstants::Result[:pass], result_string]
end
