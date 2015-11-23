# This script is to test am43xx-gpevm boot from nand->usbmsc->mmc->usbrndis. 
#              Sysboot[4:0]=00000b which is default boot switch setting
# Asssumption: 1) Intially the board can be boot to uboot prompt
#              2) usbmsc device has fat partition in it
require File.dirname(__FILE__)+'/default_boot_order_test' 

def connect_to_extra_equipment
  usb_switch1 = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usbclient_port'].keys[0]]
  if usb_switch1.respond_to?(:serial_port) && usb_switch1.serial_port != nil
    usb_switch1.connect({'type'=>'serial'})
  else
    raise "Something wrong with usb switch connection for usbclient. Please check your setup"
  end
  usb_switch2 = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usbhost_port'].keys[0]]
  if usb_switch2.respond_to?(:serial_port) && usb_switch2.serial_port != nil
    usb_switch2.connect({'type'=>'serial'})
  else
    raise "Something wrong with usb switch connection for usbhost. Please check your setup"
  end

end

def nand_boot()

  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    reboot_dut()
  end
  raise "This test require the board is able to boot to uboot prompt initially! please check if mmc has valid bootloaders in it" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
  
  # validate nandboot
  begin 
    # now the board should be in uboot prompt
    report_msg "===== NAND BOOT START =====" 
    flash_nand()

    # invalidate other boot media
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbhost_port'].keys[0])
    invalidate_mmc(0)
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
 
    #boot_to_bootloader()
    @translated_boot_params['primary_bootloader_dev'] = 'nand'
    @translated_boot_params['dut'].boot_loader = nil
    @translated_boot_params['dut'].boot_to_bootloader @translated_boot_params
    status =  uboot_sanity_test()

    # restore mmc 
    #restore_mmc(0)

  rescue Exception => e
    restore_mmc(0)
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbclient_port'])
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbhost_port'])
    raise e
  end

  boot_to_kernel = @test_params.params_chan.instance_variable_defined?(:@boot_to_kernel) ? @test_params.params_chan.boot_to_kernel[0] : 'no'
  if boot_to_kernel == 'yes'
    # check if the board can boot kernel from nand
    flash_or_boot_kernel_fromto_media('flash', 'nand')
    flash_or_boot_kernel_fromto_media('boot', 'nand')
  end
 
  report_msg "===== NAND BOOT END =====" 
  return status 
end 

def usbhost_boot()
  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    reboot_dut()
  end
  raise "usbhost_boot::Dut is not in uboot prompt" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
  
  begin

    # now the board should be in uboot prompt
    report_msg "===== USB-MSC BOOT START =====" 
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbhost_port'])
    flash_usbhost()

    # invalidate other boot media
    erase_nand()
    invalidate_mmc(0)
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])

    # validate usbhost boot
    #boot_to_bootloader()
    @translated_boot_params['primary_bootloader_dev'] = 'usbmsc'
    @translated_boot_params['dut'].boot_loader = nil
    @translated_boot_params['dut'].boot_to_bootloader @translated_boot_params
    status =  uboot_sanity_test()

    # restore mmc 
    #restore_mmc(0)

  rescue Exception => e
    restore_mmc(0)
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbclient_port'])
    raise e
  end

  boot_to_kernel = @test_params.params_chan.instance_variable_defined?(:@boot_to_kernel) ? @test_params.params_chan.boot_to_kernel[0] : 'no'
  if boot_to_kernel == 'yes'
    # check if board can boot kernel from usbhost
    flash_or_boot_kernel_fromto_media('flash', 'usbmsc')
    flash_or_boot_kernel_fromto_media('boot', 'usbmsc')
  end

  report_msg "===== USB-MSC BOOT END =====" 
  return status 
end 

# Function does boot the dut from USB(RNDIS).
# Input parameters: None 
# Return Parameter: pass or fail.  

def usbrndis_boot()
  report_msg "===== USB-ETH BOOT START =====" 
  init_dhcp()

  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    reboot_dut()
  end
  raise "usbrndis_boot::Dut is not in uboot prompt" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})

  begin
    invalidate_mmc(0) 
    puts "disconnecting usbhost..."
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbhost_port'].keys[0])
    erase_nand

    # test usbrndis boot
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbclient_port'])

    #boot_to_bootloader()
    @translated_boot_params['primary_bootloader_dev'] = 'usbrndis'
    @translated_boot_params['dut'].boot_loader = nil
    @translated_boot_params['dut'].boot_to_bootloader @translated_boot_params
    status =  uboot_sanity_test()

    # restore to original settings
    @equipment['dut1'].send_cmd("setenv ethact cpsw", @equipment['dut1'].boot_prompt, 5)
    restore_mmc(0)
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbhost_port'])

  rescue Exception => e
    @equipment['dut1'].send_cmd("setenv ethact cpsw", @equipment['dut1'].boot_prompt, 5)
    restore_mmc(0)
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbhost_port'])
    raise e
  end
 
  boot_to_kernel = @test_params.params_chan.instance_variable_defined?(:@boot_to_kernel) ? @test_params.params_chan.boot_to_kernel[0] : 'no'
  if boot_to_kernel == 'yes'
    # check if the dut can boot to kernel under usbrndis booting mode
    flash_or_boot_kernel_fromto_media('boot', 'eth')
  end
 
  report_msg "===== USB-ETH BOOT END =====" 
  return status 
end 

