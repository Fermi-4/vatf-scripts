require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
require File.dirname(__FILE__)+'/../../power_events_module'
require File.dirname(__FILE__)+'/../../power_module'
require File.dirname(__FILE__)+'/../../netperf_module'
require File.dirname(__FILE__)+'/../../../lib/multimeter_power'
require File.dirname(__FILE__)+'/../../../lib/evms_data'  
include AndroidTest
include AndroidKeyEvents
include PowerEventsModule
include PowerModule
include MultimeterModule
include EvmData
include NetperfModule

def setup
  # Connect to multimeter
  add_equipment('multimeter') do |log_path|
    KeithleyMultiMeterDriver.new(@equipment['dut1'].params['multimeter'],log_path)
  end
  @equipment['multimeter'].connect({'type'=>'serial'})
  @equipment['dut1'].connect({'type'=>'serial'})
  #configure_adb_over_ethernet(equipment=@equipment['dut1'],'5555')
  self.as(AndroidTest).setup
end

def run
  perf = []
  # Configure multimeter 
  @equipment['multimeter'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name))
  # Set DUT in appropriate state
  if @test_params.params_chan.instance_variable_defined?(:@disabled_cpu_idle_modes)
    @test_params.params_chan.disabled_cpu_idle_modes.each do |idle_mode|
      data = send_adb_cmd("shell \"echo 1 > /debug/pm_debug/#{idle_mode.strip.downcase}\"")
      puts send_adb_cmd("shell cat /debug/pm_debug/#{idle_mode.strip.downcase}")
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

  if @test_params.params_chan.instance_variable_defined?(:@intent) 
   cmd = "push " + @test_params.params_chan.host_file_path[0] + " " +     @test_params.params_chan.target_file_path[0]
   data = send_adb_cmd cmd
   if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
    puts "Installed failed: #{data}"
    exit 
   end
  end 

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
  #Set wake time and set no wake lock 
  puts "No wake locke setting"
  send_adb_cmd("shell svc power stayon false")
  if @equipment['dut1'].params['platform_name'] != "am335xevm" 
   puts "Alarm Deleting"
   alarm_delete(@equipment['dut1'])
  end 
  
  number_of_failures = 0
  counter = 0
  power_readings = Hash.new()
  @test_params.params_chan.iterations[0].to_i.times do
   send_adb_cmd("shell svc power stayon false")
   counter = counter + 1
   puts "Number ot iterations excuted so far #{counter}"
   if @equipment['dut1'].params['platform_name'] != "am335xevm" 
    puts "Alarm Setting "
    set_alarm(@equipment['dut1'])
   end  
   puts "Waiting for suspending message."
   send_events_for(get_events_sequence(@test_params.params_chan.force_to_suspend[0]))
   puts @equipment['dut1'].send_cmd("", /Suspending\s+console/, 100, false)
   #sleep 5
   # Get voltage values for all channels in a hash
   volt_readings = @equipment['multimeter'].get_multimeter_output(@test_params.params_chan.loop_count[0].to_i, @test_params.params_equip.timeout[0].to_i)       
   @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt)
   
     if @equipment['dut1'].params['platform_name'] == "am335xevm" 
   puts "Send Wakeup console command afer 60 seconds"
   #sleep 60
   @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt) 
   sleep 1
   send_adb_cmd("shell svc power stayon true")
   @equipment['dut1'].send_cmd("", /request_suspend_state:\s+wakeup\s+\(3->0\)/, 100, false)

  else 
    send_adb_cmd("shell svc power stayon true")
    @equipment['dut1'].send_cmd("", /suspend\s+of\s+devices\s+complete/, 100, false)
  end 
   
   
   # Calculate power consumption
   power_readings = calculate_power_consumption(volt_readings)
   if  power_readings['mean_all_domains'] > @test_params.params_chan.pass_value[0].to_f 
    number_of_failures = number_of_failures + 1 #only one is added to per iteration
    perf = save_results(power_readings, volt_readings)  
   end 
  
   #@equipment['dut1'].send_cmd("netcfg", /suspend\s+of\s+devices\s+complete/, 100, false)
   sleep 5
   send_events_for(get_events_sequence(@test_params.params_chan.alarm_dismiss[0]))
   #send_adb_cmd("shell svc power stayon true")
   puts "Total number of failures so far #{number_of_failures.to_f}"
  end # end for iteration loop 
  puts "Total number of failures at the end #{number_of_failures.to_f}"
  success_rate = ((@test_params.params_chan.iterations[0].to_f - number_of_failures.to_f)/ @test_params.params_chan.iterations[0].to_f)*100.0
  puts "PASS #{success_rate}"
  if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)  
    set_result(FrameworkConstants::Result[:pass], "Success Suspend-Resume Stress Test=#{success_rate}")
  else
    set_result(FrameworkConstants::Result[:fail], "Success Suspend-Resume Stress Test=#{success_rate}")
  end
 
  dutThread.join if dutThread
ensure

end


# Function saves power consumption result
# Input parameters: Hash table populated Power require File.dirname(__FILE__)+'/../../../lib/evms_data'  consumptions for all domains.
# Return Parameter: Performance Array table for all voltages readings and powers consumptions.  
def save_results(power_consumption,voltage_reading,multimeter=@equipment['multimeter'])
  perf = []; v1=[]; v2=[]; vtotal=[]
  count = 0
  table_title = Array.new()
  table_title << 'SAMPLE NO'
  table_title <<  'All domains(mw)'
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i - 1] + "(mw)" 
  end
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i -1] + "drop(mv)" 
  end
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<  multimeter.dut_power_domains[i -1] + "(v)" 
  end
  @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["TOTAL,  PER DOMAIN POWER and VOLTAGE CALCULATED POINT BY POINT",{:bgcolor => "336666", :colspan => table_title.length},{:color => "white"}]],{:border => "1",:width=>"20%"})
  table_title = table_title
 @results_html_file.add_row_to_table(res_table,table_title)
  count = 0
  power_consumption["all_domains"].each{|power|
  table_data =  Array.new
  table_data <<  count.to_s    
  table_data << power.to_s 
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  power_consumption["domain_" +  multimeter.dut_power_domains[i - 1] + "_power_readings"] [count].to_s 
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<   voltage_reading["domain_" +  multimeter.dut_power_domains[i - 1] + "drop_volt_readings"][count].to_s 
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  voltage_reading["domain_" +  multimeter.dut_power_domains[i - 1] + "_volt_readings"][count].to_s
  end
   table_data = table_data 
    @results_html_file.add_row_to_table(res_table,table_data)
    count += 1
  }
 
 for i in (1..multimeter.number_of_channels/2)
  perf << {'name' => @equipment['multimeter'].dut_power_domains[i - 1] + " Power", 'value' =>power_consumption["domain_" + @equipment['multimeter'].dut_power_domains[i - 1] + "_power_readings"], 'units' => "mw"}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw"}
  return perf
end



