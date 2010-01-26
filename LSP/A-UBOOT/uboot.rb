# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def setup             # added on 01-12-2009 to bypass the normal setup routines.  The original routine was causing the board to hang at various times.
  puts "alternate.default.setup"
end

def run
  puts "uboot.run"
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') 
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
  
  @equipment['dut1'].boot_to_bootloader
  
  result, cmd = execute_cmd(commands)
	
  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Test Pass.")
  elsif result == 1
    set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
  elsif result == 2
    set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
  elsif result == 3
    set_result(FrameworkConstants::Result[:NSup], "This command is not supported: #{cmd.cmd_to_send}")
  else
    set_result(FrameworkConstants::Result[:nry])
  end
  ensure 
    result, cmd = execute_cmd(ensure_commands)
    @equipment['dut1'].send_cmd('boot', /login/, 90)
    @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 20) # login to the unit to leave it in a decent state
end

def clean
  #@equipment['apc1'].reset(@equipment['dut1'].power_port.to_s)
  puts 'uboot.clean'
end

def execute_cmd(commands)
		last_cmd = nil
		result = 0 	#0=pass, 1=timeout, 2=fail message detected 
		dut_timeout = 30
		vars = Array.new
				
		puts ">>>>>>>>>>>>>"
		puts "Start - Here I am."
		puts ">>>>>>>>>>>>>>>"
				
    commands.each {|cmd|
    last_cmd = cmd
            
		puts "Step 1."
						
		if cmd.ruby_code
      puts "Step 2."
			eval cmd.ruby_code
    else
			puts "Step 3."
			puts "There is no cmd.pass_regex" if !cmd.instance_variable_defined?(:@pass_regex)
      cmd.pass_regex =  /#{cmd.cmd_to_send.split(/\s/)[0]}.*#{@equipment['dut1'].boot_prompt}/m if !cmd.instance_variable_defined?(:@pass_regex)
       
			#puts "Step 4."
				
			#puts ">>>>>>>>4a>>>>>>>>"
      #puts "Command:  " + cmd.cmd_to_send
      #puts ">>>>>>>>4b>>>>>>>"
		
			if !cmd.instance_variable_defined?(:@fail_regex)
				puts "Step 5."
        puts "(#{cmd.pass_regex})"
				expect_regex = "(#{cmd.pass_regex})"
      else
				#puts "Step 6."
        expect_regex = "(#{cmd.pass_regex}|#{cmd.fail_regex})"
      end

=begin
			puts "Step 7."
			regex = Regexp.new(expect_regex)
			puts ">>>>>>>>>>>>>>>"
			puts "Regex:  " + "(#{Regexp.new(expect_regex)})"
			puts "Response:  " + @equipment['dut1'].response
      puts ">>>>>>>>>>>>>>>"
=end
      #@equipment['dut1'].send_cmd(cmd.cmd_to_send, regex, dut_timeout)
			
      regex = Regexp.new(expect_regex)
			@equipment['dut1'].send_cmd(cmd.cmd_to_send, regex, 15)
=begin
			puts "Step 8."
			puts ">>>>>>>>>>>>>>>"
      puts "Command:  " + cmd.cmd_to_send
			puts "Regex:  " + "(#{Regexp.new(expect_regex)})"
			#puts "Timeout:  (#{dut_timeout})"
      puts ">>>>>>>>>>>>>>>"
      puts "Step 9"
			puts "<<<<<<<<<<<<<<<"
      puts "Response:  " + @equipment['dut1'].response
      puts "<<<<<<<<<<<<<<<"
      puts "Result:  (#{@equipment['dut1'].timeout?})"
      puts "<<<<<<<<<<<<<<<"
=end
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
