# -*- coding: ISO-8859-1 -*-

GEL_TEST_DIR = File.dirname(__FILE__)+'/../geltest'

# Default Server-Side Test script implementation for c6x-Linux releases
module C6xGELTestScript 
    public
    @show_debug_messages = false
    def setup
      @equipment['dut1'].set_api('linux-c6x')
      @platform = @test_params.platform.downcase
      platform_gel_file = @test_params.platform_gel_file
      ddr_test_file = @test_params.ddr_test_file
      @dss_dir = @equipment['server1'].params["dss_dir"]
      power_port = @equipment['dut1'].power_port
      
      # Telnet to Linux server
      if @equipment['server1'].respond_to?(:telnet_port) and @equipment['server1'].respond_to?(:telnet_ip)
        @equipment['server1'].connect({'type'=>'telnet'})
      elsif !@equipment['server1'].target.telnet 
        raise "You need Telnet connectivity to the Linux Server. Please check your bench file" 
      end
      
      case (@platform)
      when "shannon"
        @dss_param_evm_id = "TMDXEVM6678le-le"
        @targetFlag = "evm6678l"
        @ccstargetFlag = "evmc6678l"
      when "nyquist"
        @dss_param_evm_id = "TMDXEVM6670le-le"
        @targetFlag = "evm6670l"
        @ccstargetFlag = "evmc6670l"
      when "gauss"
        @dss_param_evm_id = "TMDXEVM6657ls-le"
        @targetFlag = "evm6657l"
        @ccstargetFlag = "evmc6657l"
	  when "keystone-evm"
        @dss_param_evm_id = "evmk2h-le"
        @targetFlag = "evmk2h"
        @ccstargetFlag = "evmtci6638k2k"
      else
        raise "DDR test not supported on #{@platform}"
      end
      
      @ccs_gel_dir = "#{@equipment['server1'].params["dss_dir"]}../../emulation/boards/#{@ccstargetFlag}/gel/"
      @power_handler.switch_off(power_port)
      
      # Copy test program
      @equipment['server1'].send_cmd("mkdir -m 777 -p #{GEL_TEST_DIR}/binaries/#{@targetFlag}")
      @equipment['server1'].send_cmd("rm -rf #{GEL_TEST_DIR}/binaries/#{@targetFlag}/*")
      @equipment['server1'].send_cmd("cp #{ddr_test_file} #{GEL_TEST_DIR}/binaries/#{@targetFlag}/ddr_test_program.out")
      
      # Create directory for logs
      @equipment['server1'].send_cmd("mkdir -m 777 -p #{GEL_TEST_DIR}/logs")
      @equipment['server1'].send_cmd("rm -rf #{GEL_TEST_DIR}/logs/*")
      
      # Copy gel, the ccxml that comes with geltest/ points to this GEL file
      @equipment['server1'].send_sudo_cmd("mkdir -p #{@ccs_gel_dir}", @equipment['server1'].prompt, 10)  
      @equipment['server1'].send_sudo_cmd("cp #{platform_gel_file} #{@ccs_gel_dir}/#{@ccstargetFlag}-geltest.gel", @equipment['server1'].prompt, 10)  
      @power_handler.switch_on(power_port)
    end

    
    def clean
    end
    
    def connect_to_equipment(equipment)
      this_equipment = @equipment["#{equipment}"]
      if this_equipment.respond_to?(:telnet_port) && this_equipment.telnet_port != nil  && !this_equipment.target.telnet
        this_equipment.connect({'type'=>'telnet'})
      elsif ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.telnet && !this_equipment.target.serial
        raise "You need Telnet or Serial port connectivity to #{equipment}. Please check your bench file" 
      end
    end


end
   






