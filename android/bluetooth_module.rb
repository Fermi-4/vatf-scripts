require File.dirname(__FILE__)+'/android_test_module'

include AndroidTest

module BluetoothModule

def run_bluetooth_test()
  counter = 0  
  disable_bluetooth() 
  number_of_failures = 0
  cmd = "logcat  -c"
  #clear old logs 
  send_adb_cmd cmd
  send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
  sleep 1
  data = send_adb_cmd @test_params.params_chan.cmd[0]
  if !data.to_s.include?("ok")
   puts "command  enable failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\nCommand enable failed")
   exit
  end
  puts "Launch wireless setup Intent"
  # select wireles interface
  @test_params.params_chan.select_wireless.each{|wireless|
   send_events_for(get_events(wireless))
   send_events_for(get_events('top'))
  }
  puts "wireless  enabled "
  sleep 20
  #puts "Doing wireless setting "
  sleep 1
  puts "configuring wireless"
  @test_params.params_chan.configure_wireless.each{|config|
  send_events_for(get_events(config))
  sleep 2
  send_events_for("__back__")
  send_events_for(get_events('top'))
  }
  
 #check for connectivity 
 status =   check_bluetooth_connectivity(counter)
 if   status == 1 
  puts "bleutooth connection pass"
 else
  puts "bleutooth connection fail"
 end 
 return status 

end 


def check_bluetooth_connectivity(counter)
 puts "CHECKING BLUETOOTH CONNECTIVITY!"
 sleep 5
 check_bluetooth = `hcitool scan`
 puts @test_params.params_chan.wireless_name[0]
 if !check_bluetooth.to_s.include?(@test_params.params_chan.wireless_name[@test_params.params_chan.wireless_name.length - 1]) 
  puts "DEVICE NOT DETECTED:failure"
  @results_html_file.add_paragraph("Counter=#{counter}\n Bluetooth DEVICE  DETECTION:failure\n")
   @results_html_file.add_paragraph("Counter=#{counter}\n#{check_bluetooth}")
  return 0
 end 
 return 1 
end

def check_bluetooth_disconnectivity(counter)
 puts "CHECKING BLUETOOTH DISCONNECTIVITY!"
 sleep 15
 check_bluetooth = `hcitool scan`
 if check_bluetooth.to_s.include?(@test_params.params_chan.wireless_name[0]) 
  puts "DEVICE  DETECTED:failure"
  @results_html_file.add_paragraph("Counter=#{counter}\n WRONG STATE Bluetooth DEVICE  DETECTED:failure\n")
  @results_html_file.add_paragraph("Counter=#{counter}\n#{check_bluetooth}")
  return 1  
 end
 return 0  
end

def disable_bluetooth()
puts "DISABLING BLUETOOTH!"
 cmd = "logcat  -c"
 #clear old logs 
 send_adb_cmd cmd
 cmd = "logcat  -d -s  bluedroid"
 response = "junk data"
 count = 0
 # in this while loop, make sure to put the bluetooth in the know state 
 while !response.to_s.include?("Stopping")
  count = count + 1
  send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
  sleep 1
  data = send_adb_cmd @test_params.params_chan.cmd[0]
  if !data.to_s.include?("ok")
   puts "command check failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\ncommand check failed!")
   exit
  end 
  sleep 1
  send_events_for(get_events(@test_params.params_chan.select_wireless[@test_params.params_chan.wireless_name.length - 1]))
  sleep 20
  response = send_adb_cmd cmd
  if (count > 5)
   puts "couldn't set state to disable"
   break
  end 
 end # end of  whileloop  
end 

end 
