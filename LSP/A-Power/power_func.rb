require File.dirname(__FILE__)+'/../default_test_module' 
require File.dirname(__FILE__)+'/../../lib/multimeter_power'
require File.dirname(__FILE__)+'/../../lib/evms_data'  
require File.dirname(__FILE__)+'/power_functions' 

require 'gnuplot.rb'

include LspTestScript
include MultimeterModule
include EvmData
include PowerFunctions

def setup
  puts "\n====================\nPATH=#{ENV['PATH']}\n"
  super
  # Add multimeter to result logs
  multimeter = @equipment['dut1'].params['multimeter1']
  conn_type = multimeter.params && multimeter.params.has_key?('conn_type') ? multimeter.params['conn_type'] : 'serial'
  add_equipment('multimeter1') do |log_path|
    Object.const_get(multimeter.driver_class_name).new(multimeter,log_path)
  end
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>conn_type})
end

def run
  perf = []

  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'
  max_suspend_time = 30
  max_resume_time = 60

  cpufreq_0 = '/sys/devices/system/cpu/cpu0/cpufreq'

  # mount debugfs
  @equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt)

  report_power_stats

  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))
  
	puts "\n\n======= Current CPU Frequency =======\n" 
	@equipment['dut1'].send_cmd("cat #{cpufreq_0}/scaling_cur_freq", @equipment['dut1'].prompt, 3)
 	@equipment['dut1'].send_cmd(" cat #{cpufreq_0}/scaling_available_frequencies", @equipment['dut1'].prompt, 3)
	supported_frequencies = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    
  # Configure DUT 	
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt) 
  
  if @test_params.params_chan.cpufreq[0] != '0' && @test_params.params_chan.instance_variable_defined?(:@dvfs_freq)
    raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
    @equipment['dut1'].send_cmd("echo userspace > #{cpufreq_0}/scaling_governor", @equipment['dut1'].prompt)
  	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > #{cpufreq_0}/scaling_setspeed", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat #{cpufreq_0}/scaling_cur_freq", @equipment['dut1'].prompt, 3)
    new_opp = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    if !new_opp.include?(@test_params.params_chan.dvfs_freq[0])
      errMessage= "Could not set #{@test_params.params_chan.dvfs_freq[0]} OPP"
      return
    end
  end
  
  volt_readings={}
  expected_regulators_enabled = get_regulators_remain_on()
  test_failed = false
  err_msg = ''
  min_regulator_volt = 0.5
  measurement_time = get_power_domain_data(@equipment['dut1'].name)['power_domains'].size # approx 1 sec per channel to get 3 measurements
  rtc_only_extra_time = (wakeup_domain == 'rtc_only' ? 15 : 0)
  min_sleep_time   = 30 + rtc_only_extra_time # to guarantee that RTC alarm does not fire prior to board reaching suspend state
  measurement_time += rtc_only_extra_time
  rtc_suspend_time = [measurement_time, min_sleep_time].max
  suspend_time = (wakeup_domain == 'rtc'  or wakeup_domain == 'rtc_only') ? rtc_suspend_time : max_suspend_time
  if @test_params.params_chan.instance_variable_defined?(:@suspend) && @test_params.params_chan.suspend[0] == '1'
    @test_params.params_control.loop_count[0].to_i.times do |iter|
      power_wakeup_configuration(wakeup_domain, power_state)
      # Suspend
      start_time = Time.now
      suspend(wakeup_domain, power_state, suspend_time)
      #@equipment['dut1'].send_cmd("\x3", @equipment['dut1'].prompt, 1) if @test_params.params_chan.suspend[0] == '1'  # Ctrl^c is required for some reason w/ amsdk fs
            
      # Get voltage values for all channels in a hash
      if (volt_readings.size != 0) 
        new_volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
        volt_readings.each_key {|k|
          volt_readings[k] << new_volt_readings[k]
          puts "#{k} have #{volt_readings[k].size} samples"
        }
        expected_regulators_enabled.each {|domain|
          min_measured_volt = new_volt_readings["domain_" + domain  + "_volt_readings"].min
          if  min_measured_volt < min_regulator_volt
            test_failed = true
            err_msg += "On iteration #{iter}, Measured voltage #{min_measured_volt} for #{domain} domain is lower than expected #{min_regulator_volt}"
          end
        }

      else
        volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
        puts "volt_readings.size = #{volt_readings.size}"
      end
      
      # Resume from console
      elapsed_time = Time.now - start_time
      #sleep (suspend_time - elapsed_time) if elapsed_time < suspend_time and wakeup_domain == 'rtc'
      resume(wakeup_domain, max_resume_time)
      sleep 2
      wait_for_fs('dut1')
      @equipment['dut1'].send_cmd(" cat #{cpufreq_0}/stats/time_in_state", @equipment['dut1'].prompt)
    end
    
    volt_readings.each_key {|k|
      volt_readings[k].flatten!
      puts "#{k} have #{volt_readings[k].size} samples"
    }
    
    # Calculate power consumption
    power_readings = calculate_power_consumption(volt_readings, @equipment['dut1'], @equipment['multimeter1'])
    
    # Generate the plot of the power consumption for the given application
    perf = save_results(power_readings, volt_readings)
  end
  
  report_power_stats
ensure
  if perf.size > 0
    if test_failed
      set_result(FrameworkConstants::Result[:fail], err_msg)
    else
      set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
    end
  else
    errMessage = "Could not get Power Performance data" if !errMessage
    set_result(FrameworkConstants::Result[:fail], errMessage)
  end
end


# Function saves power consumption result
# Input parameters: Hash table populated Power consumptions for all domains.
# Return Parameter: Performance Array table for all voltages readings and powers consumptions.  
def save_results(power_consumption,voltage_reading,multimeter=@equipment['multimeter1'])
  perf = []; v1=[]; v2=[]; vtotal=[]
  power_plot_path = stat_plot(power_consumption['all_domains'],"POWER CONSUMPTION Vs Time", "Samples", "Power (mw)")
  mygraphurl = upload_file(power_plot_path)[1]
  @results_html_file.add_paragraph("PLEASE CLICK ME TO SEE POWER CONSUMPTION PLOT POINT BY POINT",nil, nil,mygraphurl)
  count = 0
  table_title = Array.new()
  table_title << 'SAMPLE NO'
  table_title <<  'All domains(mw)'
  multimeter.dut_power_domains.each do |domain|
   table_title <<   domain + "(mw)" 
  end
  multimeter.dut_power_domains.each do |domain|
   table_title <<   domain + "drop(v)" 
  end
  multimeter.dut_power_domains.each do |domain|
   table_title <<  domain + "(v)" 
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
  multimeter.dut_power_domains.each do |domain|
   table_data <<  power_consumption["domain_" +  domain + "_power_readings"] [count].to_s 
  end
  multimeter.dut_power_domains.each do |domain|
   table_data <<   voltage_reading["domain_" + domain + "drop_volt_readings"][count].to_s 
  end
  multimeter.dut_power_domains.each do |domain|
   table_data <<  voltage_reading["domain_" +  domain + "_volt_readings"][count].to_s
  end
   table_data = table_data 
    @results_html_file.add_row_to_table(res_table,table_data)
    count += 1
  }
 
  multimeter.dut_power_domains.each do |domain|
    perf << {'name' => domain + " Power", 'value' =>power_consumption["domain_" + domain + "_power_readings"], 'units' => "mw", 'significant_difference' => 100}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw", 'significant_difference' => 100}
  return perf
end




