# Updated 02-24-2012 - Initial release

module NetCommonModule
  ############################################################## run_collect_performance_data #####################################################################
  def run_collect_performance_data
    @ws2_perfdata
  end


  ############################################################## run_collect_data #####################################################################
  def run_collect_data
    puts "\n Entering net_common_mod::run_collect_data "+ __LINE__.to_s
  end
  

  ############################################################## run_determine_test_outcome #####################################################################
  def run_determine_test_outcome
    puts "\n net_common_mod::run_determine_test_outcome "+ __LINE__.to_s
    run_collect_data
    create_html_header_page
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["Test Log File Contents",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
    @results_html_file.add_paragraph(@all_lines,nil,nil,nil)
  
    if @tst_result == 1
      return [FrameworkConstants::Result[:pass], "This test pass.", @ws2_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end


  ############################################################## clean #####################################################################
  def clean
    clean_delete_log_files
    super
  end


  ############################################################## get_ws2_svr_pid #####################################################################
  #get the process ID of the Winsock server if it is running.
  def get_ws2_svr_pid
    puts "\n net_common_mod::get_ws2_svr_pid "+ __LINE__.to_s
    @ws2_svr_pid = 0
    puts "\n----------- Checking if winsock server is running. --- "+ __LINE__.to_s
    
    @equipment['server1'].send_cmd("tasklist /svc", />/)
    task_listing = @equipment['server1'].response
    
    if /perf\_winsockd2.exe\s+([0-9]*)/im.match(task_listing)
      @ws2_svr_pid = /perf\_winsockd2.exe\s+([0-9]*)/im.match(task_listing).captures[0]
      puts "\n---------- Winsock server is currently running ------ PID: #{@ws2_svr_pid} -------- "+ __LINE__.to_s
    else
      puts "\n---------- Winsock server is not currently running ------ #{@test_params.params_equip.lcl_dsktp_tmp_dir[0]}\\#{@test_params.params_equip.ws2_svr_file[0]} -debug "+ __LINE__.to_s
    end
  end
  
  
  ############################################################## start_wsperf_server #####################################################################
  def start_wsperf_server
    system("cmd /c start /min #{@test_params.params_equip.lcl_dsktp_tmp_dir[0]}\\#{@test_params.params_equip.ws2_svr_file[0]} -debug ")
    sleep 2
  end
  

  ############################################################## stop_wsperf_server #####################################################################
  def stop_wsperf_server
    system("taskkill /F /PID #{@ws2_svr_pid}")
  end
  
  
  ############################################################## start_wsserver #####################################################################
  def start_wsserver
    if /(perf\_winsockd2.exe)\s+([0-9]*)/im.match(@equipment['server1'].response)
      @ws_svr_pgm,@ws_svr_pid = /(perf\_winsockd2.exe)\s+([0-9]*)/i.match(@equipment['server1'].response).captures
      sleep 1
      @equipment['server1'].send_cmd("taskkill /pid #{@ws_svr_pid}", @equipment['server1'].prompt, 6)
    else
      raise "The Winsock server could not be started. "+ __LINE__.to_s
    end
  end

  
  ############################################################## create_ftp_file #####################################################################
  def create_ftp_file
    puts "\n -------------------- Creating FTP file -------------------- "+ __LINE__.to_s
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'createfile.bat'),'w')
    out_file.puts(eval('"'+"cd #{@lcl_dsktop_tmp_dir}".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    @tmp = "dd if=/dev/random of=#{@lcl_dsktop_tmp_dir}" + "\\" + "ftptest.bin bs=1M count=#{@test_params.params_equip.ftpfilesize[0]}"
    out_file.puts(eval('"'+@tmp.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.close
    @tst_file = "call #{File.join(@lcl_dsktop_tmp_dir, 'createfile.bat')}"                                #dd if=/dev/zero of=C:\Temp_dd\test1.bin bs=1M count=20
    system("call #{@tst_file}")
    sleep 1
  end
end