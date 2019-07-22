# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
# Script to test uboot pcie using intel ethernet card
   
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

  pcie_driver = @test_params.params_chan.instance_variable_defined?(:@pcie_driver) ? @test_params.params_chan.pcie_driver[0] : "e1000"
  @equipment['dut1'].send_cmd("help pci",@equipment['dut1'].boot_prompt, 10)
  @equipment['dut1'].send_cmd("pci e",@equipment['dut1'].boot_prompt, 10)
  if !@equipment['dut1'].response.match(/link\s+up/i)
    raise "Could not bring up PCIe link"
  end
  
  @equipment['dut1'].send_cmd("setenv ethact #{pcie_driver}#0",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("dhcp",@equipment['dut1'].boot_prompt, 60)
  if !@equipment['dut1'].response.match(/using\s+#{pcie_driver}/i)
    @equipment['dut1'].send_cmd("print ethact",@equipment['dut1'].boot_prompt, 10)
    raise "dhcp did not use PCIe #{pcie_driver} "
  end
  
  if !@equipment['dut1'].response.match(/DHCP\s+client\s+bound\s+to\s+address/i)
    raise "dhcp did not bound to address "
  end

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "Test Fail. #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end

end

def clean
  puts "clean"
end

