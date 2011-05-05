require File.dirname(__FILE__)+'/../android_test_module' 
require 'gnuplot.rb'

include AndroidTest

def setup
  #do nothing 
end

def run
   time1 = 0
   time2 = 0
   boottimes = Array.new()
   cmd  = "logcat -d "
  regexp1 = /reading\s*uImage/
  regexp2 = /bootCompleted/
  @equipment['dut1'].connect({'type'=>'serial'})
  for i in (1..5)  
   @power_handler.switch_off(@equipment['dut1'].power_port)
   sleep 5
   @power_handler.switch_on(@equipment['dut1'].power_port)
   @equipment['dut1'].wait_for(regexp1,30)
   time1 = Time.now
   count =  0
   while count < 500 
    @equipment['dut1'].send_cmd(cmd)
    if @equipment['dut1'].response.include?("bootCompleted")
     time2 = Time.now
     puts @equipment['dut1'].response
     break
    end  
   end 
   boottimes <<  time2 - time1 
  end 
 result,comment,perfdata = save_results(boottimes)
 set_result(result,comment,perfdata)
 puts "BOOT TIME is #{boottimes}" 
end 


def save_results(boottimes)
   perf_data = [];
   perf_data << {'name' => "Boottime", 'value' =>boottimes, 'units' => "sec"}
  # I have to add pass-fail criteria once known
  [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
end
