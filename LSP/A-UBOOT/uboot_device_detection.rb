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

  # device here kind of represents the setup, ex, usbhubkeyboard
  device = @test_params.params_chan.device[0] if @test_params.params_chan.instance_variable_defined?(:@device) 
  case device.downcase
  when 'usbhost'
    result,result_msg = check_usbhost_detection('usbmsc')
  when 'usbhost3'
    result,result_msg = check_usbhost_detection('usbmsc3')
  when 'usbhubkeyboard'
    result,result_msg = check_usbhost_detection('keyboard')
  when 'usbkeyboard'
    result,result_msg = check_usbhost_detection('keyboard')
  when 'usbhubmsc'
    result,result_msg = check_usbhost_detection('usbmsc')
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

def check_usbhost_detection(type=nil)
  result = 0
  msg = ''
  i = 1
  test_loop = 5
  while i <= test_loop
    report_msg "Iteration #{i.to_s} ..."

    puts "Checking 'usb reset' output"
    sleep 1
    @equipment['dut1'].send_cmd("usb reset",@equipment['dut1'].boot_prompt, 20)
    case type
    when /usbmsc/
      if ! @equipment['dut1'].response.match(/[1-9]+\s+Storage\s+Device.*found/i)
        result += 1
        msg += "No usbmsc device being detected and found in iteration #{i.to_s};"
      end
      @equipment['dut1'].send_cmd("usb storage",@equipment['dut1'].boot_prompt, 20)
      if ! @equipment['dut1'].response.match(/Capacity:/i)
        result += 1
        msg += "usb storage does not show storage device in iteration #{i.to_s};"
      end
    end

    @equipment['dut1'].send_cmd("usb info",@equipment['dut1'].boot_prompt, 20)
    @equipment['dut1'].send_cmd("usb tree",@equipment['dut1'].boot_prompt, 20)
    case type
    when /keyboard/
      if ! @equipment['dut1'].response.match(/Human\s+Interface/i)
        result += 1
        msg += "Keyboard is not detected in iteration #{i.to_s};"
      end
    when /usbmsc/
      if ! @equipment['dut1'].response.match(/Mass\s+Storage/i)
        result += 1
        msg += "Mass storage is not detected in iteration #{i.to_s};"
      end
    else
      raise "Not known usb type (keyboard, usbmsc)"
    end

    i += 1
  end
  # check speed
  @equipment['dut1'].send_cmd("usb tree",@equipment['dut1'].boot_prompt, 20)
  if type == 'usbmsc3'
    if ! @equipment['dut1'].response.match(/Mass\s+Storage\s+\(\s*5\s*[GM]b\/s,/im)
      result += 1
      msg += "Did not detect super speed usb storage device"
    end
  end
  [result, msg]
end

def check_sata_detection()
  result = 0
  msg = ''
  i = 0
  test_loop = 2
  while i < test_loop
    report_msg "Iteration #{i.to_s} ..."
    @equipment['dut1'].send_cmd("scsi scan; scsi info",@equipment['dut1'].boot_prompt, 10)
    if ! @equipment['dut1'].response.match(/Vendor:\s+ATA\s+Prod/i)
      result += 1
      msg += "No SATA device being detected and found in iteration #{i.to_s};"
    end
    i += 1
  end
  [result, msg]
end


