# This script is to test BBB boot from emmc -> uart -> usb. 
# Asssumption: 1) the power line can be controlled to turn on/off
#              2) no mmc card present (due to mmc failover doesn't work)
require File.dirname(__FILE__)+'/default_boot_order_test' 

def uart_boot()
  puts "##### UART BOOT START #####" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
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
    puts "uart_boot:: TURNING ON USB Swtich ..." 
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
  rescue Exception => e
    restore_mmc(1)
    raise e
  end

  puts "##### UART BOOT END #####" 
  return status 
end 

# Function does boot the dut from USB(RNDIS).
# Input parameters: None 
# Return Parameter: pass or fail.  

def usb_boot()
  puts "##### USB-ETH BOOT START #####" 
  init_dhcp()

  begin
    invalidate_mmc(1) 

    # usb boot won't happen without discoonect power cable
    @power_handler.switch_off(@equipment['dut1'].power_port)

    # Once the usb cable is connected, usb0 interface is established and dhcp server will be restarted
    # per /etc/NetworkManager/dispatcher.d rule
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
    sleep 1
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])

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
    raise e
  end
 
  puts "##### USB-ETH BOOT END #####" 
  return status 
end 


# Function does boot the dut from EMMC.
# Input parameters: None 
# Return Parameter: pass or fail.  
def emmc_boot()
  puts "##### EMMC BOOT START #####" 
  
  2.times {
    # remove uart from boot sequence
    @translated_boot_params['primary_bootloader_dev'] = 'none'
    @equipment['dut1'].boot_loader = nil

    # remove usb from boot sequence
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])

    # the board should boot from emmc now 
    puts "The board suppose to boot from emmc on power cycle"
    reboot_dut()  
    if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
      puts "Oops, the board could not boot from emmc, now try to boot from uart to restore emmc"
      # if emmc boot fails, restore emmc using uart boot
      @translated_boot_params['primary_bootloader_dev'] = 'uart'
      @equipment['dut1'].boot_loader = nil
      puts "suppose the board boot from uart here"
      boot_to_bootloader()
      raise "emmc_boot::DUT is not in uboot prompt after uart boot" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
      restore_mmc(1)
    else
      puts "DUT boots from emmc successfully!"
      break
    end
  }
  raise "eMMC boot failed" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})
  status= uboot_sanity_test()

  puts "##### EMMC BOOT END #####" 
  return status 
end 


