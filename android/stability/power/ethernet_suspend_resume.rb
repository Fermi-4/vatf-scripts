require File.dirname(__FILE__)+'/suspend_resume_default'


def pre_suspend_test()
  initial_value = run_ethernet_test(server = @equipment['server1'],@test_params.params_control.min_bw[0].to_f,true)[0]
  if initial_value > @test_params.params_control.min_bw[0].to_f
    puts "Presuspend Test Pass!"
  else
    puts "Presuspend Test Fail!"
  end  
  return initial_value
end 

def on_resume_disable_stay_awake(dut1=@equipment['dut1'])
  puts "Disable wake locke setting"
  disable_stay_awake_on_resume(dut1)
end 


def on_resume_test(initial_bw_value,initial_fps_value)
  status = run_ethernet_test(server = @equipment['server1'],initial_bw_value,false)[1]
end 


