# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run
  result_msg = ''
  result = 0

  platform = @test_params.platform
  puts "platform: "+platform

  test_duration = @test_params.params_control.test_duration[0].to_i
  start_time = Time.now

  @equipment['dut1'].send_cmd("setenv bootcmd reset", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("saveenv", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("reset", /U-Boot/, 30)
  raise "Uboot reset failed!" if @equipment['dut1'].timeout?
  while Time.now - start_time < test_duration
    @equipment['dut1'].wait_for(/U-Boot/, 60)
    if @equipment['dut1'].timeout?
      result = result + 1 
      result_msg = result_msg + "Could not get to U-Boot anymore and the board seems hanging!"
    end
    
  end
    
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test pass")
  else
    set_result(FrameworkConstants::Result[:fail], result_msg)
  end

end

def clean
  #self.as(LspTestScript).clean
  puts "clean..."
  10.times {
    @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
    break if !@equipment['dut1'].timeout?
  }
  @equipment['dut1'].send_cmd("env default -a -f", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("saveenv", @equipment['dut1'].boot_prompt, 5)

end


