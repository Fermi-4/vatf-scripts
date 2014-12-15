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
  ecc_bits = 1
  chunk_size = 512
  nand_env_part_addr_start = get_nand_env_part_addr()
  nand_pagesize = get_nand_pagesize()
  ramaddress = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress')
  ramaddress_2 = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress_2')
  ramaddress_3 = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress_3')
  ecc_bits = @test_params.params_chan.ecc_bits[0] if @test_params.params_chan.instance_variable_defined?(:@ecc_bits)
  chunk_size = @test_params.params_chan.chunk_size[0] if @test_params.params_chan.instance_variable_defined?(:@chunk_size)
  err_byte = 0xFF >> (8 - ecc_bits.to_i) 

  @equipment['dut1'].send_cmd("nand erase #{nand_env_part_addr_start} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("saveenv",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("saveenv",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand dump #{nand_env_part_addr_start} page",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand read.raw #{ramaddress} #{nand_env_part_addr_start} 1",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("md.b #{ramaddress} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)

  # modify the data
  # assume nand page size is multiple of 512 which is chunk size
  cnt = nand_pagesize.to_i(16) / chunk_size.to_i 
  x = 0
  byte_orig_arr = []
  while x < cnt do
    this_addr = (ramaddress.to_i(16) + x*chunk_size.to_i).to_s(16)
    byte_orig = get_first_byte(this_addr)
    byte_orig_arr << byte_orig
    byte_mod = (byte_orig.hex.to_i ^ err_byte).to_s(16)
    @equipment['dut1'].send_cmd("mm.b #{this_addr}", /\?/, 5)
    @equipment['dut1'].send_cmd("#{byte_mod}", /\?/, 5)
    @equipment['dut1'].send_cmd("q", @equipment['dut1'].boot_prompt, 5)
    x += 1
  end

  # write the modified data into nand 
  @equipment['dut1'].send_cmd("nand erase #{nand_env_part_addr_start} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand write.raw #{ramaddress} #{nand_env_part_addr_start}",@equipment['dut1'].boot_prompt, 5)

  # show modified data
  @equipment['dut1'].send_cmd("nand read.raw #{ramaddress_2} #{nand_env_part_addr_start} 1",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("md.b #{ramaddress_2} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)

  # show corrected data
  @equipment['dut1'].send_cmd("nand read #{ramaddress_3} #{nand_env_part_addr_start} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 10)
  @equipment['dut1'].send_cmd("md.b #{ramaddress_3} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)

  # compare orig with the corrected data below
  cnt = nand_pagesize.to_i(16) / chunk_size.to_i 
  x = 0
  while x < cnt do
    this_addr_2 = (ramaddress_2.to_i(16) + x*chunk_size.to_i).to_s(16)
    this_addr_3 = (ramaddress_3.to_i(16) + x*chunk_size.to_i).to_s(16)
    err_byte = get_first_byte(this_addr_2)
    corrected_byte = get_first_byte(this_addr_3)
    if byte_orig_arr[x] != corrected_byte
      result += 1
    end
    result_msg = result_msg + "For cnt=#{x.to_s}: Original byte is 0x#{byte_orig_arr[x]}, err_byte is 0x#{err_byte} and the corrected_byte is 0x#{corrected_byte}; "
    x += 1
  end

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "The error bits are not corrected; #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end

end

def clean
  	#super
  	self.as(LspTestScript).clean
end

# get the first byte from memeory
def get_first_byte(ramaddress)
  @equipment['dut1'].send_cmd("md.b #{ramaddress} 1", @equipment['dut1'].boot_prompt, 5)
  md_response = @equipment['dut1'].response if !@equipment['dut1'].timeout?
  first_byte = /\d+\s*:\s*([0-9A-Fa-f]+)/m.match(md_response).captures[0]
  return first_byte
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
  env_start_addr = /Erasing\s+at\s+(0x\h+)/.match(@equipment['dut1'].response).captures[0]
  return env_start_addr
  
end

