require File.dirname(__FILE__)+'/../android_test_module'
require File.dirname(__FILE__)+'/../f2f_utils'
  
include AndroidTest

def run
  audio_permissions = ["android.permission.RECORD_AUDIO",
                       "android.permission.READ_EXTERNAL_STORAGE",
                       "android.permission.WRITE_EXTERNAL_STORAGE",
                       "android.permission.REQUEST_INSTALL_PACKAGES"]
  
  ref_file_url = @test_params.params_chan.audio_url[0]
  ref_path, dut_src_file = get_file_from_url(ref_file_url)
  apk_path = File.join(@linux_temp_folder, File.basename(@test_params.params_chan.apk_url[0]))
  wget_file(@test_params.params_chan.apk_url[0], apk_path)
  send_adb_cmd("install -r #{apk_path}")
  pkg = 'com.ti.test.media'
  audio_permissions.each{ |permission| send_adb_cmd("shell pm grant #{pkg} #{permission}") }
  dut_test_file = 'test.3gp'
  #clear the old files if any
  send_adb_cmd("shell rm /sdcard/#{dut_test_file}")
  local_test_file = File.join(@linux_temp_folder, dut_test_file)
  data = send_adb_cmd("logcat  -d -c")
  send_adb_cmd("shell am start -W -n #{pkg}/.MediaIO -a android.intent.action.MAIN -c android.intent.category.LAUNCHER --es play_file #{File.basename(dut_src_file)} --es rec_file #{dut_test_file}")
  send_events_for(['__tab__','__tab__','__enter__'])
  if @test_params.params_control.instance_variable_defined?(:@collect_stats)
    start_collecting_stats(@test_params.params_control.collect_stats,2){|cmd, stat| 
      if stat == 'proc_mem'
        send_adb_cmd("shell #{cmd} #{process_name}")
      else
        send_adb_cmd("shell #{cmd}")
      end
    }
  end
  sleep (@test_params.params_chan.duration[0].to_i)
  send_events_for(['__enter__'])
  sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats) if @test_params.params_control.instance_variable_defined?(:@collect_stats)
  send_adb_cmd("pull -p /sdcard/#{dut_test_file} #{local_test_file}")
  audio_server = ref_file_url.match(/tp:\/\/([^\/]+)/)[1].sub(/.*?@/,'')
  staf_handle = STAFHandle.new("#{@staf_service_name.to_s}_audio_handle")
  local_test_file_mp3 = local_test_file.sub(/[^\.]*$/, '') + 'mp3'
  audio_name = File.basename(ref_file_url,'.*')
  @equipment['server1'].send_cmd("avconv -i #{local_test_file} -acodec mp3 #{local_test_file_mp3}")
  staf_req = staf_handle.submit(audio_server, "DEJAVU","MATCH FILE #{local_test_file_mp3}") 
  staf_result = STAFResult.unmarshall_response(staf_req.result)
  if staf_req.rc == 0 && staf_result['song_name'] == audio_name
     set_result(FrameworkConstants::Result[:pass], "Recorded audio matched expected audio: expected #{audio_name}, got #{staf_result['song_name']}")
  else
    audio = staf_req.rc == 0 ? staf_result['song_name'] : 'no match found'
    set_result(FrameworkConstants::Result[:fail], "Recorded audio did not match expected audio: expected #{audio_name}, got #{audio}")
  end
end
