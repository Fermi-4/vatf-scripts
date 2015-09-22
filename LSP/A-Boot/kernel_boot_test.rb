require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  translated_boot_params = setup_host_side()
  counter = 0
  result = 0
  cleanup_errors = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" );
    begin
      is_soft_boot = @test_params.params_control.is_soft_boot[0] if @test_params.params_control.instance_variable_defined?(:@is_soft_boot)
      if is_soft_boot == 'yes'
        puts "soft-reboot....\n\n"
        @equipment['dut1'].send_cmd('reboot', translated_boot_params['dut'].login_prompt, 150)
        boot_log = @equipment['dut1'].response
        3.times {
          @equipment['dut1'].send_cmd(translated_boot_params['dut'].login, translated_boot_params['dut'].prompt, 10) # login to the unit
          break if !@equipment['dut1'].timeout?
        }
        raise 'Could not soft-reboot' if @equipment['dut1'].timeout?
        errors = boot_log.split(/^u-boot\s+/i)[0].scan(/\[[\s\d\.]+\]\s+.*(?=timed out|error|fail).*/i)
        raise SignalException, "Errors detected while rebooting" if errors.size > 0
      else
        @equipment['dut1'].disconnect
        self.as(LspTestScript).setup
        @equipment['dut1'].disconnect
      end
    rescue SignalException => e
      puts "Error message seen during reboot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Error message seen during reboot on iteration #{counter}")
      cleanup_errors += 1
    rescue Exception => e 
      puts "Failed to boot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Failed to boot on Iteration #{counter}")
      result += 1
      # recover the board if soft boot fails
      setup if is_soft_boot == 'yes'

    ensure
      counter += 1
      @old_keys=''  # Clean boot keys.
    end
  end
    
  if result == 0 && cleanup_errors == 0
    set_result(FrameworkConstants::Result[:pass], "Stress Kernel Boot test passed.")
  elsif result > 0 && cleanup_errors > 0
    set_result(FrameworkConstants::Result[:fail], "Kernel failed to boot #{result} times out of #{loop_count}, and there were cleanup errors #{cleanup_errors} times")
  elsif cleanup_errors > 0
    set_result(FrameworkConstants::Result[:fail], "There were cleanup errors #{cleanup_errors} times out of #{loop_count}")
  else
    set_result(FrameworkConstants::Result[:fail], "Kernel failed to boot #{result} times out of #{loop_count}")
  end
end

def clean
  super
end

