require File.dirname(__FILE__)+'/default_boot_order_test' 

#Description
# The file defines functions used to test boot order uart->spi->nand
# on am335x EVM. Since the target is boot order related to nand, 
# only uart->fail over->nand is tested here. Booting from spi is not 
# being tested here. Once the platform is booted from uart and image is 
# loaded to nand, the platform is expected to fail over to nand, if spi 
# is not programmed. For this test to work the am335x evm switch (SW4)
# is expected to be programmed manually with SYSBOOT[15:0] hex value of 4002.
# SW3: 2 ON; SW4: 7 ON
# SYSBOOT[4:0] values are 00010b. Test setups
# are described in default_boot_order.rb
# To run this test, bench configuration must be configured as: 
# dut = EquipmentInfo.new("platform", "linux_sysboot4002_")
# on DNS workaround file 
# hwassets=[platform,linux_sysboot4002_]
# on the test case:
# dut1=["<platform>",linux_sysboot4002];server1=["linux_server"]


def connect_to_extra_equipment
  puts 'skip this step since this test do not connect to usb switch'
end

# Function does boot the dut from UART.
# Input parameters: None 
# Return Parameter: pass or fail. 
def uart_boot()
  @translated_boot_params['primary_bootloader_dev'] = 'uart'
  puts "#### UART BOOT START ####"
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  status =  uboot_sanity_test()
  puts "#### UART BOOT END ####"
  return status 
end 

# Function does boot from nand.
# Input parameters: None 
# Return Parameter: pass or fail. 
def nand_boot()
  puts "#### NAND BOOT START ####"
  flash_nand()

  # set boot_loader to nil to not boot from uart
  @equipment['dut1'].boot_loader = nil
  boot_to_bootloader()
  status =  uboot_sanity_test()
  puts "#### VALIDATE NAND BOOT END ####"
  return status

end 



