require File.dirname(__FILE__)+'/../default_test_module' 
require File.dirname(__FILE__)+'/../../lib/evms_data'

include LspTestScript
include EvmData

def setup
  # Override default behavior to boot to kernel prompt
  add_child_equipment('multimeter1')
end

def run
  max_deviation = @test_params.params_control.instance_variable_defined?(:@max_deviation) ? @test_params.params_control.max_deviation[0].to_i : 25
  failure = 0

  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))

  translated_boot_params = setup_host_side()
  @equipment['dut1'].boot_to_bootloader(translated_boot_params)

  requirements = get_required_uboot_avs(@equipment['dut1'].name)
  result_str = ''
  multimeter_readings = @equipment['multimeter1'].get_multimeter_output(10, 10) # 10 samples
  requirements.each{|req|
    domain = req.keys[0]
    efuse_addr = req[domain].values[0]
    measurement_domain = map_domain_to_measurement_rail(@equipment['dut1'].name, domain)
    measured_voltage = multimeter_readings['domain_'+measurement_domain+'_volt_readings'][0]  # AVG of 10 samples
    measured_voltage = measured_voltage.to_f * 1000 # Convert to mv, which is unit used in efuse registers
    expected_voltage = read_address(efuse_addr, false) & 0xfff # Only use bits 0-11
    ganged_rails = get_ganged_rails(@equipment['dut1'].name, domain, req[domain].keys[0])
    ganged_rails.each {|ganged_rail_addr|
      expected_ganged_voltage = read_address(ganged_rail_addr, false) & 0xfff # Only use bits 0-11
      expected_voltage = expected_ganged_voltage if expected_ganged_voltage > expected_voltage
    }
    deviation = (measured_voltage - expected_voltage.to_f).abs
    if deviation > max_deviation
      result_str += "Domain #{domain} failed. Expected:#{expected_voltage}, Measured:#{measured_voltage}. " 
      failure += 1
    else
      result_str += "Domain #{domain} passed. Expected:#{expected_voltage}, Measured:#{measured_voltage}. " 
    end
  }

  if failure == 0
    set_result(FrameworkConstants::Result[:pass], result_str)
  else
    set_result(FrameworkConstants::Result[:fail], result_str)
  end
end