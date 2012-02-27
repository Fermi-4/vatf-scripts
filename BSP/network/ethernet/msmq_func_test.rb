# 02-24-2012 - Initial release
require File.dirname(__FILE__)+'/../../common_test_mod'
include CommonTestMod

  ############################################################## run_collect_performance_data #######################################################################
  def run_collect_performance_data
  end
  
  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "Inside ws2perf_eth_test setup_connect_equipment "+ __LINE__.to_s
    @force_telnet_connect = true              #this variable, set as true, is required to run this script with the CEPC PC
  end
  
  
  ############################################################## run_save_results ##############################################################################
 def run_save_results
    puts "\n cepc_usb_host_test::run_save_results "+ __LINE__.to_s
    result,comment,@cepc_perfdata = run_determine_test_outcome
    
    if @cepc_perfdata
      set_result(result,comment,@cepc_perfdata)
      puts "\n ------------------ Marker - With perf data ------------------ "+ __LINE__.to_s
    else
      set_result(result,comment)
      puts "\n ------------------ Marker - Without perf data ------------------ "+ __LINE__.to_s
    end
  end

  
  ############################################################## run_call_script #######################################################################
  def run_call_script
    puts "\n Inside msmq_func_test::run_call_script "+ __LINE__.to_s
  
    # ------------------------ Initialize common network/USB variables/arrays --------------------
    init_net_usb_common_vars
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Check if the msmq files have been loaded --------------------
    chk_if_msmq_loaded

    super
  end
    
    
  ############################################################## chk_if_msmq_loaded #######################################################################
  def chk_if_msmq_loaded
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("msmqadm status",@equipment['dut1'].prompt)
    
    if /CE\s+\d+\.\d+.+MSMQ_CE/im.match(@equipment['dut1'].response)
      puts "\n ---------------------- MSMQADM is already running ------------------------ "+ __LINE__.to_s
    else
      puts "\n ---------------------- MSMQADM is not currently running but will be started ------------------------ "+ __LINE__.to_s
      @equipment['dut1'].send_cmd("#{@test_params.params_equip.host_cmd1[0]}",@equipment['dut1'].prompt)                                #host_cmd1
      sleep 2
      @equipment['dut1'].send_cmd("#{@test_params.params_equip.host_cmd2[0]}",@equipment['dut1'].prompt)
      
      if @equipment['dut1'].response.scan(/(DLL\_PROCESS\_ATTACH)/i)
        puts "\n ---------------------- MSMQADM was sucessfully started ------------------------ "+ __LINE__.to_s
      else
        puts "\n ---------------------- MSMQADM could not be started sucessfully ------------------------ "+ __LINE__.to_s
      end
    end
    
    sleep 2
  end
  
  
  ############################################################## run_collect_data #######################################################################
  def run_collect_data
    puts "\n Entering msmq_func_test::run_collect_data "+ __LINE__.to_s
    @msmq_perfdata = Array.new
    super
  end
  
  
  ############################################################## get_lcl_msmq_pid #######################################################################
  def get_lcl_msmq_pid            # Get msmqadm PID when run on the local desktop pc
    puts "\n msmq_func_test::get_lcl_msmq_pid "+ __LINE__.to_s
    @msmq_svr_pid = 0
    @equipment['server1'].send_cmd("tasklist /svc", />/)
    task_listing = @equipment['server1'].response
    
    if /CE\s+\d+\.\d+.+MSMQ_CE/im.match(task_listing)
      @msmq_svr_pid = /perf\_winsockd2.exe\s+([0-9]*)/im.match(@svc_lines).captures[0]
      puts "\n---------- MSMQ server is currently running ------ PID: #{@ws2_svr_pid} -------- "+ __LINE__.to_s
    else
      puts "\n---------- MSMQ server is not currently running "+ __LINE__.to_s
    end
  end
    

  ############################################################## stop_lcl_msmq_server #######################################################################
  def stop_lcl_msmq_server                              # Stop msmqadm when msmqadm is running on the local desktop pc
    puts "\n msmq_func_test::stop_msmq_server "+ __LINE__.to_s
    system("taskkill /F /PID #{@msmq_svr_pid}")
    sleep 2
  end
  

  ############################################################## clean #######################################################################
  def clean
    puts "\n msmq_func_test::clean "+ __LINE__.to_s
    clean_delete_binary_files
  end
  

  ############################################################## run_determine_test_outcome #######################################################################
  def run_determine_test_outcome
    puts "\n msmq_func_test::run_determine_test_outcome "+ __LINE__.to_s
    collect_test_header_data
    create_test_result_header
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Test Log File Contents",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    @results_html_file.add_paragraph(@all_lines,nil,nil,nil)

    if @tst_result == 1
      return [FrameworkConstants::Result[:pass], "This test pass.", @msmq_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end


  ############################################################## process_perf_data #######################################################################
  def process_perf_data
    #
    #	There is no perf data created with the MSMQ series of tests.
    #
  end


	
	