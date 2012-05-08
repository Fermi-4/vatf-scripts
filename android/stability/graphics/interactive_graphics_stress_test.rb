require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
include AndroidTest
include AndroidKeyEvents
$flag = 0

def run
   puts "ENTERRING RUN"
  status = 0
  status1 = 0
  #flag = 0 
  check_graphics_activity = ""
  do_graphics_interactiv  = ""
  send_events_for("__home__")
  puts "installing APPs"
  install_apps() 
  #clear the old log
  cmd = "logcat  -d -c"
  puts "clearing logcat"
  data = send_adb_cmd  cmd
  #construct media command
  cmd = "shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "   + @test_params.params_chan.intent[0] 
  #send intent command to play the clip  
  puts "starting APP"
  data = send_adb_cmd  cmd
  puts "APP INSTALLED! "
  sleep 5 
  do_graphics_interactiv   = Thread.new() {status = do_graphics_interactive}
  check_graphics_activity   = Thread.new() {status1 = check_graphics_activity}
  puts "THREADS ARE RUNNING!"
  do_graphics_interactiv.join
  check_graphics_activity.join
  if (status == 0 )  
    set_result(FrameworkConstants::Result[:pass], "Interactive Graphics Stress Test PASS for Duration =" + @test_params.params_chan.test_duration[0])
  else
    set_result(FrameworkConstants::Result[:fail], "Interactive Graphics Stress Test Failed at duration =" + @test_params.params_chan.test_duration[0])
  end
 
end 

# Installs applications 
def install_apps()
  cmd = "install " + @test_params.params_chan.apps_host_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  data = send_adb_cmd cmd
end

def check_graphics_activity
  fps_values = Array.new()
  initial_time = Time.now  
  counter = 0
  duration = 0 
  while duration < @test_params.params_chan.test_duration[0].to_i   do 
    fps_values = get_fps
    if fps_values.length > 2
      puts "FPS detected " 
    else 
      puts "FPS not detected"
      counter += 1
      cmd = "adb logcat -d"
      response = send_adb_cmd cmd
      @results_html_file.add_paragraph("After running for duration =#{time} Logcat output is:\n#{response}") 
     $flag = 1 
     break;
    end 
     cmd = "logcat  -d -c"
     response = send_adb_cmd cmd
     sleep 20
     duration =  Time.now - initial_time
    puts "Duration is: #{duration}"
   end #end of while loop 
  if counter == 0 
    return 0
  else 
   return 1
  end   
end 



def do_graphics_interactive
  initial_time = Time.now 
  duration = 0 
  while duration < @test_params.params_chan.test_duration[0].to_i   do 
    cmd = ["__directional_pad_right__","__directional_pad_right__","__directional_pad_left__","__directional_pad_left__"]
    send_events_for(cmd)
    duration =  Time.now - initial_time
    if $flag == 1
     break 
    end   
  end #end of while loop 
end 
