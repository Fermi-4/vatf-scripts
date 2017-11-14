require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript

def setup
  #super
  @equipment['dut1'].set_api('psp')
end

def run
  counter = 0
  result = 0
  result_dhcp = 0
  msg = ""
  loop_count = @test_params.params_control.loop_count[0].to_i
  test_dhcp = @test_params.params_chan.instance_variable_defined?(:@test_dhcp) ? @test_params.params_chan.test_dhcp[0].downcase : "no"
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
    else
      # test uboot
      if test_dhcp != 'no'
        @equipment['dut1'].send_cmd('setenv autoload no', @equipment['dut1'].boot_prompt, 3)
        @equipment['dut1'].send_cmd('dhcp', /DHCP client bound to address.*#{@equipment['dut1'].boot_prompt}/im, 60)
        if @equipment['dut1'].timeout?
          result_dhcp += 1
        end
      end
    end
    counter += 1
    @equipment['dut1'].disconnect('serial') if @equipment['dut1'].target.serial
  end

  if result == 0 and result_dhcp == 0 
    set_result(FrameworkConstants::Result[:pass], "Boot test passed.")
  else
    msg = "Boot failed to boot to uboot prompt #{result.to_s} times out of #{loop_count.to_s}; " if result != 0
    msg = msg + "DHCP failed #{result_dhcp.to_s} times out of #{loop_count.to_s}; " if result_dhcp != 0
    set_result(FrameworkConstants::Result[:fail], "boot test failed! "+msg)
  end
end

def clean
  super
end

