# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get to bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run
  result = 0
  result_msg = ''

  device = @test_params.params_chan.device[0] if @test_params.params_chan.instance_variable_defined?(:@device) 
  case device.downcase
  when 'usbhost'
    result,result_msg = check_usbhost_detection()
  when 'sata'
    result,result_msg = check_sata_detection()
  else
    raise "device=#{device} is not supported in the script yet; please add the support"
  end

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "Test Fail. #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end

end

def clean
  puts "device_detection:: clean"
end

def check_usbhost_detection()
  result = 0
  @equipment['dut1'].send_cmd("usb start",@equipment['dut1'].boot_prompt, 10)
  if ! @equipment['dut1'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
    result = 1
    msg = "No usbmsc device being detected and found"
  end
  [result, msg]
end

def check_sata_detection()
  result = 0
  @equipment['dut1'].send_cmd("scsi info",@equipment['dut1'].boot_prompt, 10)
  if ! @equipment['dut1'].response.match(/Vendor:\s+ATA\s+Prod/i)
    result = 1
    msg = "No SATA device being detected and found"
  end
  [result, msg]
end


