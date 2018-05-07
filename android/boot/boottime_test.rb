require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

#def setup
#end

def run
  time1 = 0
  boottimes = []
  trials = @test_params.params_chan.instance_variable_defined?(:@boot_trials) ?
           @test_params.params_chan.boot_trials[0].to_i : 5
  @equipment['dut1'].power_port = nil if @test_params.params_chan.instance_variable_defined?(:@soft_reboot)
  @android_boot_params['reboot_regex'] = /.+/
  for i in (1..trials)
   count =  0
   boot_timeout = 120
   @equipment['dut1'].disconnect('serial')
   @equipment['dut1'].boot_to_bootloader(@android_boot_params)
   @equipment['dut1'].set_os_bootcmd(@android_boot_params)
   time1 = Time.now
   @equipment['dut1'].send_cmd('boot', /.*/)
   res = ''
   while !res.match(/^\d+$/) && boot_timeout > 0
      sleep 1
      res = @equipment['dut1'].send_adb_cmd('shell getprop sys.boot_completed').strip()
      boot_timeout -= 1
   end
   time2 = Time.now()
   if !@equipment['dut1'].timeout? && @equipment['dut1'].at_prompt?({'prompt' => @equipment['dut1'].prompt})
     boottimes << time2 - time1
     puts @equipment['dut1'].response
   else
     set_result(FrameworkConstants::Result[:fail], "Test case failed, boot did not complete atfer #{boot_timeout} sec")
     return
   end
  end
 set_result(FrameworkConstants::Result[:pass], "Test case PASS.", {'name' => "Boottime", 'value' =>boottimes, 'units' => "sec"})
 puts "BOOT TIME is #{boottimes}"
end
