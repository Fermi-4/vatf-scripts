# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/drm_base'   



#Function to run the drm mode tests supported by modetest, takes
#  mode_params, a hash whose entry are the ones required by drm_utils set_mode method
#  plane_params, (Optional) use to defined a plane that will be overlay on top of the image,
#                the parameter is a hash whose entries are the one required by 
#                drm_utils set_mode method
#  perf_data, Array for collecting performance data
#Returns an array containing [boolean, res_string] where the boolean signals if
#the test passed (true) or failed (false); and the res_string is an informational
#string regarding the result of the test. It also populates perf_data with any
#performance data collected  
def run_mode_test(mode_params, perf_data=[])
  test_result = true
  result_string = ''
  metric_name = "#{mode_params[0]['connectors_names'].join('-')}-#{mode_params[0]['mode']}@#{mode_params[0]['framerate']}-" \
                "#{mode_params[0]['format']}"

  fps_res = nil
  fps_data = nil
  output = ''
  use_memory(4096 * 2160 * 26 * 4) do
    fps_res, fps_data, output = run_perf_sync_flip_test(mode_params) do |def_timeout|
      sleep [60, def_timeout].max
    end
  end

  perf_data << {'name' => metric_name,
                'units' => 'fps',
                'values' => fps_data}
  if output.match(/Invalid\s*argument/im)
    result_string = "negative test"
    fps_res = true
  elsif !fps_res
    result_string = "fps Failed in sync flip test "
  else
    result_string = "fps Passed in sync flip test " 
  end
  test_result &= fps_res
  [test_result, result_string]
end



