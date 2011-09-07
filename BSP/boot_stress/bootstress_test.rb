require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript
  
 # Execute shell script in DUT(s) and save results.
  def run
    puts "\n WinceTestScript::run"
	boot_data = Hash.new
    boot_data = multi_boot
	puts "Boot_Data is #{boot_data}\n"
    result=run_collect_performance_data(boot_data)
    run_save_results(result)
  end
  
  # Boot DUT if kernel image was specified in the test parameters
  
  def setup_boot
   puts "\n BootStress::setup_boot"
  end
  
  def multi_boot
    puts "\n Bootstress::multi_boot"
	loop_count = 0
	serial_output_good=0
	telnet_output_good=0
	boot_data = Hash.new
	bootup_time = Hash.new
	boot_time=Array.new
	bootup_result=Array.new
	test_result = Array[false,1000]
	regexp = @test_params.params_chan.bootup_string[0]
	if (@test_params.params_chan.test_type[0] == "boot_stress")
    while (loop_count.to_i < @test_params.params_chan.number_of_boots[0].to_i)
	@equipment['dut1'].connect({'type'=>'serial'})
      puts "Power cycling the board ........\n\n\n"
	  serial_output = false
	  if (@test_params.params_chan.image_location[0] == "nand" || @test_params.params_chan.image_location[0] =="sd")
      @power_handler.reset(@equipment['dut1'].power_port)
	  elsif (@test_params.params_chan.image_location[0] == "ethernet")
	   boot_params = {'power_handler'=> @power_handler, 'test_params' => @test_params}
	   @equipment['dut1'].boot(boot_params)
	  end
	  if (!@equipment['dut1'].wait_for(regexp,@test_params.params_chan.max_wait[0].to_i))
	    end_time_of_test = Time.now
	    serial_output=true
		puts "Did see the regexp as expected \n"
	    serial_output_good = serial_output_good+1
	  else 
	     @equipment['dut1'].send_cmd("#Serial port output not detected for loop_count #{loop_count}",@equipment['dut1'].prompt)
	  end
	  puts "will sleep before trying to telnet to target\n"
	  sleep 5
	puts "Result of test_result from run_get_script is #{serial_output_good}\n"
	puts "trying to telnet to target\n"
	begin
	if (serial_output && @equipment['dut1'].connect({'type'=>'telnet'}))
      telnet_output_good = telnet_output_good+1
	 puts "Success with telnet\n"
	end
	 rescue 
	  puts "Exception at telnet iteration number #{loop_count}\n"
	  @equipment['dut1'].send_cmd("#Telnet not successful for loop_count #{loop_count}",@equipment['dut1'].prompt)
	 ensure
	 loop_count = loop_count + 1
	 @equipment['dut1'].disconnect
	 boot_data['total'] = @test_params.params_chan.number_of_boots[0].to_i
	boot_data['serial_success'] = serial_output_good
	boot_data['telnet_success'] = telnet_output_good
    end
	end
	return boot_data
	else
	   while (loop_count.to_i < 3)
	start_time_of_test = Time.now
	@equipment['dut1'].connect({'type'=>'serial'})
      puts "Power cycling the board ........\n\n\n"
	  serial_output = false
	  if (@test_params.params_chan.image_location[0] == "nand" || @test_params.params_chan.image_location[0] =="sd")
      @power_handler.reset(@equipment['dut1'].power_port)
	  elsif (@test_params.params_chan.image_location[0] == "ethernet")
	   puts "ENTERED ethernet boot mode\n"
	   boot_params = {'power_handler'=> @power_handler, 'test_params' => @test_params}
	   @equipment['dut1'].boot(boot_params)
	  end
	  if (!@equipment['dut1'].wait_for(regexp,@test_params.params_chan.max_wait[0].to_i))
	    end_time_of_test = Time.now
	    serial_output=true
		puts "Did see the regexp as expected \n"
	    serial_output_good = serial_output_good+1
		boot_time<<end_time_of_test-start_time_of_test
	  end
	  
	puts "Result of test_result from run_get_script is #{serial_output_good}\n"
	 loop_count = loop_count + 1
	 @equipment['dut1'].disconnect
    end
	puts "Bootup_time is #{bootup_time}\n"
	bootup_time['time']=boot_time
	return bootup_time
	end
	end
  #end
 
  # Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string=@test_params.params_chan.boot_up_string[0])
    puts "\n bootstress::run_get_script_output"
	result= [false,200]
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    #puts "keep_checking is: "+keep_checking.to_s
	puts "expect_string is #{expect_string}\n"
	puts "Keep_checking is #{keep_checking}\n"
    while keep_checking
      counter=0
      while check_serial_port()
        #puts "@serial_port_data is: \n"+@serial_port_data+"\nend of @serial_port_data"
        #wait for end of test
		puts "Ssserial log is #{@serial_port_data}\nSsssssss\n"
        if expect_string != nil then
          expect_string_regex = Regexp.new(expect_string)
          if expect_string_regex.match(@serial_port_data) then
		    time = Time.now
			result[0] = true
            puts "\nDEBUG: Getting expected string and the test complete."  
			puts "Inside get_script_output Result[0] is #{result[0]}\n"
			
            keep_checking = false
            sleep 2
            break
          end
        end
        #if not see expect_string, wait for timeout to prevent infinite loop
        sleep 1
        counter += 1
        if counter >= wait_time
          puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."  
          keep_checking = false
          break
        end
      end
	  result[1] = time
	  puts "Arrived at this point to print result[0] and result[1] #{result[0]} and #{result[1]}\n"
	  return result[0]
    end
    # make sure serial port log wont lost even there is ftp exception
    begin
      log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
	  if (!File.exist?(log_file_name))
      log_file = File.new(log_file_name,'w')
	  else
	  log_file = File.open(log_file_name,'a')
	  end
    rescue Exception => e
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
      add_log_to_html(log_file_name)
      clean_delete_binary_files
      # force dut reboot on next test case
      @new_keys = ''
      raise
    end
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
      #add_log_to_html(log_file_name)
    ensure
      # std_file.close if std_file
      # err_file.close if err_file
  end
  
def run_collect_performance_data(boot_data)
  puts "\n bootstress_test::run_collect_performance_data"
  perf_data = []
 
  @results_html_file.add_paragraph("")
  
    res_table = @results_html_file.add_table([["BOOT UP STATISTICS",{:bgcolor => "336666", :colspan => "3"},{:color => "white"}]],{:border => "1",:width=>"20%"})
		if (@test_params.params_chan.test_type[0] == "boot_stress")
		@results_html_file.add_row_to_table(res_table,['BOOT_TOTAL_ATTEMPTS',boot_data['total'].to_s,' '])
		@results_html_file.add_row_to_table(res_table,['BOOT_SERIAL_SUCCESS',boot_data['serial_success'],' '])
		@results_html_file.add_row_to_table(res_table,['BOOT_TELNET_SUCCESS',boot_data['telnet_success'],' '])
		
		else
		   @results_html_file.add_row_to_table(res_table,['BOOT_TIME',boot_data['time'].to_s,' '])
		   perf_data << {'name' => "BOOT_TIME", 'value' => "#{boot_data['time']}", 'units' => "ms"}
		end
		log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
	  if (File.exist?(log_file_name))
         add_log_to_html(log_file_name)
	  end
	
  perf_data
end

def run_determine_test_outcome(perf_data)
  puts "\n bootTime_test::run_determine_test_outcome"
  if perf_data.length > 1
   [FrameworkConstants::Result[:fail], "Performance data was collected - check before passing test manually."]
  else
   [FrameworkConstants::Result[:fail], "Performance data was not collected - check pass percentage before passing test manually."]
  end
end

def run_save_results(result_of_test)
    puts "\n WinceTestScript::run_save_results"
    result,comment = run_determine_test_outcome(result_of_test)
  end

  def clean_delete_binary_files
end

