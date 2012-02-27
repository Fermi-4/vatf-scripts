# 02-24-2012 - Initial release
require File.dirname(__FILE__)+'/../../common_test_mod'
include CommonTestMod

  ############################################################## run_collect_performance_data #######################################################################
  def run_collect_performance_data
    @ws2_perfdata
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "ws2perf_eth_test setup_connect_equipment "+ __LINE__.to_s
    @force_telnet_connect = true              #this variable, set as true, is required to run this script with the CEPC PC
  end

  
  ############################################################## run #######################################################################
  # Execute shell script in DUT(s) and save results.
  def run
    puts "\n ws2perf_eth_test::run "+ __LINE__.to_s
    run_generate_script
    run_transfer_script
    run_call_script
    run_get_script_output
    puts "\n\n ----- Test timer result:  #{@script_output_timer} ------------- "+ __LINE__.to_s
    
    run_save_results
  end


 ############################################################## run_call_script #######################################################################
  def run_call_script
    puts "\n ws2perf_eth_test::run_call_script "+ __LINE__.to_s
    init_common_hash_arrays("@data1")
    init_common_hash_arrays("@copy_times")
    
    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Savet the script start time in seconds --------------------
    save_script_start_time
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Copy winsock server files to the local PC --------------------
    cp_dsktop_files
    
    # ------------------------ Get Winsock Server PID if it is running --------------------
    get_ws2_svr_pid
  
    if @ws2_svr_pid == 0
      start_wsperf_server
    end
    
    get_ws2_svr_pid
    super
  end

  
  ############################################################## run_collect_data #######################################################################
  def run_collect_data
    puts "\n ws2perf_eth_test::run_collect_data "+ __LINE__.to_s
  end


  ############################################################## clean_delete_log_files #######################################################################
  # Delete log files (if any) 
  def clean_delete_log_files
    puts "\n ws2perf_eth_test::clean_delete_log_files "+ __LINE__.to_s
    sleep 3
    tmp_file = @test_params.params_equip.lcl_dsktp_tmp_dir[0] + "\\pidchk.log"
    system("del /F #{tmp_file}")
    super
  end


  ############################################################## clean #######################################################################
  def clean
    puts "\n ws2perf_eth_test::clean "+ __LINE__.to_s
    clean_delete_local_temp_files
    super
  end

  
  ############################################################## run_determine_test_outcome #######################################################################
  def run_determine_test_outcome
    puts "\n ws2perf_eth_test::run_determine_test_outcome "+ __LINE__.to_s
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

    puts "\n ws2perf_eth_test::run_determine_test_outcome "+ __LINE__.to_s
    puts "\n\n ----- Test result:  #{@tst_result} ------------- "+ __LINE__.to_s
  
    if @tst_result == 1
      return [FrameworkConstants::Result[:pass], "This test pass.", @ws2_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end
  
  

  