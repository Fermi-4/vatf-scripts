#initial release - 10-31-2011
require File.dirname(__FILE__)+'/../../usb_common_mod'

include UsbCommonModule

	############################################################## run_collect_performance_data ##################################################################
	def run_collect_performance_data
    puts "\n usb_enum_test::run_collect_performance_data "+ __LINE__.to_s
	end

	
	############################################################## setup_connect_equipment #######################################################################
	def setup_connect_equipment
    puts "\n usb_enum_test::setup_connect_equipment "+ __LINE__.to_s
		puts "\n -------------------- Initializing the USB Switch -------------------- "+ __LINE__.to_s
		init_usb_sw("usb_sw")
		
		super
	end

	
	############################################################## run_call_script ###############################################################################
	def run_call_script
		puts "\n usb_enum_test::run_call_script"
		@data = Array.new
		@usb_enum_perfdata = Array.new
		@enum_success_count = @enum_fail_count = @iteri = 0
		
		# ------------------------ If file size is zero, or the variable does not exist in the test case xml file, do not create a transfer test file --------------------
		if @test_params.params_equip.instance_variable_defined?(:@ftp_file_size)
			@ftp_file_sze = @test_params.params_equip.instance_variable_defined?(:@ftp_file_size) ? @test_params.params_equip.ftp_file_size[0] : '0'
		end

		# ------------------------ Synchronize the time on EVM with current time on PC --------------------
		set_dut_datetime
		
		# ------------------------ Calculate the desired script run time and convert it to seconds --------------------
		calculate_desired_script_run_time
		
		# ------------------------ Compute the actual start time --------------------
		calc_test_start_time
		
		begin
			# ------------------------ Connect the USB switch to the correct USB port --------------------
			connect_usb_sw("usb_sw")
			
			# ------------------------ Determine if the USB Flash drive has been enumerated --------------------
			determine_usb_hard_drive_presence
			
			# ------------------------ Disconnect the USB switch --------------------
			reset_usb_sw("usb_sw")
			
			# ------------------------ Calculate interim script run time ------------------------
			calc_current_script_run_time
			
			@iteri += 1
		end until (@curr_time_seconds.to_i - @start_time_seconds.to_i) >= @run_duration
		
		calc_test_end_time
	end

	
	############################################################## clean #########################################################################################
	def clean
		puts "\n usb_enum_test::clean "+ __LINE__.to_s
		clean_delete_local_temp_files
		super
	end

	
	############################################################## run_save_results ##############################################################################
	def run_save_results
    puts "\n usb_enum_test::run_save_results "+ __LINE__.to_s
		create_evm_info_table
		create_usb_enum_html_page
    result,comment,@usb_enum_perfdata = run_determine_test_outcome
		
		if @usb_enum_perfdata
      set_result(result,comment,@usb_enum_perfdata)
			puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
    else
      #set_result('@{FrameworkConstants::Result[:pass]}',comment)
			set_result(result,comment)
			puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		end
	end

	
	############################################################## run_determine_test_outcome ##############################################################################
	def run_determine_test_outcome
		x=0
		@usb_enum_perfdata << {'name'=> "#{@usb_intfc} - Total USB_Connects", 'value'=> "#{@total_test_sessions}".to_i, 'units' => "Connects"}
		@usb_enum_perfdata << {'name'=> "#{@usb_intfc} - Successful USB_Connects", 'value'=> "#{@enum_success_count}".to_i, 'units' => "Connects"}
		@usb_enum_perfdata << {'name'=> "#{@usb_intfc} - Failed USB Connects", 'value'=> "#{@enum_fail_count}".to_i, 'units' => "Connects"}
		@usb_enum_perfdata << {'name'=> "#{@usb_intfc} - Success Rate %", 'value'=> "#{@tot_enum_success_rate}".to_i, 'units' => "Connects"}
		
		if @enum_fail_count == 0
			return [FrameworkConstants::Result[:pass], "This test pass.", @usb_enum_perfdata]
    puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		else
			return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
		end
	end

	
	############################################################## run_generate_script ###########################################################################
	def run_generate_script
		puts "\n usb_enum_test::run_generate_script "+ __LINE__.to_s
		#puts "\n -------------------- Creating necessary script/.bat files -------------------- "+ __LINE__.to_s
	end
	
	
	############################################################## clean_delete_binary_files #####################################################################
	def clean_delete_binary_files
	end
	
	
	############################################################## run_get_script_output #########################################################################
	def run_get_script_output(expect_string=nil)
	end
	
	
	############################################################## run_transfer_script ###########################################################################
	def run_transfer_script
	end
	
	
	
	