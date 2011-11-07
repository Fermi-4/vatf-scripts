require File.dirname(__FILE__)+'/../../default_test'

include WinceTestScript


# Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
  end
  
  def transfer_server_files(test_file, test_file_root)
    put_file({'filename' => test_file, 'src_dir' => test_file_root, 'binary' => true})
  end
  
  def run_generate_script
    puts "\n WinceTest_CAN_Kvaser_test::run_generate_script"
	FileUtils.mkdir_p @wince_temp_folder
	kvaser_root = "C:\/Program Files\/Kvaser\/CANKing"
	if @test_params.params_chan.direction[0].to_s == "tx"
	  kvaser_config_script_name = "rx"
	else
	  kvaser_config_script_name = "tx"
	end
	kvaser_config_script_name = kvaser_config_script_name+'_'+@test_params.params_chan.baud_rate[0]+'.wcc'
	 #kvaser_vbscript = File.new(File.join(kvaser_root,'can_kvaser.vbs'),'w')
	  #kvaser_vbscript = File.new(File.join(kvaser_root,'can_kvaser.vbs'),'w')
	 kvaser_vbscript = File.new(File.join(@wince_temp_folder,'can_kvaser.vbs'),'w')
	 kvaser_vbscript.puts("set c = CreateObject(\"wc32.Main\")")
	 kvaser_vbscript.puts("c.OpenConfig(\"c:\\#{kvaser_config_script_name}\")")
	 kvaser_vbscript.puts("c.StartRunning")
	 #kvaser_vbscript.puts("WScript.Sleep(#{@test_params.params_chan.duration[0].to_s})")
	 # to take care of 10s of sleep after tool starts and 5s of extra time compared to running time of test
	 kvaser_running_time = (@test_params.params_chan.duration[0].to_i)*2
	 #kvaser_running_time = kvaser_running_time*2
	 puts "Kvaser Running Time is #{kvaser_running_time}\n"
	 #kvaser_vbscript.puts("WScript.Sleep(20000)")
	 kvaser_vbscript.puts("WScript.Sleep(#{kvaser_running_time})")
	 kvaser_vbscript.puts("c.StopRunning")
	 kvaser_vbscript.puts("set c = Nothing")
	 kvaser_vbscript.close
	 response = system("net use W: /delete")
	 puts "SYSTEM RESPONSE to delete is #{response}#############\n"
	 system("Y")
     puts "SYSTEM RESPONSE to delete is #{response}#############\\\\\\\\\\\\\n"
	 can_ip = @equipment['can_kvaser'].telnet_ip
	 puts "TELNET IP is #{can_ip.to_s}###\n"
	 sleep 10
     response = system("net use W: \\\\#{can_ip.to_s}\\canking")
     puts "SYSTEM RESPONSE is #{response}#############///////////\n"
	 puts "ORIGIN file is #{File.join(@wince_temp_folder,'can_kvaser.vbs')}\n"
	 system("copy #{File.join(@wince_temp_folder,'can_kvaser.vbs').gsub('/','\\')} W:")
	
#	if @equipment['can_kvaser'].respond_to?(:telnet_port) and @equipment['can_kvaser'].respond_to?(:telnet_ip) and !@equipment['can_kvaser'].target.telnet

#  @equipment['can_kvaser'].connect({'type'=>'telnet'})
#else  
# raise "You need Telnet connectivity to the Kvaser CAN Server. Please check your bench file" 

 #end
  # @equipment['can_kvaser'].send_cmd("net use * \\\\10.218.103.117\\canking}", />/,1)
   # @kvaser_response = @equipment['can_kvaser'].response
#	puts "KVASER response to net use is #{@kvaser_response}\n"
	
	#BuildClient.copy(kvaser_vbscript, dst_path)
	#@equipment['can_kvaser'].send_cmd(command, />/,1)

	 
	 #system("cd #{kvaser_root}")
	 #system("#{kvaser_root}/cscript //nologo can_kvaser.vbs")
	 
	if (@test_params.params_chan.direction[0].to_s == "tx")
	 test_command = 'start canbench'+' -b'+@test_params.params_chan.baud_rate[0]+' -d'+@test_params.params_chan.duration[0].to_s
	elsif (@test_params.params_chan.direction[0].to_s == "rx")
	 test_command = 'start canbenchrx' +' -b'+@test_params.params_chan.baud_rate[0]+' -d'+@test_params.params_chan.duration[0].to_s 
	end
	#test_command = 'start canbench -b250 -d10'
	puts "Test Command is #{test_command}\n"
	 # test_command = 'start '+@test_params.params_chan.cmdline[0] +' '+cmd_params+' -e'+' -l' 
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_chan.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    raw_test_lines.each do |current_line|
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end
   def run_call_script
    puts "\n CAN_Kvaser_test::run_call_script"
	kvaser_root = "C:\/\"Program Files\"\/Kvaser\/CANKing"
    #system("cd #{kvaser_root}")
	kvaser_filename = File.join(@wince_temp_folder,'can_kvaser.vbs')
	#kvaser_filename = kvaser_filename.to_s.gsub('/','\\')
	puts "The path to the vbs file is cscript //nologo #{kvaser_filename}\n"
	#system("start cscript //nologo #{kvaser_root}/can_kvaser.vbs")
	command = "start cscript //nologo #{kvaser_root}\\can_kvaser.vbs"
	puts "Command sent to CAN server is #{command}\n"
	# Telnet to Kvaser CAN server
#@equipment['can_kvaser'].connect()
if @equipment['can_kvaser'].respond_to?(:telnet_port) and @equipment['can_kvaser'].respond_to?(:telnet_ip) and !@equipment['can_kvaser'].target.telnet

  @equipment['can_kvaser'].connect({'type'=>'telnet'})
else  
 raise "You need Telnet connectivity to the Kvaser CAN Server. Please check your bench file" 

 end
 #response = system("net use W: /delete")
 #puts "SYSTEM RESPONSE to delete is #{response}#############\n"
 #response = system("net use W: \\10.218.103.117\canking")
 #puts "SYSTEM RESPONSE is #{response}#############\n"
    #@equipment['can_kvaser'].send_cmd("net use * \\\\10.218.103.117\\canking", />/,1)
	#response = @equipment['can_kvaser'].response
	#puts "RESPONSE is #{response}############\n"
	#map_drive = response.split(/:/)[0]
	#puts "Scan result is #{map_drive}\n"
	#map_drive = map_drive.split(/Drive\s/)[1]
	#puts "Scan result is #{map_drive}\n"
	#map_drive = w
	#current_match = response.scan(/Drive \w: is now connected/m)
	#system("copy #{kvaser_filename} Z:") 
   # @equipment['can_kvaser'].send_cmd("cd #{kvaser_root}", />/,1)
	@equipment['can_kvaser'].send_cmd(command, />/,1)

#@all_lines = @equipment['can_kvaser'].response
#puts "Response from kvaser machine is #{@all_lines}\n"
    puts "Just before sleep is called\n"
	sleep 10 # to ensure kvaser tool is started before script is called from target
	#@equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
   #@equipment['dut1'].send_cmd("call test.bat 2> stderr.log > stdout.log",@equipment['dut1'].prompt)
    puts "Just before super if called\n"
	super
	#sleep (@test_params.params_chan.duration[0].to_i)
	sleep 20
	#@equipment['can_kvaser'].send_cmd("del 
	# aparna system("del W:\can_kvaser.vbs") 
	# aparna system("net use W: /delete")
	# aparna system("Y")
	#@equipment['can_kvaser'].send_cmd("net use * /delete",/:/,1)
	#@equipment['can_kvaser'].send_cmd("Y",/>/,1)
	@equipment['can_kvaser'].disconnect
  end
# Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string="total msg")
    puts "\n WinceTest_Kvaser_test::run_get_script_output"
   wait_time = @test_params.params_chan.duration[0].to_i/1000
   puts "Wait time is #{wait_time}\n"
  # 	if (counter%2 == 0)
# #@equipment['dut1'].send_cmd("cd \windows",@equipment['dut1'].prompt)
		   @equipment['dut1'].send_cmd("do cpuidle >> \windows\stdout_cpu.log",@equipment['dut1'].prompt)
		#  end
   #wait_time = 20
    keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    #puts "keep_checking is: "+keep_checking.to_s
	puts "expect_string is #{expect_string}\n"
    while keep_checking
	  puts "Keep_Checking is #{keep_checking}\n"
      counter=0
      while check_serial_port()
        #puts "@serial_port_data is: \n"+@serial_port_data+"\nend of @serial_port_data"
        #wait for end of test
		puts "Entered while check_serial_port loop here\n"
        if expect_string != nil then
          expect_string_regex = Regexp.new(expect_string)
          if expect_string_regex.match(@serial_port_data) then
            puts "\nDEBUG: Getting expected string and the test complete."  
            keep_checking = false
            sleep 2
            break
          end
        end
        #if not see expect_string, wait for timeout to prevent infinite loop
        sleep 1
        counter += 1
          puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."  
		  puts "Counter is #{counter} and wait time is #{wait_time}\n"
		  #aparna if (counter%2 == 0)
          # aparna  @equipment['dut1'].send_cmd("do cpuidle >> \\windows\\stdout_cpu.log",@equipment['dut1'].prompt)
		  #aparna end
        if counter >= wait_time
          keep_checking = false
          break
        end
      end
    end
    # make sure serial port log wont lost even there is ftp exception
    begin
      log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
      log_file = File.new(log_file_name,'w')
      get_file({'filename'=>'stderr.log'})
      get_file({'filename'=>'stdout.log'})
	  #get_file({'filename'=>'stdout_cpu.log'})
      #yliu: temp: save differnt test log to different files
      std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
	  # aparna std_cpu_file = File.new(File.join(@wince_temp_folder,'stdout_cpu.log'),'r')
      err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
	  
      std_output = std_file.read
	#aparna  std_cpu_output = std_cpu_file.read
      std_error  = err_file.read
	  puts "Writing log files now\n"
      log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
	  # aparna log_file.write("\n<STD_CPU_OUTPUT>\n"+std_cpu_output+"</STD_CPU_OUTPUT>\n")
      log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
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
      add_log_to_html(log_file_name)
    ensure
      std_file.close if std_file
	 #aparna  std_cpu_file.close if std_cpu_file
      err_file.close if err_file
  end
def run_collect_performance_data
  ser_out = get_serial_output.split(/[\n\r]+/)
  playout_counter = 0
  #ser_out.scan(/ duration\s*\d+\s*ms/mi)
  #puts "ser_out ... d[0] is #{d}\n"
  perf_data = []
  duration_from_log = ''
  min_pkt_size_from_log = ''
  max_pkt_size_from_log = ''
  min_burst_from_log = ''
  max_burst_from_log = ''
  throughput_from_log = ''
  msg_lost = 1
  msg_discarded = 1
  msg_filtered = 1
  ser_out.each do |current_line|
   if (@test_params.params_chan.direction[0] == "tx")
   current_match = current_line.match(/TX results/)
   else current_match = current_line.match(/RX results/)
   end
    if current_match
	  puts "Entered current_match for tx results\n"
	  if (@test_params.params_chan.direction[0].to_s == "tx")
	  duration_from_log = current_line.split(/duration/)[1].split(/ms/)[0].strip
	  puts "Duration from log is #{duration_from_log} ms\n"
	   min_pkt_size_from_log = current_line.split(/min packet size/)[1].split(/,/)[0].strip
	  puts "Min packet size is #{min_pkt_size_from_log}\n"
	   max_pkt_size_from_log = current_line.split(/max packet size/)[1].split(/,/)[0].strip
	  puts "Max packet size is #{max_pkt_size_from_log}\n"
	   min_burst_from_log = current_line.split(/min burst/)[1].split(/,/)[0].strip
	  puts "Min burst is #{min_burst_from_log}\n"
	   max_burst_from_log = current_line.split(/max burst/)[1].split(/\)/)[0].strip
	  puts "Max burst is #{max_burst_from_log}\n"
	  end
	   throughput_from_log = current_line.split(/kB\/s/)[0].split(/\)/)[1].strip
	  puts "Throughput is #{throughput_from_log}\n"
	  perf_data << {'name' => "THROUGHPUT", 'value' => throughput_from_log, 'units' => "kB/s"}
	end
	current_match=''
	#puts "Current line is #{current_line}\n"
	current_match = current_line.match(/msg lost/)
	if current_match
	  msg_lost = current_line.split(/msg lost /)[1].strip
	  puts "msg_lost is #{msg_lost}\n"
	end
	current_match=''
	current_match = current_line.match(/msg filtered out/)
	if current_match
	  msg_filtered = current_line.split(/msg filtered out /)[1].strip
	  puts "msg_filtered is #{msg_filtered}\n"
	end
	current_match=''
	current_match = current_line.match(/msg discarded/)
	if current_match
	  msg_discarded = current_line.split(/msg discarded /)[1].strip
	  puts "msg_discarded is #{msg_discarded}\n"
	end
  end
   puts "PERF_DATA is #{perf_data}\n"
   	#aparna	
    #std_cpu_out = get_std_cpu_output.split(/[\n\r]+/)
    #cpu_info = []
    
    #std_cpu_out.each do |current_line|
    #if (current_line.scan(/cpu load is/).size>0)
     #cpu_info << current_line.split(/cpu load is /)[1]
	 #puts "CPU is #{cpu_info}\n"
    #end	 
 # end
  
   @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Test Type "+ @test_params.params_chan.direction[0]+" Baud Rate "+@test_params.params_chan.baud_rate[0]+" Duration "+@test_params.params_chan.duration[0],{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["Throughput (in kB/s) is ",throughput_from_log.to_s])
	@results_html_file.add_row_to_table(res_table,["Msg lost, msg filtered, and msg discarded are ",msg_lost.to_s,msg_filtered.to_s,msg_discarded.to_s])
	# aparna @results_html_file.add_row_to_table(res_table,["CPU info is ",cpu_info.to_s])
    #@results_html_file.add_row_to_table(res_table,["Observed_Playout_Counter",playout_counter.to_s])  
    if (@test_params.params_chan.direction[0] == "tx")
	  @results_html_file.add_row_to_table(res_table,["Min pkt size, Max pkt size, Min burst and Max burst are ",min_pkt_size_from_log.to_s,max_pkt_size_from_log.to_s,min_burst_from_log.to_s,max_burst_from_log.to_s])
	end
	result = []
	result[0] = 'fail'
	if (Float(@test_params.params_chan.expected_throughput[0])<=Float(throughput_from_log) && msg_lost.to_i==0 && msg_filtered.to_i==0 && msg_discarded.to_i ==0 )
	 result[0] = 'pass'
	end
	result << perf_data
	end

   def run_determine_test_outcome
  puts "\n Kvaser_can_test::run_determine_test_outcome"
  result = run_collect_performance_data
  puts "result is #{result}\n"
  puts "throughput result is #{result[0]}\n"
  
  if result[1].length > 0
   puts "Entered performance length greater than 1\n"
   if (result[0] == 'pass')
     [FrameworkConstants::Result[:pass], "Performance data was collected", result[1]]
   else
     [FrameworkConstants::Result[:fail], "Performance data was collected but performance was below expectation or packets were lost/filtered out/discarded."]
   end
  else
    [FrameworkConstants::Result[:fail], "Performance data was not collected."]
  end
end
  # Return standard output of test.bat as a string
  def get_std_cpu_output
    std_file = File.new(File.join(@wince_temp_folder,'stdout_cpu.log'),'r')
	std_out = std_file.read
	std_file.close
	std_out
  end
# Delete log files (if any) 
def delete_temp_files
  puts "\n Wince_CANBENCH_PERF::delete_temp_files"
  #if (@test_params.params_chan.playout_type[0].to_s == "file")
    #@equipment['dut1'].send_cmd("cd  #{@test_params.params_chan.test_dir[0]}",@equipment['dut1'].prompt)
    #@equipment['dut1'].send_cmd("del test.bat",@equipment['dut1'].prompt)
	puts "FILE to be deleted is #{File.join(@wince_temp_folder,'test.bat')} $$$$$"
    system("del #{File.join(@wince_temp_folder,'test.bat')}")
    #system("del #{File.join(@wince_temp_folder,'can_kvaser.vbs')}")	
  #end
end

