require File.dirname(__FILE__)+'/../android_test_module'
require File.dirname(__FILE__)+'/../../lib/sys_stats'
require File.dirname(__FILE__)+'/../keyevents_module'  
include AndroidTest
include SystemStats
include AndroidKeyEvents

def run 
fps_values = Array.new()
process_pids = Hash.new
top_stats = Hash.new
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
  exit 
end

cmd = "install " + @test_params.params_chan.apps_host_file_path[0] + "/" + @test_params.params_chan.app_name[0]
data = send_adb_cmd cmd
if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil and !data.to_s.include?("INSTALL_FAILED_ALREADY_EXISTS")
 puts "#{data}"
#   exit 
end 

#clear the old log
cmd = "logcat  -d -c"
data = send_adb_cmd  cmd

#construct media command
cmd = @test_params.params_chan.intent[0] + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
#send intent command to play the clip
data = send_adb_cmd  cmd
#time delay before collecting data
#to be done check the locat for sign of the process started
#sleep @test_params.params_chan.sleep_time[0].to_i


# read process ids for the given processes.
process_pids = get_android_process_pids(@test_params.params_chan.processes_name)

#start Application
#pids must be supplied separated by comma
# duration and intervals are in miliseconds. Interval and duration are parameters. Pids are caculated dynamically.
# A libray which takes process name will connect the pids.
# application start command    
cmd = @test_params.params_chan.apps_intent[0] + " -e pids " + process_pids["pids"] + " -e duration " +  @test_params.params_chan.duration[0] + " -e interval " + @test_params.params_chan.interval[0]
#to start application.

data = send_adb_cmd  cmd

#Read to result 
top_stats =  get_android_top_stats(@test_params.params_chan.cpu_load_samples[0].to_i,@test_params.params_chan.processes_name[0], @test_params.params_chan.time[0])

 if (@test_params.params_control.instance_variable_defined?(:@processes_name) && top_stats['process_cpu_loads'].length == 0)
              set_result(FrameworkConstants::Result[:fail], 'Cpu load could not be obtained. Verify that process #{params_control.processes_name[0]} has started.')
              puts 'Test failed: Cpu load could not be obtained. Verify that process #{params_control.processes_name[0]} has started.'
 end 
 fps_values = get_fps
 result,comment,perfdata = save_results(fps_values,top_stats['process_cpu_loads'],top_stats['process_mem_usage_rss'],process_pids)
 set_result(result,comment,perfdata)
end 




def save_results(fps_values,cpu_loads,mem_usage,process_pids)
   perf_data = [];
   perf_data << {'name' => "#{@test_params.params_chan.testname[0]}", 'value' =>fps_values, 'units' => "fps"} if fps_values.length != 0
   perf_data << {'name' => "#{@test_params.params_chan.processes_name[0]} Cpu Load", 'value' =>cpu_loads, 'units' => "%"} if cpu_loads.length != 0
   perf_data << {'name' =>  "#{@test_params.params_chan.processes_name[0]} Mem Usage(RSS)", 'value' =>mem_usage, 'units' => "%"} if mem_usage.length != 0

#in this loop I will collect all meminfo for all processes 
#this to be completed 
@test_params.params_chan.processes_name.each{|process_name|
  process_meminfo = get_android_process_meminfo(@test_params.params_chan.metrics,process_pids[process_name])
 @test_params.params_chan.metrics.each{|metric|
  perf_data << {'name' =>  "#{@test_params.params_chan.processes_name[0]} #{metric}", 'value' =>process_meminfo[metric], 'units' => "kb"} if process_meminfo[metric].length != 0
}
}
  # I have to add pass-fail criteria once known
  [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
end
