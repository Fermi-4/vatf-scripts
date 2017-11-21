require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

#def setup
#end

def run
  time1 = 0
  boot_timeout = 120
  boottimes = Array.new()
  regexp2 = /init:\s*Service\s*'bootanim'\s*\(pid\s*\d+\)\s*exited\s*with\s*status\s*0/im
  trials = @test_params.params_chan.instance_variable_defined?(:@boot_trials) ?
           @test_params.params_chan.boot_trials[0].to_i :
           5
  for i in (1..trials)
   @equipment['dut1'].boot_to_bootloader(@android_boot_params)
   @equipment['dut1'].set_os_bootcmd(@android_boot_params)
   @equipment['dut1'].send_cmd('boot',/.*/)
   time1 = Time.now
   count =  0
   @equipment['dut1'].wait_for(regexp2,boot_timeout)
   time2 = Time.now()
   if !@equipment['dut1'].timeout? && @equipment['dut1'].at_prompt?({'prompt' => @equipment['dut1'].prompt})
     boottimes << time2 - time1
     puts @equipment['dut1'].response
   else
     set_result(FrameworkConstants::Result[:falie], "Test case failed, boot did not complete atfer #{boot_timeout} sec")
     return
   end
  end
 set_result(FrameworkConstants::Result[:pass], "Test case PASS.", {'name' => "Boottime", 'value' =>boottimes, 'units' => "sec"})
 puts "BOOT TIME is #{boottimes}"
end
