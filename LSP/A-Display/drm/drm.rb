# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/../../../lib/result_forms'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def run
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
      @results_html_file.add_rows_to_table(res_table,[[md_mode.to_s, 
                                           res ? ["Passed",{:bgcolor => "green"}] : 
                                           ["Failed",{:bgcolor => "red"}],
                                           res_string]])
    end
  end
  
  if test_result
    set_result(FrameworkConstants::Result[:pass], "DRM Test Passed", perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "DRM Test failed", perf_data)
  end
end

#Function to ask the user is a given mode test worked, takes
#  test_string, string with an informational message related to the test
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def get_drm_test_result(test_string)
  sleep(5) #Run for at least 5 secs
  res_win = ResultWindow.new(test_string)
  res_win.show()
  return res_win.get_result()
end

#Function to run the drm mode tests supported by modetest, takes
#  mode_params, a hash whose entry are the ones required by drm_utils set_mode method
#  perf_data, (Not used) Array for collecting performance data
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test  
def run_mode_test(mode_params, perf_data=[])
  test_result = true
  result_string = ''
  mode_result = FrameworkConstants::Result[:nry]
  title_string = "#{mode_params.to_s}"
  while(mode_result == FrameworkConstants::Result[:nry])
    set_mode(mode_params) do
      mode_result, mode_string = get_drm_test_result("#{title_string} mode test")
      test_result &= mode_result == FrameworkConstants::Result[:pass]
      result_string += mode_string
    end
  end
  sf_result = test_result ? FrameworkConstants::Result[:nry] : FrameworkConstants::Result[:fail]
  while(sf_result == FrameworkConstants::Result[:nry])
    fps_res = run_sync_flip_test(mode_params) do
      sf_result, sf_string = get_drm_test_result("#{title_string} sync flip test")
      test_result &= sf_result == FrameworkConstants::Result[:pass]
      result_string += ', ' + sf_string
    end
  end
  if !fps_res
    result_string += ", fps Failed in sync flip test "
  else
    result_string += ", fps Passed in sync flip test " 
  end
  test_result &= fps_res
  [test_result, result_string]
end

#Function to test the properties supported by a DRM object, takes
#  type, the type of the object whose property will be set CRTC, Connector, Plane
#  drm_obj, a hash whose entry are the {id=><id>, name=><name>, etc}
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def run_properties_test(type, drm_obj)
  test_result = true
  test_string = ''
  obj_id = drm_obj['id']
  props_hash = drm_obj['props:']
  test_string = ""
  props_hash.each do |prop, prop_info|
    prop_name = prop.match(/([A-z]+)/).captures[0].strip()
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["#{type}-#{obj_id}", {:bgcolor => "4863A0", :colspan => "3"}]])
    @results_html_file.add_rows_to_table(res_table,[[[prop_name,{:bgcolor => "98AFC7"}],   
                                                     ["Result",{:bgcolor => "98AFC7"}],
                                                     ["Comment",{:bgcolor => "98AFC7"}]]])
                                                     
    case prop_info['flags:'].strip()
      when 'enum'
        prop_info['enums:'].each do |e_name, e_val|
          res = FrameworkConstants::Result[:nry]
          while(res == FrameworkConstants::Result[:nry])
            set_property(obj_id, prop_name, prop_info['value:'])
            set_property(obj_id, prop_name, e_val)
            res, res_string = get_drm_property_test_result(prop_name, e_val, e_name)
          end
          @results_html_file.add_rows_to_table(res_table,[["#{e_val}(#{e_name})",
                                                           res == FrameworkConstants::Result[:pass] ?
                                                                   ["Passed",{:bgcolor => "green"}] :
                                                                   ["Failed",{:bgcolor => "red"}],
                                                           res_string]])
          test_result &= res == FrameworkConstants::Result[:pass]
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      when 'bitmask'
        prop_info['values:'].each do |b_name, b_val|
          res = FrameworkConstants::Result[:nry]
          while(res == FrameworkConstants::Result[:nry])
            set_property(obj_id, prop_name, prop_info['value:'])
            set_property(obj_id, prop_name, b_val)
            res, res_string = get_drm_property_test_result(prop_name, b_val, b_name)
          end
          @results_html_file.add_rows_to_table(res_table,[["#{b_val}(#{b_name})",
                                                           res == FrameworkConstants::Result[:pass] ?
                                                                   ["Passed",{:bgcolor => "green"}] :
                                                                   ["Failed",{:bgcolor => "red"}],
                                                           res_string]])
          test_result &= res == FrameworkConstants::Result[:pass]
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      when 'range'
        prop_info['values:'].each do |current_val|
          res = FrameworkConstants::Result[:nry]
          while(res == FrameworkConstants::Result[:nry])
            set_property(obj_id, prop_name, prop_info['value:'])
            set_property(obj_id, prop_name, current_val)
            res, res_string = get_drm_property_test_result(prop_name, current_val)
          end
          @results_html_file.add_rows_to_table(res_table,[["#{current_val}",
                                                           res == FrameworkConstants::Result[:pass] ?
                                                                   ["Passed",{:bgcolor => "green"}] :
                                                                   ["Failed",{:bgcolor => "red"}],
                                                           res_string]])
          test_result &= res == FrameworkConstants::Result[:pass]
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      else
         @results_html_file.add_rows_to_table(res_table,[[prop,
                                                          ["Passed",{:bgcolor => "green"}],
                                                          "Nothing to do for #{prop}, it is #{prop_info['flags:']}"]])
         test_string += ''
    end
  end
  [test_result, test_string]
end

#Function to ask the user is a given property setting worked, takes
#  prop, string with the name of the property that was set
#  prop_val, string containing the value that was set for the property
#  val_meaning, (optional) string containing the meaning of prop_val, i.e On, Off, etc
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def get_drm_property_test_result(prop, prop_val, val_meaning=nil)
  res_win = ResultWindow.new("#{prop}#{val_meaning ? "(#{val_meaning})" : ''} property test")
  res_win.show()
  return res_win.get_result()
end




