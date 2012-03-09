require File.dirname(__FILE__)+'/suspend_resume_default'


def pre_suspend_test()
   bw = ""
  initial_value = run_storage_test(server = @equipment['server1'],bw,true)[0]
  if initial_value.length == 2
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


def on_resume_test(initial_test,initial_fps_value)
  status = run_storage_test_on_resume(server = @equipment['server1'],initial_test,false)[1]
end 


