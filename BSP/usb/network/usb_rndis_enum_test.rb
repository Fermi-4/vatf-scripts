require File.dirname(__FILE__)+'/../../usb_common_mod'

include UsbCommonModule

	############################################################## run_collect_performance_data ##################################################################
	def run_collect_performance_data
    puts "\n usb_rndis_enum_test_script::run_collect_performance_data "+ __LINE__.to_s
	end

	
	############################################################## setup_connect_equipment #######################################################################
	def setup_connect_equipment
    puts "\n usb_rndis_enum_test_script::setup_connect_equipment "+ __LINE__.to_s
		puts "\n -------------------- Initializing the USB Switch -------------------- "+ __LINE__.to_s
		init_usb_sw("usb_swfn")
		super
	end

	
	############################################################## run_get_script_output #########################################################################
	def run_get_script_output
		puts "\n usb_rndis_enum_test_script::run_get_script_output"
		super("</TESTGROUP>")
	end

	
	############################################################## run_call_script ###############################################################################
  def run_call_script
		puts "\n usb_rndis_enum_test_script::usb_run_call_script "+ __LINE__.to_s
		@pings_per_iteration = @test_params.params_control.instance_variable_defined?(:@pings_per_connect) ? @test_params.params_control.pings_per_connect[0] : '5'
		@max_err_pings_ok = @test_params.params_equip.instance_variable_defined?(:@max_ping_errs) ? @test_params.params_control.max_ping_errs[0] : '0'
		@data = Array.new
		@rndis_enum_perfdata = Array.new
		@ping_success_temp = Array.new
		@ping_fail_temp = Array.new
		@ping_success_count = @ping_fail_count = @rndis_success_count = @rndis_fail_count = 0
		@ping_success_count1 = @ping_fail_count1 = x = y = @iteri = @piteri = 0
		@TempBuffer = ""
		puts "\n -------------- #{@pings_per_iteration} ----- #{@max_err_pings_ok} --------- "+ __LINE__.to_s
		
		# ------------------------ Initialize script specific variables --------------------
		init_variables
		
		# ------------------------ Synchronize the time on EVM with current time on PC --------------------
		set_dut_datetime
		
		# ------------------------ Initialize the RNDIS mode on the EVM after a power reboot --------------------
		init_rndis_on_evm
		
		# ------------------------ Copy USBDeview.exe and supporting files from gtautoftp --------------------
		cp_dv_binaryfiles
		
		# ------------------------ Calculate the desired script run time and convert it to seconds --------------------
		calculate_desired_script_run_time
		
		# ------------------------ Calculate the script run time and convert it to seconds for later use --------------------
		calc_test_start_time
		
		begin
			# ------------------------ Connect the USB switch to the correct USB port --------------------
			@equipment['usb_swfn'].select_input(@equipment['dut1'].params['otg_port'])			
			sleep @test_params.params_control.wait_after_connect[0].to_i
			
			# ------------------------ Check if the USB RNDIS connection was successfully connected to the host PC --------------------
			ck_if_rndis_connected
			
			if @rndis_pid == 0
				conn_usb_func_rndis
				ck_if_rndis_connected
			end
			
			if @rndis_pid == 99
				puts "\n---------- Rndis was successfully connected ------ "+ __LINE__.to_s
				@rndis_success_count += 1
			else
				puts "\n---------- RNDIS could not be started successfully ------ "+ __LINE__.to_s
				@rndis_fail_count += 1
			end
			
			# ------------------------ Send pings to the EVM which is being tested --------------------
			@equipment['server1'].send_cmd("ping #{@equipment['dut1'].params['evm_usb_ip']} -n #{@pings_per_iteration}", />/)
			@TempBuffer = @equipment['server1'].response
			#puts "\n--------------- Ping Status:  #{/([\d+]+)\%\s+loss/im.match(@equipment['server1'].response).captures[0]} ------ "+ __LINE__.to_s

			# ------------------------ If there is zero packet loss, increment the success counter --------------------
			if /([\d+]+)\%\s+loss/im.match(@equipment['server1'].response).captures[0].to_i == 0
				@ping_success_temp << @equipment['server1'].response.scan(/(Reply)/i)
				@test = "Reply"
				@ping_success_count1 += @ping_success_temp[@iteri].length
				@iteri += 1
				puts "\n--------------- Ping Success:  #{@ping_success_count1} ------ "+ __LINE__.to_s
				puts "\n--------------- #{@ping_success_temp.length} ------ "+ __LINE__.to_s
			end
			
			# ------------------------ If there are any lost packets, determine how many and add them to the fail counter --------------------
			if /([\d+]+)\%\s+loss/i.match(@equipment['server1'].response).captures[0].to_i != 0
				@ping_fail_temp << @equipment['server1'].response.scan(/(timed\s+out)/i)
				puts "\n---------------  #{@ping_fail_temp} ------ "+ __LINE__.to_s
				@test = "Loss"
				@ping_fail_count1 += @ping_fail_temp[@piteri].length
				@piteri += 1
				puts "\n---------------  #{@ping_fail_count1} ------- Ping Fail:  #{@ping_fail_temp} ------ "+ __LINE__.to_s
				puts "\n--------------- #{@ping_fail_temp.length} ------ "+ __LINE__.to_s
				puts "\n--------------- #{@ping_fail_temp.length} ------ "+ __LINE__.to_s
			end
			
			puts "\n--------------- #{@iteri} --- #{@piteri} ------ "+ __LINE__.to_s
			
			# ------------------------ Disconnect the USBfn switch --------------------
			@equipment['usb_swfn'].select_input(0) 
			sleep @test_params.params_control.wait_after_disconnect[0].to_i
			puts "\n -------------- #{@ping_success_count1} ------ #{@ping_fail_count1} --------- "+ __LINE__.to_s
			
			# ------------------------ Delete the existing binary file in preparation for the next test iteration ------------------------
			calc_current_script_run_time
		end until (@curr_time_seconds.to_i - @start_time_seconds.to_i) >= @run_duration
		
		calc_test_end_time
  end

	
	############################################################## conn_usb_func_rndis ###########################################################################
	def conn_usb_func_rndis
    puts "\n usb_rndis_enum_test_script::conn_usb_func_rndis "+ __LINE__.to_s
    @equipment['usb_swfn'].select_input(@equipment['dut1'].params['otg_port'])
		sleep @test_params.params_control.wait_after_connect[0].to_i
	end
	
	
	############################################################## disconnect_rndis ##############################################################################
	def disconnect_rndis
		puts "\n usb_rndis_enum_test_script::disconnect_rndis "+ __LINE__.to_s
		@equipment['usb_swfn'].select_input(0)   # 0 means don't select any input port.
		sleep @test_params.params_control.wait_after_disconnect[0].to_i
	end

	
	############################################################## dclean_delete_log_files #######################################################################
		# Delete log files (if any) 
	def clean_delete_log_files
		puts "\n usb_rndis_enum_test_script::clean_delete_log_files "+ __LINE__.to_s
		tmp_file = @test_params.params_equip.lcl_dsktp_tmp_dir[0] + "\\pidchk.log"
		system("del /F #{tmp_file}")
		tmp_file = @test_params.params_equip.lcl_dsktp_tmp_dir[0] + "\\usbint.txt"
		system("del /F #{tmp_file}")
		super
	end

	
	############################################################## clean #########################################################################################
	def clean
		puts "\n usb_rndis_enum_test_script::clean "+ __LINE__.to_s
		clean_delete_local_temp_files
		super
	end

	
	############################################################## run_save_results ##############################################################################
	def run_save_results
    puts "\n usb_rndis_enum_test_script::run_save_results "+ __LINE__.to_s
		create_evm_info_table
		create_usb_rndis_enum_html_page
    result,comment,@rndis_enum_perfdata = run_determine_test_outcome
		
		if @rndis_enum_perfdata
      set_result(result,comment,@rndis_enum_perfdata)
			puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
    else
			set_result(result,comment)
			puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		end
	end

	
	############################################################## run_determine_test_outcome ####################################################################
	def run_determine_test_outcome
    puts "\n usb_rndis_enum_test_script::run_determine_test_outcome "+ __LINE__.to_s
		x=0
		puts "\n ------------------ ping_fail_count1:  #{@ping_fail_count1} ------------------ "+ __LINE__.to_s
		@rndis_enum_perfdata << {'name'=> "Total RNDIS_Connects", 'value'=> "#{@total_rndis_test_sessions}".to_i, 'units' => "Connects"}
		@rndis_enum_perfdata << {'name'=> "Successful RNDIS_Connects", 'value'=> "#{@rndis_success_count}".to_i, 'units' => "Connects"}
		@rndis_enum_perfdata << {'name'=> "Failed RNDIS Connects", 'value'=> "#{@rndis_fail_count}".to_i, 'units' => "Connects"}
		@rndis_enum_perfdata << {'name'=> "RNDIS Success Rate %", 'value'=> "#{@tot_rndis_success_rate}".to_i, 'units' => "Percent"}
    
		@rndis_enum_perfdata << {'name'=> "Total Pings", 'value'=> "#{@total_rndis_test_sessions}".to_i, 'units' => "Pings"}
		@rndis_enum_perfdata << {'name'=> "Successful Pings", 'value'=> "#{@ping_success_count1}".to_i, 'units' => "Pings"}
		@rndis_enum_perfdata << {'name'=> "Failed Pings", 'value'=> "#{@ping_fail_count1}".to_i, 'units' => "Pings"}
		@rndis_enum_perfdata << {'name'=> "Ping Success Rate %", 'value'=> "#{@tot_ping_success_rate}".to_i, 'units' => "Percent"}

		#puts "\n #{@rndis_enum_perfdata} "+ __LINE__.to_s
		
		if @ping_fail_count1 == 0 && @rndis_fail_count == 0
			return [FrameworkConstants::Result[:pass], "This test pass.", @rndis_enum_perfdata]
    puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		else
			return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		end
	end

	
	############################################################## clean_delete_binary_files #####################################################################
	def clean_delete_binary_files
	end

	
	############################################################## run_generate_script ###########################################################################
	def run_generate_script
	end
	
	
	############################################################## run_transfer_script ###########################################################################
	def run_transfer_script
	end
	

	############################################################## run_get_script_output #########################################################################
	def run_get_script_output(expect_string=nil)
	end



	
	