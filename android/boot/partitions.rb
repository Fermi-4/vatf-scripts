require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

def run
  android_version = @equipment['dut1'].get_android_version
  partition_map = Hash.new({1 => 'xloader',
                            2 => 'bootloader',
                            3 => 'uboot-env',
                            4 => 'misc',
                            5 => 'recovery',
                            6 => 'boot',
                            7 => 'system',
                            8 => 'vendor',
                            9 => 'userdata'})
  @equipment['dut1'].disconnect('serial')
  @equipment['dut1'].boot_to_bootloader(@android_boot_params)
  @equipment['dut1'].send_cmd('mmc list', @equipment['dut1'].boot_prompt)
  emmc_dev = @equipment['dut1'].response.match(/(\d+).*?emmc/i).captures[0]
  @equipment['dut1'].send_cmd("part list mmc #{emmc_dev}", @equipment['dut1'].boot_prompt)
  emmc_partitions = @equipment['dut1'].response.scan(/^\s*\d+\s+0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s[^\r\n]+/)
  result = {}
  emmc_partitions.each do |p_info|
    p_idx, p_name = p_info.match(/(\d+)\s+0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s"([^"]+)/).captures
    result[p_idx.to_i] = p_name
  end
  if partition_map[android_version] != result
    set_result(FrameworkConstants::Result[:fail], "Expected #{partition_map[android_version]} but found #{result}")
  else
    set_result(FrameworkConstants::Result[:pass], "Expected partitions found")
  end
end
