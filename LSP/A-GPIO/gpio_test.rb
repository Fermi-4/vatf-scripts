# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript

def setup
  puts 'gpio setup.'
  self.as(LspTestScript).setup
end

def run
  puts 'gpio run'
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure) 
  result, cmd = execute_cmd(commands)
  if result == 0 
    if @test_params.params_control.is_manual_check[0] == 1 then
      # use oscilliscope to check the pin state
      begin
        file_res_form = ResultForm.new("Using Oscilliscope to verify GPIO #{@test_params.params_chan.gpio_num[0]} with dir #{@test_params.params_chan.dir[0]} Test Result Form")
        file_res_form.show_result_form
      end until file_res_form.test_result != FrameworkConstants::Result[:nry]
      set_result(file_res_form.test_result,file_res_form.comment_text)
    else
      set_result(FrameworkConstants::Result[:pass], "Test Pass.")
    end
   
    if @test_params.params_chan.dir == 0 then
      # check how many irq are been raised.
      irq_rtn = false
      irq_scan_arr = @equipment['dut1'].response.scan(/IRQ=(\d+)/) 
      irq_scan_arr.each do |x| 
        irq_rtn = x[0] == @test_params.params_chan.irq_num[0]
      end

      # check if irq number is same as 'irq_num' and the times irq been raised
      if irq_scan_arr.size >= @test_params.params_chan.test_loop[0].to_i/2.floor && irq_rtn then    
        set_result(FrameworkConstants::Result[:pass], "Test Pass. IRQ was raised #{irq_scan_arr.size} times.")
      else
        set_result(FrameworkConstants::Result[:fail], "Not enough IRQ or the irq number is not #{@test_params.params_chan.irq_num[0]}.")
      end
    else
      puts "WARNING: Testing GPIO as INPUT. Remember to loopback to pin 6. IRQ is not been checked."
    end
    
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
  puts 'gpio clean'
  self.as(LspTestScript).clean
end


