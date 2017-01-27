require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/power_functions'

include LspTestScript
include PowerFunctions

def setup
  self.as(LspTestScript).setup
end

def run_suspend_resume(wakeup_domain, power_state, max_suspend_time, max_resume_time)
  power_wakeup_configuration(wakeup_domain, power_state)
  @test_params.params_control.suspend_loop_count[0].to_i.times do
      suspend(wakeup_domain, power_state, max_suspend_time)
      resume(wakeup_domain, max_resume_time)
      sleep 2
      wait_for_fs('dut1')
      @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt)
  end
end

def run
  translated_boot_params = setup_host_side()
  counter = 0
  result = 0
  cleanup_errors = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  is_soft_boot = @test_params.params_control.is_soft_boot[0] if @test_params.params_control.instance_variable_defined?(:@is_soft_boot)
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'
  max_suspend_time = @test_params.params_chan.instance_variable_defined?(:@max_suspend_time) ? @test_params.params_chan.max_suspend_time[0].to_i : 30
  max_resume_time = @test_params.params_chan.instance_variable_defined?(:@max_resume_time) ? @test_params.params_chan.max_resume_time[0].to_i : 60
  while counter < loop_count
    begin
      if is_soft_boot == 'yes'
        puts "soft-reboot....\n\n"
        power_port_o = @equipment['dut1'].power_port
        @equipment['dut1'].power_port = nil
      end
      run_suspend_resume(wakeup_domain, power_state, max_suspend_time, max_resume_time)
      @equipment['dut1'].disconnect
      self.as(LspTestScript).setup if (counter + 1) < loop_count
    rescue SignalException => e
      puts "Error message seen during reboot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Error message seen during reboot on iteration #{counter}")
      cleanup_errors += 1
    rescue Exception => e
      puts "Failed to boot or to suspend/resume on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Failed to boot or to suspend/resume on Iteration #{counter}")
      result += 1
      # try to hardreset the board to recover if soft boot fails
      if is_soft_boot == 'yes'
        @equipment['dut1'].power_port = power_port_o
        self.as(LspTestScript).setup
      end

    ensure
      counter += 1
      @old_keys=''  # Clean boot keys.
    end
  end

  if result == 0 && cleanup_errors == 0
    set_result(FrameworkConstants::Result[:pass], "Stress Kernel Boot and suspend test passed.")
  elsif result > 0 && cleanup_errors > 0
    set_result(FrameworkConstants::Result[:fail], "Kernel failed to boot or suspend #{result} times out of #{loop_count}, and there were cleanup errors #{cleanup_errors} times")
  elsif cleanup_errors > 0
    set_result(FrameworkConstants::Result[:fail], "There were cleanup errors #{cleanup_errors} times out of #{loop_count}")
  else
    set_result(FrameworkConstants::Result[:fail], "Kernel failed to boot #{result} times out of #{loop_count}")
  end
end

def clean
  super
end
