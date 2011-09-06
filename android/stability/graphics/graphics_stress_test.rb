require File.dirname(__FILE__)+'/../android_test_module' 
require File.dirname(__FILE__)+'/../keyevents_module'
#require File.dirname(__FILE__)+'/../graphics_module'
include AndroidTest
include AndroidKeyEvents
#include GraphicsStressModule



def run
  number_of_failures = 0
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  send_events_for(put_screen_home) 
  #graphics_intents = get_graphics_intents(@test_params.params_chan.intents[0])
  graphics_intents = Array.new()
  #install media
  if @test_params.params_chan.instance_variable_defined?(:@video_intent) or @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
   exit 
  end

  elsif @test_params.params_chan.instance_variable_defined?(:@video_intent) and  @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
   exit 
  end
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " +        @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[1]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
   exit 
  end

 end 
  #get all the packages and music and video
  packages = `adb shell pm list packages | grep GL`
  packages.split("\r").each{|package|
  graphics_intents << @test_params.params_chan.intent_cmd[0].to_s.strip+ " " +  package.gsub(/package:/,"").to_s.strip + "/.".to_s.strip + package.gsub(/package:/,"").gsub(/com.powervr./,"").to_s.strip
 if @test_params.params_chan.instance_variable_defined?(:@music_intent) and !@test_params.params_chan.instance_variable_defined?(:@music_intent) 
  graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0] 
 elsif  @test_params.params_chan.instance_variable_defined?(:@video_intent) and !@test_params.params_chan.instance_variable_defined?(:@music_intent)
   graphics_intents <<  @test_params.params_chan.video_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]  
 elsif @test_params.params_chan.instance_variable_defined?(:@video_intent) and  @test_params.params_chan.instance_variable_defined?(:@music_intent) 
 graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0] 
   graphics_intents <<  @test_params.params_chan.video_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[1]
end 

  }

  #puts "Web Address #{web_address}" 
  counter = 0
  @test_params.params_chan.iterations[0].to_i.times do
  graphics_intents.each{|intent|
  #@test_params.params_chan.webaddress.each{|website|
  puts "Intent is #{intent}"
  counter = counter + 1 
  cmd = "logcat  -d -c"
  sleep 1
  #`adb shell am start -W  -n com.powervr.OGLESVase/.OGLESVase`
  
  puts intent
  data = send_adb_cmd  intent
  puts "response response is: #{data}"
  sleep @test_params.params_chan.delay[0].to_i
  cmd = "logcat  -d -s ActivityManager"
  response = send_adb_cmd cmd
  puts "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
  puts response
  puts "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
  puts "ITERATION ITERATION ITERATION  #{counter}"
  display_time = 0
  time = "" 
  if response.include?("Displayed") 
    time = response.scan(/Displayed.*:\s*\+([0-9]+\w[0-9]+)ms/)[0][0]
    #time = response.scan(/Displayed\s*com.powervr.*:\s*\+([0-9]+\w[0-9]+)ms/)[0][0]
     puts "DISPLAY DISPLAY #{display_time}"
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
  end
  sleep 60
  cmd = "logcat -d -s InputDispatcher"
  response = send_adb_cmd cmd
  puts "response #{response}"
  sleep 1 
  send_events_for(put_screen_home) 
 #At the end let's check if there were exception 
  if response.include?("Exception") 
  @results_html_file.add_paragraph("Intent=#{intent} There was exception\n#{response}") 
  end 
 puts "DEBUG: END OF ITERATION ONE" 
 }
  
 end 

 puts "Total number of failures #{number_of_failures.to_f}"
 total_iteration =  @test_params.params_chan.iterations[0].to_f * graphics_intents.size 
 success_rate = ((total_iteration - number_of_failures.to_f)/ total_iteration)*100.0
 puts "PASS #{success_rate}"
 if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Web  Browser Stress Test=#{success_rate}")
 else
    set_result(FrameworkConstants::Result[:fail], "Web  Browser Stress Test=#{success_rate}")
 end

end 
