#initial release - 11-04-2011
#update #1 - 02-25-2012
require File.dirname(__FILE__)+'/../../common_test_mod'
require File.dirname(__FILE__)+'/../../usb_common_mod'
include CommonTestMod
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

  
  ############################################################## run_get_script_output #########################################################################
  def run_get_script_output
    puts "\n usb_enum_test::run_get_script_output"
    super("</TESTGROUP>")
  end

  
  ############################################################## run_call_script ###############################################################################
  def run_call_script
    puts "\n usb_sto_media_integrity_test::run_call_script "+ __LINE__.to_s
    init_common_hash_arrays("@copy_times")
    init_common_hash_arrays("@usb_enum_perfdata")
    @enum_success_count = @enum_fail_count = @iteri = 0
    
    # ------------------------ If file size variable does not exist in the test case xml file, set a default file size of 30 Megabytes --------------------
    if @test_params.params_equip.instance_variable_defined?(:@ftp_file_size)
      @ftp_file_sze = @test_params.params_equip.instance_variable_defined?(:@ftp_file_size) ? @test_params.params_equip.ftp_file_size[0] : '30'
    end

    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_variables
    
    # ------------------------ Save the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Calculate the desired script run time and convert it to seconds --------------------
    calculate_desired_script_run_time
    save_test_start_time
    
    begin
    
      # ------------------------ Connect the USB switch to the correct USB port --------------------
      connect_usb_sw("usb_sw")
    
      # ------------------------ Determine if the USB Flash drive has been enumerated --------------------
      determine_usb_hard_drive_presence

      # ------------------------ Disconnect the USB switch --------------------
      reset_usb_sw("usb_sw")

      # ------------------------ Calculate current run times ------------------------
      calc_current_script_run_time
      calc_current_test_run_time
      
      # ------------------------ Count each loop ------------------------ 
      @iteri += 1

    end until (@data_time['curr_test_run_time_seconds'].to_i) >= @data_time['run_duration'].to_i
    
    save_test_end_time
  end

  
  ############################################################## run_determine_test_outcome ####################################################################
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

  
  ############################################################## run_save_results ##############################################################################
 def run_save_results
    puts "\n usb_enum_test::run_save_results "+ __LINE__.to_s
    create_evm_info_table
    create_usb_enum_html_page
    result,comment,@usb_enum_perfdata = run_determine_test_outcome
    
    if @usb_enum_perfdata
      set_result(result,comment,@usb_enum_perfdata)
    else
      set_result(result,comment)
    end
  end


  ############################################################## clean #########################################################################################
  def clean
    puts "\n usb_sto_media_integrity_test::clean "+ __LINE__.to_s
    clean_delete_local_temp_files
    super
  end

  
  ############################################################## run_generate_script ###########################################################################
  def run_generate_script
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
  
  