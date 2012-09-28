require File.dirname(__FILE__)+'/../../android_test_module' 
include AndroidTest

def setup
  super
  bins_list = send_host_cmd("find #{File.join(@test_params.var_test_libs_root,"armeabi-v7a/RowboPERF_binaries/*")}").split(/[\n\r]+/)
  bins_list.each do |curr_bin|
    send_adb_cmd("push #{curr_bin} /system/bin/")
  end
end

def run 
  regexp = Hash.new
  data = send_adb_cmd("shell " + @test_params.params_chan.app_name[0])
  regexp["dhrystone2 10000000"]= /Dhrystones\s*per\s*Second:\s*([0-9]+.[0-9])+/
  regexp["whetstone 20000"]= /Converted\s*Double\s*Precision\s*Whetstones:\s*([0-9]+.[0-9]+)\s*MIPS/
  regexp["linpack"]= /Unrolled\s*Single\s*Precision\s*([0-9]+)\s*Kflops\s*;\s*[0-9]+\s*Reps/
  reading = data.scan(regexp[@test_params.params_chan.app_name[0]])  
  puts reading.to_s 
  result,comment,perfdata = save_results(reading[0])
  set_result(result,comment,perfdata)
end

def save_results(reading)
   return [FrameworkConstants::Result[:fail], "Test case FAILED."] if !reading
   units = Hash.new 
   units["dhrystone2 10000000"]= "dhrystones/sec"
   units["whetstone 20000"]= "MIPS"
   units["linpack"]= "Kflops"
   perf_data = [];
   perf_data << {'name' => @test_params.params_chan.app_name[0].gsub(/\s+/,"_"), 'value' =>reading, 'units' => units[@test_params.params_chan.app_name[0]]}
  # I have to add pass-fail criteria once known
  [FrameworkConstants::Result[:pass], "Test case PASSED.",perf_data]
end
