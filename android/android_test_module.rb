require File.dirname(__FILE__)+'/metrics'
require File.dirname(__FILE__)+'/../lib/plot'
require File.dirname(__FILE__)+'/keyevents_module'

include Metrics
include TestPlots
include AndroidKeyEvents

module AndroidTest
    LOG_TAG = "VATF::ANDROID::RESULT::"
    
  # output params hash in format expected by BootLoader and SystemLoader classes
  def translate_boot_params(params)
    new_params = params.clone
    new_params['dut']        = @equipment['dut1']     if !new_params['dut'] 
    new_params['server']     = @equipment['server1']  if !new_params['server']
    new_params['primary_bootloader'] = new_params['primary_bootloader'] ? new_params['primary_bootloader'] : 
                             @test_params.instance_variable_defined?(:@primary_bootloader) ? @test_params.primary_bootloader : 
                             ''                                
    new_params['secondary_bootloader'] = new_params['secondary_bootloader'] ? new_params['secondary_bootloader'] : 
                             @test_params.instance_variable_defined?(:@secondary_bootloader) ? @test_params.secondary_bootloader : 
                             ''
    new_params['primary_bootloader_dev']   = new_params['primary_bootloader_dev'] ? new_params['primary_bootloader_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_dev) ? @test_params.params_chan.primary_bootloader_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_primary_bootloader_dev) ? @test_params.var_primary_bootloader_dev : 
                             new_params['primary_bootloader'] != '' ? 'uart' : 'none'  
    new_params['secondary_bootloader_dev']   = new_params['secondary_bootloader_dev'] ? new_params['secondary_bootloader_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_dev) ? @test_params.params_chan.secondary_bootloader_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_secondary_bootloader_dev) ? @test_params.var_secondary_bootloader_dev : 
                             new_params['secondary_bootloader'] != '' ? 'eth' : 'none'  
    new_params['kernel']     = new_params['kernel'] ? new_params['kernel'] : 
                             @test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel : 
                             ''                                
    new_params['kernel_dev'] = new_params['kernel_dev'] ? new_params['kernel_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@kernel_dev) ? @test_params.params_chan.kernel_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_kernel_dev) ? @test_params.var_kernel_dev : 
                             new_params['kernel'] != '' ? 'eth' : 'mmc'   
    new_params['kernel_image_name'] = new_params['kernel_image_name'] ? new_params['kernel_image_name'] : 
                             @test_params.instance_variable_defined?(:@var_kernel_image_name) ? @test_params.var_kernel_image_name : 
                             new_params['kernel'] != '' ? File.basename(new_params['kernel']) : 'uImage'                          
    new_params['kernel_modules'] = new_params['kernel_modules'] ? new_params['kernel_modules'] : 
                             @test_params.instance_variable_defined?(:@kernel_modules) ? @test_params.kernel_modules : 
                             ''  
    new_params['dtb']        = new_params['dtb'] ? new_params['dtb'] : 
                             @test_params.instance_variable_defined?(:@dtb) ? @test_params.dtb : 
                             @test_params.instance_variable_defined?(:@dtb_file) ? @test_params.dtb_file : 
                             ''     
    new_params['dtb_dev']    = new_params['dtb_dev'] ? new_params['dtb_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@dtb_dev) ? @test_params.params_chan.dtb_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_dtb_dev) ? @test_params.var_dtb_dev : 
                             new_params['dtb'] != '' ? 'eth' : 'none'   
    new_params['dtb_image_name'] = new_params['dtb_image_name'] ? new_params['dtb_image_name'] : 
                             @test_params.instance_variable_defined?(:@var_dtb_image_name) ? @test_params.var_dtb_image_name : 
                             File.basename(new_params['dtb'])                          
    new_params['fs']         = new_params['fs'] ? new_params['fs'] : 
                             @test_params.instance_variable_defined?(:@fs) ? @test_params.fs : 
                             @test_params.instance_variable_defined?(:@nfs) ? @test_params.nfs : 
                             @test_params.instance_variable_defined?(:@ramfs) ? @test_params.ramfs : 
                             ''                                                          
    new_params['fs_dev']     = new_params['fs_dev'] ? new_params['fs_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@fs_dev) ? @test_params.params_chan.fs_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_fs_dev) ? @test_params.var_fs_dev : 
                             new_params['fs'] != '' ? 'eth' : 'mmc'                                
    new_params['fs_type']    = new_params['fs_type'] ? new_params['fs_type'] : 
                             @test_params.params_chan.instance_variable_defined?(:@fs_type) ? @test_params.params_chan.fs_type[0] : 
                             @test_params.instance_variable_defined?(:@var_fs_type) ? @test_params.var_fs_type : 
                             @test_params.instance_variable_defined?(:@nfs) || @test_params.instance_variable_defined?(:@var_nfs) ? 'nfs' : 
                             @test_params.instance_variable_defined?(:@ramfs) ? 'ramfs' : 
                             'mmcfs'
    new_params['fs_image_name'] = new_params['fs_image_name'] ? new_params['fs_image_name'] : 
                             @test_params.instance_variable_defined?(:@var_fs_image_name) ? @test_params.var_fs_image_name : 
                             new_params['fs_type'] != 'nfs' ? File.basename(new_params['fs']) : ''                             
    new_params
  end
  
  def setup_nfs(params)
    return(nil) if params['fs_type'] != 'nfs'
     
    nfs_root_path_temp  = params['dut'].nfs_root_path
          
    if params['server'].kind_of? LinuxLocalHostDriver
      params['server'].connect({})     # In this case, nothing happens as the server is running locally
    elsif params['server'].respond_to?(:telnet_port) and params['server'].respond_to?(:telnet_ip) and !params['server'].target.telnet
      params['server'].connect({'type'=>'telnet'})
    elsif !params['server'].target.telnet 
          raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
        end
   
    params['server'].send_cmd("mkdir -p #{@linux_temp_folder}", params['server'].prompt)
    if params['fs_type'] == 'nfs' and !params.has_key?('var_nfs')
      fs = params['fs']
      fs.gsub!(/\\/,'/')
      build_id = /\/([^\/\\]+?)\/[\w\.\-]+?$/.match("#{fs.strip}").captures[0]
  params['server'].send_sudo_cmd("mkdir -p -m 777  #{nfs_root_path_temp}/autofs", params['server'].prompt, 10)  if !File.directory?("#{nfs_root_path_temp}/autofs")   
      nfs_root_path_temp 	= nfs_root_path_temp + "/autofs/#{build_id}"
      # Untar nfs filesystem if it doesn't exist
      if !File.directory?("#{nfs_root_path_temp}/sys")
        params['server'].send_sudo_cmd("mkdir -p  #{nfs_root_path_temp}", params['server'].prompt, 10)    
        params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} -jxvf #{fs}", params['server'].prompt, 300)
      end
    end
        
    if params['kernel_modules'] != '' and params['fs_type'] == 'nfs' and !params.has_key?('var_nfs')
      params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} -jxvf #{params['kernel_modules']}", params['server'].prompt, 30)
    end
      
    @samba_root_path_temp = nfs_root_path_temp
    @nfs_root_path_temp   = nfs_root_path_temp
    nfs_root_path_temp = "#{params['server'].telnet_ip}:#{nfs_root_path_temp}"
    nfs_root_path_temp = params['var_nfs']  if params.has_key? 'var_nfs'   # Optionally use external nfs server
    params['nfs_path'] = nfs_root_path_temp
  end
      
  def copy_sw_assets_to_tftproot(params)
    tmp_path = File.join(@tester.downcase.strip, @test_params.target.downcase.strip, @test_params.platform.downcase.strip)
    assets = params.select{|k,v| k.match(/_dev/i) && v.match(/eth/i) }.keys.map{|k| k.match(/(.+)_dev/).captures[0] }
    assets.each do |asset|
      next if  params[asset] == ''
      copy_asset(params['server'], params[asset], File.join(params['server'].tftp_path, tmp_path))
      params[asset+'_image_name'] = File.join(tmp_path, File.basename(params[asset]))
    end
  end

  def copy_asset(server, src, dst_dir)
    if src != dst_dir
      raise "Please specify TFTP path like /tftproot in Linux server in bench file." if server.tftp_path.to_s == ''
      server.send_sudo_cmd("mkdir -p -m 777 #{dst_dir}") if !File.exists?(dst_dir)
      if File.file?(src)
        FileUtils.cp(src, dst_dir)
      else 
        FileUtils.cp_r(File.join(src,'.'), dst_dir)
      end
    end
  end
  
  def setup_host_side
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)    
    
    boot_params = {
       'power_handler'     => @power_handler,
       'platform'          => @test_params.platform.downcase,
       'tester'            => @tester.downcase,
       'target'            => @test_params.target.downcase ,
       'staf_service_name' => @test_params.staf_service_name.to_s
    }
		  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
    boot_params['var_nfs']  = @test_params.var_nfs  if @test_params.instance_variable_defined?(:@var_nfs)

    translated_boot_params = translate_boot_params(boot_params)

    setup_nfs translated_boot_params

    copy_sw_assets_to_tftproot translated_boot_params

    return translated_boot_params
  end
    
  def setup
    translated_boot_params = setup_host_side()
    
    @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
    if @old_keys != @new_keys
	    if !(@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil) && 
         !(@equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil)
      	 raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
      end  
      @equipment['dut1'].boot(translated_boot_params) 
    end
          
    connect_to_equipment()
    send_adb_cmd("shell svc power stayon true") 
    send_events_for('__menu__') 
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
  def installPkg(apk,pkgName,force=false, tout=60)
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

  def run_test(tst_option = nil, wait=true)
    perf_matches = {}
    res_file = nil
    send_adb_cmd "shell rm #{@test_params.params_chan.res_file[0]}" if @test_params.params_chan.instance_variable_defined?(:@res_file)
    if wait
      adb_test_cmd = "shell am instrument -w #{tst_option}"
      adb_test_cmd = "shell am instrument -w #{@test_params.params_chan.test_option[0]}" if !tst_option
    else
      adb_test_cmd = "shell am instrument #{tst_option}"
      adb_test_cmd = "shell am instrument #{@test_params.params_chan.test_option[0]}" if !tst_option
    end
    send_adb_cmd "logcat -c"
    send_adb_cmd adb_test_cmd
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
    keys = @test_params.platform.to_s
    keys
  end
    
  def set_paths(samba, nfs)
    @samba_root_path_temp = samba
    @nfs_root_path_temp   = nfs
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
  
  def install_selenium_server
    response = send_adb_cmd "shell ps"
    if !/org\.openqa\.selenium\.android\.app/m.match(response)
      send_adb_cmd "shell am start -W -n org.openqa.selenium.android.app/.MainActivity --activity-clear-top"
      sleep 5  # Wait for server to start
    end
  end
end  # End of module

