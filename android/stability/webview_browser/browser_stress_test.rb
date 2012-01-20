require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
require File.dirname(__FILE__)+'/../../browser_module'
include AndroidTest
include AndroidKeyEvents
include BrowserStressModule



def run
  puts "ENTERING FUNCTION RUN"
  send_events_for("__back__") 
  cmd = "logcat  -c"
  send_adb_cmd cmd
  @equipment['dut1'].connect({'type'=>'serial'})
  puts "Connected to Serial ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.enable_eth[0])
  puts "Enabling ETH ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.enable_dhcp[0])
  puts "Enabling DHCP ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.set_dns[0])
  puts "Setting DNS ..."
  sleep 0.5
  @equipment['dut1'].send_cmd(@test_params.params_chan.set_proxy[0])
  puts "Setting PROXY ..."
  sleep 0.5
  cmd = cmd = "install " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.app_name[0]
  puts "installing application"
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil and !data.to_s.include?("INSTALL_FAILED_ALREADY_EXISTS")
   puts "#{data}"
   exit 
  end 
  number_of_failures = 0
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  clear_dialog = ["__directional_pad_down__","__enter__"]
  web_address = get_webaddress(@test_params.params_chan.webaddress[0])
  counter = 0
  interation_counter = 0
  @test_params.params_chan.iterations[0].to_i.times do
  interation_counter  = interation_counter + 1
  @test_params.params_chan.webaddress.each{|website|
  counter = counter + 1 
  cmd = "logcat  -d -c"
  data = send_adb_cmd  cmd
  sleep 1 
  cmd = @test_params.params_chan.intent[0] + " -e webaddress " + website + " -e testtype " +  @test_params.params_chan.test_type[0] 
  data = send_adb_cmd  cmd
  sleep @test_params.params_chan.delay[0].to_i
  cmd = "logcat  -d -s ActivityManager"
  response = send_adb_cmd cmd
  display_time = 0
  time = "" 
  if response.include?("Displayed") 
    time = response.scan(/Displayed\s*com.ti.android.webbrowserstress\/.WebBrowserStressActivity:\s*\+([0-9]+\w[0-9]+)ms/)[0][0]
  else
   @results_html_file.add_paragraph("Website=#{website} Not Displayed\n#{response}") 
  end  
  if time.include?("s")
   largtime = time.split("s")
   display_time = largtime[0].to_i * 1000 + largtime[1].to_i
  else 
   display_time =  time.to_i
  end 

  if display_time > 2000
  number_of_failures = number_of_failures + 1
  end
  sleep 60
  cmd = "logcat -d -s InputDispatcher"
  response = send_adb_cmd cmd
  #if response.scan(/Application\s+is\s+not\s+responding/) == nil 
   send_events_for(clear_dialog) 
  #else
   sleep 1 
   send_events_for(put_screen_home) 
  #end 
 #At the end let's check if there were exception 
  if response.include?("Exception") 
  @results_html_file.add_paragraph("Website=#{website} Not Displayed\n#{response}") 
  end 
 }
  
 end 

 puts "Total number of failures #{number_of_failures.to_f}"
 total_iteration =  @test_params.params_chan.iterations[0].to_f * @test_params.params_chan.webaddress.length 
 success_rate = ((total_iteration - number_of_failures.to_f)/ @test_params.params_chan.iterations[0].to_f)*100.0
 puts "PASS #{success_rate}"
 if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Web  Browser Stress Test=#{success_rate}")
 else
    set_result(FrameworkConstants::Result[:fail], "Web  Browser Stress Test=#{success_rate}")
 end

end 

