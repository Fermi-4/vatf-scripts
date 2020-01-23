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

  nand_pagesize = get_nand_pagesize()
  nand_test_addr = get_nand_test_addr(@test_params.platform)
  
  testfile = "#{@linux_temp_folder}/nand_testfile"
  @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{testfile} bs=1 count=#{nand_pagesize.to_i(16)}", @equipment['server1'].prompt, 60)
  transfer_testdata_to_dut(testfile)
  write_testdata_to_nand(nand_test_addr, nand_pagesize)
  ramaddress = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress')
  ramaddress_2 = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress_2')
  ramaddress_3 = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'ramaddress_3')
  chunk_size = @test_params.params_chan.chunk_size[0] if @test_params.params_chan.instance_variable_defined?(:@chunk_size)
  ecc_bits = @test_params.params_chan.ecc_bits[0] if @test_params.params_chan.instance_variable_defined?(:@ecc_bits)
  err_mask = []
  if ecc_bits.to_i <= 8
    byte_num = 1
    err_mask[0] = 0xFF >> (8 - ecc_bits.to_i) 
  elsif (ecc_bits.to_i > 8) && (ecc_bits.to_i <= 16)
    byte_num = 2
    err_mask[0] = 0xFF
    err_mask[1] = 0xFF >> (8 - (ecc_bits.to_i - 8))
  else
    raise "ecc_bits is too big, this nandecc script does not support it yet"
  end

  @equipment['dut1'].send_cmd("nand dump #{nand_test_addr} page",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand read.raw #{ramaddress} #{nand_test_addr} 1",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("md.b #{ramaddress} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  sleep 5

  # modify the data
  # assume nand page size is multiple of 512 which is chunk size
  cnt = nand_pagesize.to_i(16) / chunk_size.to_i 
  byte_orig_arr = Array.new(cnt) {Array.new(byte_num) }
  x = 0
  while x < cnt do
    for index in 0..(byte_num-1) do
      this_addr = (ramaddress.to_i(16) + x*chunk_size.to_i + index.to_i).to_s(16)
      byte_orig = retrieve_byte(this_addr)
      byte_orig_arr[x][index] = byte_orig
      modify_byte(this_addr, byte_orig, err_mask[index])
    end

    x += 1
  end

  # write the modified data into nand 
  @equipment['dut1'].send_cmd("nand erase #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("nand write.raw #{ramaddress} #{nand_test_addr}",@equipment['dut1'].boot_prompt, 5)

  # show modified data
  @equipment['dut1'].send_cmd("nand read.raw #{ramaddress_2} #{nand_test_addr} 1",@equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("md.b #{ramaddress_2} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  sleep 5

  # show corrected data
  @equipment['dut1'].send_cmd("nand read #{ramaddress_3} #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 10)
  @equipment['dut1'].send_cmd("md.b #{ramaddress_3} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 10)
  sleep 5

  # compare orig with the corrected data below
  cnt = nand_pagesize.to_i(16) / chunk_size.to_i 
  x = 0
  while x < cnt do
    for index in 0..(byte_num-1) do
      this_addr_2 = (ramaddress_2.to_i(16) + x*chunk_size.to_i + index.to_i).to_s(16)
      this_addr_3 = (ramaddress_3.to_i(16) + x*chunk_size.to_i + index.to_i).to_s(16)
      err_byte = retrieve_byte(this_addr_2)
      corrected_byte = retrieve_byte(this_addr_3)
      if byte_orig_arr[x][index] != corrected_byte
        result += 1
      end
      result_msg = result_msg + "For cnt=#{x.to_s}: Original byte is 0x#{byte_orig_arr[x][index]}, err_byte is 0x#{err_byte} and the corrected_byte is 0x#{corrected_byte}; "
    end
    x += 1
  end

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "The error bits are not corrected; #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end

end

def clean
  puts "uboot nandecc test cleaning"
end


# modify byte on this_addr 
def modify_byte(this_addr, byte_orig, err_mask)
    byte_mod = (byte_orig.hex.to_i ^ err_mask).to_s(16)
    @equipment['dut1'].send_cmd("mm.b #{this_addr}", /\?/, 5)
    @equipment['dut1'].send_cmd("#{byte_mod}", /\?/, 5)
    @equipment['dut1'].send_cmd("q", @equipment['dut1'].boot_prompt, 5)

end

# get the byte from memeory
def retrieve_byte(ramaddr)
  @equipment['dut1'].send_cmd("md.b #{ramaddr} 1", @equipment['dut1'].boot_prompt, 5)
  sleep 5
  md_response = @equipment['dut1'].response if !@equipment['dut1'].timeout?
  this_byte = /\d+\s*:\s*([0-9A-Fa-f]+)/m.match(md_response).captures[0]
  return this_byte
end

# get nand pagesize in hex dynamically in uboot prompt
def get_nand_pagesize
  # get nand pagesize in uboot prompt
  @equipment['dut1'].send_cmd("nand info",@equipment['dut1'].boot_prompt, 5)
  pagesize = /Page\s+size\s+(\d+)/.match(@equipment['dut1'].response).captures[0]
  pagesize = pagesize.to_i.to_s(16)
  return pagesize
end

# get nand test add, it could be any addr in nand. now choose an addr in file-system partition
# this addr should work for every platforms; if not, it can be overwritten.
def get_nand_test_addr(platform)
  case platform
  when "am335x-evm"
    nand_addr = "0x1000000"
  else
    nand_addr = "0x1000000"
  end
  return nand_addr
end

# get nand env partition start addr in uboot prompt
def get_nand_env_part_addr
  @equipment['dut1'].send_cmd("saveenv",@equipment['dut1'].boot_prompt, 5)
  env_start_addr = /Erasing\s+at\s+(0x\h+)/.match(@equipment['dut1'].response).captures[0]
  return env_start_addr
  
end

# transfer data from linux host to ${loadaddr} in dut
def transfer_testdata_to_dut(testfile)
  # copy testfile to tftpboot
  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  dst_dir = File.join(@equipment['server1'].tftp_path, tmp_path)
  copy_asset(@equipment['server1'], testfile, dst_dir)
  # tftp to dut
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv autoload no", @equipment['dut1'].boot_prompt, 5)
  3.times {
    @equipment['dut1'].send_cmd("dhcp", /DHCP client bound to address.*#{@equipment['dut1'].boot_prompt}/im, 30)
    break if !@equipment['dut1'].timeout?
  }

  @equipment['dut1'].send_cmd("tftp ${loadaddr} #{tmp_path}/#{File.basename(testfile)}", @equipment['dut1'].boot_prompt, 60)
  raise "Could not tftp nand testfile to dut" if !@equipment['dut1'].response.match(/Bytes\s+transferred/im)  
end

# write data from ${loadaddr} to nand
def write_testdata_to_nand(nand_test_addr, nand_pagesize)
  @equipment['dut1'].send_cmd("nand erase #{nand_test_addr} #{nand_pagesize}",@equipment['dut1'].boot_prompt, 5)
  # nand write - addr off|partition size
  @equipment['dut1'].send_cmd("nand write ${loadaddr} #{nand_test_addr} #{nand_pagesize}", @equipment['dut1'].boot_prompt, 60)
  raise "Nand write failed" if !@equipment['dut1'].response.match(/bytes\s+written:\s+OK/im)
end

