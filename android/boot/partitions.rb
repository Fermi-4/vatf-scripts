require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

def run
  partition_map = {}
  partition_map.default = Hash.new({1 => 'xloader',
                                    2 => 'bootloader',
                                    3 => 'uboot-env',
                                    4 => 'misc',
                                    5 => 'recovery',
                                    6 => 'boot',
                                    7 => 'system',
                                    8 => 'vendor',
                                    9 => 'userdata'})
  partition_map['am654x-evm']= {'2019.01' => {
                                  1 => 'bootloader',
                                  2 => 'tiboot3',
                                  3 => 'boot',
                                  4 => 'vendor',
                                  5 => 'system',
                                  6 => 'userdata' 
  }}
  partition_map['am654x-idk'] = partition_map['am654x-evm']
  partition_map['am654x-hsevm'] = partition_map['am654x-evm']
  partition_map['j721e-evm'] = partition_map['am654x-evm']
  partition_map['j721e-idk-gw'] = partition_map['am654x-evm']
  partition_map['j721e-evm-ivi'] = partition_map['am654x-evm']
  @equipment['dut1'].disconnect('serial')
  @equipment['dut1'].boot_to_bootloader(@android_boot_params)
  @equipment['dut1'].send_cmd('version', @equipment['dut1'].boot_prompt)
  uboot_version = /U-Boot\s+([\d\.]+)/.match(@equipment['dut1'].response).captures[0]
  @equipment['dut1'].send_cmd('mmc list', @equipment['dut1'].boot_prompt)
  emmc_dev = @equipment['dut1'].response.match(/(\d+)\s*\({0,1}emmc/i).captures[0]
  @equipment['dut1'].send_cmd("part list mmc #{emmc_dev}", @equipment['dut1'].boot_prompt)
  emmc_partitions = @equipment['dut1'].response.scan(/^\s*\d+\s+0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s[^\r\n]+/)
  result = {}
  emmc_partitions.each do |p_info|
    p_idx, p_name = p_info.match(/(\d+)\s+0x[0-9A-Fa-f]+\s+0x[0-9A-Fa-f]+\s"([^"]+)/).captures
    result[p_idx.to_i] = p_name
  end
  if partition_map[@equipment['dut1'].name][uboot_version] != result
    set_result(FrameworkConstants::Result[:fail], "Expected #{partition_map[@equipment['dut1'].name][uboot_version]} but found #{result}")
  else
    set_result(FrameworkConstants::Result[:pass], "Expected partitions found")
  end
end
