# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript

def setup
  self.as(LspTestScript).setup
  puts 'ata child setup: if already mount then skip mount'
  fs_type = @test_params.params_chan.fs_type[0]
  mnt_point = @test_params.params_chan.mnt_point[0]
  device_node = @test_params.params_chan.device_node[0]
  
  # mkdir
  @equipment['dut1'].send_cmd("mkdir #{mnt_point}",@equipment['dut1'].prompt, 10 )
  @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
  m_regex = Regexp.new(mnt_point)
  if !m_regex.match(@equipment['dut1'].response) then
    # do mount if not mounted yet
    @equipment['dut1'].send_cmd("mount -t #{fs_type} #{device_node} #{mnt_point}", @equipment['dut1'].prompt, 20)
    # make sure mount ok
    @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
    if !m_regex.match(@equipment['dut1'].response) then
      raise "ata mount failed!!"
    end
  end
end

def run
    commands = ensure_commands = ""
    commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
    ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
    
    t_diff = 0
    t1 = Time.now
    while(t_diff <= @test_params.params_chan.test_duration[0] * 3600) 
      result, cmd = execute_cmd(commands)
      if result == 0 
          set_result(FrameworkConstants::Result[:pass], "Test Pass.")
      elsif result == 1
          set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
          break
      elsif result == 2
          set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
          break
      else
          set_result(FrameworkConstants::Result[:nry])
          break
      end
      t_diff = (Time.now - t1).to_i
    end
    ensure 
        result, cmd = execute_cmd(ensure_commands)

end

def clean
  self.as(LspTestScript).clean
  puts 'ata child clean'
  # if the power mode is sleep, dut need reboot so ata can be functional.
  if @test_params.params_chan.power_mode == 'sleep' then 
    @equipment['apc1'].reset(@equipment['dut1'].power_port)
    sleep 30
  end
end



