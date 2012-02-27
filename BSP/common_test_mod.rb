#initial release - 02-25-2012
require File.dirname(__FILE__)+'/default_test'
require File.dirname(__FILE__)+'/net_common_mod'
require File.dirname(__FILE__)+'/create_net_html_page'
require 'digest/sha2'
require 'thread'
require 'date'
require 'time'

module CommonTestMod
  include WinceTestScript
  include NetCommonModule
  include CreateNetHtmlPage

  ############################################################## init_net_usb_common_vars #####################################################################
  #Initialize various variables which are used with the network and USB related test scripts
  def init_net_usb_common_vars
    puts "\n common_test_mod::init_net_usb_common_vars "+ __LINE__.to_s
    @all_lines = ''
    @tst_result = @array_lines = @l_pos = i = 0
    @data = Array.new
    init_common_hash_arrays("@data_time")
    @lcl_file_name = @test_params.params_equip.instance_variable_defined?(:@lcl_testfile_name) ? @test_params.params_equip.lcl_testfile_name[0] : 'usbtest.tst'
    @src_dir = @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) ? @test_params.params_equip.lcl_dsktp_tmp_dir[0] : 'C:\Temp'
    @wince_dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Windows'
    @wince_temp_dir = @test_params.params_equip.instance_variable_defined?(:@rmt_temp_root) ? @test_params.params_equip.rmt_temp_root[0] : '\Temp'
  end


  ############################################################## init_common_hash_arrays #####################################################################
  #A common routine for initialing various hash/array objects
  def init_common_hash_arrays(data_array_hash_type)
    puts "\n common_test_mod::init_common_hash_arrays -\n----------- Initializing ******* #{data_array_hash_type} ******* -------- "+ __LINE__.to_s
    
    if data_array_hash_type == "@data_time"
      @data_time = Array.new
      
      @data_time =  {"run_duration" => 0, "script_start_time_seconds" => 0, "curr_time_seconds" => 0, "test_start_time_seconds" => 0, 
                     "test_end_time_seconds" => 0, "script_start_time_seconds" => 0, "script_end_time_seconds" => 0, 
                     "curr_secs" => 0, "enum_time" => 0, "tot_enum_time" => 0, "low_enum_time" => 0, "avg_enum_time" => 0, 
                     "test_dur" => 0, "high_enum_time" => 0, "seconds" => 0, "minutes" => 0, "hours" => 0, "days" => 0, 
                     "curr_run_time_seconds" => 0, "curr_test_run_time_seconds" => 0, "curr_script_run_time_seconds" => 0
                    }
    elsif data_array_hash_type ==  "@data1"
      @data1 = Hash.new
      
      @data1 =  {"fn_success_count" => 0, "fn_fail_count" => 0, "fn_success_rate" => 0, "fn_fail_rate" => 0, 
                 "enum_success_count" => 0, "enum_fail_count" => 0, "@enum_time" => 0, "tot_enum_time" => 0, 
                 "enum_success_rate" => 0, "iteri" => 0, "low_enum_time" => 0, "avg_enum_time" => 0, "high_enum_time" => 0, 
                 "fn_integrity_success_count" => 0, "fn_integrity_fail_count" => 0, "enum_count" => 0, "seconds" => 0, 
                 "minutes" => 0, "hours" => 0, "days" => 0, "run_duration" => 0, "low_write_bw" => 0, 
                 "usb_test_intfc" => @test_params.params_control.usb_test_intfc[0].upcase, "high_write_bw" => 0, 
                 "low_read_bw" => 0, "fn_connect_ok" => 0, "enum_ok" => 0, "enum_fail" => 0, "start_enum_loop_time" => 0, 
                 "end_enum_loop_time" => 0
                }

    elsif data_array_hash_type == "@copy_times"
      @copy_times = Hash.new
    
      @copy_times = {"write_to_device_time" => 0, "low_write_to_device_time" => 0, "high_write_to_device_time" => 0, 
                     "tot_write_to_device_time" => 0, "read_fm_device_time" => 0, "low_read_fm_device_time" => 0, 
                     "high_read_fm_device_time" => 0, "tot_read_fm_device_time" => 0, "write_to_device_bw" => 0,
                     "low_write_to_device_bw" => 0, "high_write_to_device_bw" => 0, "tot_write_to_device_bw" => 0,
                     "avg_write_to_device_bw" => 0, "read_fm_device_bw" => 0, "low_read_fm_device_bw" => 0, 
                     "high_read_fm_device_bw" => 0, "avg_read_fm_device_bw" => 0, "avg_write_to_device_time" => 0, 
                     "avg_read_fm_device_time" => 0, "iterations" => 0, "xfer_file_size" => 0
                    }

    elsif data_array_hash_type == "@fn_enum_perfdata"
      @fn_enum_perfdata = Array.new

    elsif data_array_hash_type == "@usb_enum_perfdata"
      @usb_enum_perfdata = Array.new
      
    elsif data_array_hash_type ==  "drive_lists"
      @drive_list1 = []
      @drive_list2 = []
    
    elsif data_array_hash_type ==  "@cepc_vars"
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
  end
  
  
  ############################################################## collect_test_header_data #####################################################################
  # Parse CETK test result log for HEADER data and test status ----------------------------------------- 
  def collect_test_header_data
    puts "\n Entering common_test_mod::collect_test_header_data "+ __LINE__.to_s
    @lg_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
    puts "\n----------- Loading test results file --- "+ __LINE__.to_s
  
    File.open("#{@lg_file_name}").each {|line|
      @all_lines += line
      @array_lines += 1
    }

    @test_name = /\*\s+Test\s+Name:\s+(.+)/i.match(@all_lines).captures[0]                  #parse name of test case
    @tst_id = /\*\s+Test\s+ID:\s+([\d]+)/i.match(@all_lines).captures[0]                    #parse CETK test ID
    @dev_name = "#{@equipment['dut1'].board_id}"                                            #parse Device name from bench.rb file
    @os_ver = /OS\s+.+\s+(\d+.\d+)/i.match(@all_lines).captures[0]                          #parse os Version running on EVM
    @build_number = /Bu.+er\:\s+(\d+)/i.match(@all_lines).captures[0]                       #parse Build Number of OS
    @os_type = /Platform\sid\:.+\"(.+)"/i.match(@all_lines).captures[0]                     #parse Platform ID (ie Platform ID)
    @op_system = /Pl.+ID\:.+"(.+)"/i.match(@all_lines).captures[0]                          #parse Operating System name (Platform ID)
    @proc_type = /Pro.+pe\:.+\s+\"(\w+)\"/i.match(@all_lines).captures[0]                   #parse Processor type on EVM
    @proc_arc = /Pro.+ure\:.+\s+\"(\w+)\"/i.match(@all_lines).captures[0]                   #parse Processor Architecture on EVM
    @test_protocol = /\*\s+Test\s+Name:\s+([\w]+)/im.match(@all_lines).captures[0]          #parse protocol - TCP, UDP, etc
    @proc_lvl = /Pro.+Lev.+\s+(\w+\s+\(\d+\))/i.match(@all_lines).captures[0]               #parse Processor Level on EVM
    @proc_rev = /Pro.+Rev.+\s+(\w+\s+\(\d+\))/i.match(@all_lines).captures[0]               #parse Processor Revision on EVM
    @exec_time = /Su.+Exec.+me.+(\d+\:\d+\:\d+\.\d+)/i.match(@all_lines).captures[0]        #parse total execution time of test case
    @test_passed = /\*\*\s+passed\:\s+(\d+)/i.match(@all_lines).captures[0]                 #capture number of test passes
    @test_failed = /\*\*\s+failed\:\s+(\d+)/i.match(@all_lines).captures[0]                 #capture number of test failures
    @test_skipped = /\*\*\s+skipped\:\s+(\d+)/i.match(@all_lines).captures[0]               #capture number of test skips
    @test_aborted = /\*\*\s+aborted\:\s+(\d+)/i.match(@all_lines).captures[0]               #capture number of test aborts
    @total_passed = /passed\:\s+(\d+)+/im.match(@all_lines).captures[0]                     #used when running a test case which has multiple iterations
    @total_failed = /failed\:\s+(\d+)+/im.match(@all_lines).captures[0]                     #used when running a test case which has multiple iterations
    @total_skipped = /skipped\:\s+(\d+)+/im.match(@all_lines).captures[0]                   #used when running a test case which has multiple iterations
    @total_aborted = /aborted\:\s+(\d+)+/im.match(@all_lines).captures[0]                   #used when running a test case which has multiple iterations

    # ---------------------------------------- Determine if test passed or failed ---------------------------------------- 
    if @test_failed.to_i == 0 && @test_skipped.to_i == 0 && @test_aborted.to_i == 0
      @tst_result = 1
    else
      @tst_result = 0
    end
  end


  ############################################################## run_get_script_output #####################################################################
 # Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string=nil)
    puts "\n common_sub_mod::run_get_script_output"
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    puts "expect_string is #{expect_string}\n"
    @script_output_timer = 0
    
    while keep_checking
      counter=0
      
      while check_serial_port()
        if /\@{6}([\d]+)/i.match(@serial_port_data) then
          puts "\nDEBUG: Received the expected string and the test is complete."  
          keep_checking = false
          sleep 2
          break
        end
        
        #if not see expect_string, wait for timeout to prevent infinite loop
        sleep 1
        counter += 1
        @script_output_timer += 1

        if counter >= wait_time
          puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."
          keep_checking = false
          break
        end
      end
    end
    
    # make sure serial port log wont lost even there is ftp exception
    begin
      log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
      log_file = File.new(log_file_name,'w')
      get_file({'filename'=>'stderr.log'})
      get_file({'filename'=>'stdout.log'})
      std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
      err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
      std_output = std_file.read
      std_error  = err_file.read
      log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
      log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    rescue Exception => e
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
      clean_delete_binary_files
      @new_keys = ''
      raise
    end
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
    ensure
      std_file.close if std_file
      err_file.close if err_file
  end


  ############################################################## check_serial_port #####################################################################
   # Return true if there is no new data in serial port
  def check_serial_port
    return true if !@equipment['dut1'].target.serial   # Return right away if there is no serial port connection
    temp = (@serial_port_data.to_s).dup
    @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup.delete "\0"
    @serial_port_data == temp
  end

  
  ############################################################## set_dut_datetime #####################################################################
  def set_dut_datetime
    puts "\n common_sub_mod::set_dut_datetime "+ __LINE__.to_s
    @equipment['dut1'].send_cmd("date #{"#{Time.now.month}"+"-"+"#{Time.now.day}"+"-"+"#{Time.now.year}"}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("time #{/\s+(\d+\:\d+\:\d+)/i.match(Time.now.to_s).captures[0]}",@equipment['dut1'].prompt)
  end
  
  
  ############################################################## run_generate_test_script_bat ###########################################################################
  def run_generate_test_script_bat
    puts "\n common_sub_mod::run_generate_test_script_bat "+ __LINE__.to_s
    puts "\n -------------------- Generating the test.bat file -------------------- "+ __LINE__.to_s
    @cmd_line = "ftp -d -s:#{@lcl_dsktop_tmp_dir}\\ftptest.txt #{@equipment['dut1'].telnet_ip} 1>#{@lcl_dsktop_tmp_dir}\\result.log 2>&1"
    puts "\n -------------------- #{@cmd_line} -------------------- "+ __LINE__.to_s
    puts "\n -------------------- #{@lcl_dsktop_tmp_dir} -------------------- "+ __LINE__.to_s
    puts "\n -------------------- #{File.join(@lcl_dsktop_tmp_dir, 'test.bat')} -------------------- "+ __LINE__.to_s
    out_file = File.new(File.join(@lcl_dsktop_tmp_dir, 'test.bat'),'w')
    out_file.puts "\@ECHO off"
    out_file.puts(eval('"'+"echo "+"\"Testing #{@equipment['dut1'].board_id} with IP:  #{@equipment['dut1'].telnet_ip}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.puts(eval('"'+"echo "+"\"Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : 'No kernel specified'}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.puts(eval('"'+"echo "+"\"Command Line: #{@cmd_line}\"".gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.puts(eval('"'+@cmd_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    out_file.close
  end
  
  
  ############################################################## rm_dsktop_files #####################################################################
  def rm_dsktop_files
    puts "\n common_sub_mod::rm_dsktop_files "+ __LINE__.to_s
    @test_params.params_equip.desktop_test_libs.each {|filename|
    tmp = File.join(@dst_dsktop_dir, filename)
    
    FileUtils.rm(tmp, {:verbose => true})
    }
  end
  
  
  ############################################################## clean_delete_log_files #####################################################################
  # Delete log files (if any) 
  def clean_delete_log_files
    puts "\n Entering common_sub_mod::clean_delete_log_files "+ __LINE__.to_s
    @equipment['dut1'].send_cmd("cd \\Release",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("del \*\.LOG",@equipment['dut1'].prompt)
  end


  ############################################################## read_log_file #################################################################################
  def read_log_file(log_file)
    puts "\n Entering common_sub_mod::read_log_file "+ __LINE__.to_s
    @svc_lines = ''
    
    File.open("#{log_file}").each {|line|
      @svc_lines += line
    }
    
    sleep 1
  end
  
  
  ############################################################## cp_dsktop_files #####################################################################
  def cp_dsktop_files
    puts "\n Entering common_sub_mod::cp_dsktop_files "+ __LINE__.to_s
    
    if @test_params.params_equip.instance_variable_defined?(:@lcl_dsktp_tmp_dir) && @test_params.instance_variable_defined?(:@var_test_libs_root)
      @dst_dsktop_dir = @test_params.params_equip.lcl_dsktp_tmp_dir[0]
      @src_dsktop_dir = File.join(@test_params.var_test_libs_root,'desktop')
    end

    if @test_params.params_equip.instance_variable_defined?(:@desktop_test_libs)
      puts "------------- The required perf files are present -------- #{@test_params.params_equip.desktop_test_libs} ---------- "+ __LINE__.to_s
    end

    @test_params.params_equip.desktop_test_libs.each {|filename|
    puts "Copying Filename #{filename}"
    tmp = File.join(@test_params.var_test_libs_root,'desktop', filename)
    
    FileUtils.cp("#{tmp}", @dst_dsktop_dir)
    }
  end
  

  ############################################################## clean_delete_local_temp_files #################################################################
  # Delete log files (if any) 
  def clean_delete_local_temp_files
    puts "\n Entering common_sub_mod::clean_delete_local_temp_files "+ __LINE__.to_s
    
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

  
 ############################################################## save_test_start_time ##################################################################
  def save_test_start_time
    puts "\n common_test_mod::save_test_start_time "+ __LINE__.to_s
    @data_time['test_start_time_seconds'] = Time.now.strftime("%s")
  end

  
  ############################################################## save_test_end_time ##################################################################
  def save_test_end_time
    puts "\n common_test_mod::save_test_end_time "+ __LINE__.to_s
    @data_time['test_end_time_seconds'] = Time.now.strftime("%s")
  end
  
  
 ############################################################## save_script_start_time ##################################################################
  def save_script_start_time
    puts "\n common_test_mod::save_script_start_time "+ __LINE__.to_s
    @data_time['script_start_time_seconds'] = Time.now.strftime("%s")
    puts "\n ------------ Script Start Time: #{@data_time['script_start_time_seconds']} ------------ "+ __LINE__.to_s 
  end

  
  ############################################################## save_script_end_time ##################################################################
  def save_script_end_time
    puts "\n common_test_mod::save_script_end_time "+ __LINE__.to_s
    @data_time['script_end_time_seconds'] = Time.now.strftime("%s")
    puts "\n ------------ Script End Time: #{@data_time['script_end_time_seconds']} ------------ "+ __LINE__.to_s 
  end
  
  
  ############################################################## calc_current_script_run_time ##################################################################
  def calc_current_script_run_time
    puts "\n common_test_mod::calc_current_script_run_time "+ __LINE__.to_s
    @data_time['curr_time_seconds'] = Time.now.strftime("%s")
    @data_time['curr_script_run_time_seconds'] = (@data_time['curr_time_seconds'].to_i - @data_time['script_start_time_seconds'].to_i)
    @data_time['curr_secs'] = (@data_time['curr_script_run_time_seconds'].to_i)
    parse_time
  end

  
  ############################################################## calc_current_test_run_time ##################################################################
  def calc_current_test_run_time
    puts "\n common_test_mod::calc_current_test_run_time "+ __LINE__.to_s
    @data_time['curr_time_seconds'] = Time.now.strftime("%s")
    @data_time['curr_test_run_time_seconds'] = (@data_time['curr_time_seconds'].to_i - @data_time['test_start_time_seconds'].to_i)
    @data_time['curr_secs'] = (@data_time['curr_test_run_time_seconds'])
    parse_time
  end


  ############################################################## calc_total_script_run_time ##################################################################
  def calc_total_script_run_time
    puts "\n common_test_mod::calc_total_script_run_time "+ __LINE__.to_s
    @data_time['curr_secs'] = (@data_time['test_end_time_seconds'].to_i - @data_time['test_start_time_seconds'].to_i)
    parse_time
  end


  ############################################################## parse_time #####################################################################
  def parse_time
    puts "\n common_test_mod::parse_time "+ __LINE__.to_s
    @data_time['seconds'] = @data_time['curr_secs'] % 60
    @data_time['minutes'] = ((@data_time['curr_secs'] / 60 ) % 60)
    @data_time['hours'] = (@data_time['curr_secs'] / (60 * 60) % 60)
    @data_time['days'] = (@data_time['curr_secs'] / (60 * 60 * 24))
    @test_time = "#{@data_time['days']} Days  #{@data_time['hours']} Hours  #{@data_time['minutes']} Mins. #{@data_time['seconds']} Secs."
  end

  
  ############################################################## calculate_desired_script_run_time #####################################################################
  def calculate_desired_script_run_time
    puts "\n common_test_mod::calculate_desired_script_run_time "+ __LINE__.to_s
    @data_time['run_duration'] = 0
    
    if @test_params.params_control.instance_variable_defined?(:@test_duration)
    
      if /na/i.match(@test_params.params_control.test_duration[0])
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
      @data_time['run_duration'] = @specified_test_duration.to_i * 0
      @test_dur = "#{@specified_test_duration} Seconds"
    when @units == "m"
      @data_time['run_duration'] = @specified_test_duration.to_i * 60
      @data_time['@test_dur'] = "#{@specified_test_duration} Minutes"
    when @units == "h"
      @data_time['run_duration'] = @specified_test_duration.to_i * 60 * 60
      @data_time['@test_dur'] = "#{@specified_test_duration} Hours"
      when @units == "d"
      @data_time['run_duration'] = @specified_test_duration.to_i * 60 * 60 * 24
      @data_time['@test_dur'] = "#{@specified_test_duration} Days"
    when @units == "na"
      @data_time['@test_dur'] = "N/A"
    end
    puts "\n ------------ Seconds: #{@data_time['run_duration']} ----- #{@data_time['@test_dur']} -----  #{@units} ----- #{@specified_test_duration} ------------ "+ __LINE__.to_s 
  end
end



