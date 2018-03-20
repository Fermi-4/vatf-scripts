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

def enable_smartreflex(e='dut1')
  @equipment[e].send_cmd("find /sys/kernel/debug/ -type d -name smartreflex -exec sh -c 'echo 1 > {}/autocomp' \;", @equipment[e].prompt)
end

def enable_sleep_while_idle(e='dut1')
  if @test_params.params_chan.sleep_while_idle[0] != '0'
    @equipment[e].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /sys/kernel/debug/pm_debug/sleep_while_idle", @equipment[e].prompt)
  end
end

def enable_off_mode(e='dut1')
  if @test_params.params_chan.enable_off_mode[0] != '0'
    @equipment[e].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /sys/kernel/debug/pm_debug/enable_off_mode", @equipment[e].prompt) 
  end
end

def set_opp(cpu=0, e='dut1')
  dvfs_governor = @test_params.params_chan.instance_variable_defined?(:@dvfs_governor)? @test_params.params_chan.dvfs_governor[0].strip.downcase : "userspace"
  @equipment[e].send_cmd("echo #{dvfs_governor} > /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_governor", @equipment[e].prompt)
  if @test_params.params_chan.cpufreq[0] != '0' && !@test_params.params_chan.instance_variable_defined?(:@suspend) && dvfs_governor == "userspace"
    set_cpu_opp(@test_params.params_chan.dvfs_freq[0], cpu, e)
  end
end

def configure_dut(e='dut1')
  enable_smartreflex
  enable_sleep_while_idle
  enable_off_mode
  set_opp
end

def start_app(e='dut1')
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  run_via_telnet = @test_params.params_chan.instance_variable_defined?(:@telnet) ? @test_params.params_chan.telnet[0].to_i : 1
  if @test_params.params_chan.instance_variable_defined?(:@app) and @test_params.params_chan.app[0] == 'sleep'
    Thread.new(cmd_timeout) {|t|
      @equipment[e].send_cmd("sleep #{t}", @equipment[e].prompt, t+5)
    }
  elsif @test_params.params_chan.instance_variable_defined?(:@app)
    cmd = @test_params.params_chan.app.join(';')
    @cmd_thr = start_target_tests(cmd, cmd_timeout, run_via_telnet, e)
  end
end

def run
  perf = []
  app_defined = false
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'
  
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))
  
  enable_pm_debug_messages()

  configure_dut

  start_app

  suspend(wakeup_domain, power_state, 120) if @test_params.params_chan.instance_variable_defined?(:@suspend) and @test_params.params_chan.suspend[0] == '1'

  sleep 10  # Give enough time to apps to start running

  # Get voltage values for all channels in a hash
  volt_readings = @equipment['multimeter1'].get_multimeter_output(@test_params.params_control.loop_count[0].to_i, @test_params.params_equip.timeout[0].to_i) 
  # Calculate power consumption
  power_readings = calculate_power_consumption(volt_readings, @equipment['dut1'], @equipment['multimeter1'])
  
  # Generate the plot of the power consumption for the given application
  perf = save_results(power_readings, volt_readings)

  if @test_params.params_chan.instance_variable_defined?(:@app) and @test_params.params_chan.app[0] != 'sleep'
    app_defined = true
    result = @cmd_thr.value
  end

  report_power_stats
  
ensure
  if perf.size > 0 and (!app_defined or (app_defined and result[0] == FrameworkConstants::Result[:pass]))
    set_result(FrameworkConstants::Result[:pass], "Power Performance data collected",perf)
  elsif app_defined
    set_result(result[0], result[1])
  else
    set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data")
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
  perf << {'name' => @equipment['multimeter1'].dut_power_domains[i - 1] + " Power", 'value' =>power_consumption["domain_" + @equipment['multimeter1'].dut_power_domains[i - 1] + "_power_readings"], 'units' => "mw", 'significant_difference' => 100}
  end 
  perf << {'name' => "Total Power", 'value' => power_consumption["all_domains"], 'units' => "mw", 'significant_difference' => 100}
  return perf
end




def start_target_tests(cmd, timeout, run_via_telnet, e='dut1')
  thr = Thread.new(cmd, timeout, run_via_telnet) {|c, t, run_via_telnet|
    time = Time.now
    failure = false
    result = [FrameworkConstants::Result[:pass], "Test completed without errors"]
    dut_object = @equipment[e]

    if run_via_telnet == 1
      @eth_ip_addr = get_ip_addr()
      if !@eth_ip_addr
        @equipment[e].send_cmd("ifup eth0")
        @eth_ip_addr = get_ip_addr()
      end

      @equipment[e].target.platform_info.telnet_ip = @eth_ip_addr
      old_telnet_port = @equipment[e].target.platform_info.telnet_port
      @equipment[e].target.platform_info.telnet_port = 23
      @equipment[e].connect({'type'=>'telnet'})
      @equipment[e].target.platform_info.telnet_port = old_telnet_port
      dut_object = @equipment[e].target.telnet
    end

    cmd_timeout = t
    while ((Time.now - time) < @test_params.params_control.test_duration[0].to_f && !failure )
      begin
        actual_cmd = eval('"'+c.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')
        dut_object.send_cmd(actual_cmd, @equipment[e].prompt, cmd_timeout)
      rescue Timeout::Error => er
        @equipment[e].log_info("TIMEOUT ERROR. Data START:\n #{dut_object.response}\nData END")
        result = [FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to run the test"]
        failure = true
      end
      @equipment[e].log_info("Data START:\n #{dut_object.response}\nData END")
      begin
        dut_object.send_cmd("echo $?",/^0[\0\n\r]+/m, 10) if !failure
      rescue Timeout::Error => er
        @equipment[e].log_info("TIMEOUT ERROR. Data START:\n #{dut_object.response}\nData END")
        result = [FrameworkConstants::Result[:fail], "Test returned non-zero value"]
        failure = true
      end
    end

    result
  }
  return thr
end

