require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/evms_data'
require File.dirname(__FILE__)+'/power_functions'
require 'set'

include LspTestScript
include EvmData
include PowerFunctions

OMAPCONF='http://10.218.103.34/anonymous/Automation/omapconf'

def get_abb_omapconf(e='dut1')
  @equipment[e].send_cmd("cd ~; rm -f ./omapconf; wget #{OMAPCONF} || wget --proxy off #{OMAPCONF} || http_proxy=$SITE_HTTP_PROXY wget #{OMAPCONF}; echo $?", /^0[\0\n\r]+/m, 30)
  raise "ERROR downloading omapconf" if @equipment[e].timeout?
  @equipment[e].send_cmd("chmod +x omapconf", @equipment[e].prompt)
end

def setup
  super
  get_abb_omapconf
end

def report(msg, e='dut1')
  puts msg
  @equipment[e].log_info(msg)
end

def set_opp(opp, e='dut1')
  begin
    freq = get_frequency_for_opp(@equipment[e].name, opp)
    set_cpu_opp(freq)
  rescue
    report "Warning: #{opp} is not supported by MPU"
  end
end

def get_abb_voltage(e='dut1')
  @equipment[e].send_cmd("./omapconf show abb", @equipment[e].prompt)
  data = @equipment[e].response.match(/LDO Drive voltage.+?(\d+)\s+mV/)
  raise "Could not get ABB LDP Drive voltage" if !data
  return data.captures[0].to_i
end

def describe_results(voltages)
  result_str = ''
  voltages.each {|opp, volt| result_str += "Frequency:#{opp}, ABB voltage:#{volt}. " }
  result_str
end

def run
  failure = 0
  opps = Set.new  # Set of Operating Points Supported
  result_str = ''
  voltages = []

  enable_cpufreq_governor('userspace')

  requirements = get_required_linux_avs(@equipment['dut1'].name)
  (requirements.select {|r| r.keys[0].match(/_MPU/)}[0]).values[0].keys.each {|opp|
    set_opp(opp)
    freq = (get_frequency_for_opp(@equipment['dut1'].name, opp)).to_i
    abb_voltage = get_abb_voltage()
    voltages.push([freq, abb_voltage])
  }

  if voltages.combination(2).any? {|a,b| (a[0] < b[0] and a[1] >= b[1]) or (a[0] > b[0] and a[1] <= b[1]) }
    result_str += "ABB test Failed. ABB voltage did not increase as expected. #{describe_results(voltages)}"
    failure += 1
  else
    result_str += "ABB test Passed. #{describe_results(voltages)}"
  end

  if failure == 0
    set_result(FrameworkConstants::Result[:pass], result_str)
  else
    set_result(FrameworkConstants::Result[:fail], result_str)
  end
end

def clean
  set_opp('OPP_NOM')
  @equipment['dut1'].send_cmd("cd ~; rm omapconf", @equipment['dut1'].prompt)
end