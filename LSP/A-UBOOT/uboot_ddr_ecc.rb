# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
   
include LspTestScript

def setup
	@equipment['dut1'].set_api('psp')

  translated_boot_params = setup_host_side()
  translated_boot_params['dut'].set_bootloader(translated_boot_params) if !@equipment['dut1'].boot_loader
  translated_boot_params['dut'].set_systemloader(translated_boot_params) if !@equipment['dut1'].system_loader

  translated_boot_params['dut'].boot_to_bootloader translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
  
end

def run

  platform = @test_params.platform
  puts "platform: "+platform

  @equipment['dut1'].send_cmd("help ddr", @equipment['dut1'].boot_prompt, 5)

  if ! @equipment['dut1'].response.match(/ddr\s+ecc_err\s+<addr/i)
    result_msg = "ddr ecc_err command does not exist ; "
    set_result(FrameworkConstants::Result[:fail], result_msg)
    return
  end

  # err_pattern is 0x1 or 0x1001 etc; err_cnt is 1, 2, etc
  err_pattern = @test_params.params_chan.err_pattern[0].downcase
  err_cnt = @test_params.params_chan.err_cnt[0].downcase
  ecc_test = @test_params.params_chan.ecc_test[0].downcase
  if ecc_test == '1'
    @equipment['dut1'].send_cmd("setenv ecc_test 1 ", @equipment['dut1'].boot_prompt, 5)
  end
  @equipment['dut1'].send_cmd("ddr ecc_err ${loadaddr} #{err_pattern}", @equipment['dut1'].boot_prompt, 10)

  if err_cnt.to_i == 1
    orig_data = @equipment['dut1'].response.match(/Disabling\s+DDR\s+ECC\s+\.\.\..*,\s+read\s+data\s+0x(\h+),/im).captures[0]
    read_data = @equipment['dut1'].response.match(/Enabling\s+DDR\s+ECC\s+\.\.\..*,\s+read\s+data\s+0x(\h+)/im).captures[0]
    if orig_data != read_data
      set_result(FrameworkConstants::Result[:fail], "Read data with 1-bit ecc is not the same as original data and DDR ECC test failed")
      return
    end 
    @equipment['dut1'].send_cmd("boot", /Starting\s+kernel.*Booting\s+Linux\s+on/im, 30)
  elsif err_cnt.to_i >= 2
    if ecc_test == '0'
      if ! @equipment['dut1'].response.match(/error\s+interrupted.*(resetting|Reseting\s+the\s+device)\s+\.\.\./im)
        set_result(FrameworkConstants::Result[:fail], "The board did not reset when #{err_cnt}-bit ecc is introduced.")
        return
      end
    else
      # ecc_test = 1
      if ! @equipment['dut1'].response.match(/error\s+interrupted/im)
        set_result(FrameworkConstants::Result[:fail], "No interrupt when #{err_cnt}-bit ecc is introduced.")
        return
      end
      @equipment['dut1'].send_cmd("boot", /Starting\s+kernel/i, 20)
      if ! @equipment['dut1'].response.match(/error\s+interrupted/im)
        set_result(FrameworkConstants::Result[:fail], "No interrupt from kernel when #{err_cnt}-bit ecc is introduced.")
        return
      end

    end
    
  end 

  set_result(FrameworkConstants::Result[:pass], "Test pass")

end

def clean
  	#self.as(LspTestScript).clean
    puts "clean..."
end


