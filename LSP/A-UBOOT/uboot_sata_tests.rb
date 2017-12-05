# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
   
include LspTestScript

def setup
	@equipment['dut1'].set_api('psp')

end

def run
  result = 0
  result_msg = ""

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get to bootloader prompt' if @equipment['dut1'].timeout?

  media = @test_params.params_chan.instance_variable_defined?(:@media) ? @test_params.params_chan.media[0].downcase : 'fat-sata'

  @equipment['dut1'].send_cmd("scsi scan", @equipment['dut1'].boot_prompt, 5)
  raise "No SATA device being detected" if ! @equipment['dut1'].response.match(/Found\s+\d+\s+device/i)
  @equipment['dut1'].send_cmd("scsi info", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("scsi dev", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("scsi part", @equipment['dut1'].boot_prompt, 5)

  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  case media.downcase
  when "raw-sata"
    filesize_hex, crc32_srcfile = tftp_file "${loadaddr}", "#{tmp_path}/#{File.basename(translated_boot_params['kernel_image_name'])}"
    puts "crc32_srcfile:"+crc32_srcfile

    cnt = get_blk_cnt(filesize_hex, 512)
    @equipment['dut1'].send_cmd("scsi write ${loadaddr} 0 #{cnt}", @equipment['dut1'].boot_prompt, 300)
    sleep 1
    @equipment['dut1'].send_cmd("scsi read ${loadaddr} 0 #{cnt}", @equipment['dut1'].boot_prompt, 300)
    crc32_dstfile = get_crc32("${loadaddr}", filesize_hex, 120)
    puts "crc32_dstfile:"+crc32_dstfile
  when "fat-sata"
    @equipment['dut1'].send_cmd("scsi part 0", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("ls scsi 0:1", @equipment['dut1'].boot_prompt, 10)
    if !@equipment['dut1'].response.match(/file\(s\),\s+\d+\s+dir/im)
      # boot to kernel to create/format partition 
      create_format_partition translated_boot_params
      translated_boot_params['dut'].boot_to_bootloader translated_boot_params
      @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
      @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
      raise 'Failed to stop at bootloader prompt after format sata partition in kernel' if @equipment['dut1'].timeout?
    end
    filesize_hex, crc32_srcfile = tftp_file "${loadaddr}", "#{tmp_path}/#{File.basename(translated_boot_params['kernel_image_name'])}"
    puts "crc32_srcfile:"+crc32_srcfile

    @equipment['dut1'].send_cmd("ls scsi 0:1", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("fatwrite scsi 0:1 ${loadaddr} zImage #{filesize_hex}", @equipment['dut1'].boot_prompt, 300)
    sleep 1
    @equipment['dut1'].send_cmd("fatload scsi 0:1 ${loadaddr} zImage #{filesize_hex}", @equipment['dut1'].boot_prompt, 300)
    crc32_dstfile = get_crc32("${loadaddr}", filesize_hex, 120)
    puts "crc32_dstfile:"+crc32_dstfile
  else
    raise "Unknow media type: #{media}"
  end
 
  if (crc32_dstfile != crc32_srcfile)
    result = result + 1
    result_msg = "crc32 of the file read from scsi is not the same as the one being written to scsi"
  else
    report_msg "File read is the same as the file written"
  end

  if result != 0
      set_result(FrameworkConstants::Result[:fail], "The test failed; #{result_msg}")
  else
      set_result(FrameworkConstants::Result[:pass], "Test Pass. #{result_msg}")
  end


end

def tftp_file(memaddr, filepath_in_tftp)
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv autoload no", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("dhcp", @equipment['dut1'].boot_prompt, 30)

  @equipment['dut1'].send_cmd("tftp #{memaddr} #{filepath_in_tftp}", @equipment['dut1'].boot_prompt, 300)
  raise "Could not tftp kernel to dut" if !@equipment['dut1'].response.match(/Bytes\s+transferred/im)
 
  filesize_hex = get_filesize
  @equipment['dut1'].send_cmd("crc32 #{memaddr} #{filesize_hex}", @equipment['dut1'].boot_prompt, 120)
  crc32 = get_crc32("#{memaddr}", filesize_hex, 120)
  return [filesize_hex, crc32]
end

def create_format_partition(params)
  # first boot to kernel
  params['bootargs'] = @equipment['dut1'].boot_args
  @equipment['dut1'].system_loader.run params
  # format partition
  # run ltp-ddt test; by default ltp-ddt format partition as vfat 
  cmd = "./runltp -P #{@equipment['dut1'].name} -f ddt/sata_dd_rw -s \"_S_\" "
  @equipment['dut1'].send_cmd("cd /opt/ltp; #{cmd}", @equipment['dut1'].prompt, 600)
  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2, false)
  raise "ltp-ddt sata test failed and failed to format partitions" if @equipment['dut1'].timeout?
end


def get_filesize()
  @equipment['dut1'].send_cmd("print filesize", @equipment['dut1'].boot_prompt, 10)
  size = /filesize\s*=\s*(\h+)/im.match(@equipment['dut1'].response).captures[0]
  return size
end

  # filesize: in hex
  # blk_len: in decimal
  # return: in hex
  def get_blk_cnt(filesize_hex, blk_len_dec)
    b = (filesize_hex.to_i(16).to_f / blk_len_dec.to_f).ceil
    cnt_hex = "0x" + b.to_s(16)
    return cnt_hex
  end

def get_crc32(memaddr, filesize_hex, timeout)
  @equipment['dut1'].send_cmd("crc32 #{memaddr} #{filesize_hex}", @equipment['dut1'].boot_prompt, timeout)
  crc32 = @equipment['dut1'].response.match(/==>\s*(\h+)/i).captures[0]
  return crc32

end

def clean
  	#self.as(LspTestScript).clean
    puts "clean..."
end


