# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
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
  result_msg = ''
  perfs = []

  @equipment['dut1'].send_cmd("help time", @equipment['dut1'].boot_prompt, 5)
  if @equipment['dut1'].response.match("Unknown command")
    raise " 'time' command needs to be enabled in uboot. Please enable CONFIG_CMD_TIME. "
  end

  device = @test_params.params_chan.device[0]

  case device.downcase
  when /spi/

    # both test_addr and test_size are in hex format
    test_addr = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'qspi_test_addr')
    test_size = PlatformSpecificVarNames.translate_var_name(@test_params.platform,'qspi_test_size')

    testfile = "#{@linux_temp_folder}/perf_testfile"
    @equipment['server1'].send_cmd("dd if=/dev/urandom of=#{testfile} bs=1 count=#{test_size.to_i(16)}", @equipment['server1'].prompt, 60)
    @equipment['dut1'].send_cmd("sf probe", @equipment['dut1'].boot_prompt, 10)
    @equipment['dut1'].send_cmd("time sf erase #{test_addr} #{test_size}", @equipment['dut1'].boot_prompt, 120)
    tftp_testfile_to_dut(testfile)
    @equipment['dut1'].send_cmd("time sf write ${loadaddr} #{test_addr} #{test_size}", @equipment['dut1'].boot_prompt, 120)
    write_perf = calculate_perf(@equipment['dut1'].response, test_size)
    perfs << {'name' => "UBoot #{device} Write Throughput", 'value' => write_perf, 'units' => 'KB/S'}
    
    @equipment['dut1'].send_cmd("time sf read ${loadaddr} #{test_addr} #{test_size}", @equipment['dut1'].boot_prompt, 60)
    read_perf = calculate_perf(@equipment['dut1'].response, test_size)
    perfs << {'name' => "UBoot #{device} Read Throughput", 'value' => read_perf, 'units' => 'KB/S'}

  else
    raise "Measuring RW performance for device #{device} is not supported"
  end

  if perfs.size > 0
    set_result(FrameworkConstants::Result[:pass], "UBoot throughput data collected. ", perfs)
  else
    resultMsg = "Could not get UBoot throughput data" if !resultMsg
    set_result(FrameworkConstants::Result[:fail], resultMsg)
  end

end

def clean
  	#super
  	self.as(LspTestScript).clean
end

# The throughput will be in KBytes/sec
def calculate_perf(response, test_size)
  time_taken = response.match(/time\s*:\s*([\d\.]+)\s*seconds/i).captures[0]
  perf = (test_size.to_i(16).to_f / time_taken.to_f) /1024
  return perf.to_f.round(2)
end

# transfer data from linux host to ${loadaddr} in dut
def tftp_testfile_to_dut(testfile)
  # copy testfile to tftpboot
  tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  dst_dir = File.join(@equipment['server1'].tftp_path, tmp_path)
  copy_asset(@equipment['server1'], testfile, dst_dir)
  # tftp to dut
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("setenv autoload no", @equipment['dut1'].boot_prompt, 5)
  @equipment['dut1'].send_cmd("dhcp", @equipment['dut1'].boot_prompt, 30)
  @equipment['dut1'].send_cmd("tftp ${loadaddr} #{tmp_path}/#{File.basename(testfile)}", @equipment['dut1'].boot_prompt, 60)
  raise "Could not tftp testfile to dut" if !@equipment['dut1'].response.match(/Bytes\s+transferred/im)
end

