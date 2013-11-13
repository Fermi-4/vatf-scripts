require File.dirname(__FILE__)+'/default_boot_order_test' 

def run
  @translated_boot_params = get_image()
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  puts "At this Stage booted from any media"
  puts "Made sure emmc is erased"
  erase_emmc_device(1,100, 2800) 
  uart_boot()
  restore_mmc(1)
  status = uboot_sanity_test()
  if status < 1
    set_result(FrameworkConstants::Result[:pass], "Boot Order Test Pass","")
  else
    set_result(FrameworkConstants::Result[:fail], test_result,"")   
  end  
end


# Function does boot the dut from UART.
# Input parameters: None 
# Return Parameter: None

def uart_boot()
  puts "turn OFF USB Swtich !!!!!!!!!" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  puts "turn ON USB Switch !!!!!!!!!" 
  @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
  
end 

