# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/../../../lib/result_forms'
require File.dirname(__FILE__)+'/../../../lib/evms_data'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  test_result = true
  perf_data = []
  drm_info = get_properties()
  test_modes = get_required_display_modes(@equipment['dut1'].name)
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Connector",{:bgcolor => "4863A0"}], 
                                            ["Mode", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])
  test_modes.each do |t_mode|
    res = false
    res_string = 'Mode is not supported by the board'
    test_connector = nil
    mode = nil
    drm_info['Connectors:'].each do |connector|
      mode_name, mode_rate = t_mode.split('@') 
      connector['modes:'].each do |c_mode|
        if c_mode['name'] == mode_name && c_mode['refresh (Hz)'] == mode_rate
          mode = c_mode
          break
        end
      end
      next if !mode
      test_connector = connector
      mode_params = {'connectors_ids' => [connector['id']], 
                     'mode' => mode['name'],
                     'framerate' => mode['refresh (Hz)'],
                     'type' => connector['type']}
        
      res = run_sync_flip_test(mode_params) { sleep 8 }
      res_string = res ? '' : 'fps test failed'
      break
    end
    test_result &= res
    @results_html_file.add_rows_to_table(res_table,
                                         [[test_connector ? "#{test_connector['type']} (#{test_connector['id']})":
                                           "None", 
                                           t_mode,
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Mode check Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Mode check Test failed")
  end
end




