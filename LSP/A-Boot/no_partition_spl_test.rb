require File.dirname(__FILE__)+'/default_boot_order_test' 

def run
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


# Function erases emmc
# Input parameters: part (partition), block (starting block), count  
# Return Parameter: None.  

def erase_emmc_device(part,blocks, count) 
  # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/Card\+did\+not\+respond\+to\+voltage\+select/)
  raise "Device is not selected" if device_set == nil
  # Ensure we are able to talk with this mmc device
  uboot_cmd = "mmc erase #{blocks} #{count}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/erase:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

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

