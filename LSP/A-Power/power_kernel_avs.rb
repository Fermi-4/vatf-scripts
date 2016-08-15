require File.dirname(__FILE__)+'/../default_test_module' 
require File.dirname(__FILE__)+'/../../lib/evms_data'
require File.dirname(__FILE__)+'/power_functions'
require 'set'

include LspTestScript
include EvmData
include PowerFunctions

def setup
  super
  add_child_equipment('multimeter1')
  enable_devfreq
end

def enable_devfreq(e='dut1')
  @equipment[e].send_cmd("modprobe coproc_devfreq", @equipment[e].prompt)
end

def disable_devfreq(e='dut1')
  @equipment[e].send_cmd("rmmod coproc_devfreq", @equipment[e].prompt)
end

def report(msg, e='dut1')
  puts msg
  @equipment[e].log_info(msg)
end

def set_opp(opp, e='dut1')
  if (@reqs_for_opp.select {|r| r.keys[0].match(/_MPU/)}).length > 0
    begin
      freq = get_frequency_for_opp(@equipment[e].name, opp)
      set_cpu_opp(freq)
    rescue 
      report "Warning: #{opp} is not supported by MPU"
    end
  end
  if (@reqs_for_opp.select {|r| r.keys[0].match(/_GPU/)}).length > 0
    begin
      freq = get_frequency_for_opp(@equipment[e].name, opp, 'gpu')
      set_coproc_opp(freq, 'coproc-g')
    rescue 
      report "Warning: #{opp} is not supported by GPU"
    end
  end
  if (@reqs_for_opp.select {|r| r.keys[0].match(/_IVA/)}).length > 0
    begin
      freq = get_frequency_for_opp(@equipment[e].name, opp, 'iva')
      set_coproc_opp(freq, 'coproc-i')
    rescue
      report "Warning: #{opp} is not supported by IVA"
    end
  end
end

def check_opp(opp, max_deviation)
  failure = 0
  result_str = ''
  set_opp(opp)
  multimeter_readings = @equipment['multimeter1'].get_multimeter_output(10, 10) # 10 samples
  @reqs_for_opp.each{|req|
    domain = req.keys[0]
    efuse_addr = req[domain][opp]
    measurement_domain = map_domain_to_measurement_rail(@equipment['dut1'].name, domain)
    measured_voltage = multimeter_readings['domain_'+measurement_domain+'_volt_readings'][0]  # AVG of 10 samples
    measured_voltage = measured_voltage.to_f * 1000 # Convert to mv, which is unit used in efuse registers
    expected_voltage = read_address(efuse_addr) & 0xfff # Only use bits 0-11
    ganged_rails = get_ganged_rails(@equipment['dut1'].name, domain, opp)
    ganged_rails.each {|ganged_rail_addr|
      expected_ganged_voltage = read_address(ganged_rail_addr) & 0xfff # Only use bits 0-11
      expected_voltage = expected_ganged_voltage if expected_ganged_voltage > expected_voltage
    }
    deviation = (measured_voltage - expected_voltage.to_f).abs
    if deviation > max_deviation
      result_str += "#{domain}@#{opp} failed. Expected:#{expected_voltage}, Measured:#{measured_voltage}. " 
      failure += 1
    else
      result_str += "#{domain}@#{opp} passed. Expected:#{expected_voltage}, Measured:#{measured_voltage}. " 
    end
  }
  [result_str, failure]
end

def run
  max_deviation = @test_params.params_control.instance_variable_defined?(:@max_deviation) ? @test_params.params_control.max_deviation[0].to_i : 25
  failure = 0
  opps = Set.new  # Set of Operating Points Supported
  result_str = ''

  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))

  enable_cpufreq_governor('userspace')

  requirements = get_required_linux_avs(@equipment['dut1'].name)
  requirements.each {|req| req.values.each {|v| v.keys.each {|opp| opps.add(opp)} } }
  opps.to_a.each{|opp|
    @reqs_for_opp =  requirements.select {|req| req.values[0].has_key?(opp)}
   
    tmp_result_str, tmp_failure = check_opp(opp, max_deviation)
    result_str += tmp_result_str
    failure += tmp_failure
  
  }

  if failure == 0
    set_result(FrameworkConstants::Result[:pass], result_str)
  else
    set_result(FrameworkConstants::Result[:fail], result_str)
  end
end

def clean
  set_opp('OPP_NOM')
  disable_devfreq
end