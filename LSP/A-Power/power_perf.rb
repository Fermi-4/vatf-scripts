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
  add_equipment('multimeter1') do |log_path|
    Object.const_get(@equipment['dut1'].params['multimeter1'].driver_class_name).new(@equipment['dut1'].params['multimeter1'],log_path)
  end
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>'serial'}) if @equipment['multimeter1'].instance_variable_defined?(:@serial_port)
end

def run
  perf = []
  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name))
  # Set DUT in appropriate state

  
  	puts "\n\n======= Current CPU Frequency =======\n" 
  	@equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
   	@equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies", @equipment['dut1'].prompt, 3)
  	supported_frequencies = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    
  if @test_params.params_chan.sleep_while_idle[0] != '0' ||  @test_params.params_chan.enable_off_mode[0] != '0'
  	# mount debugfs
  	@equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt)
  	@equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt)
#smart reflex ENABLE COMMANDS
        @equipment['dut1'].send_cmd("echo 1 > /debug/voltage/vdd_mpu/smartreflex/autocomp", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd("echo 1 > /debug/voltage/vdd_core/smartreflex/autocomp", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt)
  	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt) 
  	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.0/sleep_timeout", @equipment['dut1'].prompt)
  	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.1/sleep_timeout", @equipment['dut1'].prompt)
  	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.2/sleep_timeout", @equipment['dut1'].prompt)
  end
 
  dvfs_governor = @test_params.params_chan.instance_variable_defined?(:@dvfs_governor)? @test_params.params_chan.dvfs_governor[0].strip.downcase : "userspace"
  @equipment['dut1'].send_cmd("echo #{dvfs_governor} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor", @equipment['dut1'].prompt)

  if @test_params.params_chan.cpufreq[0] != '0' && !@test_params.params_chan.instance_variable_defined?(:@suspend) && dvfs_governor == "userspace"
  	# put device in avaiable OPP states
    raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
  	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
    new_opp = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    if !new_opp.include?(@test_params.params_chan.dvfs_freq[0])
      errMessage= "Could not set #{@test_params.params_chan.dvfs_freq[0]} OPP"
      return
    end
  end

  if @test_params.params_chan.instance_variable_defined?(:@app)
    cmd = @test_params.params_chan.app[0]
    cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
    cmd_thr = start_target_tests(cmd, cmd_timeout)
  end

  if @test_params.params_chan.instance_variable_defined?(:@suspend)
      @equipment['dut1'].send_cmd("sync; echo mem > /sys/power/state", /Freezing remaining freezable tasks/, 120, false) if @test_params.params_chan.suspend[0] == '1'
  end
  sleep 5

  # Get voltage values for all channels in a hash
  volt_readings = @equipment['multimeter1'].get_multimeter_output(@test_params.params_control.loop_count[0].to_i, @test_params.params_equip.timeout[0].to_i) 
  # Calculate power consumption
  power_readings = calculate_power_consumption(volt_readings, @equipment['multimeter1'])
  
  # Generate the plot of the power consumption for the given application
  perf = save_results(power_readings, volt_readings)

  if @test_params.params_chan.instance_variable_defined?(:@app)
    #cmd_thr.join
    result = cmd_thr.value
    set_result(result[0], result[1])
  end

  sleep 2
  puts "\n\n======= Power Domain states info =======\n"
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Current CPU Frequency =======\n"
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd(" cat /debug/pm_debug/count", @equipment['dut1'].prompt, 1) 
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  #dutThread.join if dutThread
ensure
  if perf.size > 0
    set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
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
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i - 1] + "(mw)" 
  end
  for i in (1..multimeter.number_of_channels/2) 
   table_title <<   multimeter.dut_power_domains[i -1] + "drop(v)" 
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
  perf << {'name' => @equipment['multimeter1'].dut_power_domains[i - 1] + " Power", 'value' =>power_consumption["domain_" + @equipment['multimeter1'].dut_power_domains[i - 1] + "_power_readings"], 'units' => "mw"}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw"}
  return perf
end




def start_target_tests(cmd, timeout)
  thr = Thread.new(cmd, timeout) {|c, t|
    time = Time.now
    failure = false
    result = [FrameworkConstants::Result[:pass], "Test completed without errors"]

    @eth_ip_addr = get_ip_addr()
    @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
    old_telnet_port = @equipment['dut1'].target.platform_info.telnet_port
    @equipment['dut1'].target.platform_info.telnet_port = 23
    @equipment['dut1'].connect({'type'=>'telnet'})
    @equipment['dut1'].target.platform_info.telnet_port = old_telnet_port

    cmd_timeout = t
    while ((Time.now - time) < @test_params.params_control.test_duration[0].to_f && !failure )
      begin
        actual_cmd = eval('"'+c.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')
        @equipment['dut1'].target.telnet.send_cmd(actual_cmd, @equipment['dut1'].prompt, cmd_timeout)
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to run the test"]
        failure = true
      end
      @equipment['dut1'].log_info("Telnet Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
      begin
        @equipment['dut1'].target.telnet.send_cmd("echo $?",/^0[\0\n\r]+/m, 10) if !failure
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "Test returned non-zero value"]
        failure = true
      end
    end

    result
  }
  return thr
end

