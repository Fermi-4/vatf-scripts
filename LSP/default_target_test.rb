# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'
require 'net/ftp'

module LspTargetTestScript
  include LspTestScript
  
  
  # Connects Test Equipment to DUT(s) and Boot DUT(s)
  def setup
    puts "\n LinuxTestScript::setup"
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)
    delete_temp_files()
    @linux_dst_dir = @test_params.params_control.instance_variable_defined?(:@test_dir) ? @test_params.params_control.test_dir[0] : '/test'
    setup_connect_equipment()
    super
  end

  # Execute shell script in DUT(s) and save results.
  def run
    puts "\n LinuxTestScript::run"
    run_generate_script
    run_transfer_script
    return_non_zero = run_call_script
    run_get_script_output
    run_collect_performance_data
    run_save_results(return_non_zero)
  end

  # Do nothing by default.  Overwrite implementation in test script if required
  def clean
    puts "\n LinuxTestScript::clean"
    clean_delete_binary_files
  end
  
  # Do nothing by default.  Overwrite implementation in test script if required to connect test equipment to DUT(s)
  def setup_connect_equipment
    puts "LinuxTestScript::setup_connect_equipment"
  end
  
  # Generate Linux shell script to be executed at DUT.
  # By default this function only replaces the @test_params references in the shell script template and creates test.sh  
  def run_generate_script
    puts "\n LinuxTestScript::run_generate_script"
    FileUtils.mkdir_p @linux_temp_folder
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_control.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(@linux_temp_folder, 'test.sh'),'w')
    raw_test_lines.each do |current_line|
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end

  # Transfer the shell script (test.sh) to the DUT and any require libraries
  def run_transfer_script()
    puts "\n LinuxTestScript::run_transfer_script"
    in_file = File.new(File.join(@linux_temp_folder,'test.sh'), 'r')
    raw_test_lines = in_file.readlines
    @equipment['dut1'].send_cmd("mkdir -p -m 777 #{@linux_dst_dir}", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat > test.sh << EOF", />/)
    raw_test_lines.each do |current_line|
      @equipment['dut1'].send_cmd(current_line.gsub(/\\[^\\]\$/,"\\$"))
    end
    @equipment['dut1'].send_cmd("EOF", @equipment['dut1'].prompt)
  end
  
  # Calls shell script (test.sh)
  def run_call_script
    puts "\n LinuxTestScript::run_call_script"
    @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("./test.sh 2> stderr.log > stdout.log",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    @equipment['dut1'].timeout?
  end

  # Collect output from standard output and  standard error in test.log
  def run_get_script_output
    puts "\n LinuxTestScript::run_get_script_output"
    log_file_name = File.join(@linux_temp_folder, 'test.log') 
    log_file = File.new(log_file_name,'w')
    stderr_file  = File.new(File.join(@linux_temp_folder,'stderr.log'),'w')
    stdout_file  = File.new(File.join(@linux_temp_folder,'stdout.log'),'w')
    @equipment['dut1'].send_cmd("cat stdout.log",@equipment['dut1'].prompt,30)
    std_output = @equipment['dut1'].response
    @equipment['dut1'].send_cmd("cat stderr.log",@equipment['dut1'].prompt,30)
    std_error = @equipment['dut1'].response
    stdout_file.write(std_output)
    stderr_file.write(std_error)
    log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
    log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    stdout_file.close
    stderr_file.close
    log_file.close
    add_log_to_html(log_file_name)
  end
  
  # Parse test.log and extracts performance data into perf.log. This method MUST be overridden if performance data needs to be collected.
  # The default implementation creates and empty perf.log file
  def run_collect_performance_data
    puts "\n LinuxTestScript::run_collect_performance_data"
  end
  
  # Parse test.log and  potentially perf.log to determine test result outcome. This method could be overridden
  # This default implementation pass the test if the call to test.sh returns 0 (i.e. no error).
  def run_determine_test_outcome(return_non_zero)
    puts "\n LinuxTestScript::run_determine_test_outcome"
    if !return_non_zero
      return [FrameworkConstants::Result[:pass], "test.sh returned zero"]
    else
      return [FrameworkConstants::Result[:fail], "test.sh returned error"]
    end
  end
  
  # Write test result and performance data to results database (either xml or msacess file)
  def run_save_results(return_non_zero)
    puts "\n LinuxTestScript::run_save_results"
    result = run_determine_test_outcome(return_non_zero)
    #result,comment = run_determine_test_outcome

    if result.length == 3
      set_result(result[0],result[1],result[2])
    elsif File.exists?(File.join(@linux_temp_folder,'perf.log'))
      perfdata = []
      data = File.new(File.join(@linux_temp_folder,'perf.log'),'r').readlines
      data.each {|line|
        if /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line)
          name,value,units = /(\S+)\s+([\.\d]+)\s+(\S+)/.match(line).captures 
          perfdata << {'name' => name, 'value' => value, 'units' => units}
        end
      }  
      set_result(result[0],result[1],perfdata)
    else
      set_result(result[0],result[1])
    end
  end
  
  # Delete binary files (if any) transfered to the DUT
  def clean_delete_binary_files
    puts "\n LinuxTestScript::clean_delete_binary_files"
    @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    if @test_params.params_control.instance_variable_defined?(:@test_libs)
      @test_params.params_control.test_libs.each {|lib_file|
        @equipment['dut1'].send_cmd("rm -f #{lib_file}",@equipment['dut1'].prompt)  
      }
    end
  end
  
  # Return standard output of test.sh as a string
  def get_std_output
    File.new(File.join(@linux_temp_folder,'stdout.log'),'r').read
  end
  
  # Return standard error of test.sh as a string
  def get_std_error
    File.new(File.join(@linux_temp_folder,'stderr.log'),'r').read
  end
  
  # Return serial (i.e. console) output of test.sh as a string
  def get_serial_output
    check_serial_port
    @serial_port_data
  end
  
  # Return true if there is no new data in serial port
  def check_serial_port
    return true if !@equipment['dut1'].target.serial   # Return right away if there is no serial port connection
    temp = (@serial_port_data.to_s).dup
    @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup
    @serial_port_data == temp
  end
  
  
  def get_keys
    kernel = @test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : ''
    keys = @test_params.platform.to_s + kernel
    keys
  end

  private
  def delete_temp_files
    return if !File.directory?(@linux_temp_folder)
    Dir.foreach(@linux_temp_folder) do |f|
      filepath = File.join(@linux_temp_folder,f)
      if f == '.' or f == '..' or File.directory?(filepath) then next
      else FileUtils.rm(filepath, {:verbose => true})
      end
    end
  end
  
end
  
