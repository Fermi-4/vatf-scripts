# -*- coding: ISO-8859-1 -*-

require File.dirname(__FILE__)+'/lsp_constants'
require File.dirname(__FILE__)+'/boot'
require File.dirname(__FILE__)+'/kernel_module_names'

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
    
    def setup
      @equipment['dut1'].set_api('psp')
      tester_from_cli  = @tester.downcase
      target_from_db   = @test_params.target.downcase
      platform_from_db = @test_params.platform.downcase
      
      nfs  = @test_params.nfs     if @test_params.instance_variable_defined?(:@nfs)
      nandfs = @test_params.nandfs  if @test_params.instance_variable_defined?(:@nandfs)
      ramfs = @test_params.ramfs   if @test_params.instance_variable_defined?(:@ramfs)
      kernel_modules = @test_params.kernel_modules   if @test_params.instance_variable_defined?(:@kernel_modules)
      
      nfs_root_path_temp	= @equipment['dut1'].nfs_root_path
      
      if @equipment.has_key?('server1')
        samba_root_path_temp = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}"
        if @equipment['server1'].kind_of? LinuxLocalHostDriver
					@equipment['server1'].connect({})     # In this case, nothing happens as the server is running locally
        elsif @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
          @equipment['server1'].connect({'type'=>'telnet'})
        elsif !@equipment['server1'].target.telnet 
          raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
        end
      
        if nfs 
          fs = nfs
          fs.gsub!(/\\/,'/')
          build_id, build_name = /\/([^\/\\]+?)\/([\w\.\-]+?)$/.match("#{fs.strip}").captures
          @equipment['server1'].send_cmd("mkdir -p -m 777  #{nfs_root_path_temp}/autofs", @equipment['server1'].prompt, 10)  if !File.directory?("#{samba_root_path_temp}\\autofs")		
          samba_root_path_temp = samba_root_path_temp + "\\autofs\\#{build_id}"
          nfs_root_path_temp 	= nfs_root_path_temp + "/autofs/#{build_id}"
          # Copy  nfs filesystem to linux server and untar it if it doesn't exist
          if !File.directory?("#{samba_root_path_temp}\\usr")
            @equipment['server1'].send_cmd("mkdir -p  #{nfs_root_path_temp}", @equipment['server1'].prompt, 10) 		
            BuildClient.copy(@test_params.nfs, "#{samba_root_path_temp}\\#{File.basename(@test_params.nfs)}")	
            @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}", @equipment['server1'].prompt, 10) 		
            @equipment['server1'].send_sudo_cmd("tar -xvzf #{build_name}", @equipment['server1'].prompt, 300)
          end
        else
          # Need to add logic to handle nandfs and ramfs
        end
        
        if kernel_modules and nfs
          kernel_modules.gsub!(/\\/,'/')
          kernel_modules_name = /\/[^\/\\]+?\/([\w\.\-]+?)$/.match("#{kernel_modules.strip}").captures[0]
          #@equipment['server1'].send_sudo_cmd("mkdir -p -m 777  #{nfs_root_path_temp}/lib/modules", @equipment['server1'].prompt, 10)  if !File.directory?("#{samba_root_path_temp}\\lib\\modules")
          BuildClient.copy(@test_params.kernel_modules, "#{samba_root_path_temp}\\..\\#{File.basename(@test_params.kernel_modules)}")
          @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}/..", @equipment['server1'].prompt, 10)
          @equipment['server1'].send_sudo_cmd("tar -xvzf #{kernel_modules_name} -C #{nfs_root_path_temp}", @equipment['server1'].prompt, 30)
		  @equipment['server1'].send_cmd("rm -f #{kernel_modules_name}", @equipment['server1'].prompt, 10)
		  @equipment['server1'].send_cmd("cd #{nfs_root_path_temp}", @equipment['server1'].prompt, 10)
        end
      
        @equipment['server1'].send_sudo_cmd("mkdir -p -m 777 #{nfs_root_path_temp}/test", @equipment['server1'].prompt) if !(@test_params.instance_variable_defined?(:@var_nfs))
      
        LspTestScript.set_paths(samba_root_path_temp, nfs_root_path_temp) 
        # Boot DUT
        samba_path = "#{samba_root_path_temp}\\test\\#{tester_from_cli}\\#{target_from_db}\\#{platform_from_db}\\bin"
        nfs_path   = "#{nfs_root_path_temp}/test/#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/bin"
        nfs_root_path_temp = "#{@equipment['server1'].telnet_ip}:#{nfs_root_path_temp}"
        nfs_root_path_temp = @test_params.var_nfs  if @test_params.instance_variable_defined?(:@var_nfs)  # Optionally use external nfs server
      
        boot_params = {'power_handler'=> @power_handler,
                       'platform' => platform_from_db,
                       'tester' => tester_from_cli,
                       'target' => target_from_db ,
                       'image_path' => @test_params.kernel,
                       'server' => @equipment['server1'], 
                       'samba_path' => samba_path, 
                       'nfs_root' => nfs_root_path_temp,
                       'nfs_path' => nfs_path}
        boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
        @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
      
        if boot_required?(@old_keys, @new_keys) # call bootscript if required
		  if @equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil
            @equipment['dut1'].connect({'type'=>'serial'})
          elsif @equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil
            @equipment['dut1'].connect({'type'=>'serial'})
          else
            raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
          end
          @equipment['dut1'].boot(boot_params) 
        end
      end
      connect_to_equipment('dut1')
      
      # by now, the dut should already login and is up; if not, dut may hang.
      raise "UUT may be hanging!" if !is_uut_up?
      
      # Copy executable sources to NFS server (if filesystem was not specified and there are @target_sources
      if @test_params.params_chan.instance_variable_defined?(:@target_sources) && @equipment.has_key?('server1') && !nfs && !@test_params.instance_variable_defined?(:@var_nfs) 
          files_array = Array.new
          src_folder = @view_drive+@test_params.params_chan.target_sources[0].to_s
          puts "target_source_drive is #{@target_source_drive}"
          src_folder = @target_source_drive+@test_params.params_chan.target_sources[0].to_s if !File.directory?(src_folder.strip.gsub("\\","/"))
          puts "target source folder is: #{src_folder}"
          
          last_folder = /\\(\w+)$/.match("#{@test_params.params_chan.target_sources[0].strip}").captures[0]
      
          BuildClient.dir_search(src_folder, files_array) if @test_params.params_chan.instance_variable_defined?(:@target_sources)
          puts "copying target source code ..."
          dst_folder_regex  = Regexp.new("#{last_folder}\\\\.+")
          files_array.each {|f|
            if File.extname(f) != '.yuv' && File.extname(f) != '.raw' && File.extname(f) != '.bmp' && File.extname(f) != '.rgb' && File.extname(f) != '.pdf' && File.extname(f) != '.doc' then
              dst_path   = samba_path+"\\..\\"+dst_folder_regex.match(f).to_s
              BuildClient.copy(f, dst_path)
            end
          }
          # Compile sources
          # force do make clean if platform is changed. 
          # if not, just do make and make will decide to do compile or not.
          
          build_params = {'server'   => @equipment['server1'],
                         'platform' => platform_from_db,
                         'microType' => @test_params.microType,
                         'target_code_dir' => LspTestScript.nfs_root_path+"#{nfs_path}/../#{last_folder}",
                         'target'   => target_from_db,
                         'code_source' => @test_params.code_source}
          platform_regex = Regexp.new("#{@test_params.platform}")
          if !platform_regex.match(@old_keys) then
            BuildClient.lsp_make_clean(build_params)
            BuildClient.lsp_configure(build_params)
          end
          BuildClient.lsp_compile(build_params)
          sleep 5
          # catch the compile error if any
          if /(error)|(\*\*\*\s+No\s+rule\s+to\s+make\s+target)/i =~ @equipment['server1'].response then
            raise "Make compilation had error!"
          end
          
          # sometimes, the one which is copied over is empty. so add delay here.
          sleep 1
          # copy the output file(s) under bin to target.
          @equipment['dut1'].send_cmd("mkdir -p -m 777 #{nfs_path}", @equipment['dut1'].prompt, 10)
          @equipment['dut1'].send_cmd("cp -f #{nfs_path}/../#{last_folder}/bin/* #{nfs_path}", @equipment['dut1'].prompt, 30)
      end 

      # Leave target in appropriate directory
      @equipment['dut1'].send_cmd("cd #{nfs_path}\n", /#{@equipment['dut1'].prompt}/, 10)  if ( @equipment.has_key?('server1') && !(nfs) && !(@test_params.instance_variable_defined?(:@var_nfs)) )
      
      # modprobe modules specified by test params
      if kernel_modules
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
      # keys = @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
      # @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
      # @test_params.microType.to_s + @test_params.configID.to_s
      keys = @test_params.platform.to_s
      keys
    end
    
    def set_paths(samba, nfs)
      @samba_root_path_temp = samba
      @nfs_root_path_temp   = nfs
    end
    
    def connect_to_equipment(equipment)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
      elsif ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
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
end
   






