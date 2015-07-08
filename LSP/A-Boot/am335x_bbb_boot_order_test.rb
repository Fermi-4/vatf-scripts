# This script is to test BBB boot from emmc -> uart -> usb. 
# Asssumption: 1) the power line can be controlled to turn on/off
#              2) no mmc card present (due to mmc failover doesn't work)
require File.dirname(__FILE__)+'/default_boot_order_test' 

def connect_to_extra_equipment
  usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usbclient_port'].keys[0]]
  if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
    usb_switch.connect({'type'=>'serial'})
  else
    raise "Something wrong with usb switch connection. Please check your setup"
  end

end

def uart_boot()
  report_msg "##### UART BOOT START #####" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    reboot_dut()
  end
  raise "uart_boot::DUT is not in uboot prompt" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})

  begin
    # remove emmc from boot sequence
    erase_emmc_device(1, 100, 2800) 
    @equipment['dut1'].disconnect()
    # boot from uart
    @translated_boot_params['primary_bootloader_dev'] = 'uart'
    @equipment['dut1'].boot_loader = nil
    boot_to_bootloader()

    status =  uboot_sanity_test()
    puts "uart_boot:: RESTORING EMMC ..." 
    restore_mmc(1)
  rescue Exception => e
    restore_mmc(1)
    raise e
  end

  # check if the dut can boot to kernel under uart booting mode
  flash_or_boot_kernel_fromto_media('boot', 'eth')

  report_msg "##### UART BOOT END #####" 
  return status 
end 

# Function does boot the dut from USB(RNDIS).
# Input parameters: None 
# Return Parameter: pass or fail.  

def usbrndis_boot()
  report_msg "##### USB-ETH BOOT START #####" 
  init_dhcp()

  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    reboot_dut()
  end
  raise "usbrndis_boot::DUT is not in uboot prompt" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})

  begin
    invalidate_mmc(1) 

    # usb boot won't happen without discoonect power cable
    @power_handler.switch_off(@equipment['dut1'].power_port)

    # Once the usb cable is connected, usb0 interface is established and dhcp server will be restarted
    # per /etc/NetworkManager/dispatcher.d rule
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
    sleep 1
    @usb_switch_handler.select_input(@equipment['dut1'].params['usbclient_port'])

    # Dut should boot from usb-eth by now
    @equipment['dut1'].wait_for(/Bytes\s+transferred/i, 60)
    raise "USB_BOOT:: uboot was not able to tftp to target" if @equipment['dut1'].timeout?
    @equipment['dut1'].stop_boot()

    status = uboot_sanity_test()

    # restore to original settings
    @equipment['dut1'].send_cmd("setenv ethact cpsw", @equipment['dut1'].boot_prompt, 5)
    restore_mmc(1)

  rescue Exception => e
    restore_mmc(1)
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
    raise e
  end
 
  # check if the dut can boot to kernel under usbrndis booting mode
  sleep 1
  flash_or_boot_kernel_fromto_media('boot', 'eth')

  @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])
  @power_handler.switch_on(@equipment['dut1'].power_port)

  report_msg "##### USB-ETH BOOT END #####" 
  return status 
end 


# Function does boot the dut from EMMC.
#     Try boot from exising emmc first; if failed, then try to boot from uart;
#     Then, update emmc with the to-be-tested bootloaders. Then verify the emmc
#     boot.
# Input parameters: None 
# Return Parameter: pass or fail.  
def emmc_boot()
  report_msg "##### EMMC BOOT START #####" 
  
  # remove uart from boot sequence
  @translated_boot_params['primary_bootloader_dev'] = 'none'
  @equipment['dut1'].boot_loader = nil

  # remove usb from boot sequence
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usbclient_port'].keys[0])

  # the board should boot from emmc now 
  puts "The board suppose to boot from emmc on power cycle"
  reboot_dut()  
  if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
    puts "Oops, the board could not boot from emmc, now try to boot from uart to update emmc"
    # if emmc boot fails, update emmc using uart boot
    puts "suppose the board boot from uart here"
    @translated_boot_params['primary_bootloader_dev'] = 'uart'
    @equipment['dut1'].boot_loader = nil
    boot_to_bootloader()
    raise "emmc_boot::DUT is not in uboot prompt after uart boot" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
  else
    puts "DUT boots from existing emmc successfully."
  end
  puts "Updating emmc..."
  restore_mmc(1)
  # remove uart from boot sequence so board boot from emmc
  @translated_boot_params['primary_bootloader_dev'] = 'none'
  @equipment['dut1'].boot_loader = nil
  reboot_dut()
  raise "emmc_boot: EMMC boot failed!" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})

  status= uboot_sanity_test()

  # check if the board can boot kernel from nand
  flash_or_boot_kernel_fromto_media('flash', 'rawmmc', 1)
  flash_or_boot_kernel_fromto_media('boot', 'rawmmc', 1)

  report_msg "##### EMMC BOOT END #####" 
  return status 
end 


