# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
include PlatformSpecificVarNames

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  
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
	bootcmd_timeout = @test_params.instance_variable_defined?(:@var_boot_timeout) ? @test_params.var_boot_timeout.to_i : 30
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
	regex = Regexp.new(expect_regex, Regexp::IGNORECASE)
	if (cmd.cmd_to_send == "bootm") || (cmd.cmd_to_send == "bootd")||(cmd.cmd_to_send == "tftpboot") || (cmd.cmd_to_send == "dhcp") \
	                               || (cmd.cmd_to_send == "reset") || (cmd.cmd_to_send.match(/ddr/)) || (cmd.cmd_to_send == "boot")
	    @equipment['dut1'].send_cmd(cmd.cmd_to_send, regex, bootcmd_timeout)
	else
	    @equipment['dut1'].send_cmd(cmd.cmd_to_send, @equipment['dut1'].boot_prompt, dut_timeout)
	end
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
	#@equipment['dut1'].wait_for(/U-Boot/, 10) 
	@equipment['dut1'].stop_boot
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
