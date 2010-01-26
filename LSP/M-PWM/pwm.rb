# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
include System::Windows::Forms
include LspTestScript

def setup
  super
end

def run
  puts 'pwm run'
  # temp adding for dm365.
  # if @test_params.platform == "dm365" then
    # @equipment['dut1'].send_cmd("/yl/apps/writel 0x01c4000c 0 0x5f5affff", /#{@equipment['dut1'].prompt}/, 10)
  # end
  result = 1
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
  # use oscilliscope to check the pin state if needed
  begin
    MessageBox.Show("Click ok to run PWM test: #{@test_params.description}")
    rescue  Exception 
  end
  
  begin
    result, cmd = execute_cmd(commands)
    file_res_form = ResultForm.new("Using Oscilliscope Verify PWM Test Case: #{@test_params.description}")
    file_res_form.show_result_form
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
  
  ensure 
    result, cmd = execute_cmd(ensure_commands)  
end


def clean
  super
end


