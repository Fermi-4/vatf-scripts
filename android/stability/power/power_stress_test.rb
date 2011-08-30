require File.dirname(__FILE__)+'/../../android_test_module' 
require File.dirname(__FILE__)+'/../../keyevents_module'
require File.dirname(__FILE__)+'/../../power_events_module'
require File.dirname(__FILE__)+'/../../power_module'
include AndroidTest
include AndroidKeyEvents
include PowerEventsModule
include PowerModule

require 'gnuplot.rb'

include AndroidTest

def setup
  puts "\n====================\nPATH=#{ENV['PATH']}\n"
  #super
  # Connect to multimeter
  @equipment['multimeter1'].connect({'type'=>'serial'})
  enable_ethernet 
end

def run
  perf = []
  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(@test_params.params_chan.sample_count[0].to_i)
  # Set DUT in appropriate state

  if @test_params.params_chan.instance_variable_defined?(:@disabled_cpu_idle_modes)
    @test_params.params_chan.disabled_cpu_idle_modes.each do |idle_mode|
      data = send_adb_cmd("shell \"echo 1 > /debug/pm_debug/#{idle_mode.strip.downcase}\"")
        puts "\n\n======= DEBUG =======\n" +  send_adb_cmd("shell cat /debug/pm_debug/#{idle_mode.strip.downcase}")
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

  #I am enabling smart reflex for suspend/resume test area. I am running the others with default smart reflex configuration. 
 
  
 #added by Yebio to be review 
  if @test_params.params_chan.instance_variable_defined?(:@intent) 
  cmd = "push " + @test_params.params_chan.host_file_path[0] + " " +     @test_params.params_chan.target_file_path[0]
  #send file push command 
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
  set_no_wakelock()
  puts "Alarm Deleting"
  alarm_delete()
  number_of_failures = 0
  counter = 0
  power_readings = Hash.new()
  @test_params.params_chan.iterations[0].to_i.times do
  counter = counter + 1
  puts "Number ot iterations excuted so far #{counter}"
  puts "Alarm Setting "
  set_alarm()
  puts "Waiting for suspending message."
  puts @equipment['dut1'].send_cmd("netcfg", /Suspending\s+console/, 100, false)
  #sleep 80
  sleep 5
  # Get voltage values for all channels in a hash
  volt_readings = run_get_multimeter_output      
  # Calculate power consumption
  power_readings = calculate_mean_power_consumption(volt_readings)
  puts "MEAN VDD1 POWER READING #{power_readings['all_vvd1']}"
  puts "MEAN VDD2 POWER READING #{power_readings['all_vvd2']}" 
  puts "MEAN VDD1 and VDD2 POWER READING #{power_readings['all_vvd1_vdd2']}"    
 
  if  power_readings['all_vvd1'] > 0.01  or power_readings['all_vvd2'] > 0.01 or power_readings['all_vvd1_vdd2'] > 0.01
   number_of_failures = number_of_failures + 1 #only one is added to per iteration
   perf = save_results(power_readings)
  
  end 
  
  @equipment['dut1'].send_cmd("netcfg", /suspend\s+of\s+devices\s+complete/, 100, false)
  #sleep 40
  sleep 5
 send_events_for(get_events(@test_params.params_chan.alarm_dismis[0]))
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
 


  # Generate the plot of the power consumption for the given application
  #power_consumption_plot(power_readings)
  #perf = save_results(power_readings)

  dutThread.join if dutThread
ensure

end

def save_results(power_consumption)
  perf = []; v1=[]; v2=[]; vtotal=[]
  @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["VDD1 and VDD2 , VOLTAGES and  TOTAL POWER CONSUMPTION POINT BY POINT",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
  count = 0
  @results_html_file.add_row_to_table(res_table,["Sample", "VDD1 and VDD2 Power in mw","VDD1 in mw","VDD2 in mw"])
    @results_html_file.add_row_to_table(res_table,[1, power_consumption['all_vvd1_vdd2'],power_consumption['all_vvd1'],power_consumption['all_vvd2']])
return perf
end

def run_get_multimeter_output
  sleep 5    # Make sure multimeter is configured and DUT is in the right state
  volt_reading = []
  counter=0
  while counter < @test_params.params_chan.loop_count[0].to_i
    Kernel.print("Collecting sample #{counter}\n")
    @equipment['multimeter1'].send_cmd("READ?", /.+?,.+?,.+?,.+?,[^\r\n]+/, @test_params.params_chan.timeout[0].to_i, false)
    d =  @equipment['multimeter1'].response
    Kernel.print("#{d}\n")
    volt_reading << @equipment['multimeter1'].response
    counter += 1
    #sleep 0.5
  end
  return sort_raw_data(volt_reading)
end

# Procedure to meaasure power on AM37x.
# chan1= vdrop at vdd1 , chan2=vdrop at vdd2, chan3=ignore, chan4=vdd1, chan5=vdd2
def sort_raw_data(volt_readings)
  chan_all_volt_reading = Hash.new
  chan_1_volt_readings = Array.new
  chan_2_volt_readings = Array.new
  chan_3_volt_readings = Array.new
  chan_4_volt_readings = Array.new
  chan_5_volt_readings = Array.new
  chan_1_current_readings = Array.new
  chan_2_current_readings = Array.new
  volt_reading_array = Array.new
  volt_readings.each do |current_line| 
    current_line_arr = current_line.strip.split(/[,\r\n]+/)
    if current_line_arr.length == 5 && current_line.match(/([+-]\d+\.\d+E[+-]\d+,){4}[+-]\d+\.\d+E[+-]\d+/)
      volt_reading_array.concat(current_line_arr)
    else 
    puts "NOTHING #{current_line}"
    end
  end
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

def calculate_mean_power_consumption(volt_reading)
  power_consumption = Hash.new
  vdd1_power_readings = Array.new
  vdd2_power_readings = Array.new
  vdd1_vdd2_power_readings = Array.new
  
  volt_reading['chan_1'].each_index{|i|
    vdd1_power_readings << ((volt_reading['chan_1'][i] * volt_reading['chan_4'][i])/0.05) * 1000
    vdd2_power_readings  << ((volt_reading['chan_2'][i] * volt_reading['chan_5'][i])/0.1) * 1000
    vdd1_vdd2_power_readings << vdd1_power_readings[i] + vdd2_power_readings[i]
  }
  vdd1_mean_power_reading =  mean(vdd1_power_readings)
  vdd2_mean_power_reading =  mean(vdd2_power_readings)
  vdd1_vdd2_mean_power_readings = mean(vdd1_vdd2_power_readings)

  power_consumption['all_vvd1'] = vdd1_mean_power_reading
  power_consumption['all_vvd2'] = vdd2_mean_power_reading
  power_consumption['all_vvd1_vdd2'] = vdd1_vdd2_mean_power_readings
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




