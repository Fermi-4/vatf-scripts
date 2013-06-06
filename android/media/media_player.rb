require File.dirname(__FILE__)+'/../android_test_module'
  
include AndroidTest

def run 
  fps_values = Array.new()
  put_screen_home = ["__back__","__back__","__back__","__back__"]
  send_events_for(put_screen_home) 
  endable_fps = "setprop debug.video.showfps 1"
  cmd = "shell " + endable_fps
  #send fps enable command 
  data = send_adb_cmd cmd

  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
    puts "EXITING EXITING EXITING "
    puts "#{data}"
    return 
  end

  #clear the old log
  cmd = "logcat  -d -c"
  data = send_adb_cmd  cmd
  #construct media command
  process_name = 'com.android.gallery3d'
  if @test_params.params_chan.intent[0].include?("music")
    process_name = @test_params.params_chan.intent[0].match(/.*?\-n\s*([^\/]+)/).captures[0]
    cmd = @test_params.params_chan.intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  else 
    component = CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })
    process_name = component.match(/([^\/]+)/).captures[0]
    cmd = "shell am start -W -n #{component} -a   action.intent.anction.VIEW -d"  + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  end 
  
  if @test_params.params_control.instance_variable_defined?(:@collect_stats)
    start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd, stat| 
      if stat == 'proc_mem'
        send_adb_cmd("shell #{cmd} #{process_name}")
      else
        send_adb_cmd("shell #{cmd}")
      end
    }
  end
  data = send_adb_cmd  cmd
  sleep (@test_params.params_chan.duration[0].to_i/1000)
  sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats) if @test_params.params_control.instance_variable_defined?(:@collect_stats)
  fps_values = get_fps
  result,comment,perfdata = save_results(fps_values)
  sys_stats.each do |current_stats|
    perfdata.concat(current_stats)
  end
  set_result(result,comment,perfdata)
end 




def save_results(fps_values)
  perf_data = [];
  perf_data << {'name' => "#{@test_params.params_chan.testname[0]}", 'value' =>fps_values, 'units' => "fps"} if fps_values.length != 0
   
  # I have to add pass-fail criteria once known
  if fps_values.length != 0  or @test_params.params_chan.intent[0].include?("music")
    [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
  else 
    [FrameworkConstants::Result[:fail], "Test case FAIL.",perf_data]
  end 
end
