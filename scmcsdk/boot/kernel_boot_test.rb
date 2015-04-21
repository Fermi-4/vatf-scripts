require File.dirname(__FILE__)+'/../../LSP/default_test_module' 
include LspTestScript

def setup
  self.as(LspTestScript).setup

end

def run
  translated_boot_params = setup_host_side()
  
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  
  success_times = 0
  fail_times = 0
  boot_arr = []   
  timeout = @test_params.instance_variable_defined?(:@var_boot_timeout) ? @test_params.var_boot_timeout.to_i : 150
  power_port = @equipment['dut1'].power_port
  boot_times = @test_params.params_control.loop_count[0].to_i
  @equipment['dut1'].send_cmd("ifconfig",@equipment['dut1'].prompt, 30)
  is_soft_boot = @test_params.params_control.is_soft_boot[0] if @test_params.params_control.instance_variable_defined?(:@is_soft_boot)
  boot_times.times { |i|
    puts("Inside the loop counter = #{i}" );
    begin
	  if is_soft_boot == 'yes'
	      puts "Rebooting for # #{i}th iteration"
		  @equipment['dut1'].send_cmd('reboot', translated_boot_params['dut'].login_prompt, timeout)
		  @equipment['dut1'].send_cmd(translated_boot_params['dut'].login, translated_boot_params['dut'].prompt, 10) # login to the unit
		  if @equipment['dut1'].timeout?
		    raise "reboot failed"
	      end
	  else
		puts "Switching power for # #{i}th iteration"
		@power_handler.switch_off(power_port)
		sleep(5)
		@power_handler.switch_on(power_port)
		if @equipment['dut1'].target.serial
		  @equipment['dut1'].wait_for(/login:/, timeout)
		  @equipment['dut1'].send_cmd(translated_boot_params['dut'].login, translated_boot_params['dut'].prompt, 10) # login to the unit
		else
		  sleep(120)
		end
	  end
	  if connect_to_equipment('dut1')
	    @equipment['dut1'].send_cmd("cat /proc/version",@equipment['dut1'].prompt, 30)
	    if (/Linux/.match(@equipment['dut1'].response.to_s) != nil)
		  success_times = success_times+1
		  boot_arr << 'B'
	    else
		  fail_times = fail_times+1
		  boot_arr << 'X'
	    end
	  else
	    fail_times = fail_times+1
	    boot_arr << 'X'
	  end
    rescue Exception => e 
      puts "Failed to boot on iteration #{i}: " + e.to_s + ": " + e.backtrace.to_s
	  fail_times = fail_times+1
	  boot_arr << 'X'
	  @power_handler.switch_off(power_port)
	  sleep(5)
	  @power_handler.switch_on(power_port)
	  @equipment['dut1'].wait_for(/login:/, timeout)
	  @equipment['dut1'].send_cmd(translated_boot_params['dut'].login, translated_boot_params['dut'].prompt, 10) # login to the unit
    end
  }
  if(success_times == boot_times)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass. Board booted successfully #{boot_times} out of #{boot_times} times "
  else
    comment = "Test failed. Board booted successfully #{success_times} out of #{boot_times} times. Boot log - #{boot_arr.to_s}"
  end
  set_result(test_done_result,comment)
end

def connect_to_equipment(equipment)
    this_equipment = @equipment["#{equipment}"]
    if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) 
      if (this_equipment.target.serial)
       # already connected via serial, do nothing 
      else
        this_equipment.connect({'type'=>'serial'})     
      end
    elsif this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
    elsif !this_equipment.target.telnet && !this_equipment.target.serial
      raise "You need Telnet or Serial port connectivity to #{equipment}. Please check your bench file" 
    end
    return true
    rescue Exception => e
      puts e.to_s+"\n"+e.backtrace.to_s
      return false
end
def disconnect(equipment)
    this_equipment = @equipment["#{equipment}"]
    if this_equipment.target.telnet || this_equipment.target.serial
      this_equipment.disconnect
    end
end
def clean
  super
end

