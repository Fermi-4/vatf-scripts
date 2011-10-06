# -*- coding: ISO-8859-1 -*-

require File.dirname(__FILE__)+'/boot'
include Boot
# Default Server-Side Test script implementation for c6x-Linux releases
    def setup
    
    end
    def run
      @equipment['dut1'].set_api('linux-c6x')
 
      boot_times = @test_params.params_chan.instance_variable_get("@boot_times")[0].to_i
      wait_for_string = Regexp.new(@test_params.params_chan.instance_variable_get("@wait_for_string")[0])
      puts "Test looks for #{wait_for_string}"
      timeout = @test_params.params_chan.instance_variable_get("@timeout")[0].to_i
      power_port = @equipment['dut1'].power_port
      success_times = 0
      fail_times = 0
      boot_failures = 0
      boot_arr = [] 
      @read_fail_caches_on = 0
      @read_fail_caches_off1 = 0
      @read_fail_caches_off2 = 0
      
      @read_refresh_fail_caches_on = 0
      @read_refresh_fail_caches_off1 = 0
      @read_refresh_fail_caches_off2 = 0

      @write_fail_caches_on = 0
      @write_fail_caches_off1 = 0
      @write_fail_caches_off2 = 0
       
      test_done_result = FrameworkConstants::Result[:fail]
      comment = "Test fail"    
      
      @nfs_root_path = @equipment['dut1'].nfs_root_path
      @samba_root_path = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['dut1'].samba_root_path}"
      ddr_test_app = @test_params.ddr_test_app     
      ddr_test_app_name = @equipment['dut1'].params["ddr_test_app_name"] 
      
      # Telnet to Linux server
      if @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip) and !@equipment['server1'].target.telnet
        @equipment['server1'].connect({'type'=>'telnet'})
      elsif !@equipment['server1'].target.telnet 
        raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
      end
      
      #Switch off power

      debug_puts 'Switching off @using power switch'
      @power_handler.switch_off(power_port)

      #Copy test app to TFTP server
      @equipment['server1'].send_cmd("cd #{@nfs_root_path}", @equipment['server1'].prompt, 10)
      BuildClient.copy(ddr_test_app, "#{@samba_root_path}\\#{File.basename(ddr_test_app)}") 
      @equipment['server1'].send_sudo_cmd("rm -f  #{@equipment['server1'].tftp_path}/#{ddr_test_app_name}", @equipment['server1'].prompt, 30) 
      @equipment['server1'].send_sudo_cmd("cp #{File.basename(ddr_test_app)} #{@equipment['server1'].tftp_path}/#{ddr_test_app_name}", @equipment['server1'].prompt, 30)
      @equipment['server1'].send_sudo_cmd("rm -f  #{File.basename(ddr_test_app)}", @equipment['server1'].prompt, 30) 
    
      boot_times.times { |i|
        puts "Switching power for # #{i}th iteration"
        disconnect('dut1')
        @power_handler.switch_off(power_port)
        sleep(30)
        @power_handler.switch_on(power_port)
        response = connect_to_equipment('dut1',wait_for_string,timeout)
        if (response != nil)
          if parse_response(response)
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
      }
      puts "read_fail_caches_on: #{@read_fail_caches_on}"
      puts "read_fail_caches_off1: #{@read_fail_caches_off1}"
      puts "read_fail_caches_off2: #{@read_fail_caches_off2}" 
      if( @read_fail_caches_on != 0 || @read_fail_caches_off1 != 0 || @read_fail_caches_off2 != 0 || @read_refresh_fail_caches_on != 0 || @read_refresh_fail_caches_off1 != 0 || @read_refresh_fail_caches_off2 != 0 || @write_fail_caches_on != 0 || @write_fail_caches_off1 != 0 || @write_fail_caches_off2 != 0)
        comment = "Test failed. DDR test completed successfully #{success_times} out of #{boot_times} times. Boot log - #{boot_arr.to_s}"
      elsif success_times == boot_times
        test_done_result = FrameworkConstants::Result[:pass]
        comment = "Test pass. DDR test completed successfully #{boot_times} out of #{boot_times} times "
      end
      if (boot_failures > 0) 
        comment += "Board failed to boot #{boot_failures} out of #{boot_times} times"
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
      puts "*******************"
      puts @equipment['dut1'].response
      puts "*******************"
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
    
    def disconnect(equipment)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.target.telnet || this_equipment.target.serial
        this_equipment.disconnect
      end
    end
    
    def parse_response(response)
      read_fail_caches_on = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[0].to_i
      @read_fail_caches_on = @read_fail_caches_on + read_fail_caches_on
      read_fail_caches_off1 = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[1].to_i
      @read_fail_caches_off1 = @read_fail_caches_off1 + read_fail_caches_off1
      read_fail_caches_off2 = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[2].to_i 
      @read_fail_caches_off2 = @read_fail_caches_off2 + read_fail_caches_off2    

      read_refresh_fail_caches_on = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[0].to_i
      @read_refresh_fail_caches_on = @read_refresh_fail_caches_on + read_refresh_fail_caches_on
      read_refresh_fail_caches_off1 = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[1].to_i
      @read_refresh_fail_caches_off1 = @read_refresh_fail_caches_off1 + read_refresh_fail_caches_off1
      read_refresh_fail_caches_off2 = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[2].to_i  
      @read_refresh_fail_caches_off2 = @read_refresh_fail_caches_off2 + read_refresh_fail_caches_off2

      write_fail_caches_on = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[0].to_i
      @write_fail_caches_on = @write_fail_caches_on + write_fail_caches_on
      write_fail_caches_off1 = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[1].to_i
      @write_fail_caches_off1 = @read_fail_caches_off1 + write_fail_caches_off1
      write_fail_caches_off2 = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[2].to_i
      @write_fail_caches_off2 = @write_fail_caches_off2 + write_fail_caches_off2   
      if (read_fail_caches_on != 0 || read_fail_caches_off1 != 0 || read_fail_caches_off2 != 0 || read_refresh_fail_caches_on != 0 || read_refresh_fail_caches_off1 != 0 || read_refresh_fail_caches_off2 != 0 || write_fail_caches_on != 0 || write_fail_caches_off1 != 0 || write_fail_caches_off2 != 0)
        return false
      else
        return true 
      end        
    end
    
    def debug_puts(message)
      if @show_debug_messages == true
        puts(message)
      end
    end

