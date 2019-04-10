require File.dirname(__FILE__)+'/../android_test_module'
require File.dirname(__FILE__)+'/../keyevents_module'
require File.dirname(__FILE__)+'/../f2f_utils' 

include AndroidTest

def run
   result = ''
   send_events_for('__home__')
   case @test_params.params_chan.type[0]
      when 'basic'
        response = send_adb_cmd("shell getprop ro.treble.enabled")
        if !response.match(/true/i)
          result += "Expected treble to be enabled but got #{response}, "
        end
   end
   if result != ''
     set_result(FrameworkConstants::Result[:fail], result)
   else
     set_result(FrameworkConstants::Result[:pass], "Test passed, no Treble issues found")
   end
end

