# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
include PlatformSpecificVarNames

def setup
	@equipment['dut1'].set_api('psp')
  target_from_db   = @test_params.target.downcase
  platform_from_db = @test_params.platform.downcase
  boot_params = {'power_handler'=> @power_handler,
                 'staf_service_name' => @test_params.staf_service_name.to_s,
                 'platform' => platform_from_db,
                 'target' => target_from_db }
  boot_params['server'] = @equipment['server1'] if  @equipment['server1']
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  boot_params['image_path'] = @test_params.kernel if @test_params.instance_variable_defined?(:@kernel)
  boot_params['primary_bootloader'] = @test_params.primary_bootloader if @test_params.instance_variable_defined?(:@primary_bootloader)
  boot_params['secondary_bootloader'] = @test_params.secondary_bootloader if @test_params.instance_variable_defined?(:@secondary_bootloader)
  if !(@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil) && !(@equipment['dut1'].respond_to?(:serial_server_port) && @equipment['dut1'].serial_server_port != nil)
    raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the board to boot. Please check your bench file" 
  end
  @equipment['dut1'].boot_to_bootloader(boot_params) 
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 2)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run
	self.as(LspTestScript).run
end

def clean
  	#super
  	self.as(LspTestScript).clean
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
			target_cmd.cmd_to_send = eval('"'+cmd+'"')
			target_commands << target_cmd
			next
		else
			target_cmd.cmd_to_send = eval('"'+m.pre_match+cmd[m.begin(0),1]+'"')
		end
    
		# get expected response
		pass_regex_specified = fail_regex_specified = false
		response_regex = m[1] + cmd[m.end(0)-2,1]
		m = /\+\+/.match(response_regex)
		(m == nil) ? (pass_regex_specified = false) : (pass_regex_specified = true)
		m = /\-\-/.match(response_regex)
		(m == nil) ? (fail_regex_specified = false) : (fail_regex_specified = true)
		m = /^\+\+/.match(response_regex)
		if m == nil     # Starts with --fail response 
			if pass_regex_specified
				target_cmd.fail_regex = /^\-\-(.+)\+\+/.match(response_regex)[1]
				target_cmd.pass_regex = /\+\+(.+)$/.match(response_regex)[1] 
			else
				target_cmd.fail_regex = /^\-\-(.+)$/.match(response_regex)[1]
			end
		else            # Starts with ++pass response
			if fail_regex_specified
				target_cmd.pass_regex = /^\+\+(.+)\-\-/.match(response_regex)[1]
				target_cmd.fail_regex = /\-\-(.+)$/.match(response_regex)[1] 
			else
				target_cmd.pass_regex = /^\+\+(.+)$/.match(eval('"'+response_regex+'"'))[1]
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
		cmd.pass_regex =  /#{@equipment['dut1'].boot_prompt.source}/m if !cmd.instance_variable_defined?(:@pass_regex)
		if !cmd.instance_variable_defined?(:@fail_regex)
			expect_regex = "(#{cmd.pass_regex})"
		else
			expect_regex = "(#{cmd.pass_regex}|#{cmd.fail_regex})"
		end
	regex = Regexp.new(expect_regex)                                                
	@equipment['dut1'].send_cmd(cmd.cmd_to_send, @equipment['dut1'].boot_prompt, dut_timeout)
	if @equipment['dut1'].timeout? || ! regex.match(@equipment['dut1'].response)
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

def stop_boot()
	@equipment['dut1'].wait_for(/I2C:/, 10) if @test_params.platform.match('am387x-evm')
	@equipment['dut1'].wait_for(/cpsw/, 10) if @test_params.platform.match('am335x-evm')
	@equipment['dut1'].send_cmd("\e", @equipment['dut1'].boot_prompt, 1)	
end

def put_val(val)
	@equipment['dut1'].send_cmd(val, @equipment['dut1'].boot_prompt, 1)	
end

def connect_to_equipment(equipment)
      this_equipment = @equipment["#{equipment}"]
      #puts "You are serially connecting to #{equipment}"
      if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.serial
        raise "You need Serial port connectivity to #{equipment}. Please check your bench file" 
      end
end
