require File.dirname(__FILE__)+'/../../usb_common_mod'

include UsbCommonModule

  ############################################################## run_collect_performance_data ##################################################################
  def run_collect_performance_data
    puts "\n cepc_usb_host_test::run_collect_performance_data "+ __LINE__.to_s
    #@cepc_perfdata
  end

  
  ############################################################## setup_connect_equipment #######################################################################
  def setup_connect_equipment
    puts "\n cepc_usb_host_test::setup_connect_equipment "+ __LINE__.to_s
    @force_telnet_connect = true              #this variable, set as true, is required to run this script with the CEPC PC
    puts "\n -------------------- #{@force_telnet_connect} -------------------- "+ __LINE__.to_s
    #puts "\n -------------------- Initializing the USB Switch -------------------- "+ __LINE__.to_s
    init_usb_sw("usb_cepcsw")
  end

  
  ############################################################## run #####################################################################
  # Execute shell script in DUT(s) and save results.
  def run
    puts "\n cepc_usb_host_test::run "+ __LINE__.to_s
    run_generate_script
    run_transfer_script
    run_call_script
    connect_usb_sw("usb_cepcsw")
    run_get_script_output
    calc_script_end_time
    disconnect_usb_cepc_device
    sleep 3
    calc_test_end_time
    @cepc['iterations'] += 1
    run_collect_test_data
    calc_total_script_run_time
    run_save_results
  end
  
  
  ############################################################## run_transfer_script #######################################################################
  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script2()
    puts "\n cepc_usb_host_test::run_transfer_script"
    put_file({'filename'=>'test.bat'})
    transfer_files(:@test_libs, :@var_test_libs_root)
    transfer_files(:@build_test_libs, :@var_build_test_libs_root)

    # transfer tux etc files to target
    if @test_params.instance_variable_defined?(:@var_test_libs_root)
      #src_dir = @test_params.var_test_libs_root
      src_dir = "T:\\EVM_Programming_Info"
      get_cetk_basic_filenames(src_dir).split(':').each {|lib_file|
        put_file({'filename' => lib_file, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end
  
  
  ############################################################## run_get_script_output #######################################################################
  def run_get_script_output
    puts "\n cepc_usb_host_test::run_get_script_output "+ __LINE__.to_s
    super("</TESTGROUP>")
  end

  
  ############################################################## run_call_script #######################################################################
  def run_call_script
    puts "\n cepc_usb_host_test::run_call_script "+ __LINE__.to_s
    
    #@equipment['server1'].send_cmd("dir C:\\", />/)
    #puts "\n ------------------------ #{@equipment['server1'].response} ------------------------ "+ __LINE__.to_s
    
    # ------------------------ Initialize various script variables --------------------
    init_cepc_vars
    
    # ------------------------ Synchronize the time on EVM with current time on PC --------------------
    set_dut_datetime
    
    # ------------------------ Calculate the desired script run time and convert it to seconds --------------------
    calculate_desired_script_run_time
    
    # ------------------------ Calculate the test start time and convert it to seconds for later use --------------------
    calc_test_start_time
    
    super
    
    puts "\n ------------------ Marker after calling SUPER ------------------ "+ __LINE__.to_s
  end


  ############################################################## init_vars ###########################################################################
  # ------------------------ Initialize varios script variables --------------------
  def init_cepc_vars
    @all_lines = ''
    #@cepc_perfdata = Array.new
    @cepc = Hash.new
    @cepc =  {"test_successful" => 0, "test_failed" => 0, "run_duration" => 0, "start_time_seconds" => 0, "curr_time_seconds" => 0, 
              "test_start_time_seconds" => 0, "test_end_time_seconds" => 0, "script_start_time_seconds" => 0, "script_end_time_seconds" => 0, 
              "curr_secs" => 0, "enum_time" => 0, "tot_enum_time" => 0, "enum_success_rate" => 0, "iteri" => 0, "low_enum_time" => 0, 
              "avg_enum_time" => 0, "high_enum_time" => 0, "fn_integrity_success_count" => 0, "fn_integrity_fail_count" => 0, 
              "enum_count" => 0, "seconds" => 0, "minutes" => 0, "hours" => 0, "days" => 0, "low_write_bw" => 0, 
              "usb_test_intfc" => @test_params.params_control.usb_test_intfc[0].upcase, "high_write_bw" => 0,"low_read_bw" => 0, 
              "fn_connect_ok" => 0, "enum_ok" => 0, "enum_fail" => 0, "xfer_file_size" => 0, "iterations" => 0, "test_result" => 0,
              "total_passed" => 0, "total_failed" => 0, "total_skipped" => 0, "total_aborted" => 0, "total_test_sessions" => 0 
              }
  end

  
  ############################################################## run_generate_script ###########################################################################
  def run_generate_script
    puts "\n cepc_usb_host_test::run_generate_script"
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

 
  ############################################################## conn_usb_cepc_device ###########################################################################
  def conn_usb_cepc_device
    puts "\n cepc_usb_host_test::conn_usb_cepc_device "+ __LINE__.to_s
    @equipment['usb_cepcsw'].select_input(@equipment['dut1'].params['cepc_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i
  end
  
  
  ############################################################## disconnect_usb_cepc_device ##############################################################################
  def disconnect_usb_cepc_device
    puts "\n cepc_usb_host_test::disconnect_usb_cepc_device "+ __LINE__.to_s
    @equipment['usb_cepcsw'].select_input(0)                # 0 means don't select any input port.
    sleep @test_params.params_control.wait_after_disconnect[0].to_i
  end
  
  
  ############################################################## connect_usb_sw #############################################################
  #Connect the USB switch if we are testing a USB device.
  def connect_usb_sw(sw_type=nil)
    puts "\n cepc_usb_host_test::connect_usb_sw #{sw_type} "+ __LINE__.to_s
    
    if @test_params.params_control.usb_test_intfc[0] == "ehci"
      @equipment["#{sw_type}"].select_input(@equipment['dut1'].params['ehci_port'])
    else
      @equipment["#{sw_type}"].select_input(@equipment['dut1'].params['otg_port'])
    end
    
    sleep @test_params.params_control.wait_after_connect[0].to_i
  end
  
  
  ############################################################## run_collect_test_data #####################################################################
  def run_collect_test_data
    puts "\n cepc_usb_host_test::run_collect_test_data "+ __LINE__.to_s
    @lg_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
    @array_lines = @l_pos = i = 0
    puts "\n----------- Loading test results file --- "+ __LINE__.to_s
  
    File.open("#{@lg_file_name}").each {|line|
      @all_lines += line
      @array_lines += 1
    }
    
    @test_id = /Test\s+ID\:\s+(\d+)+/i.match(@all_lines).captures[0]
    @test_name = /Test\s+Name\:\s+(.+)/i.match(@all_lines).captures[0]
    @os_version = /OS\s+Version\:\s+(\d+\.\d+)/i.match(@all_lines).captures[0]
    @os_type = /Platform\sid\:.+\"(.+)"/i.match(@all_lines).captures[0]
    puts "\n ------------------- #{@test_id} ------ #{@test_name} ------ #{@os_type} ------ #{@os_version} ------------------- "+ __LINE__.to_s
    
    @cepc['total_passed'] = /passed\:\s+(\d+)+/im.match(@all_lines).captures[0]
    @cepc['total_failed'] = /failed\:\s+(\d+)+/im.match(@all_lines).captures[0]
    @cepc['total_skipped'] = /skipped\:\s+(\d+)+/im.match(@all_lines).captures[0]
    @cepc['total_aborted'] = /aborted\:\s+(\d+)+/im.match(@all_lines).captures[0]
    
    if /\*\*\s+passed:\s+1/im.match(@all_lines)
      @cepc['test_successful'] += 1 ; @cepc['test_result'] = 1
    elsif /\*\*\s+failed:\s+1/im.match(@all_lines)
      @cepc['test_failed'] += 1 ; @cepc['test_result'] = 0
    end
    
    #puts "\n Exiting cepc_usb_host_test::run_collect_test_data - #{@array_lines} "+ __LINE__.to_s
  end
  
  
 ############################################################## calc_test_start_time ##################################################################
  def calc_test_start_time
    puts "\n cepc_usb_host_test::calc_test_start_time "+ __LINE__.to_s
    @cepc['test_start_time_seconds'] = Time.now.strftime("%s")
  end

  
  ############################################################## calc_test_end_time ##################################################################
  def calc_test_end_time
    puts "\n cepc_usb_host_test::calc_test_end_time "+ __LINE__.to_s
    @cepc['test_end_time_seconds'] = Time.now.strftime("%s")
  end
  
  
 ############################################################## calc_script_start_time ##################################################################
  def calc_script_start_time
    puts "\n cepc_usb_host_test::calc_script_start_time "+ __LINE__.to_s
    @cepc['script_start_time_seconds'] = Time.now.strftime("%s")
  end

  
  ############################################################## calc_script_end_time ##################################################################
  def calc_script_end_time
    puts "\n usb_common_module::calc_script_end_time "+ __LINE__.to_s
    @cepc['script_end_time_seconds'] = Time.now.strftime("%s")
  end
  
  
  ############################################################## calc_current_script_run_time ##################################################################
  def calc_current_script_run_time
    puts "\n cepc_usb_host_test::calc_current_script_run_time "+ __LINE__.to_s
    @cepc['curr_time_seconds'] = Time.now.strftime("%s")
    @cepc['curr_secs'] = (@cepc['script_end_time_seconds'].to_i - @cepc['script_start_time_seconds'].to_i)
    parse_time
	end

  
  ############################################################## calc_total_script_run_time ##################################################################
  def calc_total_script_run_time
    puts "\n cepc_usb_host_test::calc_current_script_run_time "+ __LINE__.to_s
    @cepc['curr_secs'] = (@cepc['test_end_time_seconds'].to_i - @cepc['test_start_time_seconds'].to_i)
    parse_time
  end


  ############################################################## parse_time #####################################################################
  def parse_time
    @cepc['seconds'] = @cepc['curr_secs'] % 60
    @cepc['minutes'] = ((@cepc['curr_secs'] / 60 ) % 60)
    @cepc['hours'] = (@cepc['curr_secs'] / (60 * 60) % 60)
    @cepc['days'] = (@cepc['curr_secs'] / (60 * 60 * 24))
    @test_time = "#{@cepc['days']} Days  #{@cepc['hours']} Hours  #{@cepc['minutes']} Mins. #{@cepc['seconds']} Secs."
    puts "\n ------------ Seconds: #{@cepc['curr_secs']} ----- Days: #{@cepc['days']} ----- Hours: #{@cepc['hours']} ----- Mins: #{@cepc['minutes']} ----- Secs: #{@cepc['seconds']} ------------ "+ __LINE__.to_s 
  end


  ############################################################## calculate_desired_script_run_time #####################################################################
  def calculate_desired_script_run_time
    puts "\n cepc_usb_host_test::calculate_desired_script_run_time "+ __LINE__.to_s
    @cepc['run_duration'] = 0
    
    if @test_params.params_control.instance_variable_defined?(:@test_duration)
    
      puts "\n ------------------------ #{@test_params.params_control.test_duration[0]} ------------------------ "+ __LINE__.to_s
      
      if /na/i.match(@test_params.params_control.test_duration[0])
      #if /\_duration\=(na)/i.match(@test_params.params_control.test_duration[0]).captures
        @units = "na"
      else
        @specified_test_duration,@units = /(\d+)(\w+)/i.match(@test_params.params_control.test_duration[0]).captures
      end
    else
      @specified_test_duration = '1'
      @units = 'm'
    end
    
    case
    when @units == "s"
      @cepc['run_duration'] = @specified_test_duration.to_i * 0
      @test_dur = "#{@specified_test_duration} Seconds"
    when @units == "m"
      @cepc['run_duration'] = @specified_test_duration.to_i * 60
      @test_dur = "#{@specified_test_duration} Minutes"
    when @units == "h"
      @cepc['run_duration'] = @specified_test_duration.to_i * 60 * 60
      @test_dur = "#{@specified_test_duration} Hours"
      when @units == "d"
      @cepc['run_duration'] = @specified_test_duration.to_i * 60 * 60 * 24
      @test_dur = "#{@specified_test_duration} Days"
    when @units == "na"
      @test_dur = "N/A"
    end
    
    #puts "\n ------------------------ Desired run time in seconds: #{@cepc['run_duration']} ------ #{@test_dur} ------------------------ "+ __LINE__.to_s
  end
  
  
	############################################################## check_serial_port #####################################################################
   # Return true if there is no new data in serial port
  def check_serial_port
    return true if !@equipment['dut1'].target.serial   # Return right away if there is no serial port connection
    temp = (@serial_port_data.to_s).dup
    #@serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup.tr "\0"," "          # modified to filter out the null character - Ken
    @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup.delete "\0"
    @serial_port_data == temp
  end


  ############################################################## create_evm_info_table #########################################################################
  def create_evm_info_table
    puts "\n cepc_usb_host_test::create_evm_info_table "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["General Test Information",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white", :size => "4"}]])
    
    if @cepc['xfer_file_size'] == 0
      @file_size = "N/A"
    else
      @file_size = @test_params.params_equip.ftp_file_size[0] + "MB   (#{@cepc['xfer_file_size']} Bytes)"
    end
    
    res_table = @results_html_file.add_table([["Device Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["USB Interface Tested",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Specified Test Duration",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Actual Test Duration",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["File Size Used For Test (MB)",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Future",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])
      
    @results_html_file.add_rows_to_table(res_table,[[["#{"#{@equipment['dut1'].board_id}"}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@cepc['usb_test_intfc'].upcase}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_dur}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_time}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@file_size}",{:bgcolor => "white"},{:size => "2.5"}],
                ["Future",{:bgcolor => "white"},{:size => "2"}]]])
  
    res_table = @results_html_file.add_table([["Test Case Info",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white", :size => "4"}]])
    res_table = @results_html_file.add_table([["CEPC Test ID",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["Test Suite Name",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["OS Type",{:bgcolor => "white"},{:color => "blue", :size => "3"}],
                ["OS Version",{:bgcolor => "white"},{:color => "blue", :size => "3"}]])

    @results_html_file.add_rows_to_table(res_table,[[["#{"#{@test_id}"}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@test_name}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@os_type}",{:bgcolor => "white"},{:size => "2.5"}],
                ["#{@os_version}",{:bgcolor => "white"},{:size => "2"}]]])
  end
  
  
  ############################################################## run_determine_test_outcome ####################################################################
  def run_determine_test_outcome
    puts "\n cepc_usb_host_test::run_determine_test_outcome "+ __LINE__.to_s
    #@cepc_perfdata << {'name'=> "Iterations_#{@cepc['iterations']}", 'value'=> "1254.0".to_f, 'units' => "test"}
    
    if @cepc['test_failed'] == 0
      return [FrameworkConstants::Result[:pass], "This test pass.", @cepc_perfdata]
    else
      return [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
    end
  end

  
  ############################################################## run_save_results ##############################################################################
 def run_save_results
    puts "\n cepc_usb_host_test::run_save_results "+ __LINE__.to_s
    create_evm_info_table
    create_cepc_host_statstics
    
    puts "\n --------- Passed: #{@cepc['total_passed'].to_i} ---- Failed: #{@cepc['total_failed'].to_i} ---- Skipped: #{@cepc['total_skipped'].to_i} ---- Aborted: #{@cepc['total_aborted'].to_i} --------- "+ __LINE__.to_s 

    if @cepc['total_passed'].to_i == 1
      @results_html_file.add_paragraph("")
      res_table = @results_html_file.add_table([["Test Log File Contents",{:bgcolor => "#008080", :align => "center", :colspan => "3"}, {:color => "white" ,:size => "4"}]])
      @results_html_file.add_paragraph(@all_lines,nil,nil,nil)
    end
    
    result,comment,@cepc_perfdata = run_determine_test_outcome
    
    #puts "\n #{@cepc_perfdata } "+ __LINE__.to_s
    
   if @cepc_perfdata
      set_result(result,comment,@cepc_perfdata)
      puts "\n ------------------ Marker - With perf data ------------------ "+ __LINE__.to_s
    else
      set_result(result,comment)
      puts "\n ------------------ Marker - Without perf data ------------------ "+ __LINE__.to_s
    end
  end


  ############################################################## create_cepc_host_statstics #####################################################################
  def create_cepc_host_statstics
    puts "\n cepc_usb_host_test::create_cepc_host_statstics "+ __LINE__.to_s
    res_table = @results_html_file.add_table([["CEPC Host Test Statistics - Results",{:bgcolor => "#008080", :align => "center", :colspan => "2"}, {:color => "white" ,:size => "4"}]])
    
    res_table = @results_html_file.add_table([["Total Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Successful Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Failed Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Skipped Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Aborted Test Iterations",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}],
                ["Success Rate %",{:bgcolor => "white", :align => "center"},{:color => "blue", :size => "3"}]])
    
    @cepc['total_test_sessions'] = @cepc['total_passed'].to_i + @cepc['total_failed'].to_i + @cepc['total_skipped'].to_i + @cepc['total_aborted'].to_i
    @tot_success_rate = @cepc['total_passed'].to_i / (@cepc['total_test_sessions'].to_i ) * 100
    
    if @cepc['test_failed'].to_i == 0
      status_color = "#00FF00"
    else
      status_color = "#FF0000"
    end

    @results_html_file.add_rows_to_table(res_table,[[["#{@cepc['total_test_sessions']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@cepc['total_passed']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@cepc['total_failed']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@cepc['total_skipped']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@cepc['total_aborted']}",{:bgcolor => "white"},{:size => "2"}],
                ["#{@tot_success_rate}",{:bgcolor => status_color},{:size => "2"}]]])

  end
  
  


  
  