require File.dirname(__FILE__)+'/../../android_test_module'

include AndroidTest

def run
  perf_data=[]
  result=''
  sys_stats = nil
  send_events_for('__back__')
  send_adb_cmd("logcat -c")
  process_name = @test_params.params_chan.component[0].match(/([^\/]+)/).captures[0]
  if @test_params.params_control.instance_variable_defined?(:@collect_stats)
    start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd, stat| 
      if stat == 'proc_mem'
        send_adb_cmd("shell #{cmd} #{process_name}")
      else
        send_adb_cmd("shell #{cmd}")
      end
    }
  end
  send_adb_cmd("shell am start -W -n #{@test_params.params_chan.component[0]}")
  #D/(PVRShell)( 3144): PVRShell: frame 63, FPS 62.4.
  sleep @test_params.params_chan.test_time[0].to_f
  sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats) if @test_params.params_control.instance_variable_defined?(:@collect_stats)
  perf_trace = send_adb_cmd("logcat -d -s #{@test_params.params_chan.log_option[0]}")
  perf_info = perf_trace.scan(/.*?:\s*PVRShell:.*?FPS\s*([\d.]+)/im)
  send_events_for('__back__')
  perf_data = []
  if sys_stats
    sys_stats.each do |current_stats|
      perf_data.concat(current_stats)
    end
  end
  if perf_info && !perf_info.empty?
    fps_data = {}
    fps_data["name"] = 'fps'
    fps_data["values"] = perf_info.flatten[3..-1]
    fps_data["units"] = 'fps'
    perf_data << fps_data
    set_result(FrameworkConstants::Result[:pass], "FPS data collected successfully\n", perf_data)
  else
    send_adb_cmd("logcat -d")
    set_result(FrameworkConstants::Result[:fail], "Not able to obtain performance data for graphics app")
  end
end



