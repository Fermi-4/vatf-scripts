require File.dirname(__FILE__)+'/default_boot_order_test' 

#Description
# The file defines functions used to test boot order uart->spi->nand
# on am335x EVM. Since the target is boot order related to nand, 
# only uart->fail over->nand is tested here. Booting from spi is not 
# being tested here. Once the platform is booted from uart and image is 
# loaded to nand, the platform is expected to fail over to nand, if spi 
# is not programmed. For this test to work the am335x evm switch (SW4)
# is expected to be programmed manually with SYSBOOT hex value of 4002.
#  SYSBOOT[4:0] values are 00010b. Test setups
# are described in default_boot_order.rb
# To run this test, bench configuration must be configured as: 
# dut = EquipmentInfo.new("platform", "linux_sysboot4002_")
# on DNS workaround file 
# hwassets=[platform,linux_sysboot4002_]
# on the test case:
# dut1=["<platform>",linux_sysboot4002];server1=["linux_server"]

# Function does boot from nand.
# Input parameters: None 
# Return Parameter: pass or fail. 

def nand_boot()
  # Set DUT IP 
  set_dut_ipaddr()
  #set server ip
  uboot_cmd = "setenv serverip #{@equipment['server1'].telnet_ip}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  #Because platform booted from UART, needed to chage image from SPL to MLO
  @translated_boot_params['primary_bootloader'] = @translated_boot_params['primary_bootloader_MLO']
  @translated_boot_params['primary_bootloader_image_name'] = @translated_boot_params['primary_bootloader_MLO_image_name']
  #Because platform booted from UART, needed to change from uart to nand 
  @translated_boot_params['primary_bootloader_dev'] = 'nand'
  #need to update image location
  @translated_boot_params = add_dev_loc_to_params(@translated_boot_params, 'primary_bootloader')
  #do uboot environment setup
  test_prep = PrepStep.new()
  test_prep.run(@translated_boot_params)
  #write primary boot loader to nand
  primary_boot_loader = FlashPrimaryBootloaderStep.new()
  primary_boot_loader.run(@translated_boot_params)
  #write secondary boot loader to nand 
  secondary_boot_loader = FlashSecondaryBootloaderStep.new()
  secondary_boot_loader.run(@translated_boot_params)
  #reboot the platfrom to boot from nand
  regexp = /Hit\s+any\s+key\s+to\s+stop\s+autoboot/i
  reboot_dut(regexp)
  status =  uboot_sanity_test()
  return status 
end 

# Function does boot the dut from UART.
# Input parameters: None 
# Return Parameter: pass or fail. 

def uart_boot()
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  status =  uboot_sanity_test()
  return status 
end 

