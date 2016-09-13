# This script is used to measure the resume time after suspend/standby
# The resume time will be saved into performance table

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/power_functions'
require File.dirname(__FILE__)+'/power_func'

include LspTestScript
include PowerFunctions

def setup
  self.as(LspTestScript).setup
  # Add multimeter to result logs
  setup_multimeter
end

def run
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'

  # Configure multimeter 
  @equipment['multimeter1'].configure_multimeter(get_power_domain_data(@equipment['dut1'].name).merge({'dut_type'=>@equipment['dut1'].name}))

  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /sys/kernel/debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt)

  test_loop = @test_params.params_control.test_loop[0].to_i
  params = {'platform' => @equipment['dut1'].name}
  @equipment['dut1'].send_cmd('uname -r', @equipment['dut1'].prompt)
  params['version'] = @equipment['dut1'].response.match(/^([\d\.]+)/i).captures[0]
  expected_volt_reductions = get_expected_volt_reductions(params)
  if !expected_volt_reductions
    set_result(FrameworkConstants::Result[:pass], "Nothing to validate. If required define requirement at evms_data.rb file") 
    return
  end

  i = 0
  test_failed = false
  err_msg = ''
  max_suspend_time = 30
  max_resume_time = 60
  measurement_time = get_power_domain_data(@equipment['dut1'].name)['power_domains'].size # approx 1 sec per channel to get 3 measurements
  rtc_only_extra_time = (wakeup_domain == 'rtc_only' ? 15 : 0)
  min_sleep_time   = 30 + rtc_only_extra_time # to guarantee that RTC alarm does not fire prior to board reaching suspend state
  measurement_time += rtc_only_extra_time
  rtc_suspend_time = [measurement_time, min_sleep_time].max
  suspend_time = (wakeup_domain == 'rtc'  or wakeup_domain == 'rtc_only') ? rtc_suspend_time : max_suspend_time
  while i < test_loop do
    power_wakeup_configuration(wakeup_domain, power_state)
    suspend(wakeup_domain, power_state, suspend_time)
    sleep 2 # Let system reach deep sleep state

    #Measure voltage
    volt_readings = @equipment['multimeter1'].get_multimeter_output(3, @test_params.params_equip.timeout[0].to_i)
    power_readings = calculate_power_consumption(volt_readings, @equipment['dut1'], @equipment['multimeter1'])
    save_results(power_readings, volt_readings)
    #Compare measured against expected
    expected_volt_reductions.each {|domain,volt|
      # Allows 2.5% deviation from theoretical value
      max_measured_volt = volt_readings["domain_" + domain  + "_volt_readings"].max
      if  max_measured_volt > (volt*1.025)
        test_failed = true
        err_msg += "On iteration #{i}, Measured voltage #{max_measured_volt} for #{domain} domain is higher than expected #{volt}"
      end
    }

    resume(wakeup_domain, max_resume_time)
    if test_failed
      set_result(FrameworkConstants::Result[:fail], err_msg)
      return
    end

    sleep 5 # Stay awake couple of seconds

    i += 1
  end # end of while
  set_result(FrameworkConstants::Result[:pass], "Expected voltage reductions achieved")

end

