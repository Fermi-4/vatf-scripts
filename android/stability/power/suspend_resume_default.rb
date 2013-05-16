require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
require File.dirname(__FILE__)+'/../../power_events_module'
require File.dirname(__FILE__)+'/../../power_module'
require File.dirname(__FILE__)+'/../../media_module'
require File.dirname(__FILE__)+'/../../wlan_module'
require File.dirname(__FILE__)+'/../../ethernet_module'
require File.dirname(__FILE__)+'/../../bluetooth_module'
require File.dirname(__FILE__)+'/../../storage_module'
require File.dirname(__FILE__)+'/../../netperf_module' 
require File.dirname(__FILE__)+'/../../wireless_events_module'
require File.dirname(__FILE__)+'/../device_io/file_copy'

include AndroidTest
include AndroidKeyEvents
include PowerEventsModule
include EventsModule
include PowerModule  
include MediaModule
include NetperfModule
include WlanModule
include EthernetModule
include BluetoothModule
include StorageModule

def setup
  @equipment['dut1'].connect({'type'=>'serial'})
  configure_adb_over_ethernet(equipment=@equipment['dut1'],'5555')
  self.as(AndroidTest).setup
  wlan_enable
end

def run
  perf = []
  file_integrity_status = 0
  initial_value = 0
  file_integrity_test = ""
  number_of_failures = 0
  send_adb_cmd("shell svc power stayon true")
  
  if @test_params.params_chan.instance_variable_defined?(:@bypass_dut)
    # Don't configure DUT, user will set it in the right state
    # before running this test
    puts "configure DUT, user must set it in the right state"
    sleep @test_params.params_chan.bypass_dut_wait[0].to_i if @test_params.params_chan.instance_variable_defined?(:@bypass_dut_wait)
  else
    dutThread = Thread.new {run_test(@test_params.params_chan.test_option[0]) } if @test_params.params_chan.instance_variable_defined?(:@test_option)
    if @test_params.params_chan.instance_variable_defined?(:@intent)
     dutThread = Thread.new {run_test(nil, @test_params.params_chan.intent[0]+ " #{@test_params.params_chan.target_file_path[0]}") } 
    end 
  end
  #if the test case doesn't need presuspend test, donnot override this function. 
  initial_bw_value = pre_suspend_test()
  #Set no wake lock enable_ethernet
  #Delete existing Alaerm setting
  puts "Disable wake locke setting"
  puts "Alarm Deleting"
  alarm_delete(@equipment['dut1'])  
  counter = 0
  #Run test for number for iterations
  @test_params.params_chan.iterations[0].to_i.times do
  counter = counter + 1
  puts "Number ot iterations excuted so far #{counter}"
  #if the test case doesn't need on suspend test, donnot override this function.
  if @test_params.params_chan.instance_variable_defined?(:@file_integrity) 
   #status = on_suspend_test()
   file_integrity_test   = Thread.new() {file_integrity_status = on_suspend_test}
   sleep 10
  else 
   
    status = on_suspend_test()
  end 
  puts "FILE COPY IS RUNNING."
  #wait a litle bit to collect some fps data
  sleep 5
  #if the test case doesn't need to collect stat before suspend, donnot override this function.  
  initial_stat_value =  before_resume_test()
  configure_dut_to_suspend()

  #this is only for wakeup time add temporarly
  if !@test_params.params_chan.instance_variable_defined?(:@wakeup)
  cmd  = "logcat -c"
  response = send_adb_cmd cmd 
  end 

  #Incase the application aquires wake lock force the system to suspend.
  send_events_for(get_events_sequence(@test_params.params_chan.force_to_suspend[0]))
  puts "Waiting for suspending message."
  sleep 5
  puts @equipment['dut1'].send_cmd("netcfg", /Suspending\s+console/, 100, false)
  puts "SYSTEM SUSPENDING RIGHT NOW"
  sleep 5
  time1 = 0
  # While the platfrom is down,  do nothing, used to collect suspend power  
  if @equipment['dut1'].params['platform_name'].include?("am335xevm") 
   puts "Send Wakeup console command afer 60 seconds"
   if !@test_params.params_chan.instance_variable_defined?(:@file_integrity) 
    #sleep 60
    sleep 5
   end 
   #time1 = Time.now
   time1 = Time.now.to_f
   #sleep 1
   send_adb_cmd("shell svc power stayon true")
   puts "WAITING FOR request_suspend_state: wakeup (3->0) massage"
   
   @equipment['dut1'].send_cmd("", /request_suspend_state:\s+wakeup\s+\(3->0\)/, 100, false) if !@test_params.params_chan.instance_variable_defined?(:@wakeup)
   puts "shell svc power stayon true"
  else 
   @equipment['dut1'].send_cmd("", /suspend\s+of\s+devices\s+complete/, 100, false) if !@test_params.params_chan.instance_variable_defined?(:@wakeup)
   send_adb_cmd("shell svc power stayon true")
  end 
  puts "SYSTEM IS COMMANDED TO RESUME!!!!!!!"
  if @equipment['dut1'].params['platform_name'] != "am335xevm" 
    #On resume the alarm become foreground, dismiss it so that the test application become foreground.
    send_events_for( '__menu__')
    if !@test_params.params_chan.instance_variable_defined?(:@file_integrity) 
      send_events_for(get_events_sequence(@test_params.params_chan.alarm_dismiss[0]))
    end
    #Prevent from resuspending again, becsaus we need to do some test on this state. 
    send_adb_cmd("shell svc power stayon true")
    sleep 30 
  end 
  send_adb_cmd("shell svc power stayon true")
  test_status = 0
  puts "Starting resume test ......"
  send_events_for('__menu__') 
  test_status = on_resume_test(initial_bw_value,initial_stat_value)
  puts "******* time wakeup command send is: #{time1}"
  #time result must be post to wakeul test case.
  time = 0
  if !@test_params.params_chan.instance_variable_defined?(:@file_integrity)  
   time = test_status - time1 
  end 
  puts "******* wakeup time is #{time}"
  if test_status == 1 or file_integrity_status == 1
   puts "On RESUME  TEST PASS!"
  else 
   puts "On RESUME  TEST FAILE!"
   number_of_failures = number_of_failures + 1
  end
  #send_events_for(get_events_sequence(@test_params.params_chan.alarm_dismiss[0]))
  puts "Total number of failures so far #{number_of_failures.to_f}"
 end # end for teration loop 
 
 puts "Total number of failures at the end #{number_of_failures.to_f}"
 success_rate = ((@test_params.params_chan.iterations[0].to_f - number_of_failures.to_f)/ @test_params.params_chan.iterations[0].to_f)*100.0
 #temp for file integrity 
 file_integrity_test.join if @test_params.params_chan.instance_variable_defined?(:@file_integrity)
 puts "PASS #{success_rate}"
if !@test_params.params_chan.instance_variable_defined?(:@wakeup)
   if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
     set_result(FrameworkConstants::Result[:pass], "Suspend-Resume Stress Test=#{success_rate}")
   else
     set_result(FrameworkConstants::Result[:fail], "Suspend-Resume Stress Test=#{success_rate}")
   end
 else 
   set_result(FrameworkConstants::Result[:pass], "System wake up time =#{time}")
 end  
  dutThread.join if dutThread
  ensure

end

def wlan_enable
  
end

def pre_suspend_test()
  return 0
end 

def before_resume_test()
end
def on_suspend_test()
end 

def on_resume_test(initial_bw_value,initial_fps_value)
end 

#function configures dut to suspend
def configure_dut_to_suspend()
  # Set DUT in appropriate state
  if @test_params.params_chan.instance_variable_defined?(:@disabled_cpu_idle_modes)
    @test_params.params_chan.disabled_cpu_idle_modes.each do |idle_mode|
      data = send_adb_cmd("shell \"echo 1 > /sys/kernel/debug/pm_debug/#{idle_mode.strip.downcase}\"")
        puts "\n\n======= DEBUG =======\n" +  send_adb_cmd("shell cat /sys/kernel/debug/pm_debug/#{idle_mode.strip.downcase}")
    end
  end
  
  #the timeout must be passed as parameter.  
  if @test_params.params_chan.instance_variable_defined?(:@uart_mode)
  puts "TURNING OF CPU/SUSPEND"
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.0/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.1/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.2/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.3/#{@test_params.params_chan.uart_mode[0]}\"")
  send_adb_cmd("shell \"sleep 10\"")
  end 
  send_adb_cmd("shell svc power stayon false")
  send_adb_cmd("shell input keyevent 26")
end



