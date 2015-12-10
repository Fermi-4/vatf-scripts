# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/weston stop; sleep 3',@equipment['dut1'].prompt,10)
end

def run
  passed = 0
  failed = 0
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  test_result = true
  perf_data = []
  drm_info = get_properties()
  formats = ['default']
  if @test_params.params_chan.instance_variable_defined?(:@formats)
    formats = Hash.new() { |h,k| h[k] = @test_params.params_chan.formats }
  elsif @test_params.params_chan.instance_variable_defined?(:@valid_formats)
    formats = get_supported_fmts(drm_info['Connectors:'])
  else
    formats = Hash.new(['default'])
  end

  single_disp_modes, multi_disp_modes = get_test_modes(drm_info, formats)
  
  @results_html_file.add_paragraph("")
  res_table = @results_html_file.add_table([["Connector",{:bgcolor => "4863A0"}], 
                                            ["Encoder", {:bgcolor => "4863A0"}],
                                            ["CRTC", {:bgcolor => "4863A0"}],
                                            ["Mode", {:bgcolor => "4863A0"}],
                                            ["Plane", {:bgcolor => "4863A0"}],
                                            ["Result", {:bgcolor => "4863A0"}],
                                            ["Comment", {:bgcolor => "4863A0"}]])

  single_disp_modes.each do |s_mode|
    if !@test_params.params_control.instance_variable_defined?(:@test_type) ||
           @test_params.params_control.test_type[0].strip().downcase() != 'properties'
      plane_info_str = "Scale: #{s_mode[0]['plane']['scale']}, pix_fmt: #{s_mode[0]['plane']['format']}" if s_mode[0]['plane']
      res, res_string = run_mode_test(s_mode, perf_data)
      if res == true
        passed += 1
      else
        failed += 1
      end
      test_result &= res
      @results_html_file.add_rows_to_table(res_table,[["#{s_mode[0]['type']} (#{s_mode[0]['connectors_ids'][0]})", 
                                           s_mode[0]['encoder'],
                                           s_mode[0]['crtc_id'],
                                           "#{ s_mode[0]['mode']}@#{ s_mode[0]['framerate']}",
                                           s_mode[0]['plane'] ? plane_info_str : 'No plane',
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
    else
      {'CRTC' => crtc, 'Connector' => connector}.each do |type, drm_obj|
        res, res_string = run_properties_test(type, drm_obj)
        test_result &= res
        if res == true
          passed += 1
        else
          failed += 1
        end
      end
    end
  end

  if multi_disp_modes.length > single_disp_modes.length && !@test_params.params_chan.instance_variable_defined?(:@test_type)
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Multidisplay Mode",{:bgcolor => "4863A0"}], 
                                              ["Result", {:bgcolor => "4863A0"}],
                                              ["Comment", {:bgcolor => "4863A0"}]])
    multi_disp_modes.each do |md_mode|
      res, res_string = run_mode_test(md_mode, [])
      test_result &= res
      if res == true
        passed += 1
      else
        failed += 1
      end
      @results_html_file.add_rows_to_table(res_table,[[md_mode.to_s, 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
    end
  end
  
  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Test Passed: #{passed}, Failed: #{failed}\n", perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Test Passed: #{passed}, Failed: #{failed}\n", perf_data)
  end
end

#Function to run the drm mode tests supported by modetest, takes
#  mode_params, a hash whose entry are the ones required by drm_utils set_mode method
#  perf_data, (Not used) Array for collecting performance data
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test  
def run_mode_test(mode_params, perf_data=[])
  raise "Calling run_mode_test from drm_based not allowed, " \
        "child script must implement this method"
end

#Function to test the properties supported by a DRM object, takes
#  type, the type of the object whose property will be set CRTC, Connector, Plane
#  drm_obj, a hash whose entry are the {id=><id>, name=><name>, etc}
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def run_properties_test(type, drm_obj)
  raise "Calling run_mode_test from drm_based not allowed, " \
        "child script must implement this method"
end
