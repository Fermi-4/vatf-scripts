# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def setup
  super
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && systemctl stop weston && sleep 3',@equipment['dut1'].prompt,10)
end

def run
  drm_rand = Random.new()
  perf_data = []
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  connector_test_time = @test_params.params_chan.instance_variable_defined?(:@connector_test_time) ? 
                        @test_params.params_chan.connector_test_time[0].to_i : 8 
  
  iterations = @test_params.params_chan.instance_variable_defined?(:@iterations) ? 
               @test_params.params_chan.iterations[0].to_i : 1 
  test_result = true     
  drm_info = get_properties()
  @results_html_file.add_paragraph("Random seed = #{drm_rand.seed}")
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["(Multi-)Display Mode",{:bgcolor => "4863A0"}], 
                                            ["Result", {:bgcolor => "4863A0"}]])
              
  formats = @test_params.params_chan.instance_variable_defined?(:@formats) ?
            Hash.new(@test_params.params_chan.formats) :
            get_supported_fmts(drm_info['Connectors:'])
  @results_html_file.add_paragraph("Supported Formats: #{formats}")
  
  multi_disp_modes = get_test_modes(drm_info, formats)[1]         
  modes = multi_disp_modes
      
  if iterations > 1
    modes = Array.new(iterations) {multi_disp_modes[drm_rand.rand(multi_disp_modes.length)]}
  end

  modes.each do |t_mode|
    res, fps_data, output = run_perf_sync_flip_test(t_mode, @equipment['dut1'], connector_test_time + 300) do
                            sleep connector_test_time
                        end
    if output.match(/cut\s*here/im)
      test_result &= false
    elsif output.match(/Invalid\s*argument|Not\s*enough\s*bandwidth|Function\s*not\s*implemented/im)
      test_result &= true
    elsif output.match(/error/im)
      test_result &= false
    else
      test_result &= res
    end
    @results_html_file.add_rows_to_table(res_table,[[t_mode.to_s, 
                                         res ? ["Passed",{:bgcolor => "green"}] : 
                                         ["Failed",{:bgcolor => "red"}]]])
  end
  if test_result && is_uut_up?(@equipment['dut1'])
    set_result(FrameworkConstants::Result[:pass], "DRM Stress Test Passed", [])
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Stress Test failed", [])
  end
end

