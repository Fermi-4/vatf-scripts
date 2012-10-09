require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../../lib/multimeter_power'
require File.dirname(__FILE__)+'/../../../lib/evms_data' 
require File.dirname(__FILE__)+'/../../power_module' 
require File.dirname(__FILE__)+'/../../netperf_module'
require 'gnuplot.rb'

include AndroidTest
include MultimeterModule
include EvmData
include PowerModule
include NetperfModule

def setup
  add_equipment('multimeter') do |log_path|
    KeithleyMultiMeterDriver.new(@equipment['dut1'].params['multimeter'],log_path)
  end
  # Connect to multimeter
  @equipment['multimeter'].connect({'type'=>'serial'})
  @equipment['dut1'].connect({'type'=>'serial'})
  send_adb_cmd("shell svc power stayon true") 
  self.as(AndroidTest).setup
end

def run
  perf = []
  power_readings =  Hash.new()
  volt_reading_table =  Hash.new()
  # Configure multimeter 
  @equipment['multimeter'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name))
  if @test_params.params_chan.instance_variable_defined?(:@dvfs_governor)
   number_of_governor =  @test_params.params_chan.dvfs_governor.length
  else 
  number_of_governor
  end 
  for i in (0..number_of_governor - 1 )
  # Start collecting stats
  if @test_params.params_control.instance_variable_defined?(:@collect_stats)
    start_collecting_stats(@test_params.params_control.collect_stats,@test_params.params_control.collect_stats_interval[0].to_i){|cmd| send_adb_cmd("shell #{cmd}")}
  end
  # Set DUT in appropriate state
  puts "\n\n======= Power Domain states info =======\n" + send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state")
  puts "\n\n======= Current CPU Frequency =======\n" +  send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq")
  puts "\n\n======= Power Domain transition stats =======\n" + send_adb_cmd("shell cat /sys/kernel/debug/pm_debug/count") 
  if @test_params.params_chan.instance_variable_defined?(:@dvfs_governor)
    send_adb_cmd("shell \"echo #{@test_params.params_chan.dvfs_governor[i].strip.downcase} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\"")
    if @test_params.params_chan.dvfs_governor[i].strip.downcase == 'userspace'
      supported_frequencies = send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies").split(/\s+/)
      raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
      send_adb_cmd("shell \"echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed\"")
    end 
  else
    send_adb_cmd("shell \"echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor\"")
  end
    
  if @test_params.params_chan.instance_variable_defined?(:@disabled_cpu_idle_modes)
    @test_params.params_chan.disabled_cpu_idle_modes.each do |idle_mode|
      send_adb_cmd("shell \"echo 0 > /sys/kernel/debug/pm_debug/#{idle_mode.strip.downcase}\"")
    end
  end

  #the timeout must be passed as parameter.  
  if @test_params.params_chan.instance_variable_defined?(:@uart_mode)
    send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.0/#{@test_params.params_chan.uart_mode[0]}\"")
    send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.1/#{@test_params.params_chan.uart_mode[0]}\"")
    send_adb_cmd("shell \"echo 5 > /sys/devices/platform/omap/omap_uart.2/#{@test_params.params_chan.uart_mode[0]}\"")
  end 
  #I am enabling smart reflex for suspend/resume test area. I am running the others with default smart reflex configuration. 
  if @test_params.params_chan.instance_variable_defined?(:@smart_reflex)
    if @test_params.params_chan.smart_reflex[0].strip == "enable" 
      send_adb_cmd("shell \"echo 1 > /sys/kernel/debug/voltage/vdd_core/smartreflex/autocomp\"")
      send_adb_cmd("shell \"echo 1 > /sys/kernel/debug/voltage/vdd_mpu/smartreflex/autocomp\"")
    end 
  end
 
  if @test_params.params_chan.instance_variable_defined?(:@enabled_cpu_idle_modes)
    @test_params.params_chan.enabled_cpu_idle_modes.each do |idle_mode|
      send_adb_cmd("shell \"echo 1 > /sys/kernel/debug/pm_debug/#{idle_mode.strip.downcase}\"")
    end
  end
  if @test_params.params_chan.instance_variable_defined?(:@intent) 
    cmd = "push " + @test_params.params_chan.host_file_path[0] + " " +     @test_params.params_chan.target_file_path[0]
    data = send_adb_cmd cmd
    if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
      puts "Installed failed: #{data}"
      exit 
    end
  end 
  # Get stats before starting power measurements
  states_data = send_adb_cmd("shell ls /sys/devices/system/cpu/cpu0/cpuidle/")
  states = states_data.scan(/^state.*/)
  states.each {|s|
    send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpuidle/#{s}")
  }
  if @test_params.params_chan.instance_variable_defined?(:@bypass_dut)
    # Don't configure DUT, user will set it in the right state
    # before running this test
    puts "configure DUT, user must set it in the right state"
    send_adb_cmd("shell svc power stayon false")
    if @test_params.params_chan.instance_variable_defined?(:@bypass_dut_wait) 
      if @equipment['dut1'].params['platform_name'] != "am335evm" 
       puts "Deleting Alarm"
       alarm_delete(@equipment['dut1'])
       set_alarm(@equipment['dut1'])
      end 
      send_events_for("__power__")
      @equipment['dut1'].send_cmd("", /Suspending\s+console/, 100, false)
    end 
  else
    dutThread = Thread.new {run_test(@test_params.params_chan.test_option[0]) } if @test_params.params_chan.instance_variable_defined?(:@test_option)
    if @test_params.params_chan.instance_variable_defined?(:@intent)
      dutThread = Thread.new {run_test(nil, @test_params.params_chan.intent[0]+ " #{@test_params.params_chan.target_file_path[0]}") } 
    end 
  end
  # Get voltage values for all channels in a hash
  volt_readings = @equipment['multimeter'].get_multimeter_output(@test_params.params_control.loop_count[0].to_i, @test_params.params_equip.timeout[0].to_i) 
  send_events_for("__enter__") if @test_params.params_chan.instance_variable_defined?(:@bypass_dut_wait)
  #send enter to wake up the system
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt)
  send_events_for('__home__')
  # Get Stats after measuring power
  send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state")
  states.each {|s|
    send_adb_cmd("shell cat /sys/devices/system/cpu/cpu0/cpuidle/#{s}")
  }
  # Stop collecting stats
  sys_stats=nil
  if @test_params.params_control.instance_variable_defined?(:@collect_stats)
    sys_stats = stop_collecting_stats(@test_params.params_control.collect_stats)  
    @results_html_file.add_paragraph("")
    systat_names = []
    systat_vals = []
    sys_stats.each do |current_stat|
      systat_vals << current_stat['value']
      current_stat_plot = stat_plot(current_stat['value'], current_stat['name']+" plot", "sample", current_stat['units'], current_stat['name'], current_stat['name'], "system_stats")
      plot_path, plot_url = upload_file(current_stat_plot)
      systat_names << [current_stat['name']+' ('+current_stat['units']+')',nil,nil,plot_url]
    end
    @results_html_file.add_paragraph("")
    res_table2 = @results_html_file.add_table([["Sytem Stats",{:bgcolor => "336666", :colspan => "#{systat_names.length}"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table2, systat_names)
    @results_html_file.add_rows_to_table(res_table2,systat_vals.transpose)
  end
  
  # Calculate power consumption
  power_readings[@test_params.params_chan.dvfs_governor[i].strip.downcase] = calculate_power_consumption(volt_readings)
  volt_reading_table[@test_params.params_chan.dvfs_governor[i].strip.downcase] =  volt_readings  
  end # end of loop 
  # Generate the plot of the power consumption for the given application
  perf = save_results(power_readings, volt_reading_table,number_of_governor)
  dutThread.join if dutThread
  ensure 
    send_adb_cmd("shell svc power stayon true")
    if perf.size > 0
      perf.concat(sys_stats) if sys_stats
      set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
    else
      set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data", sys_stats)
    end

end 

# Function saves power consumption result
# Input parameters: Hash table populated Power consumptions for all domains.
# Return Parameter: Performance Array table for all voltages readings and powers consumptions.  
def save_results(power_consumption,voltage_reading,multimeter=@equipment['multimeter'],number_of_governor)
  perf = []; v1=[]; v2=[]; vtotal=[]
  keys = []
  array_of_power_consumption_hashes =  Array.new
  power_consumption_table  = Hash.new
  power_consumption.each {|key, pwr|
    power_consumption_table[key] = pwr['all_domains']
  }
  power_plot_path = stat_plot(power_consumption_table,"POWER CONSUMPTION Vs Time", "Samples", "Power (mw)")
  mygraphurl = upload_file(power_plot_path)[1]
  @results_html_file.add_paragraph("PLEASE CLICK ME TO SEE POWER CONSUMPTION PLOT POINT BY POINT",nil, nil,mygraphurl)
  count = 0
  table_title = Array.new()
  table_title << 'SAMPLE NO'
  table_title <<  'All domains(mw)'
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i - 1] + "(mw)" 
  end
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i -1] + "drop(v)" 
  end
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<  multimeter.dut_power_domains[i -1] + "(v)" 
  end
   for index in (0..number_of_governor - 1)
  @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["TOTAL,  PER DOMAIN POWER and VOLTAGE CALCULATED POINT BY POINT #{@test_params.params_chan.dvfs_governor[index]}",{:bgcolor => "336666", :colspan => table_title.length},{:color => "white"}]],{:border => "1",:width=>"20%"})
  table_title = table_title
 @results_html_file.add_row_to_table(res_table,table_title)
  count = 0
  power_consumption[@test_params.params_chan.dvfs_governor[index].strip.downcase]['all_domains'].each{|power|
  table_data =  Array.new
  table_data <<  count.to_s    
  table_data << power.to_s 
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  power_consumption[@test_params.params_chan.dvfs_governor[index].strip.downcase]["domain_" +  multimeter.dut_power_domains[i - 1] + "_power_readings"] [count].to_s 
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<   voltage_reading[@test_params.params_chan.dvfs_governor[index].strip.downcase]["domain_" +  multimeter.dut_power_domains[i - 1] + "drop_volt_readings"][count].to_s 
  end
  for i in (1..multimeter.number_of_channels/2)
   table_data <<  voltage_reading[@test_params.params_chan.dvfs_governor[index].strip.downcase]["domain_" +  multimeter.dut_power_domains[i - 1] + "_volt_readings"][count].to_s
  end
   table_data = table_data 
    @results_html_file.add_row_to_table(res_table,table_data)
    count += 1
  }
  
 for i in (1..multimeter.number_of_channels/2)
  perf << {'name' => @equipment['multimeter'].dut_power_domains[i - 1] + " Power", 'value' =>power_consumption[@test_params.params_chan.dvfs_governor[index].strip.downcase]["domain_" + @equipment['multimeter'].dut_power_domains[i - 1] + "_power_readings"], 'units' => "mw"}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption[@test_params.params_chan.dvfs_governor[index].strip.downcase]['all_domains'], 'units' => "mw"}
 end # end of for loop 
 return perf
end

