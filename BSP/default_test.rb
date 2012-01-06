require 'net/ftp'
#require File.dirname(__FILE__)+'/ftp_module'
#include FTP_GET

module WinceTestScript
  attr_reader :serial_port_data    # Holds last data read from serial port
  
  # Connects Test Equipment to DUT(s) and Boot DUT(s)
  def setup
    puts "\n WinceTestScript::setup"
    @force_telnet_connect = true
    @wince_temp_folder = File.join(SiteInfo::WINCE_DATA_FOLDER,@test_params.staf_service_name.to_s,'temp')
    delete_temp_files()
    @equipment['dut1'].set_api('bsp')
    @wince_dst_dir = @test_params.params_chan.instance_variable_defined?(:@test_dir) ? @test_params.params_chan.test_dir[0] : '\Windows'
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
    #run_collect_performance_data
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
      if @equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil
        @equipment['dut1'].connect({'type'=>'serial'})
      elsif @equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil
        @equipment['dut1'].connect({'type'=>'serial'})
      else
        raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
      end
      @equipment['dut1'].boot(boot_params) 
      puts "Waiting 30 seconds for kernel to boot...."
      sleep 30
    end
    
    if @equipment['dut1'].respond_to?(:telnet_port) && @equipment['dut1'].telnet_port != nil  && !@equipment['dut1'].target.telnet
      @equipment['dut1'].connect({'type'=>'telnet','force_connect'=>@force_telnet_connect})
    end
    
    if ((@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil) || (@equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil)) && !@equipment['dut1'].target.serial
      @equipment['dut1'].connect({'type'=>'serial'})
    end
    
    if !@equipment['dut1'].target.telnet && !@equipment['dut1'].target.serial
      raise "You need Telnet or Serial port connectivity to the board. Please check your bench file" 
    end
  end
  
  # Generate WinCE shell script to be executed at DUT.
  # By default this function only replaces the @test_params references in the shell script template and creates test.bat  
  def run_generate_script
    puts "\n WinceTestScript::run_generate_script"
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
  
  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    puts "\n WinceTestScript::run_transfer_script"
    put_file({'filename'=>'test.bat'})
    transfer_files(:@test_libs, :@var_test_libs_root)
    transfer_files(:@build_test_libs, :@var_build_test_libs_root)

    # transfer tux etc files to target
  if @test_params.instance_variable_defined?(:@var_test_libs_root)
      src_dir = @test_params.var_test_libs_root
      get_cetk_basic_filenames(src_dir).split(':').each {|lib_file|
        put_file({'filename' => lib_file, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end
  
  # Calls shell script (test.bat)
  def run_call_script
    puts "\n WinceTestScript::run_call_script"
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call test.bat 2> stderr.log > stdout.log",@equipment['dut1'].prompt)
  end
  
  # Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string=nil)
    puts "\n WinceTestScript::run_get_script_output"
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    #puts "keep_checking is: "+keep_checking.to_s
    puts "expect_string is #{expect_string}\n"
    while keep_checking
      counter=0
      while check_serial_port()
        #puts "@serial_port_data is: \n"+@serial_port_data+"\nend of @serial_port_data"
        #wait for end of test
        if expect_string != nil then
          expect_string_regex = Regexp.new(expect_string)
          if expect_string_regex.match(@serial_port_data) then
            puts "\nDEBUG: Getting expected string and the test complete."  
            keep_checking = false
            sleep 2
            break
          end
        end
        #if not see expect_string, wait for timeout to prevent infinite loop
        sleep 1
        counter += 1
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
      #yliu: temp: save differnt test log to different files
      std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
      err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
      std_output = std_file.read
      std_error  = err_file.read
      log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
      log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    rescue Exception => e
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
      add_log_to_html(log_file_name)
      clean_delete_binary_files
      # force dut reboot on next test case
      @new_keys = ''
      raise
    end
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      log_file.close
      add_log_to_html(log_file_name)
    ensure
      std_file.close if std_file
      err_file.close if err_file
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
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call check_default_result.bat 2> check_result.log > check_result.log",@equipment['dut1'].prompt)
    get_file({'filename'=>'check_result.log'})
    result_output = File.new(File.join(@wince_temp_folder,'check_result.log'),'r')
    check_result_output = result_output.read
    result_output.close
    
    if check_result_output.match(/PASSED/)
      return [FrameworkConstants::Result[:pass], "test.bat returned zero", run_collect_performance_data]
    else
      return [FrameworkConstants::Result[:fail], "test.bat returned error"]
    end
  end
  
  # Write test result and performance data to results database (either xml or msacess file)
  def run_save_results
    puts "\n WinceTestScript::run_save_results"
    result,comment,perfdata = run_determine_test_outcome
    if perfdata
      set_result(result,comment,perfdata)
    else
      set_result(result,comment)
    end
  end
  
  # Delete binary files (if any) transfered to the DUT
  def clean_delete_binary_files
    puts "\n WinceTestScript::clean_delete_binary_files"
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    delete_bin(:@test_libs)
    delete_bin(:@build_test_libs)
    @equipment['dut1'].send_cmd("del stderr\.log",@equipment['dut1'].prompt)  
    @equipment['dut1'].send_cmd("del stdout\.log",@equipment['dut1'].prompt)  
    @equipment['dut1'].send_cmd("del test\.bat",@equipment['dut1'].prompt) 
  end
  
  # Return standard output of test.bat as a string
  def get_std_output
    std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
    std_out = std_file.read
    std_file.close
    std_out
  end
  
  # Return standard error of test.bat as a string
  def get_std_error
    std_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
    std_err = std_file.read
    std_file.close
    std_err
  end
  
  # Return serial (i.e. console) output of test.bat as a string
  def get_serial_output
    check_serial_port
    @serial_port_data
  end
  
  # transfer a file from PC to EVM. params keys are: filename (mandatory). dst_ip, dst_dir, src_dir, login and password (Optional)
  def put_file(params)
    p = {'dst_ip'   => @equipment['dut1'].telnet_ip,
         'dst_dir'  => @wince_dst_dir, 
         'src_dir'  => @wince_temp_folder, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
         'binary'   => false,
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['dst_ip'])
    dut_ftp.login(p['login'], p['password'])
    #yliu: if the file exist in dst_dir, don't do ftp
    begin
      dut_ftp.chdir(p['dst_dir'])
      
      if !dut_ftp.nlst.include?(p['filename']) then
        puts "ftp #{p['filename']}"
        if p['binary']
          dut_ftp.putbinaryfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
        else
          dut_ftp.puttextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
        end
      end
    rescue Exception => e
      # reboot dut to avoid the failure of next test
      #boot_dut()
      @new_keys = ''
      raise
    ensure
      dut_ftp.close
      sleep 2
    end
  end
  
  # Get a file from EVM to PC. params keys are: filename (mandatory). src_ip, src_dir, dst_dir, login and password (Optional)
  def get_file(params)
    p = {'src_ip'   => @equipment['dut1'].telnet_ip,
         'src_dir'  => @wince_dst_dir, 
         'dst_dir'  => @wince_temp_folder, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
         'binary'   => false,
        }.merge(params) 
    dut_ftp = Net::FTP.new(p['src_ip'])
    dut_ftp.login(p['login'], p['password'])
    
    if p['binary']
      dut_ftp.getbinaryfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    else
      puts 'gettextfile: src: '+ File.join(p['src_dir'],p['filename']) + ' dst: ' + File.join(p['dst_dir'],p['filename'])
      dut_ftp.gettextfile(File.join(p['src_dir'],p['filename']), File.join(p['dst_dir'],p['filename']))
    end
  dut_ftp.close
  end

  # Get a file from EVM to PC. params keys are: filename (mandatory). src_ip, src_dir, dst_dir, login and password (Optional)
  def get_dir_files(params)
    p = {'src_ip'   => @equipment['dut1'].telnet_ip,
         'src_dir'  => @wince_dst_dir, 
         'dst_dir'  => @wince_temp_folder, 
         'login'    => 'anonymous',
         'password' => 'dut@ti.com',
         'binary'   => false,
        }.merge(params) 
    dst_log_files = []
    system("ruby #{File.join(File.dirname(__FILE__),"ftp_test.rb")} #{p['src_ip']} #{p['login']} #{p['password']} #{p['src_dir']} #{p['dst_dir']} #{@test_id.to_s} #{p['binary']}")
    #dst_log_files = ftp_get(p['src_ip'], p['login'],p['password'],p['src_dir'], p['dst_dir'], @test_id.to_s, p['binary'])
    puts "done with system ruby file\n"
    dut_ftp = Net::FTP.new(p['src_ip'])
    dut_ftp.login(p['login'], p['password'])
    dut_ftp.nlst(p['src_dir']).each {|f|
      dst_f = File.join(p['dst_dir'],@test_id.to_s+'_'+f)
      puts 'files under release dir: '+f
      dst_log_files << dst_f
    }  
    dut_ftp.close
    return dst_log_files
  end
  
  # Return true if there is no new data in serial port
  def check_serial_port
    return true if !@equipment['dut1'].target.serial   # Return right away if there is no serial port connection
   # @force_telnet_connect = false
    #puts "did not return true in check_serial_port"
    temp = (@serial_port_data.to_s).dup
    #puts "---temp:\n"+temp+"\nendoftemp"
    @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup
    #puts "---@serial_port_data:\n"+@serial_port_data+"\nendoftemp"
    @serial_port_data == temp
  end
  
  
  private
  def get_keys
    kernel = @test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : ''
    keys = @test_params.platform.to_s + kernel
    keys
  end
  
  def boot_required?(old_params, new_params)
    #return false
    return false if !@test_params.instance_variable_defined?(:@kernel)
    old_test_string = get_test_string(old_params)
    new_test_string = get_test_string(new_params)
    old_test_string != new_test_string
  end
  
  def get_os_version
    os_version = '6.0_R3'
    @equipment['dut1'].send_cmd("do OSversion",@equipment['dut1'].prompt)
    @telnet_response = @equipment['dut1'].response
    @telnet_response.each_line {|l| 
    if(l.scan(/OSMajor/).size>0)
      os_version = l.split(/OSMajor=/)[1].split(/,/)[0].to_s+'.'+l.split(/OSMinor=/)[1].split(/[\n\r]+/)[0].to_s
    end
    }
    return os_version
  end
  
  def get_test_string(params)
    test_string = ''
    params.each_char {|element|
      test_string += element.strip
    }
    test_string
  end
  
  def delete_temp_files
    # yliu: fix
    if File.exist?(@wince_temp_folder) && File.directory?(@wince_temp_folder) then
      Dir.foreach(@wince_temp_folder) do |f|
        #puts "files under temp folder: "+f
        filepath = File.join(@wince_temp_folder,f)
        if f == '.' or f == '..' or File.directory?(filepath) or File.basename(f) =~ /^test_/ or File.extname(f) == '.csv' or File.extname(f) == '.LOG' then next
        else FileUtils.rm(filepath, {:verbose => true})
        end
      end
    end
  end
  
  def add_log_to_html(log_file_name)
    # add log in result page
    all_lines = ''
    File.open(log_file_name, 'r').each {|line|
      all_lines += line 
    }
    @results_html_file.add_paragraph(all_lines,nil,nil,nil)
  end
  
  def transfer_files(libs_var, libs_root)
    if @test_params.params_chan.instance_variable_defined?(libs_var) && @test_params.instance_variable_defined?(libs_root) #and false  ###### TODO TODO MUST REMOVE 'and false', Added to work around filesystem storage limit error
      src_dir = @test_params.instance_variable_get(libs_root)
      puts "apps source dir set to #{src_dir}"
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        puts "lib filename set to #{lib}"
        put_file({'filename' => lib, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end
  
  def delete_bin(libs_var)
    if @test_params.params_chan.instance_variable_defined?(libs_var)
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        @equipment['dut1'].send_cmd("del #{lib}",@equipment['dut1'].prompt)  
      }
    end
  end
 
  def get_cetk_basic_filenames(cetk_files_dir)
    cetk_basic_files = {'6.0_R3' => 'tux.exe:kato.dll:tooltalk.dll:ktux.dll','7.0' => 'tux.exe:kato.dll:ktux.dll'}    # TODO: return file list based on CE release
    os_version = get_os_version
    return cetk_basic_files[os_version.to_s]
  end 
  
  def translate_module_name(cmdline,platform,mod_name)
    @module_name = {'MSFlash'=>{'am1808'=>'NandFlashDisk','am1707'=>'NandFlashDisk','omapl138'=>'NandFlashDisk','omapl137'=>'NandFlashDisk'}}
    return cmdline if !@module_name.include?(mod_name)
    return cmdline if !@module_name[mod_name].include?(platform)
    return cmdline.gsub(mod_name,@module_name[mod_name][platform])
  end
end