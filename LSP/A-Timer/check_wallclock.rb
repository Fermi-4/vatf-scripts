require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  wait_time = @test_params.params_control.wait_time[0].to_f
  acceptable_deviation = @test_params.params_control.acceptable_deviation[0].to_f
  t1 = get_time_in_seconds
  sleep wait_time
  t2 = get_time_in_seconds
  deviation = (t2 - t1 - wait_time).abs
  if deviation >  (wait_time * acceptable_deviation)
    set_result(FrameworkConstants::Result[:fail], "DUT time is deviating more than #{acceptable_deviation}")
  else
    set_result(FrameworkConstants::Result[:pass], "DUT time is not deviating more than #{acceptable_deviation}")
  end
end

def clean
  self.as(LspTestScript).clean
end

def get_time_in_seconds(device=@equipment['dut1'])
  device.send_cmd("date +%s", /#{device.prompt}/, 2)
  t = device.response.match(/(^\d+)/).captures
  raise "Could not get date from #{device.name}" if !t 
  return t[0].to_f
end
