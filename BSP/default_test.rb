require 'net/ftp'

module WinceTestScript
  
  # Connects Test Equipment to DUT(s) and Boot DUT(s)
  def setup
    puts "WinceTestScript::setup"
    @equipment['dut1'].set_api('bsp')
    setup_connect_equipment()
    setup_boot()
  end

  # Execute shell script in DUT(s) and save results.
  def run
    puts "WinceTestScript::run"
    run_generate_script
    run_transfer_script
    run_call_script
    run_get_script_output
    run_collect_performance_data
    run_save_results
  end

  # Do nothing by default.  Overwrite implementation in test script if required
  def clean
    puts "WinceTestScript::clean"
  end
  
  # Do nothing by default.  Overwrite implementation in test script if required to connect test equipment to DUT(s)
  def setup_connect_equipment
    puts "WinceTestScript::setup_connect_equipment"
  end
  
  # Boot DUT if kernel image was specified in the test parameters
  def setup_boot
    puts "WinceTestScript::setup_boot"
    @equipment['dut1'].connect({'type'=>'serial'})
    if @test_params.instance_variable_defined?(:@kernel)
      puts "WinceTestScript::setup_boot: kernel image specified. Proceeding to boot DUT"
      boot_params = {'power_handler'=> @power_handler, 'test_params' => @test_params}
      @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
      @equipment['dut1'].boot(boot_params) if boot_required?(@old_keys, @new_keys) # call bootscript if required
    else
      puts "WinceTestScript::boot \t kernel image NOT specified. Will skip booting process"
    end
  end
  
  # Generate WinCE shell script to be executed at DUT.
  # By default this function only replaces the @test_params references in the shell script template and creates test.bat  
  def run_generate_script
    FileUtils.mkdir_p SiteInfo::WINCE_TEMP_FOLDER
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_chan.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, 'test.bat'),'w')
    raw_test_lines.each do |current_line|
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end
  
  # Transfer the shell script (test.bat) to the DUT. 
  def run_transfer_script()
    puts "WinceTestScript::run_transfer_script"
    put_file({'filename'=>'test.bat'})
  end
  
  # Calls shell script (test.bat)
  def run_call_script
    puts "WinceTestScript::run_call_script"
    @equipment['dut1'].connect({'type'=>'telnet'})
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    @equipment['dut1'].send_cmd("cd #{dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call test.bat 2> stderr.log > stdout.log",@equipment['dut1'].prompt)
  end
  
  # Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output
    puts "WinceTestScript::run_get_script_output"
    get_file({'filename'=>'stderr.log'})
    get_file({'filename'=>'stdout.log'})
    log_file = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, 'test.log'),'w')
    std_output = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stdout.log'),'r').read
    std_error  = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stderr.log'),'r').read
    log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
    log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    serial_output = @equipment['dut1'].update_response('serial')
    log_file.write("\n<SERIAL_OUTPUT>\n"+serial_output.to_s+"</SERIAL_OUTPUT>\n") 
    log_file.close
  end
  
  # Parse test.log and extracts performance data into perf.log. This method MUST be overridden if performance data needs to be collected.
  # The default implementation creates and empty perf.log file
  def run_collect_performance_data
    puts "WinceTestScript::run_collect_performance_data"
  end
  
  # Parse test.log and  potentially perf.log to determine test result outcome. This method MUST be overridden
  # This default implementation pass the test if the call to test.bat returns 0 (i.e. no error). However, please note that this default implementation
  # does not work with all CE shells and it may falsely passed a test becuase the %ERRORLEVEL% variable is not properly set
  def run_determine_test_outcome
    puts "WinceTestScript::run_determine_test_outcome"
    put_file({'filename'=>'check_default_result.bat', 'src_dir'=>File.dirname(__FILE__)})
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    @equipment['dut1'].send_cmd("cd #{dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call check_default_result.bat 2> check_result.log > check_result.log",@equipment['dut1'].prompt)
    get_file({'filename'=>'check_result.log'})
    check_result_output = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'check_result.log'),'r').read
    if check_result_output.match(/PASSED/)
      return [FrameworkConstants::Result[:pass], "test.bat returned zero"]
    else
      return [FrameworkConstants::Result[:fail], "test.bat returned error"]
    end
  end
  
  # Write test result and performance data to results database (either xml or msacess file)
  def run_save_results
    puts "WinceTestScript::run_save_results"
    result,comment = run_determine_test_outcome
    set_result(result,comment)
  end
  
  # Return standard output of test.bat as a string
  def get_std_output
    File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stdout.log'),'r').read
  end
  
  # Return standard error of test.bat as a string
  def get_std_error
    File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stderr.log'),'r').read
  end
  
  # Return serial (i.e. console) output of test.bat as a string
  def get_serial_output
    @equipment['dut1'].target.serial.response
  end
  
  # transfer a file from PC to EVM. params keys are: filename (mandatory). dst_ip, dst_dir, src_dir, login and password (Optional)
  def put_file(params)
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    p = {'dst_ip'   => @equipment['dut1'].telnet_ip,
         'dst_dir'  => dst_dir, 
         'src_dir'  => SiteInfo::WINCE_TEMP_FOLDER, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['dst_ip'])
    dut_ftp.login(p['login'], p['password'])
    dut_ftp.puttextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    dut_ftp.close
  end
  
  # Get a file from EVM to PC. params keys are: filename (mandatory). src_ip, src_dir, dst_dir, login and password (Optional)
  def get_file(params)
    src_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    p = {'src_ip'   => @equipment['dut1'].telnet_ip,
         'src_dir'  => src_dir, 
         'dst_dir'  => SiteInfo::WINCE_TEMP_FOLDER, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['src_ip'])
    dut_ftp.login(p['login'], p['password'])
    dut_ftp.gettextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    dut_ftp.close
  end
  
  
  
  private
  def get_keys
    keys = @test_params.platform.to_s + @test_params.kernel.to_s
    keys
  end
  
  def boot_required?(old_params, new_params)
    old_test_string = get_test_string(old_params)
    new_test_string = get_test_string(new_params)
    old_test_string != new_test_string
  end
  
  def get_test_string(params)
    test_string = ''
    params.each {|element|
      test_string += element.strip
    }
    test_string
  end
  
end
  