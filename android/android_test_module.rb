
module AndroidTest
    LOG_TAG = "VATF::ANDROID::RESULT::"
    
  def setup
          
      tester_from_cli  = @tester.downcase
      target_from_db   = @test_params.target.downcase
      platform_from_db = @test_params.platform.downcase
      
      nfs_root_path_temp = @equipment['dut1'].nfs_root_path
      
      if @test_params.instance_variable_defined?(:@nfs) 
        fs = @test_params.nfs.gsub(/\\/,'/')
        build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
        nfs_root_path_temp 	= File.join(nfs_root_path_temp, "/autofs/#{build_id}")
        if !@equipment['server1'].file_exists?("#{nfs_root_path_temp}/sys")
          @equipment['server1'].send_cmd("mkdir -p -m 755 #{nfs_root_path_temp}") 		
          @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}; tar -jxvf #{fs}")
        end 		
      end

      nfs_root_path_temp = "#{@equipment['server1'].telnet_ip}:#{nfs_root_path_temp}"
      nfs_root_path_temp = @test_params.var_nfs  if @test_params.instance_variable_defined?(:@var_nfs)  # Optionally use external nfs server
      
      @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
      if @old_keys != @new_keys && @test_params.params_chan.instance_variable_defined?(:@kernel) # call bootscript if required
        boot_params = {'power_handler'=> @power_handler,
                     'platform' => platform_from_db,
                     'tester' => tester_from_cli,
                     'target' => target_from_db ,
                     'image_path' => @test_params.kernel,
                     'server' => @equipment['server1'], 
                     'nfs_root' => nfs_root_path_temp
                     }
        boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
      
        if @equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil
          @equipment['dut1'].connect({'type'=>'serial'})
        elsif @equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil
          @equipment['dut1'].connect({'type'=>'serial'})
        else
          raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
        end
        @equipment['dut1'].boot(boot_params)
        #Wait for android to come-up
        boot_sec = 120
        puts "Waiting #{boot_sec} seconds for android to come-up"
        sleep(boot_sec)
        #Unlocking the screen
    end
    connect_to_equipment()  
    send_adb_cmd("shell input keyevent 82") 
    setupTest(:@test_libs,:@var_test_libs_root)
  end
	
  def clean   
  end
	
  # Send command to an android device
  def send_adb_cmd (cmd, device=@equipment['dut1'])  
    device.send_adb_cmd(cmd)
  end
  
  # Send command to host (TEE) PC
  def send_host_cmd (cmd, device=@equipment['dut1'])  
    device.send_host_cmd(cmd)
  end
    
  # Returns true if named package is installed
  def isPkgInstalled?(pkgName)
    response = send_adb_cmd("shell pm list packages")
    return true if pkgName && /package:#{pkgName}\s+/.match(response)
    return false
  end
    
  #Un-installs android package. Raise error if it can't
  def uninstallPkg(pkgName)
    if isPkgInstalled?(pkgName)
      puts "PACKAGE #{pkgName} is installed. Going to uninstall it"
      send_adb_cmd("uninstall #{pkgName}")
    end
    raise "Could not uninstall PACKAGE: #{pkgName}" if isPkgInstalled?(pkgName)
  end
    
  #Installs android package. Raise error if it can't
  def installPkg(apk,pkgName,force=false, tout=20)
    Timeout::timeout(tout) do
      if pkgName && force && isPkgInstalled?(pkgName)
        uninstallPkg(pkgName)
        send_adb_cmd("install #{apk}") 
      end
      send_adb_cmd("install #{apk}") if !isPkgInstalled?(pkgName)
      raise "Could not install PACKAGE: #{pkgName}" if !isPkgInstalled?(pkgName)
    end
    rescue Timeout::Error => e
      raise "Could not install PACKAGE: #{pkgName}\n"+e.backtrace.to_s
  end

  def setupTest(libs_var, libs_root)
    if @test_params.params_chan.instance_variable_defined?(libs_var)
      src_dir = @test_params.instance_variable_get(libs_root)
      puts "apps source dir set to #{src_dir}"
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        lib_info = lib.split(':')
        installPkg(File.join(src_dir,lib_info[0]), lib_info[1], false)
      }
    end
  end

  def run_test()
    perf_matches = {}
    res_file = nil
    send_adb_cmd "logcat -c"
    send_adb_cmd "shell am instrument -w #{@test_params.params_chan.test_option[0]}"
    log_option = '*:I *:S'
    log_option = @test_params.params_chan.log_option[0] if @test_params.params_chan.instance_variable_defined?(:@log_option)
    response = send_adb_cmd "logcat -d #{log_option}"
    if @test_params.params_chan.instance_variable_defined?(:@res_file)
      puts `mkdir -p #{File.join("../",@test_params.staf_service_name.to_s)} 2>&1`
      res_file = File.join("../",@test_params.staf_service_name.to_s,File.basename(@test_params.params_chan.res_file[0]))
      File.delete(res_file) if File.exist?(res_file)
      send_adb_cmd "pull #{@test_params.params_chan.res_file[0]} #{res_file}"
      res_file = nil if !File.exist?(res_file)
    elsif @test_params.params_chan.instance_variable_defined?(:@perf_matches)
      @test_params.params_chan.perf_matches.each do |current_match|
        perf_matches[current_match] = response.scan(Regexp.new(current_match,Regexp::MULTILINE | Regexp::IGNORECASE))
      end
    end
    {'response' => response, 'perf_data' => perf_matches, 'res_file' => res_file}
  end

  def get_keys
    # keys = @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
    # @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
    # @test_params.microType.to_s + @test_params.configID.to_s
    keys = @test_params.platform.to_s
    keys
  end
  
  def connect_to_equipment(equipment='dut1')
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
      elsif ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.telnet && !this_equipment.target.serial
        raise "You need Telnet or Serial port connectivity to #{equipment}. Please check your bench file" 
      end
    end

end  # End of module

