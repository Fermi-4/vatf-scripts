require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  # Do nothing. Booting will be controlled from run method
end

def run
  counter = 0
  result = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" );
    begin
      self.as(LspTestScript).setup
    rescue Exception 
      puts "Failed to boot on iteration #{counter}"
      result += 1
    ensure
      counter += 1
      @old_keys=''  # Clean boot keys.
      @equipment['dut1'].disconnect
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

