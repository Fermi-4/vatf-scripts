# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript   
#include PlatformSpecificVarNames

def setup
  #self.as(LspTestScript).setup
	@equipment['dut1'].set_api('psp')
end

def run
  result = 0
  translated_boot_params = setup_host_side()
  translated_boot_params.each{|k,v| puts "#{k}:#{v}"}

  flash_bootloader = @test_params.params_chan.instance_variable_defined?(:@flash_bootloader) ? @test_params.params_chan.flash_bootloader[0].downcase : 'no'
  flash_kernel = @test_params.params_chan.instance_variable_defined?(:@flash_kernel) ? @test_params.params_chan.flash_kernel[0].downcase : 'no'
  flash_fs = @test_params.params_chan.instance_variable_defined?(:@flash_fs) ? @test_params.params_chan.flash_fs[0].downcase : 'no'

  if flash_bootloader == 'yes'
    translated_boot_params['dut'].update_bootloader(translated_boot_params)

    # Verify if the board can boot using the updated bootloader
    10.times {puts "Please change the switch setting to boot from #{translated_boot_params['primary_bootloader_dev']}!!!"}
    sleep 10
    # powercycle or reset the board to check
    translated_boot_params['dut'].boot_to_bootloader(translated_boot_params)
    translated_boot_params['dut'].send_cmd("version", translated_boot_params['dut'].boot_prompt, 10)
    result += 1 if translated_boot_params['dut'].timeout? 
  end 
  
  if flash_kernel == 'yes'
    translated_boot_params['dut'].update_kernel(translated_boot_params)
  end

  if flash_fs == 'yes'
    translated_boot_params['dut'].update_fs(translated_boot_params)
  end
  
  # kernel_dev and fs_dev needs to be set to the right value
  # check if dut bootup ok using updated kernel or fs
  if flash_kernel == 'yes' or flash_fs == 'yes'
    translated_boot_params['dut'].boot(translated_boot_params)

    # check if the kernel boot up ok.
    translated_boot_params['dut'].send_cmd("uname -a", translated_boot_params['dut'].prompt, 10)
    result += 1 if translated_boot_params['dut'].timeout?
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test fail")
  end  

end 
