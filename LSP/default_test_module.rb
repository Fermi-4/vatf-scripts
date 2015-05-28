# -*- coding: ISO-8859-1 -*-

#require File.dirname(__FILE__)+'/lsp_constants'
require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/kernel_module_names'
require File.dirname(__FILE__)+'/metrics'
require File.dirname(__FILE__)+'/network_utils'
require File.dirname(__FILE__)+'/../lib/plot'
require File.dirname(__FILE__)+'/../lib/evms_data'

include Metrics
include TestPlots
include EvmData
include NetworkUtils

# Default Server-Side Test script implementation for LSP releases
module LspTestScript 
    class TargetCommand
        attr_accessor :cmd_to_send, :pass_regex, :fail_regex, :ruby_code
    end
    include Boot
    include KernelModuleNames
    public
    
    def LspTestScript.samba_root_path
      @samba_root_path_temp
    end
    
    def LspTestScript.nfs_root_path
      @nfs_root_path_temp
    end
    
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
    new_params['primary_bootloader_src_dev']   = new_params['primary_bootloader_src_dev'] ? new_params['primary_bootloader_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_src_dev) ? @test_params.params_chan.primary_bootloader_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_primary_bootloader_src_dev) ? @test_params.var_primary_bootloader_src_dev : 
                             new_params['primary_bootloader'] != '' ? 'uart' : 'none'  

    new_params['secondary_bootloader_src_dev']   = new_params['secondary_bootloader_src_dev'] ? new_params['secondary_bootloader_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_src_dev) ? @test_params.params_chan.secondary_bootloader_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_secondary_bootloader_src_dev) ? @test_params.var_secondary_bootloader_src_dev : 
                             new_params['secondary_bootloader'] != '' ? 'eth' : 'none'  

    new_params['primary_bootloader_image_name'] = new_params['primary_bootloader_image_name'] ? new_params['primary_bootloader_image_name'] :
                             @test_params.instance_variable_defined?(:@var_primary_bootloader_image_name) ? @test_params.var_primary_bootloader_image_name :
                             new_params['primary_bootloader'] != '' ? File.basename(new_params['primary_bootloader']) : 'MLO'

    new_params['secondary_bootloader_image_name'] = new_params['secondary_bootloader_image_name'] ? new_params['secondary_bootloader_image_name'] :
                             @test_params.instance_variable_defined?(:@var_secondary_bootloader_image_name) ? @test_params.var_secondary_bootloader_image_name :
                             new_params['secondary_bootloader'] != '' ? File.basename(new_params['secondary_bootloader']) : 'u-boot.img'

    new_params['kernel']     = new_params['kernel'] ? new_params['kernel'] : 
                             @test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel : 
                             ''                                
    new_params['kernel_dev'] = new_params['kernel_dev'] ? new_params['kernel_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@kernel_dev) ? @test_params.params_chan.kernel_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_kernel_dev) ? @test_params.var_kernel_dev : 
                             new_params['kernel'] != '' ? 'eth' : 'mmc'   

    new_params['kernel_src_dev'] = new_params['kernel_src_dev'] ? new_params['kernel_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@kernel_src_dev) ? @test_params.params_chan.kernel_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_kernel_src_dev) ? @test_params.var_kernel_src_dev : 
                             new_params['kernel'] != '' ? 'eth' : 'mmc'   

    new_params['kernel_image_name'] = new_params['kernel_image_name'] ? new_params['kernel_image_name'] : 
                             @test_params.instance_variable_defined?(:@var_kernel_image_name) ? @test_params.var_kernel_image_name : 
                             new_params['kernel'] != '' ? File.basename(new_params['kernel']) : 'uImage'                          
    new_params['kernel_modules'] = new_params['kernel_modules'] ? new_params['kernel_modules'] : 
                             @test_params.instance_variable_defined?(:@kernel_modules) ? @test_params.kernel_modules : 
                             ''  
    new_params['skern']     = new_params['skern'] ? new_params['skern'] : 
                             @test_params.instance_variable_defined?(:@skern) ? @test_params.skern : 
                             @test_params.instance_variable_defined?(:@skern_file) ? @test_params.skern_file : 
                             ''                               
    new_params['skern_dev'] = new_params['skern_dev'] ? new_params['skern_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@skern_dev) ? @test_params.params_chan.skern_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_skern_dev) ? @test_params.var_skern_dev : 
                             new_params['skern'] != '' ? 'eth' : 'none'   
    new_params['skern_image_name'] = new_params['skern_image_name'] ? new_params['skern_image_name'] : 
                             @test_params.instance_variable_defined?(:@var_skern_image_name) ? @test_params.var_skern_image_name : 
                             new_params['skern'] != '' ? File.basename(new_params['skern']) : 'skern'                     

    new_params['dtb']        = new_params['dtb'] ? new_params['dtb'] : 
                             @test_params.instance_variable_defined?(:@dtb) ? @test_params.dtb : 
                             @test_params.instance_variable_defined?(:@dtb_file) ? @test_params.dtb_file : 
                             ''     
    new_params['dtb_dev']    = new_params['dtb_dev'] ? new_params['dtb_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@dtb_dev) ? @test_params.params_chan.dtb_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_dtb_dev) ? @test_params.var_dtb_dev : 
                             new_params['dtb'] != '' ? 'eth' : 'none'   

    new_params['dtb_src_dev']    = new_params['dtb_src_dev'] ? new_params['dtb_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@dtb_src_dev) ? @test_params.params_chan.dtb_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_dtb_src_dev) ? @test_params.var_dtb_src_dev : 
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
    new_params['fs_src_dev']     = new_params['fs_src_dev'] ? new_params['fs_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@fs_src_dev) ? @test_params.params_chan.fs_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_fs_src_dev) ? @test_params.var_fs_src_dev : 
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
    # Optional SW asset to copy binary to rootfs                            
    new_params['user_bins']  = new_params['user_bins'] ? new_params['user_bins'] : 
                             @test_params.instance_variable_defined?(:@user_bins) ? @test_params.user_bins : 
                             ''     
    # Optional SW asset with user-defined boot commands
    new_params['boot_cmds']  = new_params['boot_cmds'] ? new_params['boot_cmds'] : 
                             @test_params.instance_variable_defined?(:@boot_cmds) ? @test_params.boot_cmds : 
                             ''     
    new_params = add_dev_loc_to_params(new_params, 'primary_bootloader')
    new_params = add_dev_loc_to_params(new_params, 'secondary_bootloader')
    new_params = add_dev_loc_to_params(new_params, 'kernel')
    new_params = add_dev_loc_to_params(new_params, 'dtb')
    new_params = add_dev_loc_to_params(new_params, 'fs')

    new_params
  end

  def add_dev_loc_to_params(params, part)
    return params if !params["#{part}_dev"]
    return params if params["#{part}_dev"] == 'none'
    
    new_params = params.clone
    case params["#{part}_dev"]
    when 'nand'
      nand_loc = get_nand_loc(@equipment['dut1'].name)
      new_params["nand_#{part}_loc"] = nand_loc["#{part}"]
    when 'spi'
      spi_loc = get_spi_loc(@equipment['dut1'].name)
      new_params["spi_#{part}_loc"] = spi_loc["#{part}"]
    when 'rawmmc'
      rawmmc_loc = get_rawmmc_loc(@equipment['dut1'].name)
      new_params["rawmmc_#{part}_loc"] = rawmmc_loc["#{part}"]
    else
      puts "There is no dev location to be added to params for #{part}_dev: #{params["#{part}_dev"]}"
    end

    return new_params
  end

  def install_kernel_modules(params, nfs_root_path_temp)
    if params['kernel_modules'] != '' and params['fs_type'] == 'nfs' and !params.has_key?('var_nfs')
    elsif params['kernel_modules'] != '' and params['fs_type'] == 'nfs' and params.has_key?('var_nfs')
      if params['var_nfs']. match(/^\d+\.\d+\.\d+\.\d+/).to_s.strip == params['server'].telnet_ip.strip
        nfs_root_path_temp = params['var_nfs'].match(/:(.+)$/).captures[0].to_s
      else
        # Not possible to install modules
        return
      end
    else
      # Not possible to install modules
      return
    end 
    tar_options = get_tar_options(params['kernel_modules'], params)
    params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} #{tar_options} #{params['kernel_modules']}", params['server'].prompt, 30)
  end 

  def setup_nfs(params)
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
      if !File.directory?("#{nfs_root_path_temp}/usr")
        tar_options = get_tar_options(fs,params)
        params['server'].send_sudo_cmd("mkdir -p  #{nfs_root_path_temp}", params['server'].prompt, 10)    
        params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} #{tar_options} #{fs}", params['server'].prompt, 300)
      end
      # Add workaround for touch screen calibration
      pointercal_rule_dst = "#{nfs_root_path_temp}/etc/rc5.d/S90-fake-pointercal"
      if !File.exists?(pointercal_rule_dst)
        pointercal_rule_src = File.join(File.dirname(__FILE__), 'TARGET', 'S90-fake-pointercal')
        params['server'].send_sudo_cmd("cp #{pointercal_rule_src} #{pointercal_rule_dst}", params['server'].prompt, 10)
      end
    end
    
    install_kernel_modules(params, nfs_root_path_temp)    
          
    params['server'].send_sudo_cmd("mkdir -p -m 777 #{nfs_root_path_temp}/test", params['server'].prompt) if !(params.has_key? 'var_nfs')
      
    LspTestScript.set_paths(nfs_root_path_temp, nfs_root_path_temp) 
    nfs_root_path_temp = "#{params['server'].telnet_ip}:#{nfs_root_path_temp}"
    nfs_root_path_temp = params['var_nfs']  if params.has_key? 'var_nfs'   # Optionally use external nfs server
    params['nfs_path'] = nfs_root_path_temp
  end
      
  def get_tar_options(fs,params)
    params['server'].send_cmd("file #{fs}", params['server'].prompt)
    case params['server'].response
    when /gzip/
      tar_options = "-xvzf" 
    when /bzip2/
      tar_options = "-xvjf"
    when /tar archive/i
      tar_options = "-xvf"
    else
      tar_options = "not tar"
    end
    tar_options
  end

  def copy_sw_assets_to_tftproot(params)
    tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
    assets = params.select{|k,v| k.match(/_dev/i) && v.match(/eth/i) }.keys.map{|k| k.match(/(.+?)(?:_src_dev|_dev)/).captures[0] }
    assets.each do |asset|
      next if  params[asset] == ''
      copy_asset(params['server'], params[asset], File.join(params['server'].tftp_path, tmp_path))
      params[asset+'_image_name'] = File.join(tmp_path, File.basename(params[asset])).sub(/^\//,'')
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

  def init_boot_params(params={})
    boot_params = params.merge({
       'power_handler'     => @power_handler,
       'platform'          => @test_params.platform.downcase,
       'tester'            => @tester.downcase,
       'target'            => @test_params.target.downcase ,
       'staf_service_name' => @test_params.staf_service_name.to_s
    })
    boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
    boot_params['var_nfs']  = @test_params.var_nfs  if @test_params.instance_variable_defined?(:@var_nfs)
    boot_params['uboot_user_cmds']  = @test_params.params_control.uboot_user_cmds if @test_params.params_control.instance_variable_defined?(:@uboot_user_cmds)
    boot_params['var_use_default_env']  = @test_params.var_use_default_env  if @test_params.instance_variable_defined?(:@var_use_default_env)
    boot_params['bootargs_append'] = @test_params.var_bootargs_append if @test_params.instance_variable_defined?(:@var_bootargs_append)
    boot_params['bootargs_append'] = @test_params.params_control.bootargs_append[0] if @test_params.params_control.instance_variable_defined?(:@bootargs_append)
    boot_params['bootargs'] = @test_params.var_bootargs if @test_params.instance_variable_defined?(:@var_bootargs)
    boot_params['var_boot_timeout']  = @test_params.var_boot_timeout  if @test_params.instance_variable_defined?(:@var_boot_timeout)
    boot_params
  end
  
  def setup_host_side(params={})
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)    
    @equipment['dut1'].set_api('psp')

    boot_params = init_boot_params(params)

    translated_boot_params = translate_boot_params(boot_params)

    setup_nfs translated_boot_params

    copy_sw_assets_to_tftproot translated_boot_params

    return translated_boot_params
  end

  # modprobe modules specified by @test_params.params_chan.kernel_modules_list.
  # Please note that preferred way is to let udev install modules instead of using this function
  def install_modules(translated_boot_params)
    if translated_boot_params['kernel_modules'].to_s != ''
      @equipment['dut1'].send_cmd("depmod -a", /#{@equipment['dut1'].prompt}/, 30) 
      @equipment['dut1'].send_cmd("lsmod", /#{@equipment['dut1'].prompt}/, 10)
      if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
        @test_params.params_chan.kernel_modules_list.each {|mod|
          mod_name = KernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
          @equipment['dut1'].send_cmd("modprobe #{mod_name}", /#{@equipment['dut1'].prompt}/, 30)  
        }
      end
    end
  end

  def check_dut_booted
    raise "UUT may be hanging!" if !is_uut_up?
    @equipment['dut1'].send_cmd("cat /proc/cmdline", /#{@equipment['dut1'].prompt}/, 10, false)
    @equipment['dut1'].send_cmd("uname -a", /#{@equipment['dut1'].prompt}/, 10, false)
    @equipment['dut1'].send_cmd("cat /proc/mtd", /#{@equipment['dut1'].prompt}/, 10, false)
  end

  # Optionally install binaries provided by user in filesystem 
  def install_user_binaries(params)
    if params['user_bins'] != ''
      @equipment['dut1'].send_cmd("mkdir ~/bin", @equipment['dut1'].prompt, 3)
      @equipment['dut1'].send_cmd("export PATH=\"$PATH:~/bin\"", @equipment['dut1'].prompt, 3)
      @equipment['dut1'].send_cmd("scp #{params['server'].telnet_login}@#{params['server'].telnet_ip}:#{params['user_bins']} ~/bin/",
                                  /(continue connecting|password:|#{@equipment['dut1'].prompt})/, 60, false)
      if @equipment['dut1'].response.match(/continue connecting/)
        @equipment['dut1'].send_cmd("y", /(password:|#{@equipment['dut1'].prompt})/, 5, false)
      end
      if @equipment['dut1'].response.match(/password:/)
        @equipment['dut1'].send_cmd("#{params['server'].telnet_passwd}", @equipment['dut1'].prompt, 60, false)
      end
      raise "Could not install user binaries #{params['user_bins']}" if !@equipment['dut1'].response.match(@equipment['dut1'].prompt)
      tar_options = get_tar_options(params['user_bins'], params)
      if tar_options != 'not tar'
        filename = File.basename(params['user_bins'])
        @equipment['dut1'].send_cmd("cd ~/bin; tar #{tar_options} #{filename}", @equipment['dut1'].prompt, 30)
      end
    end
  end
  
  def setup
    translated_boot_params = setup_host_side()
    
    @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
    @new_keys = (@test_params.params_control.instance_variable_defined?(:@booargs_append))? (@new_keys + @test_params.params_control.bootargs_append[0]) : @new_keys
    if boot_required?(@old_keys, @new_keys) #&& translated_boot_params['kernel'] != ''
      if !(@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil) && 
      !(@equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil)
        raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
      end
      
      boot_attempts = 1
      boot_attempts = @test_params.var_boot_attempts.to_i if @test_params.instance_variable_defined?(:@var_boot_attempts)
      boot_attempts.times do |trial|
        begin
          @equipment['dut1'].boot(translated_boot_params)
          break
        rescue Exception => e
          puts "Boot attempt #{trial} failed, trying again....."
          raise e if trial == boot_attempts - 1
        end
      end 
    end
    
    connect_to_equipment('dut1')
    check_dut_booted()
    install_modules(translated_boot_params)
    install_user_binaries(translated_boot_params)
  end
    
    def run      
        puts "default.run"
        commands = ensure_commands = ""
        commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
        ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
        result, cmd = execute_cmd(commands)
        if result == 0 
            set_result(FrameworkConstants::Result[:pass], "Test Pass.")
        elsif result == 1
            set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
        elsif result == 2
            set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
        else
            set_result(FrameworkConstants::Result[:nry])
        end
        ensure 
            result, cmd = execute_cmd(ensure_commands) if ensure_commands !=""
    end
    
    def clean
      puts "\nLspTestScript::clean"
      if @test_result.result == FrameworkConstants::Result[:fail] or @test_result.result == FrameworkConstants::Result[:nry]
        query_debug_data
      end
      kernel_modules = @test_params.kernel_modules   if @test_params.instance_variable_defined?(:@kernel_modules)
      if kernel_modules
        #kernel_modules_list = @test_params.params_chan.kernel_modules_list  
        if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
          @test_params.params_chan.kernel_modules_list.each {|mod|
            mod_name = KernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
            @equipment['dut1'].send_cmd("rmmod #{mod_name}", /#{@equipment['dut1'].prompt}/, 30)  
          }
        end
      end
    end
    
    # Returns string with <chan_params_name>=<chan_params_value>[,...] format that can be passed to .runltp
    def get_params
        params_arr = []
        @test_params.params_chan.instance_variables.each {|var|
        	params_arr << var.sub("@","")+"="+@test_params.params_chan.instance_variable_get(var).to_s+","	   
       	}
       	params = params_arr.to_s.sub!(/,$/,'')
    end

    def parse_cmd(var_name)
        target_commands = []
        cmds = @test_params.params_chan.instance_variable_get("@#{var_name}")
        cmds.each {|cmd|
            cmd.strip!
            target_cmd = TargetCommand.new
            if /^\[/.match(cmd)
                # ruby code
                target_cmd.ruby_code = cmd.strip.sub(/^\[/,'').sub(/\]$/,'')
            else
                # substitute matrix variables
                if cmd.scan(/[^\\]\{(\w+)\}/).size > 0
                    cmd = cmd.gsub!(/[^\\]\{(\w+)\}/) {|match|
                        match[0,1] + @test_params.params_chan.instance_variable_get("@#{match[1,match.size].gsub(/\{|\}/,'')}").to_s
                    }
                end
                # get command to send
                m = /[^\\]`(.+)[^\\]`$/.match(cmd)
                if m == nil     # No expected-response specified
                    target_cmd.cmd_to_send = cmd
                    target_commands << target_cmd
                    next
                else
                    target_cmd.cmd_to_send = m.pre_match+cmd[m.begin(0),1]
                end
                # get expected response
                pass_regex_specified = fail_regex_specified = false
                response_regex = m[1] + cmd[m.end(0)-2,1]
                m = /\+\+/.match(response_regex)
                (m == nil) ? (pass_regex_specified = false) : (pass_regex_specified = true)
                m = /\-\-/.match(response_regex)
                (m == nil) ? (fail_regex_specified = false) : (fail_regex_specified = true)
                m = /^\+\+/.match(response_regex)
                if m == nil 	# Starts with --fail response 
                    if pass_regex_specified
                        target_cmd.fail_regex = /^\-\-(.+)\+\+/.match(response_regex)[1]
                        target_cmd.pass_regex = /\+\+(.+)$/.match(response_regex)[1] 
                    else
                        target_cmd.fail_regex = /^\-\-(.+)$/.match(response_regex)[1]
                    end
                else		# Starts with ++pass response
                    if fail_regex_specified
                        target_cmd.pass_regex = /^\+\+(.+)\-\-/.match(response_regex)[1]
                        target_cmd.fail_regex = /\-\-(.+)$/.match(response_regex)[1] 
                    else
                        target_cmd.pass_regex = /^\+\+(.+)$/.match(response_regex)[1]
                    end
                end
            end
            target_commands << target_cmd
        }
        target_commands
    end
    
    def execute_cmd(commands)
        last_cmd = nil
        result = 0 	#0=pass, 1=timeout, 2=fail message detected 
        dut_timeout = 10
        vars = Array.new
        commands.each {|cmd|
            last_cmd = cmd
            if cmd.ruby_code 
                eval cmd.ruby_code
            else
                cmd.pass_regex =  /#{@equipment['dut1'].prompt.source}/m if !cmd.instance_variable_defined?(:@pass_regex)
                if !cmd.instance_variable_defined?(:@fail_regex)
                    expect_regex = "(#{cmd.pass_regex})"
                else
                    expect_regex = "(#{cmd.pass_regex}|#{cmd.fail_regex})"
                end
                regex = Regexp.new(expect_regex)                                                
                @equipment['dut1'].send_cmd(cmd.cmd_to_send, regex, dut_timeout)
                if @equipment['dut1'].timeout?
                    result = 1
                    break 
                elsif cmd.instance_variable_defined?(:@fail_regex) && Regexp.new(cmd.fail_regex).match(@equipment['dut1'].response)
                    result = 2
                    break
                end
            end
        }
        [result , last_cmd]
    end
    
    def get_keys
      keys = @test_params.platform.to_s
      keys
    end
    
    def set_paths(samba, nfs)
      @samba_root_path_temp = samba
      @nfs_root_path_temp   = nfs
    end
    
    def connect_to_equipment(equipment, connection_type=nil)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet && connection_type != 'serial'
        this_equipment.connect({'type'=>'telnet'})
      elsif ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        puts "Connecting to SERIAL console"
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.telnet && !this_equipment.target.serial
        raise "You need Telnet or Serial port connectivity to #{equipment}. Please check your bench file" 
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

  # Start collecting system metrics (i.e. cpu load, mem load)
  def run_start_stats
    begin
      # Dont collect stats if user asked so
      return if @test_params.instance_variable_defined?(:@var_test_no_stats)

      @eth_ip_addr = get_ip_addr()
      if @eth_ip_addr
        connect_to_telnet(@eth_ip_addr)
        @equipment['dut1'].target.telnet.send_cmd("pwd", @equipment['dut1'].prompt , 3)    
        @collect_stats = @test_params.params_control.collect_stats[0] if @test_params.params_control.instance_variable_defined?(:@collect_stats)
        @collect_stats_interval = @test_params.params_control.collect_stats_interval[0].to_i if @test_params.params_control.instance_variable_defined?(:@collect_stats_interval)
        start_collecting_stats(@collect_stats, @collect_stats_interval) do |cmd| 
          if cmd
            @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
            @equipment['dut1'].target.telnet.response
          end
        end
      end
    rescue Exception => e
      report_msg "WARNING: Could not start collecting stats due to error trying to telnet to DUT"
    end
  end
  
  # Stop collecting system metrics 
  def run_stop_stats
    begin
      # Dont stop stats if user asked not to collect in the first place.
      return if @test_params.instance_variable_defined?(:@var_test_no_stats)

      @eth_ip_addr = get_ip_addr()
      if @eth_ip_addr
        @equipment['dut1'].disconnect('telnet') if @equipment['dut1'].target.telnet
        connect_to_telnet(@eth_ip_addr)
        @target_sys_stats = stop_collecting_stats(@collect_stats) do |cmd| 
          if cmd
            @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
            @equipment['dut1'].target.telnet.response
          end
        end
      end
    rescue Exception => e
      report_msg "WARNING: Could not stop collecting stats due to error trying to telnet to DUT"
    end
  end

  def connect_to_telnet(eth_ip_addr, e='dut1')
    return if !@equipment.key?(e)
    this_equipment = @equipment[e]
    old_telnet_ip = this_equipment.target.platform_info.telnet_ip
    this_equipment.target.platform_info.telnet_ip = eth_ip_addr
    old_telnet_port = this_equipment.target.platform_info.telnet_port
    this_equipment.target.platform_info.telnet_port = 23
    this_equipment.connect({'type'=>'telnet'})
    this_equipment.target.platform_info.telnet_ip = old_telnet_ip
    this_equipment.target.platform_info.telnet_port = old_telnet_port
  end

  def query_debug_data(e='dut1')
    return if !@equipment.key?(e)
    this_equipment = @equipment[e]
    if is_uut_up?
      this_equipment.send_cmd("echo '=====================';echo 'START DEBUG DATA';echo '====================='", this_equipment.prompt)
      this_equipment.send_cmd("dmesg", this_equipment.prompt)
      this_equipment.send_cmd("cat /var/log/messages", this_equipment.prompt)
      this_equipment.send_cmd("which omapconf && omapconf --cpuinfo", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/cpuinfo", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/meminfo", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/devices", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/diskstats", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/interrupts", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/modules", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/schedstat", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/softirqs", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/stat", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/uptime", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/version", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/vmstat", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/zoneinfo", this_equipment.prompt)
      this_equipment.send_cmd("cat /proc/net/snmp", this_equipment.prompt)
    end
  end

   
  # export ltp-ddt path so the script/function can be called from vatf-script
  def export_ltppath
    ltppath = '/opt/ltp'
    if !dut_dir_exist?(ltppath+"/testcases/bin/ddt")
      raise "LTP-DDT is not in the file sytem. Please install LTP-DDT into the target filesystem"
    end
    @equipment['dut1'].send_cmd("export LTPPATH=/opt/ltp", @equipment['dut1'].prompt, 20)
    cmd = "export PATH=\"${PATH}:${LTPPATH}/testcases/bin\"$( find ${LTPPATH}/testcases/bin/ddt -type d -exec printf \":\"{} \\; )"
    @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo $PATH", @equipment['dut1'].prompt, 10)

  end

  # check if directory or file exist in dut target
  def dut_dir_exist?(directory)
    @equipment['dut1'].send_cmd("ls #{directory} > /dev/null", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    !@equipment['dut1'].timeout?
  end

  def save_dut_orig_path()
    @equipment['dut1'].send_cmd("echo $PATH", @equipment['dut1'].prompt, 10)
    dut_orig_path = @equipment['dut1'].response.match(/^\/.*/)
  end

  def restore_dut_path(dut_orig_path)
    @equipment['dut1'].send_cmd("export PATH=#{dut_orig_path} ", @equipment['dut1'].prompt, 10)
  end

  def kill_process(process,opts={})
    this_equipment = opts[:this_equipment] || @equipment['dut1']
    use_sudo = opts[:use_sudo] || false 
    if (use_sudo)
      this_equipment.send_sudo_cmd("kill `ps aux | grep #{process} | grep -v grep | awk '{print $2}'`", this_equipment.prompt, 10)
    else
      this_equipment.send_cmd("kill `ps aux | grep #{process} | grep -v grep | awk '{print $2}'`", this_equipment.prompt, 10)
    end  
  end

  # Preserve current governor
  def create_save_cpufreq_governors
    @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
    previous_govs = @equipment['dut1'].response.scan(/^\w+\s*$/)
  end


 # Change to specified governor
  def enable_cpufreq_governor(type='performance')
    @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do echo -n #{type} > /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    raise "#{type} governor is not available" if @equipment['dut1'].timeout?
    @equipment['dut1'].send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              @equipment['dut1'].prompt)
 end

 # Restore previous governor
  def restore_cpufreq_governors(previous_govs)
    previous_govs.each_with_index{|v,i|
       v.gsub!(/\s*/,'')
       @equipment['dut1'].send_cmd("echo -n #{v} > /sys/devices/system/cpu/cpu#{i}/cpufreq/scaling_governor", @equipment['dut1'].prompt)
    }
  end

  # Return decimal value from address
  def read_address(address, from_kernel=true, e='dut1')
    raise "equipment #{e} does not exist" if !@equipment.key?(e)
    if from_kernel
      @equipment[e].send_cmd("which devmem2; echo $?", /^0/)
      raise "devmem2 is not available" if @equipment[e].timeout?
      @equipment[e].send_cmd("devmem2 #{address}", @equipment[e].prompt)
      return @equipment[e].response.match(/Read at address  #{address} .+:\s*([x0-f]+)/i).captures[0].hex
    else
      @equipment[e].send_cmd("md.l #{address} 1", @equipment[e].boot_prompt, 2)
      return @equipment[e].response.match(/#{address.gsub(/^0x/i,'')}:\s*([0-f]+)/i).captures[0].hex
    end
  end

  # Instantiate and connect to equipment accessible from another equipment bench params definitions
  # Typical case is accessing multimeter equipment that is defined in the DUT bench params section
  def add_child_equipment(child_name, father_name='dut1')
    # Add Equipment to result logs
    equip = @equipment[father_name].params[child_name]
    conn_type = equip.params && equip.params.has_key?('conn_type') ? equip.params['conn_type'] : 'serial'
    add_equipment(child_name) do |log_path|
      Object.const_get(equip.driver_class_name).new(equip,log_path)
    end
    # Connect to equip
    @equipment[child_name].connect({'type'=>conn_type})
  end
  
  # Returns true if command return value is 0
  def check_cmd?(cmd, equip=@equipment['dut1'], timeout=10)
    equip.send_cmd("#{cmd} > /dev/null", equip.prompt, timeout)
    if equip.is_a?(LinuxLocalHostDriver)
      return  $? == 0
    else 
      equip.send_cmd("echo $?",/^0[\n\r]*/m, 2)
      return !equip.timeout?
    end
  end

  # Returns true if module is running.
  def module_running?(module_name, equip=@equipment['dut1'])
    check_cmd?("lsmod | grep '#{module_name}'", equip)
  end

  def process_running?(this_equipment=@equipment['dut1'],process)
    this_equipment.send_cmd("ps aux | grep '#{process}' | grep -v grep", this_equipment.prompt, 10)
    this_equipment.response.match(/\d+\s+\d+\.\d+\s+\d+\.\d+/) ? true : false
  end
   
  def report_msg(msg, e='dut1')
    puts msg
    @equipment[e].log_info(msg)
  end
end

