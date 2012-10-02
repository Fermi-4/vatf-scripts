require File.dirname(__FILE__)+'/../../android_test_module'

include AndroidTest

def run
  perf_data=[]
  result=''
  send_events_for('__back__')
  send_adb_cmd("logcat -c")
  send_adb_cmd("shell am start -W -n #{@test_params.params_chan.component[0]}")
  #D/(PVRShell)( 3144): PVRShell: frame 63, FPS 62.4.
  sleep @test_params.params_chan.test_time[0].to_f
  perf_trace = send_adb_cmd("logcat -d -s #{@test_params.params_chan.log_option[0]}")
  perf_info = perf_trace.scan(/.*?:\s*PVRShell:.*?FPS\s*([\d.]+)/im)
  send_events_for('__back__')
  if perf_info && !perf_info.empty?
    perf_data = {}
    perf_data["name"] = 'fps'
    perf_data["values"] = perf_info.flatten[3..-1]
    perf_data["units"] = 'fps'
    set_result(FrameworkConstants::Result[:pass], "FPS data collected successfully\n", perf_data)
  else
    send_adb_cmd("logcat -d")
    set_result(FrameworkConstants::Result[:fail], "Not able to obtain performance data for graphics app")
  end
end



