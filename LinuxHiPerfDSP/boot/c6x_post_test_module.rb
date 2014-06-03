# -*- coding: ISO-8859-1 -*-

    def setup
    
    end
    def run
      @equipment['dut1'].set_api('linux-c6x')
      boot_times = @test_params.params_chan.instance_variable_get("@boot_times")[0].to_i
      wait_for_string = @test_params.params_chan.instance_variable_get("@wait_for_string")[0]
      puts "Test looks for #{wait_for_string}"
      timeout = @test_params.params_chan.instance_variable_get("@timeout")[0].to_i
      power_port = @equipment['dut1'].power_port
      success_times = 0
      fail_times = 0
      boot_arr = [] 
      boot_failures = 0
      test_done_result = FrameworkConstants::Result[:fail]
      comment = "Test fail"
      result = false  
     
      #Switch off power

      debug_puts 'Switching off @using power switch'
      @power_handler.switch_off(power_port)

      boot_times.times { |i|
      puts "Switching power for # #{i}th iteration"
      disconnect('dut1')
      @power_handler.switch_off(power_port)
      sleep(10)
     # connect_to_equipment('dut1')
      @power_handler.switch_on(power_port)
      response = connect_to_equipment('dut1',wait_for_string,timeout)
      if (response != nil)
        result = parse_response(response,wait_for_string)
        if (result == true)
          success_times = success_times+1
          boot_arr << 'B'
        else
          fail_times = fail_times+1
          boot_arr << 'X'
        end
      else
        fail_times = fail_times+1
        boot_failures = boot_failures+1
        boot_arr << 'X'
      end
      # To prevent NAND corruption in XDS-560
      # sleep(60)
      }
      if success_times == boot_times
        test_done_result = FrameworkConstants::Result[:pass]
        comment = "Test pass. POST test completed successfully #{boot_times} out of #{boot_times} times "
	  else
		test_done_result = FrameworkConstants::Result[:fail]
        comment = "Test fail. POST test failed #{fail_times} out of #{boot_times} times. Boot log - #{boot_arr.to_s} "    
      end
      if (boot_failures > 0) 
        comment += "Did not find POST #{wait_for_string} string #{boot_failures} out of #{boot_times} times"
      end
      set_result(test_done_result,comment)
    end

    
    def clean
      debug_puts "default.clean"

    end

    def connect_to_equipment(equipment,wait_for_string,timeout)
      this_equipment = @equipment["#{equipment}"]
      if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})     
      elsif !this_equipment.target.serial
        raise "You need Serial port connectivity to #{equipment}. Please check your bench file" 
      end
      begin
        this_equipment.wait_for(wait_for_string, timeout)
        if (this_equipment.timeout?)
          return nil
        else
          return this_equipment.response
        end
      rescue Exception => e
        puts e.to_s+"\n"+e.backtrace.to_s
        return nil
      end
    end
    def parse_response(response,wait_for_string)
        if (response.match(/FAIL/))
	    return false
	else 
	    return true
        end
    end
    def disconnect(equipment)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.target.telnet || this_equipment.target.serial
        this_equipment.disconnect
      end
    end

    def debug_puts(message)
      if @show_debug_messages == true
        puts(message)
      end
    end

