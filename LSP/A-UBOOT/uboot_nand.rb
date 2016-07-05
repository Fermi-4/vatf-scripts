# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
include PlatformSpecificVarNames

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run
	#self.as(LspTestScript).run
  result = 0
  result_msg = ''
  nand_pagesize = get_nand_pagesize()
  ramaddress = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress')
  nand_test_addr = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'nand_test_addr')

  @equipment['dut1'].send_cmd("nand markbad #{nand_test_addr}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand bad",@equipment['dut1'].boot_prompt, 5)
  if !@equipment['dut1'].response.match(nand_test_addr.strip) 
    result += 1
    result_msg = result_msg + "block #{nand_test_addr} did not marked as bad; "
  end
  puts "===========result: #{result}===and result_msg: #{result_msg}========="

  @equipment['dut1'].send_cmd("nand erase.spread #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 30)
  @equipment['dut1'].send_cmd("nand write #{ramaddress} #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 30)

  if ! @equipment['dut1'].response.include?("bad block 0x#{nand_test_addr}") || @equipment['dut1'].response.match(/(error|failed)/i) 
    result += 1
    result_msg = result_msg + "nand write did not skip bad block #{nand_test_addr} or there is error; "
  end
  puts "===========nand write result: #{result}===and result_msg: #{result_msg}========="

  @equipment['dut1'].send_cmd("nand read #{ramaddress} #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)

  if ! @equipment['dut1'].response.include?("bad block 0x#{nand_test_addr}") || @equipment['dut1'].response.match(/(error|failed)/i) 
    result += 1
    result_msg = result_msg + "nand read did not skip bad block #{nand_test_addr} or there is error; "
  end
  puts "===========nand read result: #{result}===and result_msg: #{result_msg}========="
 
  @equipment['dut1'].send_cmd("nand erase #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)

  if ! @equipment['dut1'].response.match(/bad\s+block\s+at\s+0x#{nand_test_addr}/) || @equipment['dut1'].response.match(/(error|failed)/i)
    result += 1
    result_msg = result_msg + "nand erase did not skip bad block #{nand_test_addr} or there is error; "
  end
  puts "===========nand erase result: #{result}===and result_msg: #{result_msg}========="

  # test clean bad blocks
  @equipment['dut1'].send_cmd("nand scrub -y #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand bad",@equipment['dut1'].boot_prompt, 5)
  if @equipment['dut1'].response.match("#{nand_test_addr}")
    result += 1
    result_msg = result_msg + "block #{nand_test_addr} is still marked as bad and nand scrub did not work; "
  end
  puts "===========nand scrub result: #{result}===and result_msg: #{result_msg}========="

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "Test failed: #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end

end

def clean
  	#super
  	self.as(LspTestScript).clean
end

# get nand pagesize in hex dynamically in uboot prompt
def get_nand_pagesize
  # get nand pagesize in uboot prompt
  @equipment['dut1'].send_cmd("nand info",@equipment['dut1'].boot_prompt, 5)
  pagesize = /Page\s+size\s+(\d+)/.match(@equipment['dut1'].response).captures[0]
  pagesize = pagesize.to_i.to_s(16)
  return pagesize
end

# get nand env partition start addr in uboot prompt
def get_nand_env_part_addr
  @equipment['dut1'].send_cmd("saveenv",@equipment['dut1'].boot_prompt, 5)
  env_start_addr = /Erasing\s+at\s+(0x\d+)/.match(@equipment['dut1'].response).captures[0]
  return env_start_addr
  
end

