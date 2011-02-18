require File.dirname(__FILE__)+'/../default_test'
require 'gnuplot.rb'

include WinceTestScript

 # Execute shell script in DUT(s) and save results.
  def run
     initial_vol_reading = Hash.new
	 final_vol_reading = Hash.new
	 final_power_reading = Hash.new
	 reading_difference = Hash.new
	 domain_power_consumption = Hash.new
	 vdd1_power_consumption = 0
	 vdd2_power_consumption = 0
    puts "\n WinceTestScript::run"
	#set ip state to the desired state 
	run_app(@test_params.params_chan.appname,true)
	change_ips_State(@test_params.params_chan.ipname,true)
	counter=0
    run_generate_script
    run_transfer_script
	@equipment['multimeter1'].connect({'type'=>'serial'})
	#configure multimeter 
	@equipment['multimeter1'].configure_multimeter(@test_params.params_chan.sample_count[0].to_i)
	# run stress test by setting the loop to desired value in the XML
	while counter < @test_params.params_chan.suspend_loop[0].to_i  
    run_call_script
	run_get_script_output
    # The sleep is needed to syncronize multimeter and application to run. This value has to be caliberated for each 
    # Release 	
	sleep @test_params.params_chan.delay[0].to_i 
	# final voltadge reading from the domains
	final_vol_reading.merge!(run_get_multimeter_output)
	# power consumption is calculated in this function 
	final_power_reading.merge!(calculate_power_consumption(final_vol_reading))
	# generates the plot of the power consumption for the given application
	power_consumption_plot(final_power_reading,)
	run_collect_performance_data(final_power_reading,final_vol_reading)
	query_ips_State(@test_params.params_chan.ips_to_query, true)
	#run_determine_test_outcome(final_power_reading,final_vol_reading,@test_params.params_chan, true)
	#run_save_results(final_power_reading,@test_params.params_chan,true)
	run_save_results(final_power_reading,final_vol_reading,@test_params.params_chan, true)
	#set ip state to the initial  state 
	change_ips_State(@test_params.params_chan.ipname,false)
	#query_ips_State(@test_params.params_chan.ips_to_query, true)
	counter += 1
	puts "############# Iteration Number ############## #{counter}"
	sleep 10 #This sleep statment is used by the loop. We sleep a litle bit before we go to the next loop iteration.
	end 
  end

  
   # The function collects voltage output from the multimeter channels and returns readings.
  def run_get_multimeter_output(expect_string=nil)
	volt_reading = ""
    puts "\n WinceTestScript::run_get_multimeter_output"
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    keep_checking = @equipment['multimeter1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
	wait_regex = ''
    @test_params.params_chan.sample_count[0].to_i.times {wait_regex = wait_regex + '.+,'}
    wait_regex.sub!(/,$/,'')
	counter=0
    while counter < @test_params.params_chan.loop_count[0].to_i         
		@equipment['multimeter1'].send_cmd("READ?", /#{wait_regex}/, @test_params.params_chan.timeout[0].to_i, false)
		#puts "READING READING #{@equipment['multimeter1'].response}"
		volt_reading += @equipment['multimeter1'].response+","
        counter += 1
      end
	  return sort_raw_data(volt_reading.strip)
  end

  # The function calculates  average,min,max,  volttage for all channels. All value are returned in hash table. 
  def sort_raw_data(raw_volt_reading)
    chan_ave_volt_reading = Hash.new 
	chan_max_volt_reading = Hash.new  
	chan_min_volt_reading = Hash.new
	chan_all_volt_reading = Hash.new
	volt_reading = Hash.new
	chan_1_volt_readings = Array.new
	chan_2_volt_readings = Array.new
	chan_3_volt_readings = Array.new
	chan_4_volt_readings = Array.new
	chan_5_volt_readings = Array.new
	chan_1_current_readings = Array.new
	chan_2_current_readings = Array.new	
 	chan_1_volt_reading = 0
	chan_2_volt_reading = 0
	chan_3_volt_reading = 0
	chan_4_volt_reading = 0
	chan_5_volt_reading = 0
	chan_1_current_reading = 0
	chan_2_current_reading = 0
	volt_reading_array = raw_volt_reading.split(/(?<=[\d,])[+-]/)
	test_file = File.new("C:/DVSDK/debug_file.txt","w+")
	volt_reading_array.each_index{|array_index|
	 mod = array_index % 5 
	 
	 case mod
	   when  0
	   chan_1_volt_reading += volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   chan_1_volt_readings << temp
	   chan_1_current_readings << temp/0.05
	   chan_1_current_reading += temp/0.05
	    test_file.write(temp.to_s+"\n")
	   when  1
	   chan_2_volt_reading += volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   temp = volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   chan_2_volt_readings << temp
	   chan_2_current_readings << temp/0.1
	   chan_2_current_reading += temp/0.1
	   test_file.write(temp.to_s+"\n")
	   when  2
	   chan_3_volt_reading += volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   chan_3_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   when  3
	   chan_4_volt_reading += volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   chan_4_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   when  4
	   chan_5_volt_reading += volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	   chan_5_volt_readings << volt_reading_array[array_index].gsub(/\+/,'').to_f + 0.00029
	 end 
	}
	test_file.close
	array_size = volt_reading_array.size/5
	#avarage reading for each channel
	chan_ave_volt_reading["chan_1"] = chan_1_volt_reading/array_size
	chan_ave_volt_reading["chan_2"] = chan_2_volt_reading/array_size
	chan_ave_volt_reading["chan_3"] = chan_3_volt_reading/array_size
	chan_ave_volt_reading["chan_4"] = chan_4_volt_reading/array_size
	chan_ave_volt_reading["chan_5"] = chan_5_volt_reading/array_size
	chan_ave_volt_reading["chan_4_current"] = chan_1_current_reading/array_size
	chan_ave_volt_reading["chan_5_current"] = chan_2_current_reading/array_size
	# maximume reading for each channel
	chan_max_volt_reading["chan_1"] = chan_1_volt_readings.max
	chan_max_volt_reading["chan_2"] = chan_2_volt_readings.max
	chan_max_volt_reading["chan_3"] = chan_3_volt_readings.max
	chan_max_volt_reading["chan_4"] = chan_4_volt_readings.max
	chan_max_volt_reading["chan_5"] = chan_5_volt_readings.max
	chan_max_volt_reading["chan_4_current"] = chan_1_current_readings.max
	chan_max_volt_reading["chan_5_current"] = chan_2_current_readings.max
	# minimume channel for each reading 
	chan_min_volt_reading["chan_1"] = chan_1_volt_readings.min
	chan_min_volt_reading["chan_2"] = chan_2_volt_readings.min
	chan_min_volt_reading["chan_3"] = chan_3_volt_readings.min
	chan_min_volt_reading["chan_4"] = chan_4_volt_readings.min
	chan_min_volt_reading["chan_5"] = chan_5_volt_readings.min
    chan_min_volt_reading["chan_4_current"] = chan_1_current_readings.min
	chan_min_volt_reading["chan_5_current"] = chan_2_current_readings.min

	# each reading for each channel
    chan_all_volt_reading["chan_1"] = chan_1_volt_readings
	chan_all_volt_reading["chan_2"] = chan_2_volt_readings
	chan_all_volt_reading["chan_3"] = chan_3_volt_readings
	chan_all_volt_reading["chan_4"] = chan_4_volt_readings
	chan_all_volt_reading["chan_5"] = chan_5_volt_readings
	chan_all_volt_reading["chan_1_current"] = chan_1_current_readings
	chan_all_volt_reading["chan_2_current"] = chan_2_current_readings
	# All Stats 
    volt_reading['ave'] = chan_ave_volt_reading
	volt_reading['max'] = chan_max_volt_reading
	volt_reading['min'] = chan_min_volt_reading
	volt_reading['all'] = chan_all_volt_reading
	return volt_reading
 end
 # The function calculates max,min,ava, and individuall power consumption for each domain(channel). 
def calculate_power_consumption(volt_reading)
    power_consumption = Hash.new
    vdd1_power_readings = Array.new
	vdd2_power_readings = Array.new
	vdd1_vdd2_power_readings = Array.new
	power_consumption['ave_vvd1'] = ((volt_reading['ave']['chan_1']* volt_reading['ave']['chan_4'])/0.05) * 1000    
	power_consumption['ave_vvd2'] = ((volt_reading['ave']['chan_2']* volt_reading['ave']['chan_5'])/0.1) * 1000 
	power_consumption['max_vvd1'] = ((volt_reading['max']['chan_1']* volt_reading['max']['chan_4'])/0.05) * 1000     
	power_consumption['max_vvd2'] = ((volt_reading['max']['chan_2']* volt_reading['max']['chan_5'])/0.1) * 1000 
    power_consumption['min_vvd1'] = ((volt_reading['min']['chan_1']* volt_reading['min']['chan_4'])/0.05) * 1000       
	power_consumption['min_vvd2'] = ((volt_reading['min']['chan_2']* volt_reading['min']['chan_5'])/0.1) * 1000 
	power_consumption['ave_vvd1_plus_vdd2'] = power_consumption['ave_vvd1'] + power_consumption['ave_vvd2']
	power_consumption['max_vvd1_plus_vdd2'] = power_consumption['max_vvd1'] + power_consumption['max_vvd2']
	power_consumption['min_vvd1_plus_vdd2'] = power_consumption['min_vvd1'] + power_consumption['min_vvd2']
	
	count = 0
	volt_reading['all']['chan_1'].each{|volt|
	 vdd1_power_readings << (volt* volt_reading['all']['chan_4'][count])/0.05 * 1000
     count += count 
	}	
	count = 0
  	 volt_reading['all']['chan_2'].each{|volt|
	 vdd2_power_readings  << (volt* volt_reading['all']['chan_5'][count])/0.1 * 1000
     count += count 
	}
	count = 0 
	vdd1_power_readings.each{|power|
	 vdd1_vdd2_power_readings << power + vdd2_power_readings[count]
	 count += 1
	}
    power_consumption['all_vvd1'] = vdd1_power_readings
	power_consumption['all_vvd2'] = vdd2_power_readings
	power_consumption['all_vvd1_vdd2'] = vdd1_vdd2_power_readings
	return power_consumption
end 

    # The function writes performance values into perf.log. Also write all results to HTML file to be linked to each test case result.  
def run_collect_performance_data(power_consumption,voltage_reading)
    perf_log = nil
    perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
	perf_log.puts('VDD1_AVERAGE_POWER_CONSUMPTION  ' +  power_consumption['ave_vvd1'].to_s + ' mw') 
	perf_log.puts('VDD1_MAXIMUME_POWER_CONSUMPTION ' +  power_consumption['max_vvd1'].to_s + ' mw')
	perf_log.puts('VDD1_MINIMUME_POWER_CONSUMPTION ' +  power_consumption['min_vvd1'].to_s + ' mw') 
	perf_log.puts('VDD2_AVERAGE_POWER_CONSUMPTION  ' +  power_consumption['ave_vvd2'].to_s + ' mw') 
	perf_log.puts('VDD2_MAXIMUME_POWER_CONSUMPTION ' +  power_consumption['max_vvd2'].to_s + ' mw')
	perf_log.puts('VDD2_MINIMUME_POWER_CONSUMPTION ' +  power_consumption['min_vvd2'].to_s + ' mw')
	perf_log.puts('VDD1_PLUS_VDD2_AVERAGE_POWER_CONSUMPTION ' +  power_consumption['ave_vvd1_plus_vdd2'].to_s + ' mw')
	perf_log.puts('VDD1_PLUS_VDD2_MAXIMUME_POWER_CONSUMPTION ' +  power_consumption['max_vvd1_plus_vdd2'].to_s + ' mw')
	perf_log.puts('VDD1_PLUS_VDD2_MINIMUME_POWER_CONSUMPTION ' +  power_consumption['min_vvd1_plus_vdd2'].to_s + ' mw')
    perf_log.puts('VDD1_AVERAGE_VOLTAGE  ' +  voltage_reading['ave']['chan_4'].to_s + ' v') 
	perf_log.puts('VDD1_MAXIMUME_VOLTAGE ' +  voltage_reading['max']['chan_4'].to_s + ' v')
	perf_log.puts('VDD1_MINIMUME_VOLTAGE ' +  voltage_reading['min']['chan_4'].to_s + ' v') 
	perf_log.puts('VDD2_AVERAGE_VOLTAGE  ' +  voltage_reading['ave']['chan_5'].to_s + ' v') 
	perf_log.puts('VDD2_MAXIMUME_VOLTAGE ' +  voltage_reading['max']['chan_5'].to_s + ' v')
	perf_log.puts('VDD2_MINIMUME_VOLTAGE ' +  voltage_reading['min']['chan_5'].to_s + ' v')
	mygraphfile = @files_dir+"/plot_#{@test_id}\.pdf";
	#mygraphfile = @files_dir+"/vdd1_plot.pdf";
	mygraphurl= mygraphfile.sub(@session_results_base_directory,@session_results_base_url).sub(/http:\/\//i,"")
    @results_html_file.add_paragraph("PLEASE CLICK ME TO SEE POWER CONSUMPTION PLOT POINT BY POINT",nil, nil,mygraphurl)	
	@results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["POWER CONSUMPTION STATISTICS",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
	@results_html_file.add_row_to_table(res_table,['PARAMETER NAME','VALUE','UNIT'])	
    @results_html_file.add_row_to_table(res_table,['VDD1_PLUS_VDD2_AVERAGE_POWER_CONSUMPTION',power_consumption['ave_vvd1_plus_vdd2'].to_s,' mw'])
    @results_html_file.add_row_to_table(res_table,['VDD1_PLUS_VDD2_MAXIMUME_POWER_CONSUMPTION',power_consumption['max_vvd1_plus_vdd2'].to_s,' mw'])	
    @results_html_file.add_row_to_table(res_table,['VDD1_PLUS_VDD2_MINIMUME_POWER_CONSUMPTION',power_consumption['min_vvd1_plus_vdd2'].to_s,' mw'])
    @results_html_file.add_row_to_table(res_table,['VDD1_AVERAGE_POWER_CONSUMPTION',power_consumption['ave_vvd1'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MAXIMUME_POWER_CONSUMPTION',power_consumption['max_vvd1'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MINIMUME_POWER_CONSUMPTION',power_consumption['min_vvd1'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD2_AVERAGE_POWER_CONSUMPTION',power_consumption['ave_vvd2'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MAXIMUME_POWER_CONSUMPTION',power_consumption['max_vvd2'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MINIMUME_POWER_CONSUMPTION',power_consumption['min_vvd2'].to_s,' mw'])
	@results_html_file.add_row_to_table(res_table,['VDD1_AVERAGE_VOLTAGE',voltage_reading['ave']['chan_4'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MAXIMUME_VOLTAGE',voltage_reading['max']['chan_4'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MINIMUME_VOLTAGE',voltage_reading['min']['chan_4'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD2_AVERAGE_VOLTAGE',voltage_reading['ave']['chan_5'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MAXIMUME_VOLTAGE',voltage_reading['max']['chan_5'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MINIMUME_VOLTAGE',voltage_reading['min']['chan_5'].to_s,' v'])
	@results_html_file.add_row_to_table(res_table,['VDD1_AVERAGE_CURRENT',voltage_reading['ave']['chan_4_current'].to_s,' A'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MAXIMUME_CURRENT',voltage_reading['max']['chan_4_current'].to_s,' A'])
	@results_html_file.add_row_to_table(res_table,['VDD1_MINIMUME_CURRENT',voltage_reading['min']['chan_4_current'].to_s,' A'])
	@results_html_file.add_row_to_table(res_table,['VDD2_AVERAGE_CURRENT',voltage_reading['ave']['chan_5_current'].to_s,' A'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MAXIMUME_CURRENT',voltage_reading['max']['chan_5_current'].to_s,' A'])
	@results_html_file.add_row_to_table(res_table,['VDD2_MINIMUME_CURRENT',voltage_reading['min']['chan_5_current'].to_s,' A'])	
	@results_html_file.add_paragraph("")
	res_table = @results_html_file.add_table([["VDD1 and VDD2 , VOLTAGES and  TOTAL POWER CONSUMPTION POINT BY POINT",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
	count = 0
	@results_html_file.add_row_to_table(res_table,["VDD1 and VDD2 Power in mw","VDD1 in mw","VDD2 in mw", "VDD2 voltage in V",  "VDD1 voltage in V", "VDD2 current in mA","VDD1 current in mA"])
	power_consumption['all_vvd1_vdd2'].each{|power|
    @results_html_file.add_row_to_table(res_table,[power.to_s,power_consumption['all_vvd1'][count].to_s,power_consumption['all_vvd2'][count].to_s,voltage_reading['all']['chan_4'][count].to_s,voltage_reading['all']['chan_5'][count].to_s,voltage_reading['all']['chan_1_current'][count].to_s,voltage_reading['all']['chan_2_current'][count].to_s])
     count += 1	 
	}	
  ensure
  perf_log.close if perf_log
end

  # The function verifies power consumption. #This power measure must be less than the expected power consumption for the test pass.
 def verify_power_consumption(power_consumption)
    if @test_params.params_chan.expected_power[0].to_s.strip.to_f > power_consumption['ave_vvd1_plus_vdd2'].to_s.strip.to_f then 
      result = 1 
    else
      result = 0 
    end
    return result
end

  # The function determines test outcome for power  consumption or policy
 def run_determine_test_outcome(power_consumption,voltage_reading,params_chan, action)
    perf_data = [];
    case params_chan.test_type[0].strip
	when  /power/
     perf_data << {'name' => "VDD1_2_Power_Consumption", 'value' => power_consumption['all_vvd1_vdd2'], 'units' => "mw"}
	 perf_data << {'name' => "VDD1_Power_Consumption", 'value' => power_consumption['all_vvd1'], 'units' => "mw"}
	 perf_data << {'name' => "VDD2_Power_Consumption", 'value' => power_consumption['all_vvd2'], 'units' => "mw"}
	 perf_data << {'name' => "VDD1_Voltage", 'value' => voltage_reading['all']['chan_5'], 'units' => "V"}
	 perf_data << {'name' => "VDD2_Voltage", 'value' => voltage_reading['all']['chan_4'], 'units' => "V"}
	 perf_data << {'name' => "VDD1_current", 'value' => voltage_reading['all']['chan_1_current'], 'units' => "mA"}
	 perf_data << {'name' => "VDD2_current", 'value' => voltage_reading['all']['chan_2_current'], 'units' => "mA"}
    if verify_power_consumption(power_consumption) == 1 then
      puts "-----------test passed---------"
      #result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
	  [FrameworkConstants::Result[:pass], "Test case PASS.",perf_data]
    else 
      puts "-----------test failed---------"
     # result, comment = [FrameworkConstants::Result[:fail], "This test failed."]
    [FrameworkConstants::Result[:fail], "Test case FAILED.",perf_data]	  
    end

   when /policy/
     # first query for the IPs status
     query_ips_State(params_chan.ips_to_query,action)
	 sleep 10
	 run_get_script_output
    if verify_ips_state(params_chan.ips_to_query,action)  == 1 then
      puts "-----------test passed---------"
      [FrameworkConstants::Result[:pass], "This test pass.",""]
    else 
      puts "-----------test failed---------"
     [FrameworkConstants::Result[:fail], "This test failed.",""]	
    end  
   end 
end

# this function save the result to the database. 
 # def run_save_results(power_consumption,params_chan,action)
    # puts "\n WinceTestScript::run_save_results"
    # result,comment = run_determine_test_outcome(power_consumption,params_chan,action)
    # if File.exists?(File.join(@wince_temp_folder,'perf.log'))
      # perfdata = []
      # data = File.new(File.join(@wince_temp_folder,'perf.log'),'r').readlines
      # data.each {|line|
	    # if /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line)
          # name,value,units = /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line).captures 
          # perfdata << {'name' => name, 'value' => value, 'units' => units}
        # end
      # }  
      # set_result(result,comment,perfdata)
    # else
      # set_result(result,comment)
    # end
  # end
# Write test result and performance data to results database (either xml or msacess file)
  def run_save_results(power_consumption,voltage_reading,params_chan, action)
    puts "\n WinceTestScript::run_save_results"
    result,comment,perfdata = run_determine_test_outcome(power_consumption,voltage_reading,params_chan, action)
    if perfdata
      set_result(result,comment,perfdata)
    else
      set_result(result,comment)
    end
  end
# This function plots the power consumpotion point by point for the whole clip duration.
def power_consumption_plot(power_consumption)
    puts "\n WinceTestScript::power_consumption_plot"
    plot_output = @files_dir+"/plot_#{@test_id}\.pdf"
	#plot_output = @files_dir+"/vdd1_plot.pdf"
	max_range  =  (power_consumption['all_vvd1'].size).to_i - 1
	Gnuplot.open { |gp|
		Gnuplot::Plot.new( gp ) { |plot|
			plot.output plot_output
			plot.terminal "pdf colour size 13cm,10cm"
			plot.title  "POWER CONSUMPTION POINT by POINT"
			plot.ylabel "POwer in mw unit"
			plot.xlabel "Number of Readings"
            x = (0..max_range).collect { |v| v.to_f }
			y = power_consumption['all_vvd1_vdd2'].collect { |v| v }
			plot.data << Gnuplot::DataSet.new( [x, y]) { |ds|
				ds.with = "lines"
				ds.linewidth = 4
			}
		}
	}
end 

 #The function changes state of certain IPs into desired state before runnig the clip/application. The function
 # has to be called  at the end of the test to change the IPs into initial state. In the xml file the ipname has to be defined, if 
 # there is no state change require it has to be set to nothing, then the function will do nothing. there is also action parameter to 
 # distinguish the two calls in  for this function. if true it sets the new state, if false it sets to state 0. 
 def change_ips_State(ips, action)
     puts "\n WinceTestScript::change_IPs_State"
	 ip_to_config  = false
	 FileUtils.mkdir_p @wince_temp_folder
     out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
	 ips.each{|ip|
	   ipname = ip.match(/[a-zA-z]+[0-9]/)[0]
	   state = action==true ? ip.match(/_[0-9]/)[0].gsub(/_/,"").to_i : 0
	   out_file.puts('\windows\pmsetd ' + ipname + ': ' + state.to_s + ' ' + @test_params.params_chan.index[0])
	   out_file.puts('\windows\pmgetd ' + ipname + ': ' + @test_params.params_chan.index[0])
	   ip_to_config  = true 
	 } 
	 out_file.close
	if ip_to_config == true then 
	   run_transfer_script
	   run_call_script
	end 

 end 
 
 # The function queries for the IPs state 
 def query_ips_State(ips, action)
     puts "\n WinceTestScript::query_ips_State"
	 ip_to_config  = false
	 FileUtils.mkdir_p @wince_temp_folder
     out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
	 ips.each{|ip|
	   ipname = ip.match(/[a-zA-z]+[0-9]/)[0]
	   state = action==true ? ip.match(/_[0-9]/)[0].gsub(/_/,"").to_i : 0
	   #out_file.puts('\windows\pmsetd ' + ipname + ': ' + state.to_s + ' ' + @test_params.params_chan.index[0])
	   out_file.puts('\windows\pmgetd ' + ipname + ': ' + @test_params.params_chan.index[0])
	   ip_to_config  = true 
	 } 
	 out_file.close
	if ip_to_config == true then 
	   run_transfer_script
	   run_call_script
	end 

 end 
 
 # This function check the state of the IPs on the desired sysmte power states. There reading must match 
 # the registry configuration of the IPs. For example the when the system is ON state, all the IPS must be 
 # on D0 state unless otherwise the policy is overwritten. 
 
  def verify_ips_state(ips, action)
  puts "\n power_test::verify_ips_state"
  states = Array.new
  temp = Array.new
  expected_states = Array.new
  ipnames =  Array.new
  #the first IP to be quered is the first to be checked.
  ips.each{|ip|
    ipnames << ip.match(/[a-zA-z]+[0-9]/)[0]
    state = action==true ? ip.match(/_[0-9]/)[0].gsub(/_/,"").to_i : 0
    temp << state
  } 
  count = 0 
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
 	if line.include? "GetDevicePower" then
	states << line.scan(/[A-Za-z0-9:,]+\('#{ipnames[count].strip}:', 0x1\)\s[A-Za-z:,\s]+([0-4])/)[0][0].to_i 
	count +=1
	end 
  }
  count = 0 
  temp.each{|n|
  expected_states << states[count].to_s.strip.eql?(n.to_s.strip)   
  count +=1
  }
  
  if expected_states.include?(false) ==  false  then 
     result = 1
  else 
	 result = 0
  end
  return result
end
 
 
# the function runs additional application  conigured in the test case.
def run_app(apps, action)
     puts "\n WinceTestScript::run_app"
	 ip_to_config  = false
	 FileUtils.mkdir_p @wince_temp_folder
     out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
	 apps.each{|ip|
	  out_file.puts(ip)
	   ip_to_config  = true 
	 } 
	 out_file.close
	if ip_to_config == true then 
	   run_transfer_script
	   run_call_script
	end 

 end 
 

  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
	media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
	put_file({'filename'=>'test.bat'})
	transfer_files(:@test_libs, :@var_test_libs_root)
    transfer_files(:@build_test_libs, :@var_build_test_libs_root)
	subfolder = "/common/Multimedia/power"
	src_folder = ""
	src_folder = SiteInfo::FILE_SERVER + subfolder
	# scipt if there was no file to ftp 
	if @test_params.params_chan.file_name[0] != ""
	test_output_files = put_file({'filename'=>@test_params.params_chan.file_name[0],'src_dir'=>src_folder,'dst_dir'=>media_location_hash[@test_params.params_chan.media_location[0]],'binary'=>true})
	end 
  end
  
   
