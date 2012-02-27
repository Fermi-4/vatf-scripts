#initial release - 11-04-2011
#updated 02-25-2012
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
    puts "\n usb_fn_storage_enum_test::setup_connect_equipment - Initializing the USB Fn Switch Connection "+ __LINE__.to_s
    #puts "\n -------------------- Initializing the USB Fn Switch -------------------- "+ __LINE__.to_s
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
    init_common_hash_arrays("@data_time")

    @TempBuffer = ""
    @start_loop_time = @end_loop_time = @enum_success_count = @enum_fail_count = @fn_connect_ok = 0
    @fn_success_count = @fn_fail_count = @enum_ok = @end_loop_time = @enum_time = 0
    @min_enum_time = @avg_enum_time = @max_enum_time = future = xyz = tmp1 = tmp2 = tmp3 = tmp4 = 0
    
    @max_wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10')
  
    # ------------------------ Initialize common network/USB arrays used by this script--------------------
    init_net_usb_common_vars
    
    # ------------------------ Initialize script specific variables ------------------------
    init_variables
  
    # ------------------------ Save the actual script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC ------------------------
    set_dut_datetime
  
    # ------------------------ Initialize the storage function mode on the EVM after a power reboot ------------------------
    init_storage_on_evm
  
    # ------------------------ Copy USBDeview.exe and supporting files from gtautoftp ------------------------
    cp_dv_binaryfiles
  
    # ------------------------ Calculate the desired script run time and convert it to seconds ------------------------
    calculate_desired_script_run_time
  
    # ------------------------ Save the actual test start time in seconds ------------------------
    save_test_start_time
    
    begin
      # ------------------------ Connect the USB switch to the correct USB port ------------------------
      conn_usb_func_device
    
      # ------------------------ Check if the USB fn storage connection was successfully connected to the host PC ------------------------
      ck_if_fn_storage_connected
      
      # ------------------------ Start the enumeration timer ------------------------
      @data1['start_enum_loop_time'] = Time.now.strftime("%s")
      
      # ------------------------ Loop until the device has been enumerated or until the wait_time has been exceeded ------------------------
      begin
        ck_if_fn_storage_enumerated
        
        # ------------------------ Loop until either the device is enumerated or the timeout expires ------------------------
        if @enum_ok == 99
          @data1['enum_success_count'] += 1
          @data1['end_enum_loop_time'] = Time.now.strftime("%s")
          break
        end
        
        @data1['end_enum_loop_time'] = Time.now.strftime("%s")
      end until (@data1['end_enum_loop_time'].to_i - @data1['start_enum_loop_time'].to_i) >= @max_wait_time.to_i
      
      if @enum_ok == 0
        @data1['enum_fail_count'] += 1
        puts "\n---------- fnStorage device enumeration was not successful ------ "+ __LINE__.to_s
      else
        puts "\n---------- fnStorage device enumeration was successful ------ "+ __LINE__.to_s
      end
      
      @enum_time = 	(@data1['end_enum_loop_time'].to_i - @data1['start_enum_loop_time'].to_i)
      
      # ------------------------ Disconnect the USBfn switch --------------------
      disconnect_usb_func_device
      
      @data << ["#{@data1['fn_success_count'].to_i}",
                "#{@data1['fn_fail_count'].to_i}",
                "#{@data1['enum_success_count'].to_i}",
                "#{@data1['enum_fail_count'].to_i}",
                "#{@enum_time.to_i}",
                "#{@iteri.to_i}",
                "#{@low_enum_time.to_i}",
                "#{@avg_enum_time.to_i}",
                "#{@high_enum_time.to_i}",
                "#{future.to_i}"]
      
      # ------------------------ Calculate current run times ------------------------
      calc_current_script_run_time
      calc_current_test_run_time
      
      # ------------------------ Count each loop ------------------------ 
      @iteri += 1
      
    end until (@data_time['curr_test_run_time_seconds'].to_i) >= @data_time['run_duration'].to_i
    
    save_test_end_time
    
    # ------------------------ Determine the high, low and the average enumeration times --------------------
    until xyz >= (@data.length) do
      
      if tmp1.to_i == 0 || @data[xyz][4].to_i < tmp1.to_i
        tmp1 = @data[xyz][4]
      end
      
      if tmp3.to_i == 0 || @data[xyz][4].to_i > tmp3.to_i
        tmp3 = @data[xyz][4]
      end
      
      tmp2 += @data[xyz][4].to_f
      @data[xyz][7] = tmp2.to_s
      xyz += 1
    end
    
    @min_enum_spd = "%.2f" % (tmp1.to_f)
    @avg_enum_spd = "%.2f" % (tmp2.to_f / @data.length.to_f)
    @max_enum_spd = "%.2f" % (tmp3.to_f)
    
    puts "\n ---------------- #{@min_enum_spd} ------ #{@avg_enum_spd} ------ #{@max_enum_spd} ---------------- "+ __LINE__.to_s
    xyz = xyz - 1
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
    @enum_ok = 0
    @enum_fail = 0
    @equipment['server1'].send_cmd("#{@lcl_dsktop_tmp_dir}\\devcon listclass volume", /(MEDIA\\8&E615446&0&RM)/,90)
    
    if /(MEDIA\\8&E615446&0&RM)/i.match(@equipment['server1'].response)
      @enum_ok = 99
    else
      @enum_ok = 0
    end
    
    sleep 1
  end

  
  ############################################################## clean #########################################################################################
  def clean
    puts "\n usb_fn_storage_enum_test::clean "+ __LINE__.to_s
    clean_delete_local_temp_files
    super
  end

  
  ############################################################## run_save_results ##############################################################################
  def run_save_results
    puts "\n usb_fn_storage_enum_test::run_save_results "+ __LINE__.to_s
    create_evm_info_table
    create_usb_fn_enum_html_page
    result,comment,@fn_enum_perfdata = run_determine_test_outcome
  
    if @fn_enum_perfdata
      set_result(result,comment,@fn_enum_perfdata)
      puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
    else
      set_result(result,comment)
      puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s
    end
  end

  
  #[@fn_success_count.to_i, @fn_fail_count.to_i, @enum_success_count.to_i, @enum_fail_count.to_i}, @enum_time.to_i, @iteri.to_i, low_enum_time.to_i, high_enum_time.to_i
  ############################################################## run_determine_test_outcome ####################################################################
  def run_determine_test_outcome
    puts "\n usb_fn_storage_enum_test::run_determine_test_outcome "+ __LINE__.to_s
    x=0
    @tot_fn_success_rate = @data1['fn_success_count'].to_i / (@data1['fn_success_count'].to_i + @data1['fn_fail_count'].to_i)*100
    @fn_enum_perfdata << {'name'=> "Total Fn Storage Connects", 'value'=> "#{@data1['fn_success_count'].to_i + @data1['fn_fail_count'].to_i}".to_i, 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Successful Fn Storage Connects", 'value'=> "#{@data1['fn_success_count'].to_i}", 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Failed Fn Storage Connects", 'value'=> "#{@data1['fn_fail_count'].to_i}", 'units' => "Connects"}
    @fn_enum_perfdata << {'name'=> "Fn Storage Connect Success Rate %", 'value'=> "#{@tot_fn_success_rate.to_i}", 'units' => "Percent"}

    @tot_enum_success_rate = @data1['enum_success_count'].to_i / (@data1['enum_success_count'].to_i + @data1['enum_fail_count'].to_i)*100
    @fn_enum_perfdata << {'name'=> "Total Fn Storage Enumerations", 'value'=> "#{@data1['enum_success_count'].to_i + @data1['enum_fail_count'].to_i}", 'units' => "Pings"}
    @fn_enum_perfdata << {'name'=> "Successful Fn Storage Enumerations", 'value'=> "#{@data1['enum_success_count'].to_i}", 'units' => "Pings"}
    @fn_enum_perfdata << {'name'=> "Failed Fn Storage Enumerations", 'value'=> "#{@data1['enum_fail_count'].to_i}", 'units' => "Pings"}
    @fn_enum_perfdata << {'name'=> "Fn Storage Enumerations Success Rate %", 'value'=> "#{@tot_enum_success_rate.to_i}", 'units' => "Percent"}
    
    if @data1['fn_fail_count'].to_i == 0 && @data1['enum_fail_count'].to_i == 0
      return [FrameworkConstants::Result[:pass], "This test pass.", @fn_enum_perfdata]
    puts "\n -------------------- Marker Pass -------------------- "+ __LINE__.to_s
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    puts "\n -------------------- Marker Fail -------------------- "+ __LINE__.to_s
    end
  end
  
  
  ############################################################## create_usb_rndis_enum_html_page #####################################################################
  def create_usb_fn_enum_html_page
    puts "\n usb_common_module::create_usb_enum_html_page "+ __LINE__.to_s
    
    res_table = @results_html_file.add_table([["USB Fn Connect Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Fn Storage Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Fn Storage Connect Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
    
    if @data1['fn_fail_count'].to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    
    
    @tot_fn_success_rate = @data1['fn_success_count'].to_i / (@data1['fn_success_count'].to_i + @data1['fn_fail_count'].to_i)*100
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data1['fn_success_count'].to_i + @data1['fn_fail_count'].to_i}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_success_count'].to_i}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['fn_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_fn_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])
    
    res_table = @results_html_file.add_table([["USB Fn Enumeration Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Fn Enumeration Attempts",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Fn Storage Enumerations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Fn Storage Enumerations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Minimum Enumeration Time",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Average Enumeration Time",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Maximum Enumeration Time",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Fn Storage Enumeration Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    if @data1['enum_fail_count'].to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @tot_enum_success_rate = @data1['enum_success_count'].to_i / (@data1['enum_success_count'].to_i + @data1['enum_fail_count'].to_i)*100
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data1['enum_success_count'].to_i + @data1['enum_fail_count'].to_i}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['enum_success_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@data1['enum_fail_count']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@min_enum_spd}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@avg_enum_spd}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@max_enum_spd}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_enum_success_rate}", {:bgcolor => status_color},{:size => "2"}]]])
      
    res_table = @results_html_file.add_table([["NOTES",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["01. Each time the USB Fn device connects successfully, #{@pings_per_iteration} pings are sent to the EVM to verify network connectivity has been established.",{:bgcolor => "white", :align => "left", :colspan => "1"}, {:color => "blue", :size => "2"}]])
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

