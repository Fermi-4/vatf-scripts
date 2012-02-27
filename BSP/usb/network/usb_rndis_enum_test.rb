#Release date:  02-24-2012
require File.dirname(__FILE__)+'/../../common_test_mod'
require File.dirname(__FILE__)+'/../../usb_common_mod'
include CommonTestMod
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
    init_common_hash_arrays("@data1")
    init_common_hash_arrays("@copy_times")

    @pings_per_iteration = @test_params.params_control.instance_variable_defined?(:@pings_per_connect) ? @test_params.params_control.pings_per_connect[0] : '5'
    @max_err_pings_ok = @test_params.params_equip.instance_variable_defined?(:@max_ping_errs) ? @test_params.params_control.max_ping_errs[0] : '0'
    @rndis_enum_perfdata = Array.new
    @ping_success_temp = Array.new
    @ping_fail_temp = Array.new
    @ping_success_count = @ping_fail_count = @rndis_success_count = @rndis_fail_count = 0
    @ping_success_count1 = @ping_fail_count1 = x = y = @iteri = @piteri = 0
    @TempBuffer = ""
    puts "\n -------------- #{@pings_per_iteration} ----- #{@max_err_pings_ok} --------- "+ __LINE__.to_s
    
    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Save the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Initialize the RNDIS mode on the EVM after a power reboot --------------------
    init_rndis_on_evm
    
    # ------------------------ Copy USBDeview.exe and supporting files from gtautoftp --------------------
    cp_dv_binaryfiles
    
    # ------------------------ Calculate the desired script run time and convert it to seconds --------------------
    calculate_desired_script_run_time
    
    # ------------------------ Calculate the script run time and convert it to seconds for later use --------------------
    save_test_start_time
    
    begin
      # ------------------------ Connect the USB switch to the correct USB port --------------------
      conn_usb_func_device
      
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

      # ------------------------ If there is zero packet loss, increment the success counter --------------------
      if /([\d+]+)\%\s+loss/im.match(@equipment['server1'].response).captures[0].to_i == 0
        @ping_success_temp << @equipment['server1'].response.scan(/(Reply)/i)
        @test = "Reply"
        @ping_success_count1 += @ping_success_temp[@iteri].length
        @iteri += 1
        puts "\n--------------- Ping Success:  #{@ping_success_count1} ------ "+ __LINE__.to_s
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
      
      # ------------------------ Disconnect the USBfn switch --------------------
      disconnect_usb_func_device
      
      # ------------------------ Delete the existing binary file in preparation for the next test iteration ------------------------
      calc_current_script_run_time
      
      puts "\n -------------- #{@ping_success_count1} ------ #{@ping_fail_count1} ------- #{@data_time['run_duration']} --------- "+ __LINE__.to_s
      
    end until (@data_time['curr_time_seconds'].to_i - @data_time['script_start_time_seconds'].to_i) >= @data_time['run_duration'].to_i
    
    save_test_end_time
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



	
	