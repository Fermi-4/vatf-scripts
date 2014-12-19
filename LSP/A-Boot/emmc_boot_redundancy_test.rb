require File.dirname(__FILE__)+'/default_boot_order_test' 

def run
  @translated_boot_params = get_image()
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  puts "Invalidate both blocks on eMMC"
  disable_blocks(1,100, 100)
  disable_blocks(1,200, 100)
  uart_boot()
  puts "Boot from default emmc block 1"
  enable_blocks(1,100, 100,@translated_boot_params)
  reboot_dut
  status = uboot_sanity_test()
  if status < 1
    puts "Now invalidate emmc block 1"
    disable_blocks(1,100, 100)
    uart_boot()
    puts "Boot from default emmc block 2"
    enable_blocks(1,200, 100,@translated_boot_params)
    reboot_dut
    status = uboot_sanity_test()
  end 
  if status  < 1
    set_result(FrameworkConstants::Result[:pass], "Boot redundancy pass!","")
  else
    set_result(FrameworkConstants::Result[:fail], "Boot redundancy Failed!","")   
  end  
end


# Function enable sd and emmc media.
# Input parameters: part (partition), block (starting block), count 
# Return Parameter: None.  

def enable_blocks(part,blocks, count,translated_params) 
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  configut_dut(part)
  # Load MLO
  raise "no MLO to be tftp-ed" if translated_params['primary_bootloader_mmc_image_name']==nil
  uboot_cmd = "tftp ${loadaddr} #{translated_params['primary_bootloader_mmc_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load =  @equipment['dut1'].response.to_s.scan(/done/)
  raise "MLO tftp load failed" if tftp_load == nil
  # Write MLO to device 
  uboot_cmd = "mmc write ${loadaddr} #{blocks} #{count}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

end 

# Function disable sd and emmc media.
# Input parameters: part (partition), block (starting block), count 
# Return Parameter: None.  

def disable_blocks(part,blocks, count)
  puts "INVALIDATING a block >>>>>>>>>>>>>"
  configut_dut(part)
  # Load MLO
  uboot_cmd = "mw ${loadaddr} ffffffff 100"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  uboot_cmd = "md ${loadaddr}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mem_data = @equipment['dut1'].response.to_s.scan(/ffffffff /)
  raise "write garbage data to memory failed" if mem_data == nil
 
  # Write MLO to device 
  uboot_cmd = "mmc write ${loadaddr} #{blocks} #{count}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

end 

# Function does configures dut ip and selects boot media.
# Input parameters: part to select boot device. 
# Return Parameter: None 

def configut_dut(part)
  # Set DUT IP 
  set_dut_ipaddr()
  #set server ip
  uboot_cmd = "setenv serverip #{@equipment['server1'].telnet_ip}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
 # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/Card\+did\+not\+respond\+to\+voltage\+select/)
  raise "Device is not selected" if device_set == nil
end

# Function does boot the dut from UART.
# Input parameters: None 
# Return Parameter: None 

def uart_boot()
  puts "turn OFF USB Swtich !!!!!!!!!" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
end 


