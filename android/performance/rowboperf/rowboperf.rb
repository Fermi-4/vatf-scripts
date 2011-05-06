require File.dirname(__FILE__)+'/../../android_test_module' 
include AndroidTest

def run 
  regexp = Hash.new
  cmd = "shell /system/bin/sh /data/data/com.ti.android.apps.launcher/files/" + @test_params.params_chan.app_name[0]
  #send apps command 
  data = send_adb_cmd cmd
  regexp["runDhrystone"]= /Dhrystones\s*per\s*Second:\s*([0-9]+.[0-9])+/
  regexp["runWhetstone"]= /Converted\s*Double\s*Precision\s*Whetstones:\s*([0-9]+.[0-9]+)\s*MIPS/
  regexp["runLinpack"]= /Unrolled\s*Single\s*Precision\s*([0-9]+)\s*Kflops\s*;\s*[0-9]+\s*Reps/
  reading = data.scan(regexp[@test_params.params_chan.app_name[0]])  
  puts reading 
  result,comment,perfdata = save_results(reading[0])
  set_result(result,comment,perfdata)
end

def save_results(reading)
   units = Hash.new 
   units["runDhrystone"]= "sec"
   units["runWhetstone"]= "MIPS"
   units["runLinpack"]= "Kflops"
   perf_data = [];
   perf_data << {'name' => @test_params.params_chan.app_name[0], 'value' =>reading, 'units' => units[@test_params.params_chan.app_name[0]]}
  # I have to add pass-fail criteria once known
  [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
end
