require File.dirname(__FILE__)+'/power_events_module'
include PowerEventsModule
module PowerModule

def set_alarm(dut1 = @equipment['dut1'] )
  data = send_adb_cmd @test_params.params_chan.set_alarm_cmd[0]
  if !data.to_s.include?("ok")
    puts "command  enable failed!"
    exit
  end
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>'alarm_select_minute', 'version'=>dut1.get_android_version }))
  for i in (1..@test_params.params_chan.suspend_duration[0].to_i)
   send_events_for(get_events_sequence(@test_params.params_chan.alarm_set_minute[0]))
  end 
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>'alarm_save_minute', 'version'=>dut1.get_android_version }))
end #function end

def alarm_delete(dut1 = @equipment['dut1'])
  send_events_for(get_events_sequence(@test_params.params_chan.go_home[0]))
  data = send_adb_cmd @test_params.params_chan.alarm_delete_cmd[0]
  if !data.to_s.include?("ok")
   puts "command  enable failed!"
   exit
  end
  sleep 1
  send_events_for(get_events_sequence(@test_params.params_chan.step_down[0]))
  for i in (1..1)
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>'alarm_delete', 'version'=>dut1.get_android_version }))
  end 
  sleep 1
  send_events_for(get_events_sequence(@test_params.params_chan.go_home[0]))
end

def mean(a)
  array_sum = 0.0
  a.each{|elem|
   array_sum = array_sum + elem.to_f
  }
  mean = array_sum/a.size
  return mean
end

end 



