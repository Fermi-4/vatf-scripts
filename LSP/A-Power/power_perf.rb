require File.dirname(__FILE__)+'/../default_test_module' 
require 'gnuplot.rb'

include LspTestScript

def setup
  puts "\n====================\nPATH=#{ENV['PATH']}\n"
  super
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>'serial'})

end

def run
  perf = []
  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(@test_params.params_equip.sample_count[0].to_i)
  # Set DUT in appropriate state

  if @test_params.params_chan.cpufreq[0] != '0'
	puts "\n\n======= Current CPU Frequency =======\n" 
	@equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)

	@equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	supported_frequencies = @equipment['dut1'].response.split(/\s+/)  
	#raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
	# mount debugfs
	@equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	#if @test_params.params_chan.cpufreq[0] != 0
	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt, 1) 
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.0/sleep_timeout", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.1/sleep_timeout", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("echo 5 > /sys/devices/platform/omap/omap_uart.2/sleep_timeout", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
	#end

	# put device in avaiable OPP states
	@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", @equipment['dut1'].prompt, 1)
	@equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 10)
  end

  if @test_params.params_chan.instance_variable_defined?(:@suspend)
      @equipment['dut1'].send_cmd("echo mem > /sys/power/state", @equipment['dut1'].prompt, 10) if @test_params.params_chan.suspend[0] == '1'
  end
  sleep 10

  # Get voltage values for all channels in a hash
  volt_readings = run_get_multimeter_output      
  # Calculate power consumption
  power_readings = calculate_power_consumption(volt_readings)
  # Generate the plot of the power consumption for the given application
  power_consumption_plot(power_readings)
  perf = save_results(power_readings, volt_readings)

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
    set_result(FrameworkConstants::Result[:fail], "Could not get Power Performance data")
  end
end

def save_results(power_consumption,voltage_reading)
  perf = []; v1=[]; v2=[]; vtotal=[]
  mygraphfile = @files_dir+"/plot_#{@test_id}\.pdf";
  mygraphurl= mygraphfile.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"")
    @results_html_file.add_paragraph("PLEASE CLICK ME TO SEE POWER CONSUMPTION PLOT POINT BY POINT",nil, nil,mygraphurl)
  @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["VDD1 and VDD2 , VOLTAGES and  TOTAL POWER CONSUMPTION POINT BY POINT",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
  count = 0
  @results_html_file.add_row_to_table(res_table,["VDD1 and VDD2 Power in mw","VDD1 in mw","VDD2 in mw", "VDD1 voltage in V",  "VDD2 voltage in V"])
  power_consumption['all_vvd1_vdd2'].each{|power|
    @results_html_file.add_row_to_table(res_table,[power.to_s,power_consumption['all_vvd1'][count].to_s,power_consumption['all_vvd2'][count].to_s,voltage_reading['chan_4'][count].to_s,voltage_reading['chan_5'][count].to_s])
    v1 << power_consumption['all_vvd1'][count]
    v2 << power_consumption['all_vvd2'][count]
    vtotal << power
    count += 1
  }
  perf << {'name' => "VDD1 Power", 'value' => v1, 'units' => "mw"}
  perf << {'name' => "VDD2 Power", 'value' => v2, 'units' => "mw"}
  perf << {'name' => "VDD1+VDD2 Power", 'value' => vtotal, 'units' => "mw"}
  return perf
end

def run_get_multimeter_output
  sleep 5    # Make sure multimeter is configured and DUT is in the right state
  volt_reading = ""
  counter=0
  while counter < @test_params.params_control.loop_count[0].to_i
    Kernel.print("Collecting sample #{counter}\n")
    @equipment['multimeter1'].send_cmd("READ?", /.+,.+,.+,.+,.+/, @test_params.params_equip.timeout[0].to_i, false)
    d =  @equipment['multimeter1'].response
    Kernel.print("#{d}\n")
    volt_reading += @equipment['multimeter1'].response+","
    counter += 1
  end
  return sort_raw_data(volt_reading.strip)
end

# Procedure to meaasure power on AM37x.
# chan1= vdrop at vdd1 , chan2=vdrop at vdd2, chan3=ignore, chan4=vdd1, chan5=vdd2
def sort_raw_data(raw_volt_reading)
  chan_all_volt_reading = Hash.new
  chan_1_volt_readings = Array.new
  chan_2_volt_readings = Array.new
  chan_3_volt_readings = Array.new
  chan_4_volt_readings = Array.new
  chan_5_volt_readings = Array.new
  chan_1_current_readings = Array.new
  chan_2_current_readings = Array.new 
  volt_reading_array = raw_volt_reading.split(",")
  volt_reading_array.each_index{|array_index|
   mod = array_index % 5 
   case mod
     when  0
     temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     chan_1_volt_readings << temp
     chan_1_current_readings << temp/0.05
     when  1
     temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     chan_2_volt_readings << temp
     chan_2_current_readings << temp/0.1
     when  2
     chan_3_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     when  3
     chan_4_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
     when  4
     chan_5_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
   end 
  }
  # each reading for each channel
  chan_all_volt_reading["chan_1"] = chan_1_volt_readings
  chan_all_volt_reading["chan_2"] = chan_2_volt_readings
  chan_all_volt_reading["chan_3"] = chan_3_volt_readings
  chan_all_volt_reading["chan_4"] = chan_4_volt_readings
  chan_all_volt_reading["chan_5"] = chan_5_volt_readings
  chan_all_volt_reading["chan_1_current"] = chan_1_current_readings
  chan_all_volt_reading["chan_2_current"] = chan_2_current_readings
  
  return chan_all_volt_reading
 end

def calculate_power_consumption(volt_reading)
  power_consumption = Hash.new
  vdd1_power_readings = Array.new
  vdd2_power_readings = Array.new
  vdd1_vdd2_power_readings = Array.new
  
  volt_reading['chan_1'].each_index{|i|
    vdd1_power_readings << ((volt_reading['chan_1'][i] * volt_reading['chan_4'][i])/0.05) * 1000
    vdd2_power_readings  << ((volt_reading['chan_2'][i] * volt_reading['chan_5'][i])/0.1) * 1000
    vdd1_vdd2_power_readings << vdd1_power_readings[i] + vdd2_power_readings[i]
  }
  
  power_consumption['all_vvd1'] = vdd1_power_readings
  power_consumption['all_vvd2'] = vdd2_power_readings
  power_consumption['all_vvd1_vdd2'] = vdd1_vdd2_power_readings
  return power_consumption
end 

# This function plots the power consumpotion point by point for the whole clip duration.
def power_consumption_plot(power_consumption)
  plot_output = @files_dir+"/plot_#{@test_id}\.pdf"
  max_range  =  (power_consumption['all_vvd1'].size).to_i - 1
  puts "\nDEBUG\nmaxrange=#{max_range}=========\nDEBUG"
  Gnuplot.open { |gp|
    Gnuplot::Plot.new( gp ) { |plot|
      plot.terminal "post eps colour size 13cm,10cm"
      plot.output plot_output
      plot.title  "POWER CONSUMPTION Vs Time"
      plot.ylabel "Power (mw)"
      plot.xlabel "Samples"
            x = (0..max_range).collect { |v| v.to_f }
      y = power_consumption['all_vvd1_vdd2'].collect { |v| v }
      plot.data << Gnuplot::DataSet.new( [x, y]) { |ds|
        ds.with = "lines"
        ds.linewidth = 4
      }
      
    }
  }
end 



