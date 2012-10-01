require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  self.as(LspTestScript).setup

end

def run
  translated_boot_params = setup_host_side()
  counter = 0
  result = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" );
    begin
      is_soft_boot = @test_params.params_control.is_soft_boot[0] if @test_params.params_control.instance_variable_defined?(:@is_soft_boot)
      if is_soft_boot == 'yes'
        puts "soft-reboot....\n\n"
        @equipment['dut1'].send_cmd('reboot', translated_boot_params['dut'].login_prompt, 40)
        @equipment['dut1'].send_cmd(translated_boot_params['dut'].login, translated_boot_params['dut'].prompt, 10) # login to the unit
      else
        @equipment['dut1'].disconnect
        self.as(LspTestScript).setup
        @equipment['dut1'].disconnect
      end
    rescue Exception => e 
      puts "Failed to boot on iteration #{counter}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Failed to boot on Iteration #{counter}")
      result += 1
    ensure
      counter += 1
      @old_keys=''  # Clean boot keys.
    end
  end
    
  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Stress Kernel Boot test passed.")
  else
    set_result(FrameworkConstants::Result[:fail], "Kernel failed to boot #{result} times out of #{loop_count}, stress kernel boot test failed!")
  end
end

def clean
  super
end

