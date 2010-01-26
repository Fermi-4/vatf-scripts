# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript
include Bootscript
def setup
  self.as(LspTestScript).setup
end

def run
  test_result = 0 # '0' is pass; else fail
  result_msg = 'this test pass'
  
  fs_type = @test_params.params_chan.fs_type[0]
  mnt_point = @test_params.params_chan.mnt_point[0]
  device_node = @test_params.params_chan.device_node[0]
  test_duration = @test_params.params_chan.test_duration[0]

  @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("flash_eraseall #{get_flash_eraseall_option(fs_type)} #{device_node.delete('block')}", @equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("mount #{device_node} #{mnt_point} -t #{fs_type}", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 30)
  regex = Regexp.new(mnt_point)
  if !regex.match(@equipment['dut1'].response)
    puts "mounting failed"
  end
  @equipment['dut1'].send_cmd("df -h", @equipment['dut1'].prompt, 10)
  
  # keep write/read until it is full and then delete and then start over again.
  start_time = Time.now
  
  elapsed_time = 0
  while elapsed_time <= test_duration.to_i
    test_num = 0
    loop do
      @equipment['dut1'].send_cmd("dd if=/dev/zero of=#{mnt_point}/test#{test_num} bs=1M count=100", @equipment['dut1'].prompt, 300)
      if /fail|error/i.match(@equipment['dut1'].response)
        set_result(FrameworkConstants::Result[:fail], "write failed!") 
        return
      end
      # check if the disk if full
      @equipment['dut1'].send_cmd("df", @equipment['dut1'].prompt, 10)
      puts "<<<<<<"
      puts @equipment['dut1'].response
      puts ">>>>>>"
      used_perc = /#{device_node}\s+[\d\.]+\s+[\d\.]+\s+[\d\.]+\s+([\d\.]+)%\s+#{mnt_point}/.match(@equipment['dut1'].response).captures[0]
      puts "<<<<<"
      puts used_perc
      puts ">>>>>"
      break if used_perc.to_i >= 100 
      
      @equipment['dut1'].send_cmd("dd if=#{mnt_point}/test#{test_num} of=/dev/null bs=1M count=100", @equipment['dut1'].prompt, 300)
      if /fail|error/i.match(@equipment['dut1'].response)
        set_result(FrameworkConstants::Result[:fail], "read failed!")
        return
      end
      
      test_num += 1
      puts "<<<<<"
      puts "test_num: " + test_num.to_s
      puts ">>>>>"
      
    end
    @equipment['dut1'].send_cmd("rm -f #{mnt_point}/test*", @equipment['dut1'].prompt, 10)
    elapsed_time = Time.now - start_time
    puts "<<<<<"
    puts "elapsed_time: " + elapsed_time.to_s
    puts "test_duration: " + test_duration.to_s    
    puts ">>>>>"
  end
  set_result(FrameworkConstants::Result[:pass], result_msg)
end

def clean
  self.as(LspTestScript).clean
  puts 'child clean'
  mnt_point = @test_params.params_chan.mnt_point[0]
  @equipment['dut1'].send_cmd("umount #{mnt_point}", @equipment['dut1'].prompt, 30)
end  

def get_flash_eraseall_option(fs)
  option = ''
  option = '-j' if fs == 'jffs2'
  return option
end
