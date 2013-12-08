# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../default_test_module'
require File.dirname(__FILE__)+'/drm_utils'   

include LspTestScript

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt) #making sure that the board is ok
  test_result = true
  result_string = ''
  drm_info = get_properties()
  drm_info['Connectors:'].each do |connector|
    drm_info['Encoders:'].each do |encoder|
      next if encoder['id'] != connector['encoder']
      drm_info['CRTCs:'].each do |crtc|
      next if crtc['id'] != encoder['crtc']
        if !@test_params.params_control.instance_variable_defined?(:@test_type) ||
               @test_params.params_control.test_type[0].strip().downcase() != 'properties'
          connector['modes:'].each do |mode|
            formats = ['default']
              formats = @test_params.params_chan.formats if @test_params.params_chan.instance_variable_defined?(:@formats)
              formats.each do |format|
                result_string += "conn: #{connector['id']}, enc: #{encoder['id']}, " \
                               "crtc: #{crtc['id']}, 'mode': #{mode.to_s}, " \
                               "format: #{format} => "
              
                  mode_params = {'connectors_ids' => [connector['id']], 
                                 'crtc_id' => crtc['id'], 
                                 'mode' => mode['name'],
                                 'framerate' => mode['refresh (Hz)']}
                  mode_params['format'] = format if format != 'default'
                  res, res_string = run_mode_test(mode_params)
                  test_result &= res
                  result_string += res_string + "\n\n"
              end
          end
        else
            {'CRTC' => crtc, 'Connector' => connector}.each do |type, drm_obj|
              res, res_string = run_properties_test(type, drm_obj)
              test_result &= res
              result_string += res_string + "\n\n"
            end
        end
      end
    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], result_string)
  else
    set_result(FrameworkConstants::Result[:fail], result_string)
  end
end

#Function to ask the user is a given mode test worked, takes
#  test_string, string with an informational message related to the test
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test 
def get_drm_test_result(test_string)
  sleep(5)
  print "Did the test display correctly [y/n]?"
  answer = STDIN.gets()
  if answer.downcase().start_with?('y')
    return [true, " #{test_string} Passed"]
  else
    print "Failure reason? "
    reason = STDIN.gets()
    return [false, " #{test_string} Failed: #{reason.strip()}"]
  end
end

#Function to run the drm mode tests supported by modetest, takes
#  mode_params, a hash whose entry are the ones required by drm_utils set_mode method
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test  
def run_mode_test(mode_params)
  test_result = true
  result_string = ''
  set_mode(mode_params) do
    mode_result, mode_string = get_drm_test_result('set mode test')
    test_result &= mode_result
    result_string += mode_string
  end
  fps_res = run_sync_flip_test(mode_params) do
    sf_result, sf_string = get_drm_test_result('sync flip test')
    test_result &= sf_result
    result_string += ', ' + sf_string
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
  obj_id = drm_obj['id']
  props_hash = drm_obj['props:']
  test_string = "#{type}-#{obj_id} => "
  props_hash.each do |prop, prop_info|
    prop_name = prop.match(/([A-z]+)/).captures[0].strip()
    case prop_info['flags:'].strip()
      when 'enum'
        prop_info['enums:'].each do |e_name, e_val|
          set_property(obj_id, prop_name, e_val)
          res, res_string = get_drm_property_test_result(prop_name, e_val, e_name)
          test_result &= res
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      when 'bitmask'
        prop_info['values:'].each do |b_name, b_val|
          set_property(obj_id, prop_name, b_val)
          res, res_string = get_drm_property_test_result(prop_name, b_val, b_name)
          test_result &= res
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      when 'range'
        prop_info['values:'].each do |current_val|
          set_property(obj_id, prop_name, current_val)
          res, res_string = get_drm_property_test_result(prop_name, current_val)
          test_result &= res
          test_string += ' ,' + res_string
        end
        set_property(obj_id, prop_name, prop_info['value:'])
      else 
         test_string += ", Nothing to do for #{prop}, it is #{prop_info['flags:']}"
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
  meaning_string = val_meaning ? "(#{val_meaning})" : ''
  print "Did the property #{prop} value #{prop_val}#{meaning_string} function correctly [y/n]?"
  answer = STDIN.gets()
  if answer.downcase().start_with?('y')
    return [true, " Property #{prop} value #{prop_val}#{meaning_string} Passed"]
  else
    print "Failure reason? "
    reason = STDIN.gets()
    return [false, " Property #{prop} value #{prop_val}#{meaning_string} Failed: #{reason.strip()}"]
  end
end




