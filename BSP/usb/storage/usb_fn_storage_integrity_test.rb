#initial release - 11-22-2011
#update #1 - 02-25-2012
require File.dirname(__FILE__)+'/../../common_test_mod'
require File.dirname(__FILE__)+'/../../usb_common_mod'
include CommonTestMod
include UsbCommonModule

  ############################################################## run_collect_performance_data ##################################################################
  def run_collect_performance_data
    puts "\n usb_fn_storage_enum_test::run_collect_performance_data "+ __LINE__.to_s
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "\n usb_fn_storage_enum_test::setup_connect_equipment "+ __LINE__.to_s
    #puts "\n -------------------- Initializing the USB Fn Switch Connection-------------------- "+ __LINE__.to_s
    init_usb_sw("usb_swfn")
    super
  end


  ############################################################## run_get_script_output #########################################################################
  def run_get_script_output
    puts "\n usb_fn_storage_enum_test::run_get_script_output"
    super("</TESTGROUP>")
  end


  ############################################################## run_call_script ###############################################################################
  def run_call_script
    puts "\n usb_fn_storage_enum_test::usb_run_call_script "+ __LINE__.to_s
    init_common_hash_arrays("@data1")
    init_common_hash_arrays("@copy_times")
    init_common_hash_arrays("@fn_enum_perfdata")
    init_common_hash_arrays("drive_lists")

    @lcl_dsktop_tmp_dir = @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) ? @test_params.params_equip.lcl_dsktp_tmp_dir[0] : 'c:\Temp'
    @max_wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10')
    @fn_sto_file_name = (@test_params.params_equip.instance_variable_defined?(:@fn_sto_file_name) ? @test_params.params_equip.fn_sto_file_name[0] : 'fntest.bin')
    @lcl_fn_file_name = (@test_params.params_equip.instance_variable_defined?(:@lcl_testfile_name) ? @test_params.params_equip.lcl_testfile_name[0] : 'usbtest.tst')

    # ------------------------ Initialize common network/USB arrays used by this script--------------------
    init_net_usb_common_vars
    
    # ------------------------ Initialize script specific variables --------------------
    init_variables
    
    # ------------------------ Save the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Initialize the storage function mode on the EVM after a power reboot --------------------
    init_storage_on_evm
    
    # ------------------------ Copy dd.exe from gtautoftp --------------------
    cp_dd_binaryfile
    
    # ------------------------ Copy USBDeview.exe and supporting files from gtautoftp --------------------
    cp_dv_binaryfiles
    
    # ------------------------ Calculate the desired script run time and convert it to seconds --------------------
    calculate_desired_script_run_time
    
    # -------------------------------------------------------------------------------------------------------------
    #                          Create a file which can be copied to the fn storage devicce, renamed, copied
    #                          back to the host, and then perform an integrity comparison check on both files.
    # ------------------------------------------------------------------------------------------------------------
    create_ftp_binary_file
    
    # ------------------------ Get a listing of all drives on the WinXP Host --------------------
    @equipment['server1'].send_cmd("fsutil fsinfo drives", />/)
    @drive_list1 << @equipment['server1'].response.scan(/(\w+\:)\\/i)

    # ------------------------ Calculate the script run time and convert it to seconds for later use --------------------
    save_test_start_time
    
    begin
      # ------------------------ Connect the USB switch to the correct USB port --------------------
      conn_usb_func_device
      
      # ------------------------ Check if the USB fn storage connection was successfully connected to the host PC --------------------
      ck_if_fn_storage_connected
      
      # ------------------------ Check if the USB fn storage devicen was successfully enumerated to the host PC --------------------
      wait_for_device_enumeration
      
      # ------------------------ Get a listing of all the drive letters ------------------------
      get_drive_list
      
      # ------------------------ Determine actual target drive ------------------------
      @target_drive = get_string_diff(@drive_list1, @drive_list2)
      
      # ------------------------ Copy file from WinXP host to fn storage ------------------------
      copy_file_to_device
      
      #-------------------------- This fix implemented to correct an issue with the file being downloaded from a queue instead of the actual target device ---#
      disconnect_usb_func_device                                                                                                                              #
                                                                                                                                                              #
      # ------------------------ Connect the USB switch to the correct USB port -----------------------                                                       #
      conn_usb_func_device                                                                                                                                    #   11-15-2011
      sleep 5                                                                                                                                                 #
                                                                                                                                                              #
      # ------------------------ Check if the USB fn storage connection was successfully connected to the host PC --------------------                        #
      ck_if_fn_storage_connected                                                                                                                              #
                                                                                                                                                              #
      # ------------------------ Check if the USB fn storage devicen was successfully enumerated to the host PC --------------------                          #
      wait_for_device_enumeration                                                                                                                             #
      #-------------------------------------------------------------------------------------------------------------------------------------------------------#
      
      # ------------------------ Copy file from fn storage to the WinXP host ------------------------
      copy_file_fm_device
      
      # ------------------------ Disconnect the USBfn switch --------------------
      disconnect_usb_func_device
      
      @copy_times['iterations'] += 1
      
      # ------------------------ Compare hash value when a single storage type is being used ------------------------ 
      if Digest::SHA2.file(@lcl_dsktop_tmp_dir+"\\"+@lcl_fn_file_name).hexdigest == Digest::SHA2.file(path_to_file_2 = @lcl_dsktop_tmp_dir+"\\"+@fn_sto_file_name).hexdigest
        @data1['fn_integrity_success_count'] += 1
        puts "\n ------------ Media file 1 was the same ------ Integrity Success: #{@data1['fn_integrity_success_count']} ------ Integrity Fail: #{@data1['fn_integrity_fail_count']} ------------ "+ __LINE__.to_s
        @equipment['dut1'].log_info("Iteration #{@copy_times['iterations']}: fn File integrity check with USBfn storage was successful")
      else
        @data1['fn_integrity_fail_count'] += 1
        puts "\n ------------ Media file 1 was the same ------ Integrity Success: #{@data1['fn_integrity_success_count']} ------ Integrity Fail: #{@data1['fn_integrity_fail_count']} ------------ "+ __LINE__.to_s
        @equipment['dut1'].log_info("Iteration #{@copy_times['iterations']}: fn File integrity check with USBfn storage was not successful")
      end
      
      # ------------------------ Calculate integrity check success rate for each iteration ------------------------ 
      @tot_integrity_success_rate = "%.2f" % (@data1['fn_integrity_success_count'] / (@data1['fn_integrity_success_count'] + @data1['fn_integrity_fail_count'])*100)
      
      # ------------------------ Delete local host copy of the test file ------------------------ 
      @equipment['server1'].send_cmd("del #{@lcl_dsktop_tmp_dir}\\#{@fn_sto_file_name}", />/,15)
      
      # ------------------------ Calculate current run times ------------------------
      calc_current_script_run_time
      calc_current_test_run_time
      
      # ------------------------ Count each loop ------------------------ 
      @iteri += 1
    end until (@data_time['curr_test_run_time_seconds'].to_i) >= @data_time['run_duration'].to_i
    
    save_test_end_time
    @avg_write_to_device_bw = 0
    @copy_times['avg_write_to_device_time'] = @copy_times['tot_write_to_device_time'].to_f / @copy_times['iterations'].to_f
    @copy_times['avg_write_to_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / @copy_times['avg_write_to_device_time']).to_f) / 1000000)
    @avg_write_to_device_bw = "%.3f" % (((@copy_times['xfer_file_size'].to_f / @copy_times['avg_write_to_device_time']).to_f) / 1000000).to_f
    @copy_times['avg_read_fm_device_time'] = "%.3f" % (@copy_times['tot_read_fm_device_time'].to_f / @copy_times['iterations']).to_f
    @copy_times['avg_read_fm_device_bw'] = "%.3f" % ((@copy_times['xfer_file_size'].to_f / @copy_times['avg_read_fm_device_time'].to_f) / 1000000)
    @avg_read_fm_device_bw = "%.3f" % ((@copy_times['xfer_file_size'].to_f / @copy_times['avg_read_fm_device_time'].to_f) / 1000000)
  end


  ############################################################## create_ftp_binary_file ########################################################################
  def create_ftp_binary_file
  
    super
    
    @equipment['server1'].send_cmd("dir #{@lcl_dsktop_tmp_dir}\\#{@lcl_fn_file_name}", />/)
    @copy_times['xfer_file_size'] = File.size?("#{@lcl_dsktop_tmp_dir}\\#{@lcl_fn_file_name}")
  end
  
  
  ############################################################## wait_for_device_enumeration #####################################################################
  def wait_for_device_enumeration
    puts "\n usb_fn_storage_integrity_test::wait_for_device_enumeration "+ __LINE__.to_s
    # ------------------------ Loop until the device has been enumerated or until the wait_time has been exceeded --------------------
    @data1['start_enum_loop_time'] = Time.now.strftime("%s")
    @data1['enum_ok'] = @data1['enum_fail'] = 0
    begin
      # ------------------------ Check if device has been enumerated and then increment the appropriate counter -------------- "
      @equipment['server1'].send_cmd("#{@lcl_dsktop_tmp_dir}\\devcon listclass volume", /(MEDIA\\8&E615446&0&RM)/,100)
    
      if /(MEDIA\\8&E615446&0&RM)/i.match(@equipment['server1'].response)
        @data1['enum_ok'] = 99
        @data1['end_enum_loop_time'] = Time.now.strftime("%s")
        @data1['enum_success_count'] += 1
        puts "\n ------------------------ fnStorage device enumeration was successful ------ "+ __LINE__.to_s
        break
      else
        @data1['enum_ok'] = 0
      end
      
      @data1['end_enum_loop_time'] = Time.now.strftime("%s")
      sleep 1
    end until (@data1['end_enum_loop_time'].to_i - @data1['start_enum_loop_time'].to_i) >= @max_wait_time.to_i
    
    # ------------------------ If device was not enumerated, increment the fail counter ---------------- "
    if @data1['enum_ok'] == 0
      @data1['enum_fail_count'] += 1
      puts "\n ------------------------ fnStorage device enumeration was not successful ------ "+ __LINE__.to_s
    else
      
    end
    
    # ------------------------ Determine enumeration time and populate the high or low variable ---------------- "
    @temp_enum_time = (@data1['end_enum_loop_time'].to_i - @data1['start_enum_loop_time'].to_i)
    
    if @temp_enum_time.to_i < @data1['low_enum_time'].to_i || @data1['low_enum_time'].to_i == 0
      @data1['low_enum_time'] = @temp_enum_time.to_i
    end
      
    if @temp_enum_time.to_i > @data1['high_enum_time'].to_i || @data1['high_enum_time'].to_i == 0
      @data1['high_enum_time'] = @temp_enum_time.to_i
    end
    
    @data1['enum_count'] += 1
    @data1['tot_enum_time'] += @temp_enum_time.to_i
    @data1['avg_enum_time'] = "%.2f" % (@data1['tot_enum_time'] / @data1['enum_count']).to_f
  end

  
  ############################################################## get_drive_list #####################################################################
  def get_drive_list
      # ------------------------ Get a listing of all the drive letters ------------------------
      @equipment['server1'].send_cmd("fsutil fsinfo drives", />/)
      @drive_list2.clear
      
      if @drive_list2.length == 0
        @drive_list2 << @equipment['server1'].response.scan(/(\w+\:)\\/i)
      else
        @drive_list2[0] << @equipment['server1'].response.scan(/(\w+\:)\\/i)
      end
  end
  
  
  ############################################################## copy_file_to_device #####################################################################
  # ------------------------ Copy test file from WinXP host to the storage device ------------------------
  def copy_file_to_device
    puts "\n ------------------------ The test file is being copied to the target device ------------------------ "+ __LINE__.to_s
    @copy_media1_start_seconds = Time.now.strftime("%s").to_i
    @equipment['server1'].send_cmd("copy #{@lcl_dsktop_tmp_dir}\\#{@lcl_fn_file_name} #{@target_drive}\\#{@fn_sto_file_name}", />/,100)
    @copy_media1_end_seconds = Time.now.strftime("%s").to_i
    
    if (@copy_media1_end_seconds - @copy_media1_start_seconds) < @copy_times['low_write_to_device_time'] || @copy_times['low_write_to_device_time'] == 0
      @copy_times['low_write_to_device_time'] = (@copy_media1_end_seconds - @copy_media1_start_seconds).to_i
      @copy_times['low_write_to_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / (@copy_media1_end_seconds - @copy_media1_start_seconds)).to_f) / 1000000)
    end
    
    if (@copy_media1_end_seconds - @copy_media1_start_seconds) > @copy_times['high_write_to_device_time'] || @copy_times['high_write_to_device_time'] == 0
      @copy_times['high_write_to_device_time'] = (@copy_media1_end_seconds - @copy_media1_start_seconds).to_i
      @copy_times['high_write_to_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / (@copy_media1_end_seconds - @copy_media1_start_seconds)).to_f) / 1000000)
    end

    @copy_times['tot_write_to_device_time'] += (@copy_media1_end_seconds - @copy_media1_start_seconds)
    @copy_times['write_to_device_time'] = (@copy_media1_end_seconds - @copy_media1_start_seconds)
    @copy_times['write_to_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / @copy_times['write_to_device_time']).to_f) / 1000000)

    sleep 4
  end
  
  
  ############################################################## get_string_diff #####################################################################
  # ------------------------ Copy test file from storage device to the WinXP host ------------------------
  def copy_file_fm_device
    puts "\n ------------------------ The test file is being copied from the target device ------------------------ "+ __LINE__.to_s
    @copy_media2_start_seconds = Time.now.strftime("%s").to_i
    @equipment['server1'].send_cmd("copy #{@target_drive}\\#{@fn_sto_file_name} #{@lcl_dsktop_tmp_dir}\\#{@fn_sto_file_name}", />/,100)
    @copy_media2_end_seconds = Time.now.strftime("%s").to_i

    if (@copy_media2_end_seconds - @copy_media2_start_seconds) < @copy_times['low_read_fm_device_time'] || @copy_times['low_read_fm_device_time'] == 0
       @copy_times['low_read_fm_device_time'] = (@copy_media2_end_seconds - @copy_media2_start_seconds).to_i
       @copy_times['low_read_fm_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / (@copy_media2_end_seconds - @copy_media2_start_seconds)).to_f) / 1000000)
    end
    
    if (@copy_media2_end_seconds - @copy_media2_start_seconds) > @copy_times['high_read_fm_device_time'] || @copy_times['high_read_fm_device_time'] == 0
       @copy_times['high_read_fm_device_time'] = (@copy_media2_end_seconds - @copy_media2_start_seconds).to_i
       @copy_times['high_read_fm_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / (@copy_media2_end_seconds - @copy_media2_start_seconds)).to_f) / 1000000)
    end

    @copy_times['tot_read_fm_device_time'] += (@copy_media2_end_seconds - @copy_media2_start_seconds)
    @copy_times['read_fm_device_time'] = (@copy_media2_end_seconds - @copy_media2_start_seconds)
    @copy_times['read_fm_device_bw'] = "%.3f" % (((@copy_times['xfer_file_size'].to_f / (@copy_media2_end_seconds.to_f - @copy_media2_start_seconds)).to_f) / 1000000)
    @equipment['server1'].send_cmd("del #{@target_drive}\\#{@fn_sto_file_name}", />/,15)
    sleep 4
  end
  
  
  ############################################################## get_string_diff #####################################################################
  def get_string_diff(first_string, second_string)
    ref_array = first_array = first_string
    second_array = sec_array = second_string
    
    if sec_array[0].length < first_array[0].length
      ref_array = sec_array
      second_array = first_array 
    end
    
    bottom_up = 0
    top_down = second_array[0].length
    length_diff = second_array[0].length - ref_array[0].length
    (second_array[0].length-1).downto(0) do |idx|
    
      if ref_array[0][idx-length_diff] != second_array[0][idx]
        bottom_up = idx
        break
      end
    end
  0.upto(second_array[0].length-1) do |idx|
    if ref_array[0][idx] != second_array[0][idx]
      top_down = idx
      break
    end
  end
  
  test_drive = second_array[0][top_down..bottom_up][0][0]
  test_drive
  end


  ############################################################## ck_if_fn_storage_connected #####################################################################
  def ck_if_fn_storage_connected
    puts "\n usb_fn_storage_integrity_test::ck_if_fn_storage_connected "+ __LINE__.to_s
    @data1['fn_connect_ok'] = 0
    @equipment['server1'].send_cmd("#{@lcl_dsktop_tmp_dir}\\devcon listclass usb", />/)
  
    # ------------------------ If connect was successful, increment the success_count value. Otherwise, increment the fail_count value --------------------
    if /VID\_(045e)\&PID\_(FFFF)/i.match(@equipment['server1'].response)
      @data1['fn_connect_ok'] = 99
      @data1['fn_success_count'] += 1
    else
      @data1['fn_connect_ok'] = 0
      @data1['fn_fail_count'] += 1
    end
    
    @tot_fn_success_rate = "%.2f" % (@data1['fn_success_count'].to_f / (@data1['fn_success_count'] + @data1['fn_fail_count']).to_f * 100) 
  end
  
  
  ############################################################## ck_if_fn_storage_enumerated #####################################################################
  def ck_if_fn_storage_enumerated
    @data1['enum_ok'] = @data1['enum_fail'] = 0
    @equipment['server1'].send_cmd("#{@lcl_dsktop_tmp_dir}\\devcon listclass volume", /(MEDIA\\8&E615446&0&RM)/,100)
    
    if /(MEDIA\\8&E615446&0&RM)/i.match(@equipment['server1'].response)
      @data1['enum_ok'] = 99
      @data1['end_enum_loop_time'] = Time.now.strftime("%s")
      @data1['enum_success_count'] += 1
    else
      @data1['enum_ok'] = 0
    end
  end

  
  ############################################################## clean #########################################################################################
  def clean
    puts "\n usb_fn_storage_integrity_test::clean "+ __LINE__.to_s
    clean_delete_local_temp_files
    super
  end

  
  ############################################################## run_save_results ##############################################################################
  def run_save_results
    puts "\n usb_fn_storage_integrity_test::run_save_results "+ __LINE__.to_s
    create_evm_info_table
    create_usb_fn_enum_html_page
    result,comment,@fn_enum_perfdata = run_determine_test_outcome
    
    if @fn_enum_perfdata
      set_result(result,comment,@fn_enum_perfdata)
    else
      set_result(result,comment)
    end
  end

  
  ############################################################## run_determine_test_outcome ####################################################################
  def run_determine_test_outcome
    puts "\n usb_fn_storage_integrity_test::run_determine_test_outcome "+ __LINE__.to_s
    @fn_enum_perfdata << {'name'=> "Total Fn Storage Connects", 'value'=> "#{@data1['fn_success_count'] + @data1['fn_fail_count']}".to_i, 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Successful Fn Storage Connects", 'value'=> "#{@data1['fn_success_count']}", 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Failed Fn Storage Connects", 'value'=> "#{@data1['fn_fail_count']}", 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Fn Storage Connect Success Rate %", 'value'=> "#{@tot_fn_success_rate.to_i}", 'units' => "Percent"}
    @tot_enum_success_rate = @data1['enum_success_count'] / (@data1['enum_success_count'] + @data1['enum_fail_count'])*100
    
    @fn_enum_perfdata << {'name'=> "Total Fn Storage Enumerations", 'value'=> "#{@data1['enum_success_count'] + @data1['enum_fail_count']}", 'units' => "Enumerations"}
    @fn_enum_perfdata << {'name'=> "Successful Fn Storage Enumerations", 'value'=> "#{@data1['enum_success_count']}", 'units' => "Enumerations"}
    @fn_enum_perfdata << {'name'=> "Failed Fn Storage Enumerations", 'value'=> "#{@data1['enum_fail_count']}", 'units' => "Enumerations"}
    @fn_enum_perfdata << {'name'=> "Fn Storage Enumerations Success Rate %", 'value'=> "#{@tot_enum_success_rate.to_i}", 'units' => "Percent"}
    @fn_enum_perfdata << {'name'=> "Low Enumeration Time", 'value'=> "#{@data1['low_enum_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Average Enumeration Time", 'value'=> "#{@data1['avg_enum_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "High Enumeration Time", 'value'=> "#{@data1['high_enum_time']}", 'units' => "Secondst"}
    @tot_integrity_success_rate = "%.2f" % (@data1['fn_integrity_success_count'] / (@data1['fn_integrity_success_count'] + @data1['fn_integrity_fail_count'])*100)
    @fn_enum_perfdata << {'name'=> "Successful File Integrity Checks", 'value'=> "#{@data1['fn_integrity_success_count']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Successful File Integrity Checks", 'value'=> "#{@data1['fn_integrity_fail_count']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Successful File Integrity Checks", 'value'=> "#{@tot_integrity_success_rate}", 'units' => "Seconds"}
    
    @fn_enum_perfdata << {'name'=> "Min Copy Time to Device", 'value'=> "#{@copy_times['low_write_to_device_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Average Copy Time to Device", 'value'=> "#{@copy_times['avg_write_to_device_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Max Copy Time to Device", 'value'=> "#{@copy_times['high_write_to_device_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Min Copy Time fm Device", 'value'=> "#{@copy_times['low_read_fm_device_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Average Copy Time fm Device", 'value'=> "#{@copy_times['avg_read_fm_device_time']}", 'units' => "Seconds"}
    @fn_enum_perfdata << {'name'=> "Max Copy Time fm Device", 'value'=> "#{@copy_times['high_read_fm_device_time']}", 'units' => "Secondst"}
    
    if @data1['fn_fail_count'] == 0 && @data1['enum_fail_count'] == 0 && @data1['fn_integrity_fail_count'] == 0
      return [FrameworkConstants::Result[:pass], "This test pass.", @fn_enum_perfdata]
    puts "\n -------------------- Marker Pass -------------------- "+ __LINE__.to_s
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    puts "\n -------------------- Marker Fail -------------------- "+ __LINE__.to_s
    end
  end

  
  ############################################################## create_evm_info_table #########################################################################
  def create_evm_info_table
    puts "\n usb_fn_storage_integrity_test::create_evm_info_table "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["General Test Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white", :size => "4"}]])
    
    if @copy_times['xfer_file_size'].to_i == 0
      @file_size = "N/A"
    else
      @file_size = @test_params.params_equip.ftp_file_size[0]
    end
    
    res_table = @results_html_file.add_table([["Device Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["USB Interface Tested",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Specified Test Duration",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Actual Test Duration",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["File Size Used For Test (MB)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Future",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
      
    @results_html_file.add_rows_to_table(res_table,[[["#{"#{@equipment['dut1'].board_id}"}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@data1['usb_test_intfc'].upcase}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_dur}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_time}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@file_size} MB  (#{@copy_times['xfer_file_size']} Bytes)",{:bgcolor => "white"},{:size => "2.5"}],
                ["Future",{:bgcolor => "white"},{:size => "2"}]]])
  end
  
  
  ############################################################## create_usb_fn_enum_html_page #####################################################################
  # ------------------------ Add any notes about the displayed info/test results/statistics ------------------------
  def create_usb_fn_enum_html_page
    puts "\n usb_fn_storage_integrity_test::create_usb_enum_html_page "+ __LINE__.to_s
    
    # ------------------------ Setup connect test result portion of the html page ------------------------
    res_table = @results_html_file.add_table([["USB Fn Connect Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Fn Storage Connect Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
    
    if @data1['fn_fail_count'] == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data1['fn_success_count'] + @data1['fn_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_success_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_fn_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])
    
    # ------------------------ Add file integrity check info/test results/statistics ------------------------
    res_table = @results_html_file.add_table([["USB Fn Enumeration Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Fn Enumeration Attempts",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Fn Storage Enumerations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Fn Storage Enumerations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Fn Storage Enumeration Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Low Enumeration Time (Secs)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Average Enumeration Time (Secs)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["High Enumeration Time (Secs)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    if @data1['enum_fail_count'] == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @tot_enum_success_rate = "%.2f" % (@data1['enum_success_count'].to_f / (@data1['enum_success_count'].to_f + @data1['enum_fail_count'].to_f)*100)
    @results_html_file.add_rows_to_table(res_table,[[["#{@data1['enum_success_count'] + @data1['enum_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['enum_success_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['enum_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_enum_success_rate}",{:bgcolor => status_color},{:size => "2"}],
                ["#{@data1['low_enum_time']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['avg_enum_time']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['high_enum_time']}", {:bgcolor => "white"},{:size => "2"}]]])

    # ------------------------ Add file integrity check info/test results/statistics ------------------------
    res_table = @results_html_file.add_table([["USB Fn File Integrity Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Fn File Copy Integrity Checks",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful File Integrity Checks",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed File Integrity Checks",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Fn File Integrity Checks Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])

    if @data1['fn_integrity_fail_count'] == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data1['fn_integrity_success_count'] + @data1['fn_integrity_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_integrity_success_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_integrity_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_integrity_success_rate}", {:bgcolor => status_color},{:size => "2"}]]])
    
    # ------------------------ Add file copy results/statistics ------------------------
    res_table = @results_html_file.add_table([["USB Fn File Copy Speeds",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Min Copy To Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Average Copy To Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Max Copy To Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Min Copy Fm Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Average Copy Fm Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Max Copy Fm Device Perf (MB/Sec)",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])

    @results_html_file.add_rows_to_table(res_table,[[["#{@copy_times['high_write_to_device_bw']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@avg_write_to_device_bw}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@copy_times['low_write_to_device_bw']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@copy_times['high_read_fm_device_bw']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@avg_read_fm_device_bw}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@copy_times['low_read_fm_device_bw']}", {:bgcolor => "white"},{:size => "2"}]]])

    # ------------------------ Add any notes about the displayed info/test results/statistics ------------------------
    res_table = @results_html_file.add_table([["NOTES",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["01. Each time the USB Fn device connects successfully, a file is copied betwenn the WinXP host snd the device. The integrity of file transferred file is then checked.",{:bgcolor => "white", :align => "left", :colspan => "1"}, {:color => "blue", :size => "2"}]])		
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

