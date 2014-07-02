require File.dirname(__FILE__)+'/../default_test_module' 
require File.dirname(__FILE__)+'/../../lib/multimeter_power'
require File.dirname(__FILE__)+'/../../lib/evms_data'  
require 'gnuplot.rb'

include LspTestScript
include MultimeterModule
include EvmData

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

  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))
  
	puts "\n\n======= Current CPU Frequency =======\n" 
	@equipment['dut1'].send_cmd("cat #{cpufreq_0}/scaling_cur_freq", @equipment['dut1'].prompt, 3)
 	@equipment['dut1'].send_cmd(" cat #{cpufreq_0}/scaling_available_frequencies", @equipment['dut1'].prompt, 3)
	supported_frequencies = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    
  # Configure DUT 	
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt) 
  cmd = CmdTranslator.get_linux_cmd({'cmd'=>'enable_uart_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})
  @equipment['dut1'].send_cmd(cmd , @equipment['dut1'].prompt) if cmd.to_s != ''
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
  
  # set uart to gpio in standby_gpio_pad_conf so that uart can wakeup from standby
  if power_state == 'standby' && wakeup_domain == 'uart'
    @equipment['dut1'].send_cmd("cd /debug/omap_mux/board", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'set_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})}" , @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'get_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})}", @equipment['dut1'].prompt, 10)
  end

  if wakeup_domain == 'uart'
    # Disable usb wakeup to reduce standby power
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'disable_usb_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})
    @equipment['dut1'].send_cmd(cmd , @equipment['dut1'].prompt) if cmd.to_s != ''
    # Disable tsc wakeup tp reduce standby power
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'disable_tsc_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment['dut1'].get_linux_version})
    @equipment['dut1'].send_cmd(cmd , @equipment['dut1'].prompt) if cmd.to_s != ''
  end

  volt_readings={}
  measurement_time = get_power_domain_data(@equipment['dut1'].name)['power_domains'].size # approx 1 sec per channel to get 3 measurements
  min_sleep_time   = 30 # to guarantee that RTC alarm does not fire prior to board reaching suspend state
  rtc_suspend_time = [measurement_time, min_sleep_time].max
  suspend_time = wakeup_domain == 'rtc' ? rtc_suspend_time : max_suspend_time 
  if @test_params.params_chan.instance_variable_defined?(:@suspend) && @test_params.params_chan.suspend[0] == '1'
    @test_params.params_control.loop_count[0].to_i.times do
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
      else
        volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
        puts "volt_readings.size = #{volt_readings.size}"
      end
      
      # Resume from console
      elapsed_time = Time.now - start_time
      sleep (suspend_time - elapsed_time) if elapsed_time < suspend_time and wakeup_domain != 'uart'
      resume(wakeup_domain, max_resume_time)
      @equipment['dut1'].send_cmd(" cat #{cpufreq_0}/stats/time_in_state", @equipment['dut1'].prompt, 1)
      sleep 1
    end
    
    volt_readings.each_key {|k|
      volt_readings[k].flatten!
      puts "#{k} have #{volt_readings[k].size} samples"
    }
    
    # Calculate power consumption
    power_readings = calculate_power_consumption(volt_readings, @equipment['multimeter1'])
    
    # Generate the plot of the power consumption for the given application
    perf = save_results(power_readings, volt_readings)
  end
  
  puts "\n\n======= Power Domain states info =======\n"
  @equipment['dut1'].send_cmd(" cat #{cpufreq_0}/stats/time_in_state", @equipment['dut1'].prompt, 1)
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Current CPU Frequency =======\n"
  @equipment['dut1'].send_cmd(" cat #{cpufreq_0}/scaling_cur_freq", @equipment['dut1'].prompt, 1)
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd(" cat /debug/pm_debug/count", @equipment['dut1'].prompt, 1) 
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
ensure
  if perf.size > 0
    set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
  else
    errMessage = "Could not get Power Performance data" if !errMessage
    set_result(FrameworkConstants::Result[:fail], errMessage)
  end
end

def suspend(wakeup_domain, power_state, suspend_time)
  @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 120)
  if wakeup_domain == 'uart'
    @equipment['dut1'].send_cmd("echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/i, suspend_time, false)
  elsif wakeup_domain == 'rtc'
    @equipment['dut1'].send_cmd("rtcwake -d /dev/rtc0 -m #{power_state} -s #{suspend_time}", /Freezing remaining freezable tasks/i, suspend_time, false)
  else
    raise "#{wakeup_domain} wakeup domain is not supported"
  end
  raise "DUT took more than #{suspend_time} seconds to suspend" if @equipment['dut1'].timeout?
  sleep 2 # extra time to make sure board is sleep 
end

def resume(wakeup_domain, max_resume_time)
  max_resume_time.times do |i|
    @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 1, false)
    break if !@equipment['dut1'].timeout?
    raise "DUT took more than #{max_resume_time} seconds to resume" if i == (max_resume_time-1)
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
    perf << {'name' => domain + " Power", 'value' =>power_consumption["domain_" + domain + "_power_readings"], 'units' => "mw"}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw"}
  return perf
end




