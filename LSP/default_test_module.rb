# -*- coding: ISO-8859-1 -*-
# -*- coding: ISO-8859-1 -*-

#require File.dirname(__FILE__)+'/lsp_constants'
require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/kernel_module_names'
require File.dirname(__FILE__)+'/metrics'
require File.dirname(__FILE__)+'/network_utils'
require File.dirname(__FILE__)+'/../lib/plot'
require File.dirname(__FILE__)+'/../lib/evms_data'
require File.dirname(__FILE__)+'/lsp_helpers'
require File.dirname(__FILE__)+'/update_mmc'
require File.dirname(__FILE__)+'/known_linux_problems'

include Metrics
include TestPlots
include EvmData
include NetworkUtils
include LspHelpers
include UpdateMMC
include KnownLinuxProblems

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
                             @test_params.instance_variable_defined?(:@var_primary_bootloader_dev) ? @test_params.var_primary_bootloader_dev : "mmc"
    new_params['secondary_bootloader_dev']   = new_params['secondary_bootloader_dev'] ? new_params['secondary_bootloader_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_dev) ? @test_params.params_chan.secondary_bootloader_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_secondary_bootloader_dev) ? @test_params.var_secondary_bootloader_dev : "mmc"
    new_params['primary_bootloader_src_dev']   = new_params['primary_bootloader_src_dev'] ? new_params['primary_bootloader_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_src_dev) ? @test_params.params_chan.primary_bootloader_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_primary_bootloader_src_dev) ? @test_params.var_primary_bootloader_src_dev : 
                             new_params['primary_bootloader'] != '' ? 'uart' : 'none'  

    new_params['secondary_bootloader_src_dev']   = new_params['secondary_bootloader_src_dev'] ? new_params['secondary_bootloader_src_dev'] : 
                             @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_src_dev) ? @test_params.params_chan.secondary_bootloader_src_dev[0] : 
                             @test_params.instance_variable_defined?(:@var_secondary_bootloader_src_dev) ? @test_params.var_secondary_bootloader_src_dev : 
                             new_params['secondary_bootloader'] != '' ? 'uart' : 'none'

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
    new_params['initramfs'] = new_params['initramfs'] ? new_params['initramfs'] :
                             @test_params.instance_variable_defined?(:@initramfs) ? @test_params.initramfs :
                             @test_params.instance_variable_defined?(:@initramfs_file) ? @test_params.initramfs_file :
                             ''
    new_params['initramfs_dev'] = new_params['initramfs_dev'] ? new_params['initramfs_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@initramfs_dev) ? @test_params.params_chan.initramfs_dev[0] :
                             @test_params.instance_variable_defined?(:@var_initramfs_dev) ? @test_params.var_initramfs_dev :
                             new_params['initramfs'] != '' ? 'eth' : 'none'
    new_params['initramfs_image_name'] = new_params['initramfs_image_name'] ? new_params['initramfs_image_name'] :
                             @test_params.instance_variable_defined?(:@var_initramfs_image_name) ? @test_params.var_initramfs_image_name :
                             new_params['initramfs'] != '' ? File.basename(new_params['initramfs']) : 'initramfs'
    new_params['pmmc']     = new_params['pmmc'] ? new_params['pmmc'] :
                             @test_params.instance_variable_defined?(:@pmmc) ? @test_params.pmmc :
                             @test_params.instance_variable_defined?(:@pmmc_file) ? @test_params.pmmc_file :
                             ''
    new_params['pmmc_dev'] = new_params['pmmc_dev'] ? new_params['pmmc_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@pmmc_dev) ? @test_params.params_chan.pmmc_dev[0] :
                             @test_params.instance_variable_defined?(:@var_pmmc_dev) ? @test_params.var_pmmc_dev :
                             new_params['pmmc'] != '' ? 'eth' : 'none'
    new_params['pmmc_image_name'] = new_params['pmmc_image_name'] ? new_params['pmmc_image_name'] :
                             @test_params.instance_variable_defined?(:@var_pmmc_image_name) ? @test_params.var_pmmc_image_name :
                             new_params['pmmc'] != '' ? File.basename(new_params['pmmc']) : 'pmmc'
    new_params['fit']     = new_params['fit'] ? new_params['fit'] :
                             @test_params.instance_variable_defined?(:@fit) ? @test_params.fit :
                             @test_params.instance_variable_defined?(:@fit_file) ? @test_params.fit_file :
                             ''
    new_params['fit_dev'] = new_params['fit_dev'] ? new_params['fit_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@fit_dev) ? @test_params.params_chan.fit_dev[0] :
                             @test_params.instance_variable_defined?(:@var_fit_dev) ? @test_params.var_fit_dev :
                             new_params['fit'] != '' ? 'eth' : 'none'
    new_params['fit_image_name'] = new_params['fit_image_name'] ? new_params['fit_image_name'] :
                             @test_params.instance_variable_defined?(:@var_fit_image_name) ? @test_params.var_fit_image_name :
                             new_params['fit'] != '' ? File.basename(new_params['fit']) : 'fit'

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
                             @test_params.instance_variable_defined?(:@var_fs_dev) ? @test_params.var_fs_dev : 'mmc'                                
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
    new_params['ubi_root'] = new_params['ubi_root'] ? new_params['ubi_root'] :
                             @test_params.instance_variable_defined?(:@var_ubi_root) ? @test_params.var_ubi_root :
                             "ubi0:rootfs" 
    new_params['skip_touchcal'] = new_params['skip_touchcal'] ? new_params['skip_touchcal'] :
                             @test_params.params_chan.instance_variable_defined?(:@skip_touchcal) ? @test_params.params_chan.skip_touchcal[0] :
                             @test_params.instance_variable_defined?(:@var_skip_touchcal) ? @test_params.var_skip_touchcal :
                             "0"

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

    new_params['dut'].prompt =  /#{@test_params.var_fs_prompt}/ if @test_params.instance_variable_defined?(:@var_fs_prompt)

    new_params
  end

  def add_dev_loc_to_params(params, part)
    return params if !params["#{part}_dev"]
    return params if params["#{part}_dev"] == 'none'
    
    new_params = params.clone
    case params["#{part}_dev"]
    when 'nand'
      nand_loc = get_nand_loc(params['dut'].name)
      new_params["nand_#{part}_loc"] = nand_loc["#{part}"]
    when 'spi'
      spi_loc = get_spi_loc(params['dut'].name)
      new_params["spi_#{part}_loc"] = spi_loc["#{part}"]
    when 'qspi'
      spi_loc = get_qspi_loc(params['dut'].name)
      new_params["spi_#{part}_loc"] = spi_loc["#{part}"]
    when /rawmmc/
      rawmmc_loc = get_rawmmc_loc(params['dut'].name)
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

  def copy_sw_assets_to_tftproot(params)
    tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
    assets = params.select{|k,v| k.match(/_dev/i) && v.match(/eth/i) }.keys.map{|k| k.match(/(.+?)(?:_src_dev|_dev)/).captures[0] }
    assets.each do |asset|
      next if  (params[asset] == '' or (params['host_side_mmc_update'] and asset == 'fs'))
      copy_asset(params['server'], params[asset], File.join(params['server'].tftp_path, tmp_path))
      params[asset+'_image_name'] = File.join(tmp_path, File.basename(params[asset])).sub(/^\//,'')
    end
  end

  def init_boot_params(params={})
    boot_params = params.merge({'platform' => @test_params.platform.downcase}) if !params.has_key?("platform")
    boot_params = params.merge({
       'power_handler'     => @power_handler,
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
    boot_params['autologin'] = @test_params.var_autologin if @test_params.instance_variable_defined?(:@var_autologin)
    boot_params
  end
  
  def setup_host_side(params={})
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)    
    params['dut'] = @equipment['dut1'] if !params['dut']
    params['dut'].set_api('psp')

    boot_params = init_boot_params(params)

    translated_boot_params = translate_boot_params(boot_params)

    setup_nfs translated_boot_params
    copy_sw_assets_to_tftproot translated_boot_params

    return translated_boot_params
  end

  # modprobe modules specified by @test_params.params_chan.kernel_modules_list.
  # Please note that preferred way is to let udev install modules instead of using this function
  def install_modules(params)
    params['dut'] = @equipment['dut1'] if !params['dut']
    if params['kernel_modules'].to_s != ''
      params['dut'].send_cmd("depmod -a", /#{params['dut'].prompt}/, 120) 
      params['dut'].send_cmd("lsmod", /#{params['dut'].prompt}/, 10)
      if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
        @test_params.params_chan.kernel_modules_list.each {|mod|
          mod_name = KernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
          params['dut'].send_cmd("modprobe #{mod_name}", /#{params['dut'].prompt}/, 30)  
        }
      end
    end
  end

  def check_dut_booted(params)
    params['dut'] = @equipment['dut1'] if !params['dut']
    raise "UUT may be hanging!" if !is_uut_up?(params['dut'])
    params['dut'].send_cmd("cat /proc/cmdline", /#{params['dut'].prompt}/, 10, false)
    params['dut'].send_cmd("uname -a", /#{params['dut'].prompt}/, 10, false)
    params['dut'].send_cmd("cat /proc/mtd", /#{params['dut'].prompt}/, 10, false)
  end

  # Optionally install binaries provided by user in filesystem 
  def install_user_binaries(params)
    params['dut'] = @equipment['dut1'] if !params['dut']
    if params['user_bins'] != ''
      params['dut'].send_cmd("mkdir ~/bin", params['dut'].prompt, 3)
      params['dut'].send_cmd("export PATH=\"$PATH:~/bin\"", params['dut'].prompt, 3)
      params['dut'].send_cmd("scp #{params['server'].telnet_login}@#{params['server'].telnet_ip}:#{params['user_bins']} ~/bin/",
                                  /(continue connecting|password:|#{params['dut'].prompt})/, 60, false)
      if params['dut'].response.match(/continue connecting/)
        params['dut'].send_cmd("y", /(password:|#{params['dut'].prompt})/, 5, false)
      end
      if params['dut'].response.match(/password:/)
        params['dut'].send_cmd("#{params['server'].telnet_passwd}", params['dut'].prompt, 60, false)
      end
      raise "Could not install user binaries #{params['user_bins']}" if !params['dut'].response.match(params['dut'].prompt)
      tar_options = get_tar_options(params['user_bins'], params)
      if tar_options != 'not tar'
        filename = File.basename(params['user_bins'])
        params['dut'].send_cmd("cd ~/bin; tar #{tar_options} #{filename}", params['dut'].prompt, 30)
      end
    end
  end

  def boot_dut(params)
    params['dut'] = @equipment['dut1'] if !params['dut'] 
    @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
    @new_keys = (@test_params.params_control.instance_variable_defined?(:@booargs_append))? (@new_keys + @test_params.params_control.bootargs_append[0]) : @new_keys
    if boot_required?(@old_keys, @new_keys) #&& params['kernel'] != ''
      if !(params['dut'].respond_to?(:serial_port) && params['dut'].serial_port != nil) && 
      !(params['dut'].respond_to?(:serial_server_port) && params['dut'].serial_server_port != nil)
        raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
      end
      
      boot_attempts = 1
      boot_attempts = @test_params.var_boot_attempts.to_i if @test_params.instance_variable_defined?(:@var_boot_attempts) and @test_params.var_boot_attempts.to_i > 0
      boot_attempts.times do |trial|
        begin
          params['dut'].boot(params)
          params['dut'].log_info("Sleeping 15 secs to allow systemd to finish starting processes...")
          sleep 15
          break
        rescue Exception => e
          fail_str = (trial == boot_attempts - 1) ? "Boot attempt #{trial + 1}/#{boot_attempts} failed" : \
          "Boot attempt #{trial + 1}/#{boot_attempts} failed, trying again....."
          puts fail_str
          params['dut'].log_info(fail_str)
          if trial == boot_attempts -1
            #check for known Linux problems
            new_e = Exception.new(e.inspect+"\n"+check_for_known_problem(params['dut']))
            new_e.set_backtrace(e.backtrace)
            # when board failed to boot, trigger sysrq to provide kernel trace
            params['dut'].log_info("Collecting kernel traces via sysrq...")
            params['dut'].send_sysrq('t')
            params['dut'].send_sysrq('l')
            params['dut'].send_sysrq('w')
            raise new_e
          end
        ensure
          params['dut'].disconnect('serial') if params['dut'].target.serial
          params['dut'].disconnect('bmc') if params['dut'].target.bmc
        end
      end 
    end
    params
  end

  def setup
    @equipment.select{|k| k.match(/dut/i)}.keys.each {|device|
      setup_boards(device, {})
    }
  end
 
  def setup_boards(device_name='dut1', params={})
    device_object = @equipment[device_name]
    device_object.set_api('psp')
    update_mmc = @test_params.instance_variable_defined?(:@var_update_mmc)? @test_params.var_update_mmc : "0"
    host_side_mmc_update = (update_mmc != '0' and device_object.params.has_key?("microsd_switch"))
    params = params.merge({'host_side_mmc_update' => host_side_mmc_update})
    params['dut'] = device_object
    translated_boot_params = setup_host_side(params)

    if host_side_mmc_update
        begin
            translated_boot_params = flash_sd_card_from_host(translated_boot_params)
        rescue Exception => e
            report_msg "Failed to update SD card from host"
            raise e
        end
    end

    boot_dut(translated_boot_params)

    connect_to_equipment(device_name)
    check_dut_booted(params)
    device_object.send_cmd(@test_params.var_post_boot_cmd, device_object.prompt, 60) if @test_params.instance_variable_defined?(:@var_post_boot_cmd)
    query_start_stats(device_name)

    if update_mmc != '0' and !host_side_mmc_update
      call_setup = false

      report_msg "Check if bootloader in MMC needs to be updated ..."
      if translated_boot_params.has_key?('primary_bootloader') \
         && translated_boot_params.has_key?('secondary_bootloader')\
         && need_update_mmcbootloader?(translated_boot_params)
        report_msg "Updating bootloader in MMC ..."
        update_mmcbootloader translated_boot_params
        report_msg "Donw with updating bootloader in MMC!"
        call_setup = true
      end

      report_msg "Check if rootfs in MMC needs to be updated ..."
      if translated_boot_params.has_key?('fs') && need_update_mmcfs?(translated_boot_params)
        report_msg "Updating rootfs in MMC ..."
        update_mmcfs translated_boot_params
        report_msg "Donw with updating rootfs in MMC!"
        call_setup = true
      end
      if call_setup
        device_object.system_loader = nil
        setup_boards(device_name, translated_boot_params)
      end
    end

    install_modules(translated_boot_params)
    install_user_binaries(translated_boot_params)
  end
    
    def run      
        puts "default.run"
        commands = ensure_commands = ""
        commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
        ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
        cmd_timeout = @test_params.params_chan.instance_variable_defined?(:@timeout) ? @test_params.params_chan.timeout[0].to_i : 10
        result, cmd = execute_cmd(commands, cmd_timeout)
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
      clean_boards()
    end

    def clean_boards(device_name='dut1')
      puts "\nLspTestScript::clean"
      device_object = @equipment[device_name]
      if @test_result.result == FrameworkConstants::Result[:fail] or @test_result.result == FrameworkConstants::Result[:nry]
        query_debug_data device_object
      end
      kernel_modules = @test_params.kernel_modules   if @test_params.instance_variable_defined?(:@kernel_modules)
      if kernel_modules
        if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
          @test_params.params_chan.kernel_modules_list.each {|mod|
            mod_name = KernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
            device_object.send_cmd("rmmod #{mod_name}", /#{device_object.prompt}/, 30)  
          }
        end
      end
      device_object.reset_sysboot(device_object)
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
    
    def execute_cmd(commands, dut_timeout=10, device_object=@equipment['dut1'])
        last_cmd = nil
        result = 0 	#0=pass, 1=timeout, 2=fail message detected 
        vars = Array.new
        commands.each {|cmd|
            last_cmd = cmd
            if cmd.ruby_code 
                eval cmd.ruby_code
            else
                cmd.pass_regex =  /#{device_object.prompt.source}/m if !cmd.instance_variable_defined?(:@pass_regex)
                if !cmd.instance_variable_defined?(:@fail_regex)
                    expect_regex = "(#{cmd.pass_regex})"
                else
                    expect_regex = "(#{cmd.pass_regex}|#{cmd.fail_regex})"
                end
                regex = Regexp.new(expect_regex)                                                
                device_object.send_cmd(cmd.cmd_to_send, regex, dut_timeout)
                if device_object.timeout?
                    result = 1
                    break 
                elsif cmd.instance_variable_defined?(:@fail_regex) && Regexp.new(cmd.fail_regex).match(device_object.response)
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
      return if File.size?(log_file_name) > 25000 # Don't write to main result pages too much data to avoid high download time
      all_lines = ''
      File.open(log_file_name, 'r').each {|line|
        all_lines += line 
      }
      @results_html_file.add_paragraph(all_lines,nil,nil,nil)
    end

  # Start collecting system metrics (i.e. cpu load, mem load)
  def run_start_stats(device_object=@equipment['dut1'])
    begin
      # Dont collect stats if user asked so
      return if @test_params.instance_variable_defined?(:@var_test_no_stats)

      @eth_ip_addr = get_ip_addr()
      if @eth_ip_addr
        connect_to_telnet(@eth_ip_addr)
        device_object.target.telnet.send_cmd("pwd", device_object.prompt , 3)    
        @collect_stats = @test_params.params_control.collect_stats[0] if @test_params.params_control.instance_variable_defined?(:@collect_stats)
        @collect_stats_interval = @test_params.params_control.collect_stats_interval[0].to_i if @test_params.params_control.instance_variable_defined?(:@collect_stats_interval)
        start_collecting_stats(@collect_stats, @collect_stats_interval) do |cmd| 
          if cmd
            device_object.target.telnet.send_cmd(cmd, device_object.prompt, 10, true)
            device_object.target.telnet.response
          end
        end
      end
    rescue Exception => e
      report_msg "WARNING: Could not start collecting stats due to error trying to telnet to DUT"
    end
  end
  
  # Stop collecting system metrics 
  def run_stop_stats(device_object=@equipment['dut1'])
    begin
      # Dont stop stats if user asked not to collect in the first place.
      return if @test_params.instance_variable_defined?(:@var_test_no_stats)

      @eth_ip_addr = get_ip_addr()
      if @eth_ip_addr
        device_object.disconnect('telnet') if device_object.target.telnet
        connect_to_telnet(@eth_ip_addr)
        @target_sys_stats = stop_collecting_stats(@collect_stats) do |cmd| 
          if cmd
            device_object.target.telnet.send_cmd(cmd, device_object.prompt, 10, true)
            device_object.target.telnet.response
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

  def query_start_stats(e='dut1')
    return if !@equipment.key?(e)
    this_equipment = @equipment[e]
    this_equipment.send_cmd("ls -l /lib/firmware; ls -lR /lib/firmware/ipc", this_equipment.prompt)
    this_equipment.send_cmd("cat /proc/diskstats", this_equipment.prompt)
    this_equipment.send_cmd("cat /proc/interrupts", this_equipment.prompt)
    this_equipment.send_cmd("cat /proc/softirqs", this_equipment.prompt)
  end

  def query_debug_data(e='dut1')
    return if !@equipment.key?(e)
    this_equipment = @equipment[e]
    if is_uut_up?(this_equipment)
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
      this_equipment.send_cmd("zcat /proc/config.gz", this_equipment.prompt)
      this_equipment.send_cmd("lspci", this_equipment.prompt)
      this_equipment.send_cmd("journalctl --no-pager", this_equipment.prompt, 60)
    end
  end

   
  # export ltp-ddt path so the script/function can be called from vatf-script
  def export_ltppath(device_object=@equipment['dut1'])
    ltppath = '/opt/ltp'
    if !dut_dir_exist?(ltppath+"/testcases/bin/ddt")
      raise "LTP-DDT is not in the file sytem. Please install LTP-DDT into the target filesystem"
    end
    device_object.send_cmd("export LTPPATH=/opt/ltp", device_object.prompt, 20)
    cmd = "export PATH=\"${PATH}:${LTPPATH}/testcases/bin\"$( find ${LTPPATH}/testcases/bin/ddt -type d -exec printf \":\"{} \\; )"
    device_object.send_cmd(cmd, device_object.prompt, 10)
    device_object.send_cmd("echo $PATH", device_object.prompt, 10)

  end

  def save_dut_orig_path(device_object=@equipment['dut1'])
    device_object.send_cmd("echo $PATH", device_object.prompt, 10)
    dut_orig_path = device_object.response.match(/^\/.*/)
  end

  def restore_dut_path(dut_orig_path, device_object=@equipment['dut1'])
    device_object.send_cmd("export PATH=#{dut_orig_path} ", device_object.prompt, 10)
  end

  def kill_process(process,opts={},device_object=@equipment['dut1'])
    this_equipment = opts[:this_equipment] || device_object
    use_sudo = opts[:use_sudo] || false 
      if (use_sudo)
        this_equipment.send_sudo_cmd("killall -9 #{process}", this_equipment.prompt, 10)  
      else
        this_equipment.send_cmd("killall -9 #{process}", this_equipment.prompt, 10)  
      end  
   end

  # Preserve current governor
  def create_save_cpufreq_governors(device_object=@equipment['dut1'])
    device_object.send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              device_object.prompt)
    previous_govs = device_object.response.scan(/^\w+\s*$/)
  end


 # Change to specified governor
  def enable_cpufreq_governor(type='performance', device_object=@equipment['dut1'])
    device_object.send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do echo -n #{type} > /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              device_object.prompt)
    device_object.send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
    device_object.log_info("#{type} governor is not available") if device_object.timeout?
    device_object.send_cmd("cpus=$(ls /sys/devices/system/cpu | grep \"cpu[0-9].*\"); for cpu in $cpus; do cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor; done",
                              device_object.prompt)
 end

 # Restore previous governor
  def restore_cpufreq_governors(previous_govs, device_object=@equipment['dut1'])
    previous_govs.each_with_index{|v,i|
       v.gsub!(/\s*/,'')
       device_object.send_cmd("echo -n #{v} > /sys/devices/system/cpu/cpu#{i}/cpufreq/scaling_governor", device_object.prompt)
    }
  end

  # Return decimal value from address
  def read_address(address, from_kernel=true, device_object=@equipment['dut1'])
    if from_kernel
      device_object.send_cmd("which devmem2; echo $?", /^0/)
      raise "devmem2 is not available" if device_object.timeout?
      device_object.send_cmd("devmem2 #{address}", device_object.prompt)
      return device_object.response.match(/Read at address  #{address} .+:\s*([x0-f]+)/i).captures[0].hex
    else
      device_object.send_cmd("md.l #{address} 1", device_object.boot_prompt, 2)
      return device_object.response.match(/#{address.gsub(/^0x/i,'')}:\s*([0-f]+)/i).captures[0].hex
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
    if this_equipment.is_a?(LinuxLocalHostDriver) 
      this_equipment.send_cmd("ps aux | grep '#{process}' | grep -v grep", this_equipment.prompt, 10)
      this_equipment.response.match(/\d+\s+\d+\.\d+\s+\d+\.\d+/) ? true : false
    else
      this_equipment.send_cmd("ps | grep '#{process}' | grep -v grep", this_equipment.prompt, 10)
      this_equipment.response.match(/\w+\s+\d+\s+.+/) ? true : this_equipment.send_cmd("ps -ef | grep '#{process}' | grep -v grep", this_equipment.prompt, 10)
      this_equipment.response.match(/\w+\s+\d+\s+.+/) ? true : false
    end
  end
   
end

