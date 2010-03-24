require 'net/ftp'

module WinceTestScript
  attr_reader :serial_port_data    # Holds last data read from serial port
  
  # Connects Test Equipment to DUT(s) and Boot DUT(s)
  def setup
    puts "\n WinceTestScript::setup"
    delete_temp_files()
    @equipment['dut1'].set_api('bsp')
    setup_connect_equipment()
    setup_boot()
  end

  # Execute shell script in DUT(s) and save results.
  def run
    puts "\n WinceTestScript::run"
    run_generate_script
    run_transfer_script
    run_call_script
    run_get_script_output
    run_collect_performance_data
    run_save_results
  end

  # Do nothing by default.  Overwrite implementation in test script if required
  def clean
    puts "\n WinceTestScript::clean"
    clean_delete_binary_files
  end
  
  # Do nothing by default.  Overwrite implementation in test script if required to connect test equipment to DUT(s)
  def setup_connect_equipment
    puts "WinceTestScript::setup_connect_equipment"
  end
  
  # Boot DUT if kernel image was specified in the test parameters
  def setup_boot
    puts "\n WinceTestScript::setup_boot"
    boot_params = {'power_handler'=> @power_handler, 'test_params' => @test_params}
    @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
    if boot_required?(@old_keys, @new_keys)   # call bootscript if required
      puts " WinceTestScript::setup_boot: kernel image specified. Proceeding to boot DUT"
      if @equipment['dut1'].respond_to?(:serial_port)
        @equipment['dut1'].connect({'type'=>'serial'})
      elsif @equipment['dut1'].respond_to?(:serial_server_port)
        @equipment['dut1'].connect({'type'=>'serial'})
      else
        raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
      end
      @equipment['dut1'].boot(boot_params) 
      puts "Waiting 10 seconds for kernel to boot...."
      sleep 10
    end
    if @equipment['dut1'].respond_to?(:telnet_port)  and !@equipment['dut1'].target.telnet
      @equipment['dut1'].connect({'type'=>'telnet'})
    elsif (@equipment['dut1'].respond_to?(:serial_port) or @equipment['dut1'].respond_to?(:serial_server_port)) and !@equipment['dut1'].target.serial
      @equipment['dut1'].connect({'type'=>'serial'})
    elsif !@equipment['dut1'].target.telnet and !@equipment['dut1'].target.serial
      raise "You need Telnet or Serial port connectivity to the board. Please check your bench file" 
    end
  end
  
  # Generate WinCE shell script to be executed at DUT.
  # By default this function only replaces the @test_params references in the shell script template and creates test.bat  
  def run_generate_script
    puts "\n WinceTestScript::run_generate_script"
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
  
  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    puts "\n WinceTestScript::run_transfer_script"
    put_file({'filename'=>'test.bat'})
    if @test_params.params_chan.instance_variable_defined?(:@test_libs) #and false  ###### TODO TODO MUST REMOVE 'and false', Added to work around problem in Primus 
      src_dir = @test_params.test_libs_root
      puts "libs source dir set to #{src_dir}"
      @test_params.params_chan.test_libs.each {|lib_file|
        puts "libs filename set to #{lib_file}"
        put_file({'filename' => lib_file, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end
  
  # Calls shell script (test.bat)
  def run_call_script
    puts "\n WinceTestScript::run_call_script"
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    @equipment['dut1'].send_cmd("cd #{dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call test.bat 2> stderr.log > stdout.log",@equipment['dut1'].prompt)
  end
  
  # Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output
    puts "\n WinceTestScript::run_get_script_output"
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    keep_checking = true
    while keep_checking
      counter=0
      while check_serial_port()
        sleep 1
        counter += 1
        if counter >= wait_time
          puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."  
          keep_checking = false
          break
        end
      end
    end
    get_file({'filename'=>'stderr.log'})
    get_file({'filename'=>'stdout.log'})
    log_file = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, 'test.log'),'w')
    std_output = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stdout.log'),'r').read
    std_error  = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER,'stderr.log'),'r').read
    log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
    log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
    log_file.close
  end
  
  # Parse test.log and extracts performance data into perf.log. This method MUST be overridden if performance data needs to be collected.
  # The default implementation creates and empty perf.log file
  def run_collect_performance_data
    puts "\n WinceTestScript::run_collect_performance_data"
  end
  
  # Parse test.log and  potentially perf.log to determine test result outcome. This method MUST be overridden
  # This default implementation pass the test if the call to test.bat returns 0 (i.e. no error). However, please note that this default implementation
  # does not work with all CE shells and it may falsely passed a test becuase the %ERRORLEVEL% variable is not properly set
  def run_determine_test_outcome
    puts "\n WinceTestScript::run_determine_test_outcome"
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
    puts "\n WinceTestScript::run_save_results"
    result,comment = run_determine_test_outcome
    set_result(result,comment)
  end
  
  # Delete binary files (if any) transfered to the DUT
  def clean_delete_binary_files
    puts "\n WinceTestScript::clean_delete_binary_files"
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    @equipment['dut1'].send_cmd("cd #{dst_dir}",@equipment['dut1'].prompt)
    if @test_params.params_chan.instance_variable_defined?(:@test_libs)
      @test_params.params_chan.test_libs.each {|lib_file|
        @equipment['dut1'].send_cmd("del #{lib_file}",@equipment['dut1'].prompt)  
      }
    end
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
    check_serial_port
    @serial_port_data
  end
  
  # transfer a file from PC to EVM. params keys are: filename (mandatory). dst_ip, dst_dir, src_dir, login and password (Optional)
  def put_file(params)
    dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Temp'
    p = {'dst_ip'   => @equipment['dut1'].telnet_ip,
         'dst_dir'  => dst_dir, 
         'src_dir'  => SiteInfo::WINCE_TEMP_FOLDER, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
         'binary'   => false,
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['dst_ip'])
    dut_ftp.login(p['login'], p['password'])
    if p['binary']
      dut_ftp.putbinaryfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    else
      dut_ftp.puttextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    end
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
         'binary'   => false,
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['src_ip'])
    dut_ftp.login(p['login'], p['password'])
    if p['binary']
      dut_ftp.getbinaryfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    else
      dut_ftp.gettextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    end
    dut_ftp.close
  end
  
  # Return true if there is no new data in serial port
  def check_serial_port
    temp = (@serial_port_data.to_s).dup
    @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup
    @serial_port_data == temp
  end
  
  
  
  private
  def get_keys
    keys = @test_params.platform.to_s + @test_params.kernel.to_s
    keys
  end
  
  def boot_required?(old_params, new_params)
    return false if !@test_params.instance_variable_defined?(:@kernel)
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
  
  def delete_temp_files
    Dir.foreach(SiteInfo::WINCE_TEMP_FOLDER) do |f|
      filepath = File.join(SiteInfo::WINCE_TEMP_FOLDER,f)
      if f == '.' or f == '..' or File.directory?(filepath) then next
      else FileUtils.rm(filepath, {:verbose => true})
      end
    end
  end
  
end
  