# -*- coding: ISO-8859-1 -*-
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  commands = ensure_commands = ""
  baud_rate = '115200'
  data = '8'
  baud_rate = @test_params.params_chan.baud_rate[0] if @test_params.params_chan.instance_variable_defined?(:@baud_rate)
  data = @test_params.params_chan.data[0] if @test_params.params_chan.instance_variable_defined?(:@data)
  parity = @test_params.params_chan.parity[0] if @test_params.params_chan.instance_variable_defined?(:@parity)
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
    begin
      result, cmd = execute_cmd(commands)
      if result == 0 
        file_res_form = ResultForm.new("Uart baudrate #{baud_rate}+data #{data}+parity #{parity} Test Result Form")
        file_res_form.show_result_form
      elsif result == 1
        set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
        return
      elsif result == 2
        set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
        return
      else
        set_result(FrameworkConstants::Result[:nry])
        return
      end
    end until file_res_form.test_result != FrameworkConstants::Result[:nry]
    set_result(file_res_form.test_result,file_res_form.comment_text)
    ensure 
      result, cmd = execute_cmd(ensure_commands)
=begin
  begin
    @equipment['dut1'].send_cmd("\./keypad_test &", @equipment['dut1'].prompt, 20)
    file_res_form = ResultForm.new("Keypad Test Result Form")
    file_res_form.show_result_form
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
=end
end

def clean
  self.as(LspTestScript).clean
end


