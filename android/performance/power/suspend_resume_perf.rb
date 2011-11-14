
require File.dirname(__FILE__)+'/../../power_events_module'
require File.dirname(__FILE__)+'/../../power_module'
require File.dirname(__FILE__)+'/../../android_test_module'

include AndroidTest
include PowerEventsModule
include PowerModule

def setup
  puts "\n====================\nPATH=#{ENV['PATH']}\n"
  #super
  # Connect to multimeter
  @equipment['multimeter'].connect({'type'=>'serial'})
   enable_ethernet 

  if @test_params.params_chan.ti_multimeter[0] == "no" 
      require File.dirname(__FILE__)+'/../../../lib/multimeter_power'
      self.class_eval('include MultimeterModule')
  else 
      require File.dirname(__FILE__)+'/../../../lib/ti_meter_power'
      self.class_eval('include TiMeterPower')
 end 


end



def run
  perf = []
  fps_values = Array.new()
  result_data = Hash.new()
  graphics_intents = Array.new()
  #install graphics application
  install_android_graphics_apps()
  #install media
  if @test_params.params_chan.instance_variable_defined?(:@video_intent) or @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
 # exit 
  end

  elsif @test_params.params_chan.instance_variable_defined?(:@video_intent) and  @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
  # exit 
  end
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[1]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
  # exit 
  end
 end 

  #get all the packages and music and video
  packages = `adb shell pm list packages | grep GL`
  packages.split("\r").each{|package|
  graphics_intents << @test_params.params_chan.intent_cmd[0].to_s.strip+ " " +  package.gsub(/package:/,"").to_s.strip + "/.".to_s.strip + package.gsub(/package:/,"").gsub(/com.powervr./,"").to_s.strip
 if @test_params.params_chan.instance_variable_defined?(:@music_intent) and !@test_params.params_chan.instance_variable_defined?(:@music_intent) 
  puts "ONE "
  graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0] 
 elsif  @test_params.params_chan.instance_variable_defined?(:@video_intent) and !@test_params.params_chan.instance_variable_defined?(:@music_intent)
     puts "TWO "
   graphics_intents <<  @test_params.params_chan.video_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]  
 elsif @test_params.params_chan.instance_variable_defined?(:@video_intent) and  @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  puts "THREE "
 graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0] 
   graphics_intents <<  @test_params.params_chan.video_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[1]

end 
 break
}
  
  if @test_params.params_chan.ti_multimeter[0] == "no" 
  # Configure multimeter 
  @equipment['multimeter'].configure_multimeter(@test_params.params_chan.sample_count[0].to_i)
  end 
  if @test_params.params_chan.instance_variable_defined?(:@disabled_cpu_idle_modes)
    @test_params.params_chan.disabled_cpu_idle_modes.each do |idle_mode|
      data = send_adb_cmd("shell \"echo 1 > /debug/pm_debug/#{idle_mode.strip.downcase}\"")
        puts "\n\n======= DEBUG =======\n" +  send_adb_cmd("shell cat /debug/pm_debug/#{idle_mode.strip.downcase}")
    end
  end
  
  #the timeout must be passed as parameter.  
  if @test_params.params_chan.instance_variable_defined?(:@uart_mode)
  puts "TURNING OF CPU/SUSPEND"
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.0/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.1/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.2/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.3/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"sleep 10\"")
  end 

  #I am enabling smart reflex for suspend/resume test area, while running the others with default smart reflex configuration. 
 
  if @test_params.params_chan.instance_variable_defined?(:@bypass_dut)
    # Don't configure DUT, user will set it in the right state
    # before running this testb
    puts "configure DUT, user must set it in the right state"
    sleep @test_params.params_chan.bypass_dut_wait[0].to_i if @test_params.params_chan.instance_variable_defined?(:@bypass_dut_wait)
  else
    dutThread = Thread.new {run_test(@test_params.params_chan.test_option[0]) } if @test_params.params_chan.instance_variable_defined?(:@test_option)
 if @test_params.params_chan.instance_variable_defined?(:@intent)
    dutThread = Thread.new {run_test(nil, @test_params.params_chan.intent[0]+ " #{@test_params.params_chan.target_file_path[0]}") }  if @test_params.params_chan.ti_multimeter[0] == "no" 
 end 

    
 end
 #Set wake time and set no wake lock 
  puts "No wake locke setting"
  counter = 0
  set_no_wakelock(counter)
  number_of_failures = 0
  power_readings = Hash.new()
  endable_fps = "setprop debug.video.showfps 1"
  cmd = "shell " + endable_fps
  #send fps enable command 
  data = send_adb_cmd cmd
  @test_params.params_chan.iterations[0].to_i.times do
  puts "Alarm Deleting"
  alarm_delete() 
  counter = counter + 1
  puts "Number ot iterations excuted so far #{counter}"
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  result_data = play_graphic_media(graphics_intents)
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  send_events_for(put_screen_home) 
  puts "Alarm Setting "
  set_alarm()
  puts "Waiting for suspending message."
  @equipment['dut1'].wait_for(/Suspending\s+console/, 100) 
  #puts @equipment['dut1'].send_cmd("netcfg", /Suspending\s+console/, 100, false)
  sleep 5
  if @test_params.params_chan.ti_multimeter[0] == "no" 
  # Get voltage values for all channels in a hash
    volt_readings = run_get_multimeter_output(@equipment['multimeter'])
  # Calculate power consumption
  power_readings = calculate_mean_power_consumption(volt_readings)
  
  if result_data['fps'].length == 0 or  power_readings['all_vvd1'] > 0.01  or power_readings['all_vvd2'] > 0.01 or power_readings['all_vvd1_vdd2'] > 0.01 #puts power pass fial as configurable 
   number_of_failures = number_of_failures + 1 #only one is added to per iteration
   perf = save_results(power_readings,result_data['fps'])
  end 

  else 
   #TI MULTI METER
 @equipment['multimeter'].read_for(num_of_reading - 10)
  # Get voltage values for all channels in a hash
  multimeter_readings = run_get_multimeter_output(@equipment['multimeter'].response)     
  # Calculate power consumption
  power_readings = calculate_power_consumption(multimeter_readings )
  if mean(power_readings['Total_power'])  > 0.5 or  result_data['fps'].length == 0
  number_of_failures = number_of_failures + 1 #only one is added to per iteration
  perf = save_results(power_readings, multimeter_readings)
  end 
 end
  #sleep 40
  sleep 5
  send_events_for(get_events(@test_params.params_chan.alarm_dismis[0]))
  puts "Total number of failures so far #{number_of_failures.to_f}"
 
end # end for iteration loop 

 #End of test 
 puts "Total number of failures #{number_of_failures.to_f}"
 total_iteration =  @test_params.params_chan.iterations[0].to_f * graphics_intents.size 
 success_rate = ((total_iteration - result_data['failurs'].to_f)/ total_iteration)*100.0
 puts "PASS RATE is: #{success_rate}"
 if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Success Suspend-Resume Stress Test=#{success_rate}")
 else
    set_result(FrameworkConstants::Result[:fail], "Success Suspend-Resume Stress Test=#{success_rate}")
 end
  dutThread.join if dutThread
ensure

end

def verify_fps_result(fps)
    total = 0;
    fps.each_index{| i |
    total = total + fps[i].to_i  
    }
    avarage = total/fps.length     
    if avarage < @test_params.params_chan.fps[0].to_i
    return 0
    else 
    return 1
    end 
end 


def play_graphic_media(graphics_intents)
  result_data = Hash.new
  number_of_failures = 0
  counter = 0   
  graphics_intents.each{|intent|
  counter = counter + 1 
  cmd = "logcat  -d -c"
  sleep 1
  data = send_adb_cmd  intent
  sleep @test_params.params_chan.delay[0].to_i
  cmd = "logcat  -d -s ActivityManager"
  response = send_adb_cmd cmd
  display_time = 0
  time = "" 
  if response.include?("Displayed") 
    time = response.scan(/Displayed.*:\s*\+([0-9]+\w[0-9]+)ms/)[0][0]
  else
   number_of_failures = number_of_failures + 1
   @results_html_file.add_paragraph("Intent=#{intent} Not Displayed\n#{response}") 
  end     
  if time.include?("s")
   largtime = time.split("s")
   display_time = largtime[0].to_i * 1000 + largtime[1].to_i
  else 
   display_time =  time.to_i
  end 
  if display_time > 600
   number_of_failures = number_of_failures + 1
   puts "DISPLAY TIME #{number_of_failures}"
  end

  if @test_params.params_chan.instance_variable_defined?(:@video_intent)
   sleep 1
   result_data['fps'] = get_fps
   if result_data['fps'].length != 0 
   fps_result = verify_fps_result(result_data['fps'])
   if fps_result == 0
    number_of_failures = number_of_failures + 1
   end
  else 
  number_of_failures = number_of_failures + 1
  puts "there was no FPS detected"
  end 
 end 
 #break
}       
 # data["instances"] = graphics_intents
  result_data['failurs'] = number_of_failures
  return  result_data 
end

def install_android_graphics_apps()
  graphics_apps = send_host_cmd ("ls #{@test_params.params_chan.apps_host_file_path[0]} | grep OGL")
  puts graphics_apps
  graphics_apps.split("\n").each{|app| 
   cmd = "install " + @test_params.params_chan.apps_host_file_path[0] + "/" + app
  data = send_adb_cmd cmd
 }
end














