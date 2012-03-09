require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
include AndroidTest
include AndroidKeyEvents

def run
  number_of_failures = 0
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  send_events_for(put_screen_home) 
  graphics_intents = Array.new()
  #install graphics application
  install_graphics_apps()
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
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "#{data}"
   exit 
  end
 end 
  packages = send_adb_cmd "shell pm list packages | grep GL"
  packages.split("\r").each{|package|
  graphics_intents << @test_params.params_chan.intent_cmd[0].to_s.strip+ " " +  package.gsub(/package:/,"").to_s.strip + "/.".to_s.strip + package.gsub(/package:/,"").gsub(/com.powervr./,"").to_s.strip
 if !@test_params.params_chan.instance_variable_defined?(:@video_intent) and @test_params.params_chan.instance_variable_defined?(:@music_intent) 
  graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0]    
   
 elsif  @test_params.params_chan.instance_variable_defined?(:@video_intent) and !@test_params.params_chan.instance_variable_defined?(:@music_intent)
     graphics_intents <<  "shell am start -W -n #{CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })} -a action.intent.anction.VIEW -d"  + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
   
 elsif @test_params.params_chan.instance_variable_defined?(:@video_intent) and  @test_params.params_chan.instance_variable_defined?(:@music_intent) 
 graphics_intents <<  @test_params.params_chan.music_intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" +   @test_params.params_chan.file_name[0] 
   graphics_intents << "shell am start -W -n #{CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })} -a action.intent.anction.VIEW -d"  + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]

end 
  
}

  counter = 0
  @test_params.params_chan.iterations[0].to_i.times do
  graphics_intents.each{|intent|
  next if @test_params.params_control.instance_variable_defined?(:@media_stress) and intent.include?("GL")
  counter = counter + 1 
  cmd = "logcat  -d -c"
  response = send_adb_cmd cmd
  sleep 2
  data = send_adb_cmd  intent
  sleep 1
  sleep @test_params.params_chan.delay[0].to_i
  cmd = "logcat  -d -s ActivityManager"
  response = send_adb_cmd cmd
  display_time = 0
  time = "" 
  if response.include?("Displayed") 
    #fix to include com.cooliris.media/.MovieView
    time = response.scan(/Displayed\s+com.*:\s*\+([0-9]+\w[0-9]+)ms/)[0][0]
  else
   puts "DISPLAY TIME NOT DETECTED"
   @results_html_file.add_paragraph("Intent=#{intent} Not Displayed\n#{response}") 
  end                                                                
  if time.include?("s")
   largtime = time.split("s")
   display_time = largtime[0].to_i * 1000 + largtime[1].to_i
  else 
   display_time =  time.to_i
  end 
  if display_time > 1000
  number_of_failures = number_of_failures + 1
  end
  sleep 60
  cmd = "logcat -d -s InputDispatcher"
  response = send_adb_cmd cmd
  sleep 1 
  send_events_for(put_screen_home) 
  if response.include?("Exception") 
  @results_html_file.add_paragraph("Intent=#{intent} There was exception\n#{response}") 
  end 
 }                                                       
 end 

 puts "Total number of failures #{number_of_failures.to_f}"
 total_iteration =  @test_params.params_chan.iterations[0].to_f * graphics_intents.size 
 success_rate = ((total_iteration - number_of_failures.to_f)/ total_iteration)*100.0
 puts "PASS RATE is: #{success_rate}"
 if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Graphics Stress Test=#{success_rate}")
 else
    set_result(FrameworkConstants::Result[:fail], "Graphics Stress Test=#{success_rate}")
 end

end 


def install_graphics_apps()
  graphics_apps = send_host_cmd ("ls #{@test_params.params_chan.apps_host_file_path[0]} | grep OGL")
  puts graphics_apps
  graphics_apps.split("\n").each{|app| 
   cmd = "install " + @test_params.params_chan.apps_host_file_path[0] + "/" + app
  data = send_adb_cmd cmd
 }
end
