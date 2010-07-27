# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
Include System::Windows::Forms
include LspTestScript

def setup
  super
end

def run
  MessageBox.Show(“Change the I/O for this test”)
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
=begin
  begin
    #@equipment['dut1'].send_cmd("audiolb -s 48 -f 8192 #{@test_params.params_chan.block[0]} #{@test_params.params_chan.mic[0]}", @equipment['dut1'].prompt, 60)
    #file_res_form = ResultForm.new("Audio Test HW Result Form")
    #file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
=end
end

def clean
  super
end


