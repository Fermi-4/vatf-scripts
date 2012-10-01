require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  #super
  @equipment['dut1'].set_api('psp')
end

def run
  counter = 0
  result = 0
  loop_count = @test_params.params_control.loop_count[0].to_i
  translated_boot_params = setup_host_side()
  @equipment['dut1'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  @equipment['dut1'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader
  while counter < loop_count
    puts("Inside the loop counter = #{counter}" )
    @equipment['dut1'].boot_to_bootloader(translated_boot_params)
    connect_to_equipment('dut1','serial')
    @equipment['dut1'].send_cmd("#-----------------counter=#{counter}-----------------", @equipment['dut1'].boot_prompt, 2)
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
  super
end

