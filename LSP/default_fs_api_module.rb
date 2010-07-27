# -*- coding: ISO-8859-1 -*-
# This module does 'mount'if not mounted. Also, can be used for stress tests.
require File.dirname(__FILE__)+'/default_test_module'

module LspFSTestScript
  include LspTestScript

  def setup
    super
    puts 'child setup: if already mount then skip mount'
  end

  def run
    # mount the device. if already mount then skip mount
    fs_type = @test_params.params_chan.fs_type[0]
    mnt_point = @test_params.params_chan.mnt_point[0]
    device_node = @test_params.params_chan.device_node[0]
    @equipment['dut1'].send_cmd("mkdir #{mnt_point}",@equipment['dut1'].prompt, 10 )
    @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
    m_regex = Regexp.new(mnt_point)
    if !m_regex.match(@equipment['dut1'].response) then
      # do mount if not mounted yet
      @equipment['dut1'].send_cmd("flash_eraseall #{device_node.delete("block")}", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("mount -t #{fs_type} #{device_node} #{mnt_point}", @equipment['dut1'].prompt, 20)
      # make sure mount ok
      @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
      if !m_regex.match(@equipment['dut1'].response) then
        raise "device mount failed!!"
      end
    end
    
    if @test_params.params_chan.instance_variable_defined?(:@test_duration) then
      begin
      # for stress test.
      commands = ensure_commands = ""
      commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
      ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
      test_duration = @test_params.params_chan.test_duration[0].to_i * 3600 
      t_diff = 0
      t1 = Time.now
      while(t_diff <= test_duration) 
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
          result, cmd = execute_cmd(ensure_commands) if ensure_commands !=""
      end
    else
      # only run once
      super
    end # define test_duration
  end

  def clean
    super
    puts 'child clean'
  end

end
