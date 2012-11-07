# -*- coding: ISO-8859-1 -*-

#require File.dirname(__FILE__)+'/lsp_constants'
require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/kernel_module_names'
require File.dirname(__FILE__)+'/metrics'
require File.dirname(__FILE__)+'/../lib/plot'

include Metrics
include TestPlots

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
        params['server'].send_sudo_cmd("mkdir -p  #{nfs_root_path_temp}", params['server'].prompt, 10)    
        params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} -xvzf #{fs}", params['server'].prompt, 300)
          end
        end
        
    if params['kernel_modules'] != '' and params['fs_type'] == 'nfs' and !params.has_key?('var_nfs')
      params['server'].send_sudo_cmd("tar -C #{nfs_root_path_temp} -xvzf #{params['kernel_modules']}", params['server'].prompt, 30)
    		end
      
    params['server'].send_sudo_cmd("mkdir -p -m 777 #{nfs_root_path_temp}/test", params['server'].prompt) if !(params.has_key? 'var_nfs')
      
        LspTestScript.set_paths(nfs_root_path_temp, nfs_root_path_temp) 
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
    @equipment['dut1'].set_api('psp')

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
    if boot_required?(@old_keys, @new_keys) #&& translated_boot_params['kernel'] != ''
	    if !(@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil) && 
         !(@equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil)
      		raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
          end
        
      @equipment['dut1'].boot(translated_boot_params) 
      end
    
      connect_to_equipment('dut1')
      
      # by now, the dut should already login and is up; if not, dut may hang.
      raise "UUT may be hanging!" if !is_uut_up?
      
      @equipment['dut1'].send_cmd("cat /proc/cmdline", /#{@equipment['dut1'].prompt}/, 10)
      @equipment['dut1'].send_cmd("uname -a", /#{@equipment['dut1'].prompt}/, 10)

      # modprobe modules specified by test params
    if translated_boot_params['kernel_modules'] != ''
        @equipment['dut1'].send_cmd("depmod -a", /#{@equipment['dut1'].prompt}/, 30) 
        if @test_params.params_chan.instance_variable_defined?(:@kernel_modules_list)
          @test_params.params_chan.kernel_modules_list.each {|mod|
            #puts 'each mod is '+mod.to_s
            mod_name = KernelModuleNames::translate_mod_name(@test_params.platform, mod.strip)
            @equipment['dut1'].send_cmd("modprobe #{mod_name}", /#{@equipment['dut1'].prompt}/, 30)  
          }
        end
      end
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
      puts "default.clean"
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
                #puts ">>>>>>>>>>>>>"
                #puts "response:" + @equipment['dut1'].response
                #puts ">>>>>>>>>>>>>>>" 
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
    @eth_ip_addr = get_ip_addr()
    if @eth_ip_addr
      @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
      old_telnet_port = @equipment['dut1'].target.platform_info.telnet_port
      @equipment['dut1'].target.platform_info.telnet_port = 23
      @equipment['dut1'].connect({'type'=>'telnet'})
      @equipment['dut1'].target.platform_info.telnet_port = old_telnet_port
      @equipment['dut1'].target.telnet.send_cmd("pwd", @equipment['dut1'].prompt , 3)    
    @collect_stats = @test_params.params_control.collect_stats[0]
    @collect_stats_interval = @test_params.params_control.collect_stats_interval[0].to_i
      start_collecting_stats(@collect_stats, @collect_stats_interval) do |cmd| 
        if cmd
          @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
          @equipment['dut1'].target.telnet.response
        end
      end
      @equipment['dut1'].target.telnet.send_cmd("cd /sys/class/net/eth0/statistics", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec basename {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec cat {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", /.*/, 3)
    end
  end
  
  # Stop collecting system metrics 
  def run_stop_stats
    if @eth_ip_addr
      @target_sys_stats = stop_collecting_stats(@collect_stats) do |cmd| 
        if cmd
          @equipment['dut1'].target.telnet.send_cmd(cmd, @equipment['dut1'].prompt, 10, true)
          @equipment['dut1'].target.telnet.response
        end
      end
      @equipment['dut1'].target.telnet.send_cmd("cd /sys/class/net/eth0/statistics", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec basename {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("find -type f -exec cat {} \;", /.*/, 3)
      @equipment['dut1'].target.telnet.send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", /.*/, 3)
    end
     @equipment['dut1'].send_cmd("find /sys/class/net/eth0/statistics -type f -exec basename {} \\;", @equipment['dut1'].prompt, 3)
     @equipment['dut1'].send_cmd("find /sys/class/net/eth0/statistics -type f -exec cat {} \\;", @equipment['dut1'].prompt, 3)
     @equipment['dut1'].send_cmd("cat /sys/devices/platform/cpsw.0/net/eth0/hw_stats", @equipment['dut1'].prompt, 3)
  end

    def get_ip_addr(dev='dut1', iface_type='eth')     
    this_equipment = @equipment["#{dev}"]
    this_equipment.send_cmd("eth=`ls /sys/class/net/ | awk '/.*#{iface_type}.*/{print $1}' | head -1`;ifconfig $eth", this_equipment.prompt)
    #eth=`ls /sys/class/net/ | awk '/.*eth.*/{print $1}' | head -1`
    #ifconfig_data =`ifconfig #{eth}`
    ifconfig_data =/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(this_equipment.response)
    ifconfig_data ? ifconfig_data[1] : nil
  end
   
end

