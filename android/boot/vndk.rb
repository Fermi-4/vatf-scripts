require File.dirname(__FILE__)+'/../android_test_module'

include AndroidTest

def run
   vndk_str = @equipment['dut1'].send_adb_cmd("shell 'ls -d /system/lib*/vndk*'").to_s
   vndk_folders = vndk_str.scan(/\/system\/lib.*?\/vndk-[^\s]+/i).uniq()
   if vndk_folders.length >= 2
     set_result(FrameworkConstants::Result[:pass], "Test passed found #{vndk_folders}")
   else
     result = "Some vndk folder(s) are missing from /system/lib* found (#{vndk_folders.length}) \n#{vndk_str}"
     set_result(FrameworkConstants::Result[:fail], result)
   end
end
