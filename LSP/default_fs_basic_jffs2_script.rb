# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
require File.dirname(__FILE__)+'/default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
  puts 'child setup: if already mount then skip mount'
  fs_type = @test_params.params_chan.fs_type[0]
  mnt_point = @test_params.params_chan.mnt_point[0]
  device_node = @test_params.params_chan.device_node[0]
  #mount_device = @test_params.params_chan.mount_device[0]
  
  # mkdir
  @equipment['dut1'].send_cmd("mkdir #{mnt_point}",@equipment['dut1'].prompt, 10 )
  @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
  m_regex = Regexp.new(mnt_point)
  if !m_regex.match(@equipment['dut1'].response) then
    # do mount if not mounted yet
    #@equipment['dut1'].send_cmd("flash_eraseall -j #{device_node.delete("block")}", @equipment['dut1'].prompt, 60)
    @equipment['dut1'].send_cmd("flash_eraseall #{device_node.delete("block")}", @equipment['dut1'].prompt, 60)
    @equipment['dut1'].send_cmd("mount -t #{fs_type} #{device_node} #{mnt_point}", @equipment['dut1'].prompt, 120)
    # make sure mount ok
    @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 10)
    if !m_regex.match(@equipment['dut1'].response) then
      raise "device mount failed!!"
    end
  end
end

def run
  self.as(LspTestScript).run
  puts 'child run'
end

def clean
  self.as(LspTestScript).clean
  puts 'child clean'
end


