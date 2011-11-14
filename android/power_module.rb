require File.dirname(__FILE__)+'/power_events_module'
include PowerEventsModule
module PowerModule
def set_alarm()
 data = send_adb_cmd @test_params.params_chan.set_alarm_cmd[0]
 puts data 
 if !data.to_s.include?("ok")
 puts "command  enable failed!"
  @results_html_file.add_paragraph("Counter=#{counter}\nCommand enable failed")
 exit
 end
#send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
send_events_for(get_events(@test_params.params_chan.alarm_select__munite[0]))
for i in (1..@test_params.params_chan.suspend_duration[0].to_i)
send_events_for(get_events(@test_params.params_chan.alarm_set_munite[0]))
end 
send_events_for(get_events(@test_params.params_chan.alarm_save_munite[0]))

end #function end


def set_no_wakelock(counter)
sleep 1
send_events_for(get_events(@test_params.params_chan.go_home[0]))
data = send_adb_cmd @test_params.params_chan.no_stay_awake_cmd[0]
if !data.to_s.include?("ok")
 puts "command  enable failed!"
  @results_html_file.add_paragraph("Counter=#{counter}\nCommand enable failed")
 exit
end
sleep 1
send_events_for(get_events(@test_params.params_chan.no_stay_awake[0]))
sleep 1
send_events_for(get_events(@test_params.params_chan.go_home[0]))
end

def alarm_delete
send_events_for(get_events(@test_params.params_chan.go_home[0]))
data = send_adb_cmd @test_params.params_chan.alarm_delete_cmd[0]
if !data.to_s.include?("ok")
 puts "command  enable failed!"
  @results_html_file.add_paragraph("Counter=#{counter}\nCommand enable failed")
 exit
end
sleep 1
send_events_for(get_events(@test_params.params_chan.step_down[0]))
for i in (1..20)
send_events_for(get_events(@test_params.params_chan.alarm_delete[0]))
end 
sleep 1
send_events_for(get_events(@test_params.params_chan.go_home[0]))
end

def enable_ethernet 
  @equipment['dut1'].connect({'type'=>'serial'})
  puts "Connected to Serial ..."
  sleep 0.5
  @equipment['dut1'].send_cmd("netcfg eth0 up")
  puts "Enabled ETH ..."
  sleep 10
  @equipment['dut1'].send_cmd("netcfg eth0 dhcp")
  puts "Enabled DHCP ..."
  sleep 2
  @equipment['dut1'].send_cmd("setprop service.adb.tcp.port 5555")
  puts "Configured PORT ..."
  sleep 2
  @equipment['dut1'].send_cmd("stop adbd")
  puts "Stop ADBD  ..."
  sleep 2
  @equipment['dut1'].send_cmd("start adbd")
  puts "Start ADBD  ..."
  #@equipment['dut1'].send_cmd("netcfg")
  @equipment['dut1'].send_cmd("netcfg", /eth0\s+UP\s*[0-9]+.[0-9]+.[0-9]+.[0-9]+/, 10, false)
  response = @equipment['dut1'].response
  puts "response #{response}\n"
  dut_ip = response.to_s.scan(/eth0\s+UP\s*([0-9.]+)/) 
  puts "LINE LINE LINE #{dut_ip[0][0]}"
  raise "NO IP alocated for dut" if dut_ip.size == 0
  for i in (1..5)
  system("export ADBHOST=#{dut_ip[0][0]}")
  sleep 1
  count = 0
 # for i in (1..5)
  count = count + 1 
  puts "killing adb server"
  puts system("adb kill-server")
  #sleep 10
  puts "Starting adb server"
  puts system("adb start-server")
  #sleep 20
  device = `adb devices`
  puts device
  if device.to_s.include?("emulator-5554") 
  break 
  end 
 end 
  if count >= 5 
  raise "Device is not listed for ADB connection."
  end 
  

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



