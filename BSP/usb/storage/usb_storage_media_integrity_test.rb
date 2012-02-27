#initial release - 11-02-2011
#update #1 - 02-25-2012
require File.dirname(__FILE__)+'/../../common_test_mod'
require File.dirname(__FILE__)+'/../../usb_common_mod'
include CommonTestMod
include UsbCommonModule

  ############################################################## run_collect_performance_data ##################################################################
  def run_collect_performance_data
    puts "\n usb_sto_media_integrity_test::run_collect_performance_data "+ __LINE__.to_s
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "\n usb_sto_media_integrity_test::setup_connect_equipment "+ __LINE__.to_s
    puts "\n -------------------- Initializing the USB Switch -------------------- "+ __LINE__.to_s
    init_usb_sw("usb_sw")
    super
  end

  
  ############################################################## run_get_script_output #########################################################################
  def run_get_script_output
    puts "\n usb_sto_media_integrity_test::run_get_script_output"
    super("</TESTGROUP>")
  end

  
  ############################################################## run_call_script ###############################################################################
  def run_call_script
    puts "\n usb_sto_media_integrity_test::run_call_script "+ __LINE__.to_s
    init_common_hash_arrays("@copy_times")
    init_common_hash_arrays("@usb_enum_perfdata")
    @copy_speed = Array.new
    @srcmdia = @test_params.params_control.mediatype_1[0]
    @dstmdia = @test_params.params_control.mediatype_2[0]
    @xyz = @avg_med1_copy_spd = @avg_med2_copy_spd = @avg_ftpput_copy_spd = @avg_ftpget_copy_spd = 0
    
    # ------------------------ If file size variable does not exist in the test case xml file, set a default file size of 30 Megabytes --------------------
    if @test_params.params_equip.instance_variable_defined?(:@ftp_file_size)
      @ftp_file_sze = @test_params.params_equip.instance_variable_defined?(:@ftp_file_size) ? @test_params.params_equip.ftp_file_size[0] : '30'
    end

    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Initialize script specific variables --------------------
    init_variables

    # ------------------------ Save the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Calculate the desired script run time and convert it to seconds --------------------
    calculate_desired_script_run_time
    
    # ------------------------ Determine the USB interface to use and switch to the applicable port only if a usbhd device is being tested)--------------------
    connect_usb_sw("usb_sw")

    # ------------------------ Scan the EVM subdirectories and capture/parse the available media volume names -------------------- 
    determine_storage_media_available
    
    # ------------------------ Setup the various variables with the previously obtained storage data -------------------- 
    config_mediatype_vars
    
    # ------------------------ Generate the ftp client command script files --------------------
    generate_dos_ftp_put_txt_file
    generate_dos_ftp_get_txt_file
    
    # ------------------------ Save the current test start time for later use --------------------
    save_test_start_time
    
    begin
    
      # ------------------------ Connect the USB switch to the correct USB port --------------------
      connect_usb_sw("usb_sw")
    
      # ------------------------ Perform the actual FTP file transfer using the Windows FTP client --------------------
      xfr_ftp_files
      
      # ------------------------ Create a hash value for both files and compare them to ensure they are the same --------------------
      check_file_integrity
      
      # ------------------------ Disconnect the USB switch --------------------
      reset_usb_sw("usb_sw")
      
      # ------------------------ Delete the existing binary file in preparation for the next test iteration ------------------------
      @equipment['server1'].send_cmd("del /F #{@test_params.params_chan.lcl_dsktp_tmp_dir[0]}" + "\\*.bin", />/)
      @iteri += 1
      calc_current_test_run_time
    end until (@data_time['curr_test_run_time_seconds'].to_i) >= @data_time['run_duration'].to_i
    
    save_test_end_time
  end

  
  ############################################################## run_determine_test_outcome ####################################################################
  def run_determine_test_outcome
    x=0
    puts "session_fail_count:  #{@session_fail_count} "+ __LINE__.to_s
    
    if @session_fail_count == 0
      return [FrameworkConstants::Result[:pass], "This test pass.", @ws2_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end

  
  ############################################################## run_save_results ##############################################################################
 def run_save_results
    puts "\n usb_sto_media_integrity_test::run_save_results "+ __LINE__.to_s
    create_evm_info_table
    create_usb_storage_media_integrity_html
    result,comment,@ws2_perfdata = run_determine_test_outcome
    
    puts "\n #{@ws2_perfdata } "+ __LINE__.to_s
    
   if @ws2_perfdata
      set_result(result,comment,@ws2_perfdata)
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
    puts "\n usb_sto_media_integrity_test::run_generate_script "+ __LINE__.to_s
    puts "\n -------------------- Creating necessary script/.bat files -------------------- "+ __LINE__.to_s
    cp_dd_binaryfile                          #copy dd.exe from central location
    create_ftp_binary_file                    #create a binary file whose length can be specified by you (i.e. 20 would be a 20 megabyte file)
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
  
  