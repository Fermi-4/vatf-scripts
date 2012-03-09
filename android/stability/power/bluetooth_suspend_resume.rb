require File.dirname(__FILE__)+'/suspend_resume_default'


def pre_suspend_test()
  initial_value = run_bluetooth_test()
  return initial_value
end 

def on_resume_disable_stay_awake(dut1=@equipment['dut1'])
  puts "Disable wake locke setting"
  disable_stay_awake_on_resume(dut1)
end 


def on_resume_test(initial_test_status,initial_fps_value)

  if initial_test_status == 0
   puts "bluetooth test before suspsnd failed!"
   return 0
  end   
  send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
  sleep 1
  data = send_adb_cmd @test_params.params_chan.cmd[0]
  if !data.to_s.include?("ok")
   puts "command  enable failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\nCommand enable failed")
   exit
  end
  puts "Launch wireless setup Intent"
  
  sleep 1
  puts "configuring wireless"
  @test_params.params_chan.configure_wireless.each{|config|
  send_events_for(get_events(config))
  sleep 2
  send_events_for("__back__")
  send_events_for(get_events('top'))
  }
  
 status =   check_bluetooth_connectivity(initial_test_status)
 if   status == 1 
  puts "On resume bleutooth connection pass"
 else
  puts "On resume bleutooth connection fail"
 end 
 return status
end 


