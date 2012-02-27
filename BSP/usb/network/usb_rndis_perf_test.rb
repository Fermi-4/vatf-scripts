#initial release - 02-24-2012
require File.dirname(__FILE__)+'/../../common_test_mod'
require File.dirname(__FILE__)+'/../../usb_common_mod'
include CommonTestMod
include UsbCommonModule

  ############################################################## run_collect_performance_data ##################################################################
  def run_collect_performance_data
    puts "\n usb_rndis_perf_test::run_collect_performance_data "+ __LINE__.to_s
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "\n usb_rndis_perf_test::setup_connect_equipment "+ __LINE__.to_s
    puts "\n -------------------- Initializing the USB Fn Switch Connection-------------------- "+ __LINE__.to_s
    init_usb_sw("usb_swfn")
    
    super
  end


  ############################################################## run_generate_script #######################################################################
    def run_generate_script
    puts "\n usb_rndis_perf_test::run_generate_script"
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

  
   ############################################################## run_call_script #######################################################################
  def run_call_script
    puts "\n usb_rndis_perf_test::usb_run_call_script"
    init_common_hash_arrays("@data1")
    init_common_hash_arrays("@copy_times")

    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Save the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Initialize the RNDIS function mode on the EVM after a power reboot --------------------
    init_rndis_on_evm
    
    # ------------------------ Copy USBDeview.exe and supporting files from gtautoftp --------------------
    cp_dv_binaryfiles

    cp_rndis_dsktop_files
    get_ws2_svr_pid
  
    # ------------------------ Save the test start time and convert it to seconds for later use --------------------
    save_test_start_time
    
    if @ws2_svr_pid == 0
      start_wsperf_server
      get_ws2_svr_pid
    else
      get_ws2_svr_pid
    end
    
    ck_if_rndis_connected

    if @rndis_pid == 0
      conn_usb_func_device
    else
      puts "\n---------- Rndis is already running ------ "+ __LINE__.to_s
    end
    
    ck_if_rndis_connected
    super
  end


  ############################################################## clean_delete_log_files ###########################################################################
  # Delete log files (if any) 
  def clean_delete_log_files
    puts "\n usb_rndis_perf_test::clean_delete_log_files"
    super
  end

  
  ############################################################## run_save_results ##############################################################################
  def run_save_results
    puts "\n usb_rndis_perf_test::run_save_results "+ __LINE__.to_s
    stop_wsperf_server                              #stop perf_winsock server on WinP desktop
    disconnect_usb_func_device
    result,comment,@fn_enum_perfdata = run_determine_test_outcome
    
    if @fn_enum_perfdata
      set_result(result,comment,@fn_enum_perfdata)
    else
      set_result(result,comment)
    end
  end


  ############################################################## run_determine_test_outcome #######################################################################
  def run_determine_test_outcome
    puts "\n usb_rndis_perf_test::run_determine_test_outcome "+ __LINE__.to_s
    stop_wsperf_server                              #stop perf_winsock server on WinP desktop
    @ws2_perfdata = Array.new
    collect_test_header_data
    collect_test_type_data
    process_perf_data
    create_test_result_header
    create_html_header_page
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Test Log File Contents",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    @results_html_file.add_paragraph(@all_lines,nil,nil,nil)

    puts "\n usb_rndis_perf_test::run_determine_test_outcome "+ __LINE__.to_s
    puts "\n\n ----- Test result:  #{@tst_result} ------------- "+ __LINE__.to_s
  
    if @tst_result == 1
      return [FrameworkConstants::Result[:pass], "This test pass.", @ws2_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end


  ############################################################## run_collect_data #####################################################################
  def clean
    clean_delete_local_temp_files
    tmp_file = @test_params.params_equip.lcl_dsktp_tmp_dir[0] + "\\pidchk.log"
    @equipment['server1'].send_cmd("del /F #{tmp_file}", />/)
    super
  end
  
  
  ############################################################## run_collect_data #####################################################################
  def run_collect_data
    puts "\n Entering usb_rndis_perf_test::run_collect_data "+ __LINE__.to_s
  end
  
  