require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
require File.dirname(__FILE__)+'/../../wireless_events_module'
require File.dirname(__FILE__)+'/../../netperf_module'
require File.dirname(__FILE__)+'/../../wlan_module'
    
include AndroidTest
include AndroidKeyEvents
include EventsModule
include NetperfModule
include WlanModule


def setup
  @equipment['dut1'].connect({'type' => 'serial'})  
  send_adb_cmd("shell svc power stayon true") 
  send_events_for('__menu__')
  if @test_params.params_chan.instance_variable_defined?(:@lan_wlan_data_video) 
   enable_wlan
  end 
end


def run
  counter = 0  
  if !@test_params.params_chan.instance_variable_defined?(:@lan_data_video)
    disable_bluetooth() if @test_params.params_chan.wireless[0] == "bluetooth"  or @test_params.params_chan.wireless[0] == "both"
    disable_wifi()  if @test_params.params_chan.wireless[0] == "wifi"  or @test_params.params_chan.wireless[0] == "both"
    clear_configured_access if @test_params.params_chan.wireless[0] == "wifi" or @test_params.params_chan.wireless[0] == "both"
  end 
  #the wireless device is disabled, now let's start the test  for the number of iterations given in the test case. 
  number_of_failures = 0
  @test_params.params_chan.iterations[0].to_i.times do
 puts "Number ot iterations excuted so far #{counter}"
  cmd = "logcat  -c"
  send_adb_cmd cmd
  each_iteration_failure = Array.new  
  counter = counter + 1 
  if !@test_params.params_chan.instance_variable_defined?(:@lan_data_video)
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
  puts "Select wireless interface"
    @test_params.params_chan.select_wireless.each{|wireless|
   send_events_for(CmdTranslator.get_android_cmd({'cmd'=>wireless, 'version'=>@equipment['dut1'].get_android_version }))
   puts "sellecting wireless interface: #{wireless}"
   sleep 2
   send_events_for("__back__")
      send_events_for(get_events('top'))
   }
   sleep 2
  puts "Configure wireless interface"
   @test_params.params_chan.configure_wireless.each{|config|
  puts "Configuring  wireless interface: #{config}"
    send_events_for(CmdTranslator.get_android_cmd({'cmd'=>config, 'version'=>@equipment['dut1'].get_android_version }))
  sleep 2
  send_events_for("__back__")
     send_events_for(get_events('top'))
   }

  puts "wireless configured "
end  # none wireless stress test lan_data_video 

  if !@test_params.params_chan.instance_variable_defined?(:@lan_data_video)
 #check for connectivity 
    each_iteration_failure <<  check_bluetooth_connectivity(counter) if @test_params.params_chan.wireless[0] == "bluetooth"   or    @test_params.params_chan.wireless[0] == "both"
   each_iteration_failure <<   check_wifi_connectivity(counter) if @test_params.params_chan.wireless[0] == "wifi"  or @test_params.params_chan.wireless[0] == "both"
  end 

 if @test_params.params_chan.instance_variable_defined?(:@data_video) or @test_params.params_chan.instance_variable_defined?(:@lan_data_video)
    stress_result = run_stress 
  end
 
  if !@test_params.params_chan.instance_variable_defined?(:@lan_data_video)
   send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
   sleep 1
   data = send_adb_cmd @test_params.params_chan.cmd[0]
   if !data.to_s.include?("ok")
   puts "command failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\nCommand Failed")
   exit
  end 

  sleep 1
  @test_params.params_chan.select_wireless.each{|wireless|
   send_events_for(CmdTranslator.get_android_cmd({'cmd'=>wireless, 'version'=>@equipment['dut1'].get_android_version }))
  send_events_for("__back__")
   send_events_for(get_events('top'))
  }

 each_iteration_failure <<   check_bluetooth_disconnectivity(counter) if  @test_params.params_chan.wireless[0] == "bluetooth" or @test_params.params_chan.wireless[0] == "both"
  each_iteration_failure <<   check_wlan_status(counter) if  @test_params.params_chan.wireless[0] == "wifi" or @test_params.params_chan.wireless[0] == "both"

  if @test_params.params_chan.wireless[0].to_s.strip == "wifi"  or  @test_params.params_chan.wireless[0].to_s.strip == "both" 
   puts "CLEARING AP ON COUNTER INCREASE"
   clear_configured_access
  end 

 end # no wireless lan_data_video

  array_sum = 0
  each_iteration_failure.each{|elem|
  array_sum = array_sum +  elem 
}

 if !@test_params.params_chan.instance_variable_defined?(:@lan_data_video)

  if array_sum  > 0
    number_of_failures = number_of_failures + 1 #only one is added to per iteration
  if  @test_params.params_chan.wireless[0] == "bluetooth"
  resp = send_adb_cmd "logcat  -d -s  bluedroid"
   @results_html_file.add_paragraph("Counter=#{counter}\n#{resp}") 
  elsif @test_params.params_chan.wireless[0] == "both"
  resp = send_adb_cmd "logcat  -d -s  bluedroid"
   @results_html_file.add_paragraph("Counter=#{counter}\n#{resp}") 
   resp =send_adb_cmd "logcat  -d -s wpa_supplicant"
   @results_html_file.add_paragraph("Counter=#{counter}\n#{resp}")
  else 
   resp =send_adb_cmd "logcat  -d "
   @results_html_file.add_paragraph("Counter=#{counter}\n#{resp}")
  end
 end 
end # no wireless lan_data_video 
 puts "Number ot failures so far are: #{number_of_failures.to_f}"
end  # end for loop
 puts "Total number of failures #{number_of_failures.to_f}"
 success_rate = ((@test_params.params_chan.iterations[0].to_f - number_of_failures.to_f)/ @test_params.params_chan.iterations[0].to_f)*100.0
 puts "PASS #{success_rate}"
 if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Success Wireless Enable Disable Stress Test=#{success_rate}")
 else
    set_result(FrameworkConstants::Result[:fail], "Success Wireless Enable Disable Stress Test=#{success_rate}")
 end
end 

def clear_configured_access
  puts "CLEARING ACCESS POINTS FROM DATABASE" 
  send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
  data = send_adb_cmd @test_params.params_chan.cmd[0]
  if !data.to_s.include?("ok")
   puts "command failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\nCommand Failed")
   exit
  end 
  sleep 1
 # select wireles interface
 puts "SELECTING WIFE"
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.select_wireless[0], 'version'=>@equipment['dut1'].get_android_version }))
  sleep 2
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.select_setting[0], 'version'=>@equipment['dut1'].get_android_version }))
  sleep 2
  sleep 1
  send_events_for(get_events(@test_params.params_chan.two_step_down[0]))
  net_list = send_adb_cmd("shell wpa_cli list_networks")
 puts net_list
  nets_info = net_list.lines.to_a
  lists = nets_info.length - 2
 puts nets_info
  sleep 2
  for i in(1..lists)  
   send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.clear_access[0], 'version'=>@equipment['dut1'].get_android_version }))
  end 
  send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
  data = send_adb_cmd @test_params.params_chan.cmd[0]
  if !data.to_s.include?("ok")
   puts "command failed!"
   @results_html_file.add_paragraph("Counter=#{counter}\nCommand Failed")
   exit
  end 
  sleep 1
 # select wireles interface
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.select_wireless[0], 'version'=>@equipment['dut1'].get_android_version }))
 puts "cleared WIFI WIFI WIFI WIFI"

 end 

def check_wifi_connectivity(counter)
 puts "CHECKING WIFI CONNECTIVITY!"
 send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.go_top_access[0], 'version'=>@equipment['dut1'].get_android_version }))
 net_list = send_adb_cmd("shell wpa_cli list_networks")
 puts net_list
 nets_info = net_list.lines.to_a
 lists = nets_info.length - 2
 for i in(1..lists)
   resp =send_adb_cmd "logcat  -d -s wpa_supplicant"
   if !resp.include?(@test_params.params_chan.wireless_name[0])  and resp.include?("Associated")
   puts "NAMED WIRELESS ACCESS NOT DETECTED, TRY to CONNECT\n"
   @results_html_file.add_paragraph("Counter=#{counter}\nNAMED WIRELESS ACCESS NOT DETECTED, TRY to CONNECT\n #{resp}\n")
   send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.connect_access[0], 'version'=>@equipment['dut1'].get_android_version }))
   sleep 10
  end 
  if check_access_status(counter) == 1 and check_ping(counter) == 1
  return 0 
  end 
 end
 @results_html_file.add_paragraph("Counter=#{counter}\nWifi connectivity test failed.")
 return 1 
end

def check_ping(counter)
 puts "CHECKING PING!"
   ping_data = ""
   sleep 5
   net_list = send_adb_cmd("shell netcfg")
   nets_info = net_list.lines.to_a
  net_id = -1 
    nets_info.each do |current_info|
      puts "current_info #{current_info}" 
      if current_info.include?("wlan0") and current_info.include?("UP")
       response = send_adb_cmd "shell getprop wifi.interface" 
       dut_ip = send_adb_cmd "shell getprop dhcp.#{response}.ipaddress"
       server_lan_ip = get_server_lan_ip(dut_ip)
       ping_data = send_adb_cmd "shell ping -c3 #{server_lan_ip}"
       if ping_data.scan(/3\s+packets\s+transmitted,\s+3\s+received/) != nil
        return 1 
       end
      end 
   end 
  @results_html_file.add_paragraph("Counter=#{counter}\n#{net_list}")
 return 0 
end   

def check_access_status(counter)
 puts "CHECKING ACCESS IS CURRENT!"
  sleep 15
  net_list = send_adb_cmd("shell wpa_cli list_networks")
  puts net_list
  nets_info = net_list.lines.to_a
  net_id = -1 
    nets_info.each do |current_info|
      if current_info.include?(@test_params.params_chan.wireless_name[0]) and current_info.include?("CURRENT")
      return 1 
      end 
   end 
 @results_html_file.add_paragraph("Counter=#{counter}\n#{net_list}")
 return 0 
end

def check_wlan_status(counter)
 puts "CHECKING WLAN STATUS!"
   sleep 10
   net_list = send_adb_cmd("shell netcfg")
   puts net_list
   nets_info = net_list.lines.to_a
  net_id = -1 
  nets_info.each do |current_info|
      if current_info.include?("wlan0")
      @results_html_file.add_paragraph("Counter=#{counter}\n#{net_list}") 
        return 1 
      end
  end 
 return 0 
end


def check_bluetooth_connectivity(counter)
 puts "CHECKING BLUETOOTH CONNECTIVITY!"
 sleep 5
 check_bluetooth = `hcitool scan`
 model = send_adb_cmd("shell getprop ro.product.model").strip
 check_bluetooth  = check_bluetooth
 if !check_bluetooth.to_s.include?(model)  
  puts "DEVICE NOT DETECTED:failure"
  @results_html_file.add_paragraph("Counter=#{counter}\n Bluetooth DEVICE  DETECTION:failure\n")
   @results_html_file.add_paragraph("Counter=#{counter}\n#{check_bluetooth}")
  return 1
 end 
 return 0 
end

def check_bluetooth_disconnectivity(counter)
 puts "CHECKING BLUETOOTH DISCONNECTIVITY!"
 send_events_for('__menu__') 
 sleep 15
 check_bluetooth = `hcitool scan`
 check_bluetooth  = check_bluetooth.downcase
 puts check_bluetooth
 if check_bluetooth.to_s.include?(@test_params.params_chan.wireless_name[@test_params.params_chan.wireless_name.length - 1]) 
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
  send_adb_cmd cmd
  cmd = "logcat -d -s "  + CmdTranslator.get_android_cmd({'cmd'=>'bluetooth_filter', 'version'=>@equipment['dut1'].get_android_version })
  response = "junk data"
  count = 0
 # in this while loop, make sure to put the bluetooth in the know state 
  while !response.to_s.include?("13 -> 10")
    count = count + 1
    send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
    sleep 1
    data = send_adb_cmd @test_params.params_chan.cmd[0]
 puts data
    if !data.to_s.include?("ok")
      puts "command check failed!"
 @results_html_file.add_paragraph("Counter=#{counter}\ncommand check failed!")
      exit
    end 
    sleep 1
    select_wireless =  @test_params.params_chan.select_wireless[@test_params.params_chan.wireless_name.length - 1]
    send_events_for(CmdTranslator.get_android_cmd({'cmd'=>select_wireless, 'version'=>@equipment['dut1'].get_android_version }))
  sleep 20
   response = send_adb_cmd cmd
   puts "response #{response}"
 
  if (count > 5)
   puts "couldn't set state to disable"
   break
  end 
 end 
end 


def disable_wifi()
 puts "DISABLING WIFI!"
 cmd = "logcat  -c"
 send_adb_cmd cmd
 cmd = "shell netcfg"
 count = 0
 response = send_adb_cmd cmd
 # in this while loop, make sure to put the bluetooth in the know state 
 while response.to_s.include?("wlan0")
   count = count + 1
   send_events_for(get_events(@test_params.params_chan.put_screen_home[0]))
   sleep 1
   data = send_adb_cmd @test_params.params_chan.cmd[0]
   if !data.to_s.include?("ok")
     puts "command check failed!"
     exit
   end 
  sleep 1
  send_events_for(CmdTranslator.get_android_cmd({'cmd'=>@test_params.params_chan.select_wireless[0], 'version'=>@equipment['dut1'].get_android_version }))
  sleep 10 
  response = send_adb_cmd cmd
  sleep 5
  if (count > 5)
    puts "couldn't set state to disable"
   break
  end 
 end 
 puts "WIFI DISABLED DISABLED"
end 


def run_stress
    bw = ""
    fps = ""
    wlan_test = ""
    if @test_params.params_chan.instance_variable_defined?(:@lan_data_video)
    wlan_test   = Thread.new() {bw = start_lan_netperf}
    else 
    wlan_test   = Thread.new() {bw = start_netperf}
    end 
    video_test  = Thread.new() {fps = play_video}
    wlan_test.join
    video_test.join
    min_bw = @test_params.params_chan.min_bw[0].to_f
    if bw.to_f  > min_bw and fps > 28 
    return 1 
    end   
    return 0  
end 


