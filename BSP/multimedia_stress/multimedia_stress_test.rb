require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

# Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
	if (@test_params.params_chan.playout_type[0].to_s == "file")
	puts "filename second part is: #{@test_params.params_chan.input_file[0].to_s.split('.')[1]}\n"
	 if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("avi") == 0)
	  subfolder = "/common/Multimedia/Video/AVI"
	  puts "subfolder is #{subfolder}\n"
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("3gp") == 0)
	  subfolder = "/common/Multimedia/Video/3GPP"
	  puts "subfolder is #{subfolder}\n"
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("mp4") == 0)
	  subfolder = "/common/Multimedia/Video/MP4"
	 puts "subfolder is #{subfolder}\n" 
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("wmv") == 0)
	  subfolder = "/common/Multimedia/Video/WMV"
	 puts "subfolder is #{subfolder}\n" 
	 end
	puts "subfolder is #{subfolder}\n"
	dest_folder = ""
	dest_folder = SiteInfo::FILE_SERVER + subfolder
	puts "destination folder is #{dest_folder}\n"
    transfer_server_files(@test_params.params_chan.input_file[0].to_s, dest_folder)
	else
	end	
  end
  
  def transfer_server_files(test_file, test_file_root)
    put_file({'filename' => test_file, 'src_dir' => test_file_root, 'binary' => true})
  end
  
  def run_generate_script
    puts "\n WinceTest_Multimedia_Stress_Test::run_generate_script"
	if (@test_params.params_chan.playout_type[0].to_s == "file")
	test_command = 'start '+@test_params.params_chan.cmdline[0] +' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' -e'+' -l' 
    else
	  #if (@test_params.params_chan.streaming_server[0]
	  cmd_params = @test_params.params_chan.instance_variable_defined?(:@streaming_server) ? @test_params.params_chan.streaming_server[0] : SiteInfo::FILE_SERVER
	  #cmd_params = SiteInfo::FILE_SERVER
	  #cmd_params = '//158.218.103.149:8080/tftpboot/anonymous'
	  #cmd_params = @test_params.var_build_test_libs_root.to_s
	  cmd_params = cmd_params.sub('/tftpboot','')
	  cmd_params = 'http:'+cmd_params
	  if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("avi") == 0)
	  cmd_params = cmd_params+"/common/Multimedia/Video/AVI/"+@test_params.params_chan.input_file[0].to_s
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("3gp") == 0)
	  cmd_params = cmd_params+"/common/Multimedia/Video/3GP/"+@test_params.params_chan.input_file[0].to_s
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("mp4") == 0)
	  cmd_params = cmd_params+"/common/Multimedia/Video/MP4/"+@test_params.params_chan.input_file[0].to_s
	 elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("wmv") == 0)
	  cmd_params = cmd_params+"/common/Multimedia/Video/WMV/"+@test_params.params_chan.input_file[0].to_s
	 end
	 puts "cmd_params is #{cmd_params}\n"
	  test_command = 'start '+@test_params.params_chan.cmdline[0] +' '+cmd_params+' -e'+' -l' 
	 puts "test command is #{test_command}\n"
	end
	  FileUtils.mkdir_p @wince_temp_folder
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_chan.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    raw_test_lines.each do |current_line|
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end
# Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string=nil)
    puts "\n WinceTest_Multimedia_Stress::run_get_script_output"
#    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
   if (@test_params.params_chan.total_test_duration_units[0] == "sec") 
    wait_time = @test_params.params_chan.total_test_duration[0].to_i
   elsif (@test_params.params_chan.total_test_duration_units[0] == "min")
    wait_time = @test_params.params_chan.total_test_duration[0].to_i*60
   elsif (@test_params.params_chan.total_test_duration_units[0] == "hr")
    wait_time = @test_params.params_chan.total_test_duration[0].to_i*3600
   end
    keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    #puts "keep_checking is: "+keep_checking.to_s
	puts "expect_string is #{expect_string}\n"
	counter=0
    while keep_checking
      while check_serial_port()
        #puts "@serial_port_data is: \n"+@serial_port_data+"\nend of @serial_port_data"
        #wait for end of test
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
		  if (counter%10 == 0)
		   @equipment['dut1'].send_cmd("do display on",@equipment['dut1'].prompt)
		  end
		  puts "Counter is #{counter}\n"
          puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."  
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
      #yliu: temp: save differnt test log to different files
      std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
      err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
      std_output = std_file.read
      std_error  = err_file.read
      log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
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
      err_file.close if err_file
  end
def run_collect_performance_data
  ser_out = get_serial_output.split(/[\n\r]+/)
  playout_counter = 0
  ser_out.each do |current_line|
   current_match = current_line.match(/EC_COMPLETE/)
    if current_match 
      playout_counter += 1
    end
  end
  if (@test_params.params_chan.total_test_duration_units[0] == "sec")
   expected_playout_counter = @test_params.params_chan.total_test_duration[0].to_i/@test_params.params_chan.file_duration_in_sec[0].to_i
  elsif (@test_params.params_chan.total_test_duration_units[0] == "min")
    expected_playout_counter = @test_params.params_chan.total_test_duration[0].to_i*60/@test_params.params_chan.file_duration_in_sec[0].to_i
  elsif (@test_params.params_chan.total_test_duration_units[0] == "hr")
    expected_playout_counter = @test_params.params_chan.total_test_duration[0].to_i*3600/@test_params.params_chan.file_duration_in_sec[0].to_i
  end
   @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([[@test_params.params_chan.playout_type[0]+" fps",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["Expected_Playout_Counter",expected_playout_counter.to_s])
    @results_html_file.add_row_to_table(res_table,["Observed_Playout_Counter",playout_counter.to_s])  
end

def run_determine_test_outcome
  perf_data  = run_collect_performance_data
    [FrameworkConstants::Result[:fail], "This test is marked fail because manual check needs to be done to ensure that media is still playing, touchscreen is still active and ethernet link is up "]
end

# Delete log files (if any) 
def clean_delete_log_files
  puts "\n Wince_Multimedia_Stress::clean_delete_log_files"
  if (@test_params.params_chan.playout_type[0].to_s == "file")
    @equipment['dut1'].send_cmd("cd  #{@test_params.params_chan.test_dir[0]}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("del #{@test_params.params_chan.input_file[0]}",@equipment['dut1'].prompt) 
  end
end

