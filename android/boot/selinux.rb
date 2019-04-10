require File.dirname(__FILE__)+'/../android_test_module'
require File.dirname(__FILE__)+'/../keyevents_module'
require File.dirname(__FILE__)+'/../f2f_utils' 

include AndroidTest

#def setup
#end

def run
   result = ''
   send_events_for('__home__')
   case @test_params.params_chan.type[0]
      when 'audio'
        duration, s_file = fetch_src_file()
        send_adb_cmd("shell logcat -c")
        send_adb_cmd("shell am start -a android.intent.action.VIEW -d file://#{s_file} -t 'audio/*'")
        sleep duration
        response = send_adb_cmd("shell 'logcat -d | grep -i selinux'")
        result += "Logcat reported: #{response}, " if response.match(/audio/)
        response = send_adb_cmd("shell 'dmesg | grep -i \"avc: \"'")
        result += "kernel reported: #{response}" if response.match(/audio/)
      when 'multimedia'
        duration, s_file = fetch_src_file()
        comp = CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })
        send_adb_cmd("shell am start -n #{comp} -a action.intent.action.VIEW -d file://#{s_file}")
        sleep duration
        response = send_adb_cmd("shell 'logcat -d | grep -i selinux'")
        result += "Logcat reported: #{response}, " if response.match(/media|drm|display|graphics|tv|audio/)
        response = send_adb_cmd("shell 'dmesg | grep -i \"avc: \"'")
        result += "kernel reported: #{response}" if response.match(/media|drm|display|graphics|tv|audio/)
      when 'basic'
        send_adb_cmd("shell su root setenforce 1")
        response = send_adb_cmd("shell getenforce")
        if !response.match(/enforcing/i)
          result += "Expecting enforcing got #{response}, "
        else
          send_adb_cmd("shell logcat -c")
          send_adb_cmd("shell am start -W -n com.android.gallery3d/.app.GalleryActivity")
          send_events_for("__sysrq__")
          send_events_for("__home__")
          send_events_for("__sysrq__")
          response = send_adb_cmd("shell 'logcat -d | grep -i exception'")
          result += "Unexpected exception while enforcing: #{response}," if response.match(/exception/i)
        end
        send_adb_cmd("shell su root setenforce 0")
        response = send_adb_cmd("shell getenforce")
        result += "Expecting permissive got #{response}" if !response.match(/permissive/i)
   end
   if result != ''
     set_result(FrameworkConstants::Result[:fail], result)
   else
     set_result(FrameworkConstants::Result[:pass], "Test passed, no SELinux issues found")
   end
end

def fetch_src_file()
  ref_path, s_file = get_file_from_url(@test_params.params_chan.src_url[0], nil)
  @equipment['server1'].send_cmd("avprobe #{ref_path} 2>&1 | grep -i duration:", @equipment['server1'].prompt, 10)
  hrs, mins, secs = @equipment['server1'].response.match(/(\d+):(\d+):(\d+)/m).captures.map(&:to_i)
  duration = hrs * 3600 + mins * 60 + secs
  [duration, s_file]
end
