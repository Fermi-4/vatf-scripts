# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../../lib/result_forms'
require File.dirname(__FILE__)+'/drm_base'   

#Function to ask the user is a given mode test worked, takes
#  test_string, string with an informational message related to the test
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def get_drm_test_result(test_string)
  sleep(5) #Run for at least 5 secs
  return [FrameworkConstants::Result[:pass], ''] if @test_params.params_chan.instance_variable_defined?(:@auto)
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
    output = set_mode(mode_params) do
      mode_result, mode_string = get_drm_test_result("#{title_string} mode test")
      test_result &= mode_result == FrameworkConstants::Result[:pass]
      result_string += mode_string
    end
  end
  
  if output.match(/error|cut\s*here/im)
    result_string += output
    test_result &= false
  else
    result_string += 'negative test' if output.match(/Invalid\s*argument/im)
    test_result &= true
  end

  sf_result = test_result ? FrameworkConstants::Result[:nry] : FrameworkConstants::Result[:fail]

  while(sf_result == FrameworkConstants::Result[:nry])
    fps_res, output = run_sync_flip_test(mode_params) do
      sf_result, sf_string = get_drm_test_result("#{title_string} sync flip test")
      test_result &= sf_result == FrameworkConstants::Result[:pass]
      result_string += ', ' + sf_string if sf_string != ''
    end 
  end
  if output.match(/error|cut\s*here/im)
    result_string += ", #{output}"
    test_result &= false
  else
    result_string += ', negative test' if output.match(/Invalid\s*argument/im)
    test_result &= true
    fps_res = true
  end
  if !fps_res
    result_string += ", fps Failed in sync flip test "
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




