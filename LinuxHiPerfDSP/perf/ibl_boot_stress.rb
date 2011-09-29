require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript
  
def setup
  super
end

def run
  dut = @equipment['dut1']
  boot_times = @test_params.params_chan.instance_variable_get("@boot_times")[0].to_i
  power_port = @equipment['dut1'].power_port
  success_times = 0
  fail_times = 0
  boot_arr = []   
   
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  
  if power_port ==nil
    raise "You need APC connectivity to run this test"
  end
  # So we can identify boards
  @equipment['dut1'].send_cmd("ifconfig",@equipment['dut1'].prompt, 30)

  boot_times.times { |i|
    puts "Switching power for # #{i}th iteration"
    disconnect('dut1')
    @power_handler.switch_off(power_port)
    sleep(30)
    @power_handler.switch_on(power_port)
    sleep(30)
    if connect_to_equipment('dut1')
      @equipment['dut1'].send_cmd("cat /proc/version",@equipment['dut1'].prompt, 30)
      if (/Linux/.match(@equipment['dut1'].response.to_s) != nil)
        success_times = success_times+1
        boot_arr << 'B'
      end
    else
      fail_times = fail_times+1
      boot_arr << 'X'
    end
    # disconnect('dut1')
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
    if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
      this_equipment.connect({'type'=>'serial'})     
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

end