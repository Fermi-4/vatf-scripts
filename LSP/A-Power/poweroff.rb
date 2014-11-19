# This script is used to validate that domains are voltage shutdown during poweroff

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/power_functions'

include LspTestScript
include PowerFunctions

def setup
  self.as(LspTestScript).setup
  # Add multimeter to result logs
  setup_multimeter
end

def run
  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))

  expected_poweroff_domains = get_expected_poweroff_domains
  if !expected_poweroff_domains
    set_result(FrameworkConstants::Result[:pass], "Nothing to validate. If required define requirement at evms_data.rb file") 
    return
  end
  
  puts "GOING TO POWEROFF"
  @equipment['dut1'].poweroff
  if @equipment['dut1'].timeout?
    puts "Timeout while waiting to poweroff"
    raise "DUT took more than 120 seconds to poweroff"
  end
  sleep 2 # Extra couple of seconds after poweroff message is seen on console
  #Measure voltage
  volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
  puts "volt_readings size is #{volt_readings.size} and class is #{volt_readings.class}"
  #Compare measured against expected
  expected_poweroff_domains.each {|domain|
    puts "Checking domain #{domain}"
    max_measured_volt = volt_readings["domain_" + domain  + "_volt_readings"].max
    if  max_measured_volt > 0.1
      set_result(FrameworkConstants::Result[:fail], "Measured voltage #{max_measured_volt} for #{domain} domain is higher than 0.1v")
      return
    end
  }
  set_result(FrameworkConstants::Result[:pass], "All domains set to 0v")
end

