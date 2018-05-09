require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

#def setup
#end

def run
   mount_count = @equipment['dut1'].send_adb_cmd("shell 'dmesg | grep -i __mount | grep -i -e system -e vendor'").scan(/Success/i).length()
   ls_count = @equipment['dut1'].send_adb_cmd("shell 'ls / | grep -e system -e vendor | wc -l'").to_i
   if mount_count == 2 && ls_count == 2 && @equipment['dut1'].at_prompt?({'prompt' => @equipment['dut1'].prompt})
     set_result(FrameworkConstants::Result[:pass], "Test case passed (#{mount_count}/2)")
   else
     result = 'Test case failed'
     result += ", failed early mount detection (#{mount_count}/2)" if mount_count < 2
     result += ", system or vendor partition not listed in / (#{ls_count}/2)" if ls_count < 2
     set_result(FrameworkConstants::Result[:fail], result)
   end
end
