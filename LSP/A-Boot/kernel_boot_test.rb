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
  is_soft_boot = @test_params.params_control.is_soft_boot[0] if @test_params.params_control.instance_variable_defined?(:@is_soft_boot)
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" );
    begin
      if is_soft_boot == 'yes'
        puts "soft-reboot....\n\n"
        power_port_o = @equipment['dut1'].power_port
        @equipment['dut1'].power_port = nil
      end
      @equipment['dut1'].disconnect
      self.as(LspTestScript).setup
      @equipment['dut1'].disconnect
    rescue SignalException => e
      puts "Error message seen during reboot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Error message seen during reboot on iteration #{counter}")
      cleanup_errors += 1
    rescue Exception => e 
      puts "Failed to boot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Failed to boot on Iteration #{counter}")
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

