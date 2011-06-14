require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  super
end

def run
  counter = 0
  result = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" );
    @equipment['dut1'].send_cmd("#-----------------counter=#{counter}-----------------", @equipment['dut1'].boot_prompt, 2)
    @equipment['dut1'].boot_to_bootloader(@power_handler)
    @equipment['dut1'].send_cmd('printenv', @equipment['dut1'].boot_prompt, 10)
    if @equipment['dut1'].timeout?
      result += 1
      #break
    #else
    #  result = 0
    end
    counter += 1
  end

  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Boot test passed.")
  else
    #set_result(FrameworkConstants::Result[:fail], "No uboot response on iteration #{counter}, boot test failed!")
    set_result(FrameworkConstants::Result[:fail], "No uboot response for #{result} times out of #{loop_count}, boot test failed!")
  end
end

def clean
  #puts "reset the board..."
  #@power_handler.reset(@equipment['dut1'].power_port)

end

