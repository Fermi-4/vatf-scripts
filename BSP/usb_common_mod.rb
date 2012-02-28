#initial release - 10-31-2011
#Update #1 - 02-24-2012

module UsbCommonModule

  ############################################################## run_collect_performance_data ###################################################################
  def run_collect_performance_data
    @ws2_perfdata
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "usb_common_module::setup_connect_equipment "+ __LINE__.to_s
    #@wince_temp_dir = @test_params.params_equip.instance_variable_defined?(:@rmt_temp_root) ? @test_params.params_equip.rmt_temp_root[0] : '\Temp'
    
    if @test_params.params_chan.instance_variable_defined?(:@lcl_dsktp_tmp_dir) && @test_params.instance_variable_defined?(:@var_test_libs_root)
      @lcl_dsktop_tmp_dir = @test_params.params_chan.lcl_dsktp_tmp_dir[0]
    end
    
    @usb_intfc = @test_params.params_equip.instance_variable_defined?(:@usb_test_intfc) ? @test_params.params_control.usb_test_intfc[0] : 'ehci'
    super()
  end


  ############################################################## conn_usb_func_rndis #############################################################
  def conn_usb_func_rndis
    puts "\n usb_common_module::conn_usb_func_rndis "+ __LINE__.to_s
    @equipment['usb_swfn'].select_input(@equipment['dut1'].params['otg_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i
  end
  
  
  ############################################################## init_usb_switch ###############################################################################
  # -------------------- This routine will initialize the USB switch --------------------
  def init_usb_sw(sw_type=nil)
    puts "\n usb_common_module::init_usb_sw ----- #{sw_type} ----- "+ __LINE__.to_s
    
    if @equipment["#{sw_type}"].respond_to?(:serial_port) && @equipment["#{sw_type}"].serial_port != nil
      @equipment["#{sw_type}"].connect({'type'=>'serial'})
    elsif @equipment["#{sw_type}"].respond_to?(:serial_server_port) && @equipment["#{sw_type}"].serial_server_port != nil
      @equipment["#{sw_type}"].connect({'type'=>'serial'})
    else
      raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the USB switch. Please check your bench file" 
    end
    
    puts "\n --------------------  Resetting the Extron USB switch to port 0-------------------- "+ __LINE__.to_s
    @equipment["#{sw_type}"].send_cmd("I") ; sleep 2                          #Used to clear serial buffer, after initial connect to USB switch has been completed
    @equipment["#{sw_type}"].select_input(0)
  end

  
  ############################################################## connect_usb_sw #############################################################
  #Connect the USB switch if we are testing a USB device.
  def connect_usb_sw(sw_type=nil)
    puts "\n usb_common_module::connect_usb_sw #{sw_type} "+ __LINE__.to_s
    
    if @test_params.params_control.mediatype_1[0] == "usbhd" || @test_params.params_control.mediatype_2[0] == "usbhd"
      if @test_params.params_control.usb_test_intfc[0] == "ehci"
      @equipment["#{sw_type}"].select_input(@equipment['dut1'].params['ehci_port'])
      else
      @equipment["#{sw_type}"].select_input(@equipment['dut1'].params['otg_port'])
      end
    
      sleep @test_params.params_control.wait_after_connect[0].to_i
    end
  end

  
  ############################################################## reset_usb_switch #############################################################
  #Disconnect the HOST USB switch, if we were/are testing a USB device, after the particular test iteration has completed.
  def reset_usb_sw(sw_type=nil)
    puts "\n usb_common_module::reset_usb_sw #{sw_type} "+ __LINE__.to_s
    if @dstmdia == "usbhd" || @srcmdia == "usbhd"
    @equipment["#{sw_type}"].select_input(0)
      sleep @test_params.params_control.wait_after_disconnect[0].to_i
    else
      sleep 2
    end
  end
  

  ############################################################## conn_usb_func_device ###########################################################################
  def conn_usb_func_device
    puts "\n usb_common_module::conn_usb_func_device "+ __LINE__.to_s
    @equipment['usb_swfn'].select_input(@equipment['dut1'].params['otg_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i
  end
  
  
  ############################################################## disconnect_usb_func_device ##############################################################################
  def disconnect_usb_func_device
    puts "\n usb_common_module::disconnect_rndis "+ __LINE__.to_s
    @equipment['usb_swfn'].select_input(0)                                        # 0 means don't select any input port.
    sleep @test_params.params_control.wait_after_disconnect[0].to_i
  end

  
  ############################################################## init_rndis_on_evm #############################################################################
  def init_rndis_on_evm
    puts "\n usb_common_module::init_rndis_on_evm "+ __LINE__.to_s
    @equipment['dut1'].send_cmd("do usbFnSet rndis",@equipment['dut1'].prompt)
    sleep 6
  end	

  
  ############################################################## init_rndis_on_evm #############################################################################
  def init_storage_on_evm
    puts "\n usb_common_module::init_rndis_on_evm "+ __LINE__.to_s
    puts "\n------- Initializing STORAGE connection on EVM ------ "+ __LINE__.to_s
    @equipment['dut1'].send_cmd("do usbFnSet storage",@equipment['dut1'].prompt)
    sleep 6
  end	

  
  ############################################################## determine_storage_media_available #############################################################
  #Because we could be copying between two different storage media types, we need to identify each one individually and the available storage size.
  def determine_storage_media_available
    puts "\n usb_common_module::determine_storage_media_available "+ __LINE__.to_s
    # -------------------- Initialize script variables --------------------
    @ram_present = @nand_present = @sd_card_present = @usb_hd_present = @ram_present2 = 0
    @nand_present2 = @sd_card_present = @sdhc_card_present = @mmc_card_present = @ram_free_storage = 0
    
    # -------------------- Obtain a listing of currently available storage media.. In CE7, media types show up as a sub-directory. --------------------
    @equipment['dut1'].send_cmd("dir \/AD",/\\>/) ; sleep 2 ; @dir_list = @equipment['dut1'].response
    
    # -------------------- By default, the Temp sub-directory should always show as present if there is recognizable RAM present --------------------
    if /(Temp.+)$/im.match(@dir_list)
      @ram_present = 1 ; @dst_dir = "\\Temp" ; calc_free_storage() ; @ram_free_storage = @size_query.to_i
    end
    
    # -------------------- By default, this should always show as present if there is recognizable NAND present --------------------
    if /(Moun.+)$/im.match(@dir_list)
      @nand_present = 1 ; @dst_dir = "\\Mounted_Volume" ; calc_free_storage() ; @nand_free_storage = @size_query.to_i
    end
    
    # -------------------- If there is a storage card inserted, this will show in the directory listing (SD/SDHC/MMC) --------------------
    if /(Stor.+)$/im.match(@dir_list)
      @sd_card_present = 1 ; @dst_dir = "\\Storage_Card" ; calc_free_storage() ; @sd_free_storage = @size_query.to_i
    end
    
    # ----------------- If there is a hard drive connected, either through a USB switch or directly to the EVM, this will show up in the directory listing) -----------------
    if /(Hard.+)$/im.match(@dir_list)
      @usb_hd_present = 1 ; @dst_dir = "\"\\Hard Disk\"" ; calc_free_storage() ; @usbhd_free_storage = @size_query.to_i
    end
  end
  
  
  ############################################################## calc_free_storage ###############################################################################
  # -------------------- Determine the maximum available storage space when a specific directory name is passed to it  --------------------
  def calc_free_storage()
    @equipment['dut1'].send_cmd("dir #{@dst_dir}",/\\>/) ; @size_query = @equipment['dut1'].response 
    @size_query = "%.2f" % (/\s+Dir\(s\)\s([\d]+)\s+/.match(@size_query).captures[0].to_f / 1000000) ; @size_query2 = @size_query
  end
  
  
  ############################################################## read_log_file #################################################################################
  def read_log_file(log_file)
    @svc_lines = ''
    
    File.open("#{log_file}").each {|line|
      @svc_lines += line
    }
    
    sleep 1
  end
  
  
  ############################################################## cp_dsktop_files #####################################################################
  def cp_dsktop_files
    if @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) && @test_params.instance_variable_defined?(:@var_test_libs_root)
      @dst_dsktop_dir = @test_params.params_equip.lcl_dsktp_tmp_dir[0]
      @src_dsktop_dir = File.join(@test_params.var_test_libs_root,'desktop')
    end
    
    if @test_params.params_equip.instance_variable_defined?(:@desktop_test_libs)
      #@src_dsktop_dir = File.join(@test_params.var_test_libs_root,'desktop')
      #puts "------------- The winsock perf filess are present -------- #{@test_params.params_equip.desktop_test_libs} ---------- "+ __LINE__.to_s
    end
    
    @test_params.params_equip.desktop_test_libs.each {|filename|
      puts "Copying Filename #{filename}"
      tmp = File.join(@test_params.var_test_libs_root,'desktop', filename)
      
      FileUtils.cp("#{tmp}", @dst_dsktop_dir)
    }
  end
  
  
  ############################################################## cp_rndis_dsktop_files #########################################################################
  def cp_rndis_dsktop_files
    if @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) && @test_params.instance_variable_defined?(:@var_test_libs_root)
      @dst_dsktop_dir = @test_params.params_equip.lcl_dsktp_tmp_dir[0]
      @src_dsktop_dir = File.join(@test_params.var_test_libs_root,'desktop')
    end
    
    if @test_params.params_equip.instance_variable_defined?(:@desktop_test_libs)
      #@src_dsktop_dir = File.join(@test_params.var_test_libs_root,'desktop')
      #puts "------------- The winsock perf filess are present -------- #{@test_params.params_equip.desktop_test_libs} ---------- "+ __LINE__.to_s
    end
    
    @test_params.params_equip.desktop_test_libs.each {|filename|
      puts "Copying Filename #{filename}"
      tmp = File.join(@test_params.var_test_libs_root,'desktop', filename)
      
      FileUtils.cp("#{tmp}", @dst_dsktop_dir)
    }
  end

  
  ############################################################## start_wsperf_server ###########################################################################
  def start_wsperf_server
    system("cmd /c start /min #{@test_params.params_equip.lcl_dsktp_tmp_dir[0]}\\#{@test_params.params_equip.ws2_svr_file[0]} -debug ")
    sleep 2
  end
  
  
  ############################################################## stop_wsperf_server ############################################################################
  def stop_wsperf_server
    system("taskkill /F /PID #{@ws2_svr_pid}")
  end
  
  
  ############################################################## ck_if_rndis_connected #####################################################################
  def ck_if_rndis_connected
    puts "\n usb_common_module::ck_if_rndis_connected "+ __LINE__.to_s
    @rndis_pid = 0
    tmp_run = ''
    @equipment['server1'].send_cmd("C:\\Temp\\devcon listclass net", />/)
    
    if /VID\_(045e)\&PID\_(0301)/i.match(@equipment['server1'].response)
      puts "\n---------- Rndis is currently running ------ "+ __LINE__.to_s
      @rndis_pid = 99
    else
      puts "\n---------- Rndis is currently running ------ "+ __LINE__.to_s
      @rndis_pid = 0
    end
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
      puts "\n---------- fn storage successfully connected ------ "+ __LINE__.to_s
    else
      @data1['fn_connect_ok'] = 0
      @data1['fn_fail_count'] += 1
      puts "\n---------- fn storage could not be connected successfully ------ "+ __LINE__.to_s
    end
    
    @tot_fn_success_rate = "%.2f" % (@data1['fn_success_count'].to_f / (@data1['fn_success_count'] + @data1['fn_fail_count']).to_f * 100) 
  end
  
  ############################################################## ck_if_fn_storage_enumerated #####################################################################
  def ck_if_fn_storage_enumerated
    puts "\n usb_common_module::ck_if_fn_storage_enumerated "+ __LINE__.to_s
    @rndis_pid = 0
    tmp_run = ''
    @equipment['server1'].send_cmd("C:\\Temp\\devcon listclass volume", />/)
    
    if /(MEDIA\\8&E615446&0&RM)/i.match(@equipment['server1'].response)
      puts "\n---------- The fnStorage device has been enumerated ------ "+ __LINE__.to_s
      @rndis_pid = 99
    else
      puts "\n---------- fnStorage device enumeration ws not successful ------ "+ __LINE__.to_s
      @rndis_pid = 0
    end
  end

  
  ############################################################## get_ws2_svr_pid ###############################################################################
  #get the process ID of the Winsock server if it is running.
  def get_ws2_svr_pid
    @ws2_svr_pid = 0
    puts "\n----------- Checking if winsock server is running. --- "+ __LINE__.to_s
    pid_log = @test_params.params_equip.lcl_dsktp_tmp_dir[0] + "\\pidchk.log"
    system("tasklist /svc > #{pid_log}")
    read_log_file(pid_log)
    
    if /perf\_winsockd2.exe\s+([0-9]*)/im.match(@svc_lines)
      @ws2_svr_pid = /perf\_winsockd2.exe\s+([0-9]*)/im.match(@svc_lines).captures[0]
      puts "\n---------- Winsock server is currently running ------ PID: #{@ws2_svr_pid} -------- "+ __LINE__.to_s
    else
      puts "\n---------- Winsock server is not currently running ------ #{@test_params.params_equip.lcl_dsktp_tmp_dir[0]}\\#{@test_params.params_equip.ws2_svr_file[0]} -debug "+ __LINE__.to_s
    end
  end
  
  
  ############################################################## config_mediatype_vars #########################################################################
  # -------------------- Assign various default values depending on the type of storage devices found --------------------
  def config_mediatype_vars
    puts "\n usb_common_module::config_mediatype_vars "+ __LINE__.to_s
    @data = Array.new
    @media_type01 = @media_type02 = pos_in_array = 0
    puts "\n -------------------- Media1:  #{@srcmdia.upcase} ------- Media2:  #{@dstmdia.upcase} -------------------- "+ __LINE__.to_s
      
    @data << ["ram", @ram_present,"\\Temp", "\\Temp", "ramtest.bin", "ramtest.bin", "RAM Storage", "RAM Storage",
              @ram_free_storage.to_i,	@ram_compare_success.to_i, @ram_compare_fail.to_i]
    @data << ["nand", @nand_present, "\\Mounted_Volume", "\\Mounted_Volume", "nandtest.bin", "nandtest.bin",
              "NAND Storage", "NAND Storage",	@nand_free_storage, @ram_compare_success.to_i, @ram_compare_fail.to_i]
    @data << ["usbhd", @usb_hd_present, "\"\\Hard Disk\"", "\"\\Hard Disk\"", "usbhdtest.bin", "usbhdtest.bin",
              "USB Hard Drive Storage",	"USB Hard Drive Storage", @usbhd_free_storage.to_i, @usbhd_compare_success.to_i,
              @usbhd_compare_fail.to_i]
    @data << ["sdhc", @sdhc_card_present, "\\Storage_Card", "\\Storage_Card", "sdhctest.bin", "sdhctest.bin",
              "SDHC Storage Card", "SDHC Storage Card",	@sd_free_storage.to_i, @sdhc_compare_success.to_i, @sd_compare_fail.to_i]
    @data << ["sd", @sd_card_present, "\\Storage_Card", "\\Storage_Card", "sdtest.bin", "sdtest.bin",
              "SD Storage Card", "SD Storage Card", @sd_free_storage.to_i, @sd_compare_success.to_i, @sd_compare_fail.to_i]
    @data << ["mmc", @sd_card_present, "\\Storage_Card", "\\Storage_Card", "mmctest.bin", "mmctest.bin", "MMC Storage",
              "MMC Storage", @sd_free_storage.to_i, @mmc_compare_success.to_i, @mmc_compare_fail.to_i]
      
    # -------------------- This will determine the type of storage being used for media01 --------------------
    # pos_in_array is used as a counter and will indicate the location of the correct information in the array based on media type
    for pos_in_array in 0..5
      if @data[pos_in_array][0] != @srcmdia then
        next
      end
      break
    end
    
    # ------------- Initially, media type 2 is defined as the same type as media type 1
    @media_type02 = @media_type01 = pos_in_array
    
    # -------------------- This will determine the type of storage being used for media02 if it is different than media01 --------------------
    if @dstmdia != @srcmdia
      for pos_in_array in 0..5
        if @data[pos_in_array][0] != @dstmdia then
          next
        end
        break
      end
      
      @media_type02 = pos_in_array
    end
    
    @data[@media_type01][3] = @data[@media_type02][3] ; @data[@media_type01][5] = @data[@media_type02][5] ; @data[@media_type01][7] = @data[@media_type02][7]
  end
  
  
  ############################################################## determine_usb_hard_drive_presence #############################################################
  def determine_usb_hard_drive_presence
    @equipment['dut1'].send_cmd("dir \/AD \\h*",/\\>/) ; sleep 2
    
    if /(Hard.+)$/im.match(@equipment['dut1'].response)
      puts "\n --------------------  A USB Hard Drive is present-------------------- "+ __LINE__.to_s
      @enum_success_count += 1 ; @usb_hd_present = 1
      @equipment['dut1'].log_info("Iteration #{@iteri}:  #{@usb_intfc.upcase} - USB enumeration check was successful")
    else
      puts "\n --------------------  USB Hard Drive Storage card is not present-------------------- "+ __LINE__.to_s
      @enum_fail_count += 1 ; @usb_hd_present = 0
      @equipment['dut1'].log_info("Iteration #{@iteri}:  #{@usb_intfc.upcase} - USB enumeration check was not successful")
      @err_msg = "An error occured while the USB device was being enumerated."
    end
  end
  
  
  ############################################################## clean_delete_local_temp_files #################################################################
  # Delete log files (if any) 
  def clean_delete_local_temp_files
    puts "\n Entering usb_common_module::clean_delete_local_temp_files "+ __LINE__.to_s
    
    Dir.foreach(@test_params.params_equip.lcl_dsktp_tmp_dir[0]) do |f|
      filepath = "#{@test_params.params_equip.lcl_dsktp_tmp_dir[0]}\\#{f}"
      if f == '.' or f == '..' or File.directory?(filepath) or File.basename(f) =~ /^test_/ or File.extname(f) == '.csv' or File.extname(f) == '.LOG' then next
        puts "\n --------------------  Marker -------------------- "+ __LINE__.to_s
      else
        puts "\n --------------------  #{filepath} -------------------- "+ __LINE__.to_s
        @equipment['server1'].send_cmd("del #{filepath}", />/)
      end
    end
  end

  
  ############################################################## rm_dsktop_files ###############################################################################
  def rm_dsktop_files
    @test_params.params_equip.desktop_test_libs.each {|filename|
    tmp = File.join(@dst_dsktop_dir, filename)
    
    FileUtils.rm(tmp, {:verbose => true})
    }
  end

  
  ############################################################## cp_usb_desqview_binaryfile ##############################################################################
  def cp_dv_binaryfiles
    @test_params.params_equip.desktop_usb_test_files.each {|filename|
      tmp = File.join(@test_params.var_build_test_libs_root,'tools\usbdeview',filename)
      tmp2 = File.join(@test_params.params_equip.lcl_dsktp_tmp_dir[0],filename)
      
      FileUtils.cp("#{tmp}", "#{tmp2}")
    }
  end
  
  
  ############################################################## cp_dd_binaryfile ##############################################################################
  def cp_dd_binaryfile
    @test_params.params_equip.desktop_test_bins.each {|filename|
      tmp = File.join(@test_params.var_test_libs_root,'desktop/tools', filename)
      puts "Copying Filename #{tmp} "+ __LINE__.to_s
      
      FileUtils.cp("#{tmp}", @lcl_dsktop_tmp_dir)
    }
  end
  
  
  ############################################################## run_generate_script ###########################################################################
  def run_generate_script
    puts "\n usb_common_module::run_generate_script "+ __LINE__.to_s
    puts "\n -------------------- Generating the test.bat file -------------------- "+ __LINE__.to_s
    @cmd_line = "ftp -d -s:#{@lcl_dsktop_tmp_dir}\\ftptest.txt #{@equipment['dut1'].telnet_ip} 1>#{@lcl_dsktop_tmp_dir}\\result.log 2>&1"
    puts "\n -------------------- #{@cmd_line} -------------------- "+ __LINE__.to_s
    puts "\n -------------------- #{File.join(@lcl_dsktop_tmp_dir, 'test.bat')} -------------------- "+ __LINE__.to_s
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'test.bat'),'w')
    out_file.puts "\@ECHO off"
    out_file.puts(eval('"'+"echo "+"\"Testing #{@equipment['dut1'].board_id} with IP:  #{@equipment['dut1'].telnet_ip}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.puts(eval('"'+"echo "+"\"Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : 'No kernel specified'}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.puts(eval('"'+"echo "+"\"Command Line: #{@cmd_line}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    puts "\n -------------------- #{@cmd_line} -------------------- "+ __LINE__.to_s
    out_file.puts(eval('"'+@cmd_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.close
  end
  
  
  ############################################################## generate_dos_ftp_put_txt_file #################################################################
  def generate_dos_ftp_put_txt_file
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'dosftpputcmds.txt'),'w')
    out_file.puts("anonymous")
    out_file.puts("dut@ti.com")
    out_file.puts("cd #{@data[@media_type01][2]}")
    out_file.puts("bin")
    
    if @dstmdia == @srcmdia
      out_file.puts("put #{@lcl_dsktop_tmp_dir}\\#{@test_params.params_equip.lcl_testfile_name[0]} #{@data[@media_type01][2]}\\#{@data[@media_type01][4]}")
    else
      out_file.puts("put #{@lcl_dsktop_tmp_dir}\\#{@test_params.params_equip.lcl_testfile_name[0]} #{@data[@media_type01][2]}\\#{@test_params.params_equip.lcl_testfile_name[0]}")
    end
    
    out_file.puts("dir")
    out_file.puts("bye")
    sleep 2
    out_file.close
  end
  
  
  ############################################################## generate_dos_ftp_get_txt_file #################################################################
  def generate_dos_ftp_get_txt_file
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'dosftpgetcmds.txt'),'w')
    out_file.puts("anonymous")
    out_file.puts("dut@ti.com")
    out_file.puts("cd #{@data[@media_type01][2]}")                    #out_file.puts("cd #{@dst_dir}")
    out_file.puts("bin")
    
    if @dstmdia == @srcmdia
      out_file.puts("get #{@data[@media_type01][2]}\\#{@data[@media_type01][4]} #{@lcl_dsktop_tmp_dir}\\#{@data[@media_type01][4]}")
      out_file.puts("del #{@data[@media_type01][2]}\\#{@data[@media_type01][4]}")
    else
      out_file.puts("get #{@data[@media_type01][2]}\\#{@data[@media_type01][4]} #{@lcl_dsktop_tmp_dir}\\#{@data[@media_type01][4]}")
      out_file.puts("del #{@data[@media_type01][2]}\\#{@data[@media_type01][4]}")
      out_file.puts("get #{@data[@media_type01][3]}\\#{@data[@media_type01][5]} #{@lcl_dsktop_tmp_dir}\\#{@data[@media_type01][5]}")
      out_file.puts("del #{@data[@media_type01][3]}\\#{@data[@media_type01][5]}")
    end
    
      out_file.puts("bye")
    sleep 2
    out_file.close
  end
  
  
  ############################################################## init_variables ################################################################################
  # ------------------------ Initialize script specific variables --------------------
  def init_variables
    @success_rate = 0
    @session_success_count = @session_success_count2 = @ram_compare_success = @ram_compare_success2 = 0
    @nand_compare_success = @nand_compare_success2 = @usbhd_compare_success = @usbhd_compare_success2 = 0
    @sdhc_compare_success = @sdhc_compare_success2 = @sd_compare_success = @sd_compare_success2 = 0
    @mmc_compare_success = @mmc_compare_success2 = @ram_compare_fail = @ram_compare_fail2 = 0
    @nand_compare_fail = @nand_compare_fail2 = @usbhd_compare_fail = @usbhd_compare_fail2 = 0
    @sdhc_compare_fail = @sdhc_compare_fail2 = @sdhc_compare_fail = @sdhc_compare_fail2 = 0
    @mmc_compare_fail = @mmc_compare_fail2 = @iter = @session_fail_count = @ram_free_storage = 0
    @lcl_file_name = @test_params.params_equip.instance_variable_defined?(:@lcl_testfile_name) ? @test_params.params_equip.lcl_testfile_name[0] : 'usbtest.tst'
    @src_dir = @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) ? @test_params.params_equip.lcl_dsktp_tmp_dir[0] : 'C:\Temp'
    @wince_dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Windows'
    @iteri = @enum_success_count = @enum_fail_count = 0
  end
  
  
  ############################################################## check_file_integrity ##########################################################################
  # ------------------------ Compare original file with the file(s) received from the EVM (ftp transfer) --------------------
  def check_file_integrity
    puts "\n usb_common_module::check_file_integrity "+ __LINE__.to_s
    path_to_file_1 = "#{@lcl_dsktop_tmp_dir}\\#{@test_params.params_equip.lcl_testfile_name[0]}" 
    
    if @dstmdia == @srcmdia
      path_to_file_2 = "#{@lcl_dsktop_tmp_dir}\\#{@data[@media_type01][4]}"
    else
      path_to_file_2 = "#{@lcl_dsktop_tmp_dir}\\#{@data[@media_type01][4]}" ; path_to_file_3 = "#{@lcl_dsktop_tmp_dir}\\#{@data[@media_type02][5]}"
    end
    
    @equipment['server1'].send_cmd("dir #{@lcl_dsktop_tmp_dir}}", />/)
    
    #****************************# Compare hash value when a single storage type is being used #****************************#
    if Digest::SHA2.file(path_to_file_1).hexdigest == Digest::SHA2.file(path_to_file_2).hexdigest
      puts "\n ------------ Media file 1 was the same ------------ "+ __LINE__.to_s
      @equipment['dut1'].log_info("Iteration #{@iteri}:  File integrity check with #{@data[@media_type01][4]} was successful")
      @session_success_count = @data[@media_type01][9] += 1
    else
      puts "\n ------------ Media file 1 was not the same ------------ "+ __LINE__.to_s
      @equipment['dut1'].log_info("Iteration #{@iteri}:  File integrity check with #{@data[@media_type01][4]} was not successful")
      @session_fail_count = @data[@media_type01][10] += 1
    end
    
    #******************************# Compare hash value of second media when 2 different types are being tested #******************************#
    if @dstmdia != @srcmdia
      if Digest::SHA2.file(path_to_file_1).hexdigest == Digest::SHA2.file(path_to_file_3).hexdigest
        puts "\n ------------ Media file 2 was the same ------------ "+ __LINE__.to_s
        @equipment['dut1'].log_info("Iteration #{@iteri}:  File integrity check with #{@data[@media_type01][5]} was successful")
        @session_success_count = @data[@media_type02][9] += 1
      else
        puts "\n ------------ Media file 2 was not the same ------------ "+ __LINE__.to_s
        @equipment['dut1'].log_info("Iteration #{@iteri}:  File integrity check with #{@data[@media_type01][5]} was not successful")
        @session_fail_count = @data[@media_type02][10] += 1
      end
    end
    
    puts "\n -------------------- #{@session_success_count} ------ #{@session_fail_count} ------------------- "+ __LINE__.to_s
  end
  
  
  ############################################################## create_ftp_binary_file ########################################################################
  def create_ftp_binary_file
    puts "\n usb_common_module::create_ftp_binary_file "+ __LINE__.to_s
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'createfile.bat'),'w') ; out_file.puts("cd #{@lcl_dsktop_tmp_dir}")
    out_file.puts("dd if=/dev/random of=#{@lcl_dsktop_tmp_dir}" + "\\" + "#{@test_params.params_equip.lcl_testfile_name[0]} bs=1M count=#{@test_params.params_equip.ftp_file_size[0]}")
    out_file.close
    @tst_file = "call #{File.join(@lcl_dsktop_tmp_dir, 'createfile.bat')}"                        #dd if=/dev/random of=C:\Temp_dd\test1.bin bs=1M count=20
    system("call #{@tst_file}")
    sleep 1
  end
  

  ############################################################## xfr_ftp_files #################################################################################
  # Copy a file between a PC/EVM. The params keys are: filename (mandatory). src_ip, src_dir, dst_dir, login and password (Optional)
  def xfr_ftp_files()
    puts "\n usb_common_module::xfr_ftp_files "+ __LINE__.to_s
    xyz = tmp3 = tmp4 = tmp5 = tmp6 = tmp7 = 0
    puts "\n -------------------- Transferring test file to EVM via FTP -------------------- "+ __LINE__.to_s 
    @ftp_put_start_seconds = Time.now.strftime("%s").to_i
    @equipment['server1'].send_cmd("#{eval('"'+"ftp -s:#{@lcl_dsktop_tmp_dir}\\dosftpputcmds.txt #{@equipment['dut1'].telnet_ip}".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')}", />/)
    @ftp_put_end_seconds = Time.now.strftime("%s").to_i
      
    if @data[@media_type01][5] == @data[@media_type01][4]
      puts "\n -------------------- Marker -------------------- "+ __LINE__.to_s 
      @ftp_get_start_seconds = Time.now.strftime("%s").to_i
      @equipment['server1'].send_cmd("#{eval('"'+"ftp -s:#{@lcl_dsktop_tmp_dir}\\dosftpgetcmds.txt #{@equipment['dut1'].telnet_ip}".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')}", />/)
      @ftp_get_end_seconds = Time.now.strftime("%s").to_i
      
      @copy_speed << ["#{("0".to_i)}",
                    "#{("0".to_i)}",
                    "#{(@ftp_put_end_seconds.to_i - @ftp_put_start_seconds.to_i)}",
                    "#{@ftp_get_end_seconds.to_i - @ftp_get_start_seconds.to_i}",
                    "#{tmp5.to_i.to_i}", "#{tmp7.to_i}", "#{tmp7.to_i}"]
      
      puts "\n -------------------- #{@copy_speed.length} ------ #{@copy_speed} ------------- "+ __LINE__.to_s
      
    else
      puts "\n -------------------- Copying test file between media storage types -------------------- "+ __LINE__.to_s 
      @copy_media1_media2_start_seconds = Time.now.strftime("%s").to_i
      @equipment['dut1'].send_cmd("copy #{@data[@media_type01][2]}\\#{@test_params.params_equip.lcl_testfile_name[0]} #{@data[@media_type01][3]}\\#{@data[@media_type01][5]}",/\>/,90)
      @copy_media1_media2_end_seconds = Time.now.strftime("%s").to_i
      @equipment['dut1'].send_cmd("del #{@data[@media_type01][2]}\\#{@test_params.params_equip.lcl_testfile_name[0]}",/\>/,90)
      @copy_media2_media1_start_seconds = Time.now.strftime("%s").to_i
      @equipment['dut1'].send_cmd("copy #{@data[@media_type01][3]}\\#{@data[@media_type01][5]} #{@data[@media_type01][2]}\\#{@data[@media_type01][4]}",/\>/,90)
      @copy_media2_media1_end_seconds = Time.now.strftime("%s").to_i
      
      puts "\n -------------------- Retrieving files from EVM via FTP -------------------- "+ __LINE__.to_s 
      @ftp_get_start_seconds = Time.now.strftime("%s").to_i
      @equipment['server1'].send_cmd("#{eval('"'+"ftp -s:#{@lcl_dsktop_tmp_dir}\\dosftpgetcmds.txt #{@equipment['dut1'].telnet_ip}".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')}", />/)
      @ftp_get_end_seconds = Time.now.strftime("%s").to_i
      
      @copy_speed << ["#{(@copy_media1_media2_end_seconds.to_i - @copy_media1_media2_start_seconds.to_i)}",
                    "#{(@copy_media2_media1_end_seconds.to_i - @copy_media2_media1_start_seconds.to_i)}",
                    "#{(@ftp_put_end_seconds.to_i - @ftp_put_start_seconds.to_i)}",
                    "#{@ftp_get_end_seconds.to_i - @ftp_get_start_seconds.to_i}",
                    "#{tmp5.to_i.to_i}", "#{tmp7.to_i}", "#{tmp7.to_i}"]
      
      # ------------------------ Calculate the average value of the media copy and ftp put/get transfer time --------------------
      until xyz >= (@copy_speed.length)  do
        tmp3 += @copy_speed[xyz][0].to_i
        tmp4 += @copy_speed[xyz][1].to_i
        tmp5 += @copy_speed[xyz][2].to_i
        mp6 += @copy_speed[xyz][3].to_i
        xyz +=1
      end
      
      @avg_med1_copy_spd = "%.2f" % (tmp3.to_f / @copy_speed.length.to_f)
      @avg_med2_copy_spd = "%.2f" % (tmp4.to_f / @copy_speed.length.to_f)
      @avg_ftp_put_spd = "%.2f" % (tmp5.to_f / @copy_speed.length.to_f)
      @avg_ftp_get_spd = "%.2f" % (tmp6.to_f / @copy_speed.length.to_f)
      
      puts "\n---------- #{@iteri} ----- #{@avg_med1_copy_spd} ----- #{@avg_med2_copy_spd} ----- #{@avg_ftp_put_spd} ----- #{@avg_ftp_get_spd} ------ "+ __LINE__.to_s
      puts "\n---------- #{@avg_ftp_put_spd} ------ #{@avg_ftp_get_spd} ------ #{@copy_speed} ------ "+ __LINE__.to_s
    end
  end

  
  ############################################################## create_evm_info_table #########################################################################
  def create_evm_info_table
    puts "\n usb_common_module::create_evm_info_table "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["General Test Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white", :size => "4"}]])
    
    if @ftp_file_sze.to_i == 0
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
      
    @test_time = "#{@data_time['days']} Days  #{@data_time['hours']} Hours  #{@data_time['minutes']} Mins. #{@data_time['seconds']} Secs."
      
    case
    when @units == "s"
      @data_time['@test_dur'] = "#{@specified_test_duration} Seconds"
    when @units == "m"
      @data_time['@test_dur'] = "#{@specified_test_duration} Minutes"
    when @units == "h"
      @data_time['@test_dur'] = "#{@specified_test_duration} Hours"
    when @units == "d"
      @data_time['@test_dur'] = "#{@specified_test_duration} Days"
    end
      
    @results_html_file.add_rows_to_table(res_table,[[["#{"#{@equipment['dut1'].board_id}"}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_params.params_control.usb_test_intfc[0].upcase}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@data_time['@test_dur']}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_time}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@file_size}",{:bgcolor => "white"},{:size => "2.5"}],
                ["Future",{:bgcolor => "white"},{:size => "2"}]]])
  end
  
  
  ############################################################## create_usb_enum_html_page #####################################################################
  def create_usb_enum_html_page
    puts "\n usb_common_module::create_usb_enum_html_page "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["#{@test_name} #{@script_name} Statistics/Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    @total_test_sessions = @enum_success_count.to_i + @enum_fail_count.to_i
    @tot_enum_success_rate = @enum_success_count.to_i / (@enum_success_count.to_i + @enum_fail_count.to_i )*100
    
    if @enum_fail_count.to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@total_test_sessions}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@enum_success_count}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@enum_fail_count}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_enum_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])
  end

  
  ############################################################## create_usb_rndis_enum_html_page #####################################################################
  def create_usb_rndis_enum_html_page
    puts "\n usb_common_module::create_usb_enum_html_page "+ __LINE__.to_s
    @tot_ping_success_rate = @ping_success_count1.to_i / (@ping_success_count1.to_i + @ping_fail_count1.to_i )*100
    @total_rndis_test_sessions = @rndis_success_count.to_i + @rndis_fail_count.to_i 
    @tot_rndis_success_rate = @rndis_success_count.to_i / (@rndis_success_count.to_i + @rndis_fail_count.to_i )*100
    
    res_table = @results_html_file.add_table([["#{@test_name} #{@script_name} RNDIS Statistics/Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total RNDIS Connect-Disconnect Pairs",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful RNDIS Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed RNDIS Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["RNDIS Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    if @rndis_fail_count.to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@total_rndis_test_sessions}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@rndis_success_count}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@rndis_fail_count}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_rndis_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])
                
    res_table = @results_html_file.add_table([["#{@test_name} #{@script_name} PING Statistics/Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Total Connect-Disconnect Pairs",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Pings Per Iteration",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Total Successful Pings",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Total Failed Pings",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Ping Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    if @ping_fail_count1.to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
      
    @results_html_file.add_rows_to_table(res_table,[[["#{@total_rndis_test_sessions}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@pings_per_iteration}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@ping_success_count1}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@ping_fail_count1}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_ping_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])
      
    res_table = @results_html_file.add_table([["NOTES",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["01. Each time RNDIS connects successfully, #{@pings_per_iteration} pings are sent to the EVM to verify network connectivity has been established.",{:bgcolor => "white", :align => "left", :colspan => "1"}, {:color => "blue", :size => "2"}]])
  end

  
  ############################################################## create_usb_storage_media_integrity_html #######################################################
  # ---------------------------------------- Create EVM information portion of the test results data page ----------------------------------------
  def create_usb_storage_media_integrity_html
    puts "\n usb_common_module::create_usb_storage_media_integrity_html "+ __LINE__.to_s
    tmp01 = tmp02 = tmp03 = ""
    
    res_table = @results_html_file.add_table([["Test Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["Storage Media Type",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Total Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Connects",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Media Source",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Media Dest",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Average Copy Time",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
      
    puts "\n -------------------- #{@test_params.params_control.mediatype_1[0]} ------- #{@test_params.params_control.mediatype_2[0]} ------------- "+ __LINE__.to_s
    puts "\n ------ RAM Storage: #{@ram_present} ----  SD/SDHC/MMC Storage: #{@sd_card_present} ---- NAND Storage: #{@nand_present} ---- USB Hard Drive: #{@usb_hd_present} ------ "+ __LINE__.to_s
    puts "\n -------------------- #{@data[@media_type01][9].to_i} ------- #{@data[@media_type01][10].to_i} ------- #{@data[@media_type01][10].to_i} ------------- "+ __LINE__.to_s
    puts "\n -------------------- #{@data[@media_type01]} ------------- "+ __LINE__.to_s

    # -------------------- Compute the total success rate based on the completed iterations --------------------
    if @dstmdia == @srcmdia
      @total_test_sessions = @data[@media_type01][9].to_i + @data[@media_type01][10].to_i
      @success_rate = (@data[@media_type01][9].to_i / @data[@media_type01][9].to_i + @data[@media_type01][10].to_i)*100.0
    else
      @total_test_sessions = @data[@media_type01][9].to_i + @data[@media_type01][10].to_i
      @success_rate = (@data[@media_type01][9].to_i / @data[@media_type01][9].to_i + @data[@media_type01][10].to_i)*100.0
    end
    
    # -------------------- If there is only 1 media, put N/A under the Media Source, Media Destination, and Copy Time columns --------------------
    if @dstmdia == @srcmdia
      tmp01 = tmp02 = tmp03 = "N/A"
    else
      tmp01 = "#{@data[@media_type01][6]}"
      tmp02 = "#{@data[@media_type01][7]}"
      tmp03 = "#{@avg_med1_copy_spd} seconds"
    end
    
    if @rndis_fail_count.to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data[@media_type01][6]}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type01][9].to_i + @data[@media_type01][10].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type01][9].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type01][10].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@success_rate}",{:bgcolor => status_color},{:size => "2"}],
            ["#{tmp01}",{:bgcolor => "white"},{:size => "2"}],
            ["#{tmp02}",{:bgcolor => "white"},{:size => "2"}],
            ["#{tmp03}",{:bgcolor => "white"},{:size => "2"}]]])
    
    # ----------- If there are 2 media types, the Media Source, Media Destination, and Copy Time columns for the second media type will be displayed -----------
    if @dstmdia != @srcmdia
      @total_test_sessions2 = @data[@media_type02][9].to_i + @data[@media_type02][10].to_i
      @success_rate = (@data[@media_type02][9].to_i / @total_test_sessions2.to_i)*100.0
      
    if @rndis_fail_count.to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end
    
    @results_html_file.add_rows_to_table(res_table,[[["#{@data[@media_type01][7]}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type02][9].to_i + @data[@media_type02][10].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type02][9].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type02][10].to_i}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@success_rate}",{:bgcolor => status_color},{:size => "2"}],
            ["#{@data[@media_type01][7]}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@data[@media_type01][6]}",{:bgcolor => "white"},{:size => "2"}],
            ["#{@avg_med2_copy_spd} seconds",{:bgcolor => "white"},{:size => "2"}]]])
    end
    
    res_table = @results_html_file.add_table([["NOTES",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["01. When only 1 media type is being tested, Media Source, Media Dest, and Average Copy Time are not applicable. When 2 media types are being tested, these fields will display the average copy time to/from each media type.",{:bgcolor => "white", :align => "left", :colspan => "1"}, {:color => "blue", :size => "2"}]])
  end

  # ---------------------------- end of UsbCommonModule ----------------------------
end