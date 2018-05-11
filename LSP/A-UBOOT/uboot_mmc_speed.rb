# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript

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
  result = 0

  platform = @test_params.platform
  puts "platform: "+platform

  device = @test_params.params_chan.device[0].downcase
  case device
  when "mmc"
    @equipment['dut1'].send_cmd("mmc dev 0; mmc info", @equipment['dut1'].boot_prompt, 5)
    raise "MMC bus width is not 4-bit" if !@equipment['dut1'].response.match(/Bus\s+Width\s*:\s+4-bit/i)
    mmc_op_mode = @test_params.params_chan.mmc_op_mode[0].downcase
    expected_speed = get_expected_busspeed_sd(platform, mmc_op_mode)
    raise "expected speed for SD card can not be empty" if expected_speed == nil
    if ! @equipment['dut1'].response.match(/Bus\s+Speed\s*:\s+#{expected_speed}/i)
      result += 1
      result_msg = result_msg + "SD card is not working at expected speed: #{mmc_op_mode}::#{expected_speed} ; "
    end
  
  when 'emmc'
    @equipment['dut1'].send_cmd("mmc dev 1; mmc info", @equipment['dut1'].boot_prompt, 5)
    raise "eMMC bus width is not 8-bit" if !@equipment['dut1'].response.match(/Bus\s+Width\s*:\s+8-bit/i)
    expected_speed = get_expected_busspeed_emmc(platform)
    raise "expected speed for eMMC can not be empty" if expected_speed == nil
    if ! @equipment['dut1'].response.match(/Bus\s+Speed\s*:\s+#{expected_speed}/i)
      result += 1
      result_msg = result_msg + "EMMC is not working at expected speed: #{mmc_op_mode}::#{expected_speed} ; "
    end
  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test pass")
  else
    set_result(FrameworkConstants::Result[:fail], result_msg)
  end

end

def clean
  	#self.as(LspTestScript).clean
    puts "clean..."
end

def get_expected_speed_sd(platform, sd_mode)
  expected_speed_sd = Hash.new({ 'sdr104' => '208000000', 'ddr50' => '50000000', })
  expected_speed_sd['am57xx-evm'] = { 'sdr104' => '50000000', 'ddr50' => '50000000', }
  return expected_speed_sd[platform][sd_mode]
end

def get_expected_busspeed_sd(platform, sd_mode)
  expected_speed_sd = Hash.new({ 'sdr104' => '192000000', 'ddr50' => '96000000', 'hs' => '48000000'})
  #expected_speed_sd['am57xx-evm'] = { 'sdr104' => '48000000', 'ddr50' => '48000000', }
  return expected_speed_sd[platform][sd_mode]
end

def get_expected_speed_emmc(platform)
  expected_speed_emmc = Hash.new('200000000') 
  expected_speed_emmc['am57xx-evm'] = '52000000'
  return expected_speed_emmc[platform]
end

def get_expected_busspeed_emmc(platform)
  expected_speed_emmc = Hash.new('192000000')
  expected_speed_emmc['am57xx-evm'] = '48000000'
  return expected_speed_emmc[platform]
end

