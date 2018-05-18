# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  #translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run
  result_msg = ''
  result = 0

  platform = @test_params.platform
  puts "platform: "+platform

  device_name = @test_params.params_chan.instance_variable_defined?(:@device_name) ? @test_params.params_chan.device_name[0].downcase : 'emmc'
  command = @test_params.params_chan.command[0].downcase
  test_loop = @test_params.params_chan.instance_variable_defined?(:@test_loop) ? @test_params.params_chan.test_loop[0].to_i : 2
  case device_name
  when "mmc"
    raise "Skip testing mmc erase on SD card since it might corrupt the SD contents" if command == 'erase'
  
  when 'emmc'
    @equipment['dut1'].send_cmd("mmc dev 1; mmc info", @equipment['dut1'].boot_prompt, 5)
    raise "eMMC bus width is not 8-bit" if !@equipment['dut1'].response.match(/Bus\s+Width\s*:\s+8-bit/i)
    i = 0
    while i < test_loop
      report_msg "Iteration #{i.to_s} ..."
      @equipment['dut1'].send_cmd("mmc erase 0x10000 0x2000", @equipment['dut1'].boot_prompt, 30)
      raise "There is error when do mmc erase" if @equipment['dut1'].response.match(/error/im)
      i += 1
    end

  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test failed " + result_msg)
  end

end

def clean
  	#self.as(LspTestScript).clean
    puts "clean..."
end

