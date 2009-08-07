# -*- coding: ISO-8859-1 -*-

# Default Server-Side Test script implementation for LSP releases

module LspTestScript 
    class TargetCommand
        attr_accessor :cmd_to_send, :pass_regex, :fail_regex, :ruby_code
    end
    
    include Bootscript, Boot
    public
    def setup
        puts "default.setup"
        # Boot DUT        
        tester_from_cli  = @tester.downcase
        target_from_db   = @test_params.target.downcase
        platform_from_db = @test_params.platform.downcase
        dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path}\\#{tester_from_cli}\\#{target_from_db}\\#{platform_from_db}"
        boot_params = {'platform' => platform_from_db, 'image_path' => @test_params.kernel, 'tftp_path' => @equipment['server1'].tftp_path, 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder}
        boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
        @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
        boot_dut(boot_params) if Boot::boot_required?(@old_keys, @new_keys) # call bootscript if required
        # by now, the dut should already login and is up; if not, dut may hang.
        raise "UUT may be hanging!" if !is_uut_up?
        # Copy executable sources to NFS server
        if @test_params.params_chan.instance_variable_defined?(:@target_sources) 
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
              if File.extname(f) != '.yuv' && File.extname(f) != '.raw' && File.extname(f) != 'bmp' && File.extname(f) != 'rgb' && File.extname(f) != 'pdf' && File.extname(f) != 'doc' then
                dst_path   = dst_folder+"\\"+dst_folder_regex.match(f).to_s
                BuildClient.copy(f, dst_path)
              end
            }
            # Compile sources
          	# force do make clean if platform is changed. 
          	# if not, just do make and make will decide to do compile or not.
            
            build_params = {'server'   => @equipment['server1'],
                           'tester'   => tester_from_cli,
                           'platform' => platform_from_db,
                           'microType' => @test_params.microType,
                           'source'   => last_folder,
                           'target'   => target_from_db,
                           'code_source' => @cli_params['code_source']}
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
            @equipment['dut1'].send_cmd("mkdir -p /#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/bin/", @equipment['dut1'].prompt, 10)
            @equipment['dut1'].send_cmd("cp -f /#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/#{last_folder}/bin/* /#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/bin/", @equipment['dut1'].prompt, 30)
        end 

        # Leave target in appropriate directory
        @equipment['dut1'].send_cmd("cd /#{tester_from_cli}/#{target_from_db}/#{platform_from_db}/bin/\n", /#{@equipment['dut1'].prompt}/, 10)
        
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
            result, cmd = execute_cmd(ensure_commands)
    end
    
    def clean
        puts "default.clean"
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
                cmd.pass_regex =  /#{cmd.cmd_to_send.split(/\s/)[0]}.*#{@equipment['dut1'].prompt.source}/m if !cmd.instance_variable_defined?(:@pass_regex)
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
                if @equipment['dut1'].is_timeout
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
end
   






