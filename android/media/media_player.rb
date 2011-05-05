require File.dirname(__FILE__)+'/../android_test_module' 
include AndroidTest

def run 
fps_values = Array.new()
endable_fps = "setprop debug.video.showfps 1"
cmd = "shell " + endable_fps
#send fps enable command 
data = send_adb_cmd cmd
cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
#send file push command 
data = send_adb_cmd cmd
if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
  puts "#{data}"
  exit 
end

#cmd = "shell am start -W -n com.cooliris.media/.MovieView -a action.intent.anction.VIEW -d " + 

cmd = @test_params.params_chan.intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
#send intent command to play the clip
data = send_adb_cmd  cmd
sleep 30
cmd  = "logcat -d "
response = send_adb_cmd cmd 
 response .split("\n").each{|line|
 if line.include?("FPS")
  line = line.scan(/([0-9]*\.[0-9]+)/)
  fps_values << line[0][0]
 end 
 }
 result,comment,perfdata = save_results(fps_values)
 set_result(result,comment,perfdata)
end 




def save_results(fps_values)
   perf_data = [];
   perf_data << {'name' => @test_params.params_chan.testname[0], 'value' =>fps_values, 'units' => "fps"}
  # I have to add pass-fail criteria once known
  [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
end
