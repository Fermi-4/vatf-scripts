# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/weston stop; sleep 3',@equipment['dut1'].prompt,10)
end

def run
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('mkdir ' + @linux_dst_dir,@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd('cd ' + @linux_dst_dir,@equipment['dut1'].prompt)
  url = @test_params.params_chan.bin[0]
  exec = File.basename(url)
  @equipment['dut1'].send_cmd("ls #{exec} || wget #{url}", @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("chmod 755 #{exec}", @equipment['dut1'].prompt)
  result = true
  iters = 3
  exec_time = 300
  iters = @test_params.params_chan.iterations[0].to_i if @test_params.params_chan.instance_variable_defined?(:@iterations)
  exec_time = @test_params.params_chan.exec_time[0].to_i if @test_params.params_chan.instance_variable_defined?(:@exec_time)
  iters.times do |i|
    @equipment['dut1'].send_cmd("./#{exec}", /Segmentation fault/, exec_time)
    result &= @equipment['dut1'].timeout?
    break if !result
    @equipment['dut1'].send_cmd("\C-c", @equipment['dut1'].prompt, 30)
  end
  res_str = 'passed'
  res_str = 'failed' if !result
  set_result(result ? FrameworkConstants::Result[:pass] : FrameworkConstants::Result[:fail], "GFX test #{res_str}")
end
