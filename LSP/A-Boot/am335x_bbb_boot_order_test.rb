require File.dirname(__FILE__)+'/default_boot_order_test' 

def uart_boot()
  puts "turn OFF USB Swtich !!!!!!!!!" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  @equipment['dut1'].wait_for(@equipment['dut1'].boot_prompt,20)
  if @equipment['dut1'].timeout?
    invalidate_mmc(1)
  end
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  status =  uboot_sanity_test()
  restore_mmc(1)
  puts "turn ON USB Swtich !!!!!!!!!" 
  @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
  return status 
end 

# Function does boot the dut from USB(RNDIS).
# Input parameters: None 
# Return Parameter: pass or fail.  

def usb_boot()
  puts "USB BOOTING .........."
  init_dhcp()
  invalidate_mmc(1) 
  regexp = /cccccc/i
  reboot_dut(regexp)
  #refressh dhcp because it is taking so long.
  #restarting dhcp to early is not initiating bootp
  sleep 5
  restart_dhcp()
  regexp = /BOOTP\s+broadcast/i
  @equipment['dut1'].wait_for(regexp,250)
  puts "BOOTP sent ..."
  #refresh dhcp 
  restart_dhcp()
  regexp = /Bytes\s+transferred/i
  @equipment['dut1'].wait_for(regexp,200)
  puts "Image loaded"
  #Sleep for image loading time
  sleep 5
  status = uboot_sanity_test()
  restore_mmc(1)
  return status 
end 


# Function does boot the dut from EMMC.
# Input parameters: None 
# Return Parameter: pass or fail.  

def emmc_boot()
  regexp = /Hit\s+any\s+key\s+to\s+stop\s+autoboot/i 
  reboot_dut(regexp)  
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  status= uboot_sanity_test()
  return status 
end 

