require File.dirname(__FILE__)+'/android_test_module'


module MediaModule
include AndroidTest

def run_video_test()
  pass_fail = 0
  send_events_for("__home__")
  fps_values = Array.new()
  install_video_clip()
  endable_fps = "setprop debug.video.showfps 1"
  cmd = "shell " + endable_fps
  #send fps enable command 
  data = send_adb_cmd cmd
  #clear the old log
  cmd = "logcat  -d -c"
  data = send_adb_cmd  cmd
  #construct media command
  cmd = "shell am start -W -n #{CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })} -a action.intent.anction.VIEW -d"  + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send intent command to play the clip
  data = send_adb_cmd  cmd
  return 1
end

def run_graphic_test()
  pass_fail = 0
  send_events_for("__home__")
  install_apps()
  #clear the old log
  cmd = "logcat  -d -c"
  data = send_adb_cmd  cmd
  #construct media command
  cmd = "shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "   + @test_params.params_chan.intent[0] 
  #send intent command to play the clip  
  data = send_adb_cmd  cmd
  return 1
end


# Installs applications 
def install_video_clip()
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " + @test_params.params_chan.target_file_path[0] + "/"
  #send file push command
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
   puts "EXITING EXITING EXITING "
   puts "#{data}"
  end
end


# Installs applications 
def install_apps()
  cmd = "install " + @test_params.params_chan.apps_host_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  data = send_adb_cmd cmd
end


end 
