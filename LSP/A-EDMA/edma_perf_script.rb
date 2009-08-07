# -*- coding: ISO-8859-1 -*-
require 'rubygems'
require 'facets'

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

class Edma_run_params
    def initialize(params)
        @test_cmd  		= "insmod ./kStTimer.ko ; insmod ./#{params.params_chan.test_module[0]} ; rmmod ./#{params.params_chan.test_module[0]} ; rmmod ./kStTimer.ko"
    	@test_regex 	= /A\s*Count:\s*65535.*usec:\s*\d+/mi
    	@test_timeout 	= 60
    end
    
    def get_test_cmd(test_type)
        @test_cmd 
    end
    
    def get_test_regex(test_type)
        @test_regex
    end
    
    def get_test_timeout(test_type)
        @test_timeout
    end
    
    def get_res_table_header()
	    ["A Count", "B Count", "C Count", "Time (uSec)", "Bytes/uSec"]
    end
    
    def get_table_row(test_values)
        time = test_values[4]
        size = test_values[3]
        test_values[3] = time
        test_values[4] = "%0.2f"%(size.to_f/time.to_i).to_s		
        test_values
    end  
end


def setup
	self.as(LspTestScript).setup
end

def run
    run_params_name = @test_params.params_chan.test_type[0]+'_run_params'
    klass = Object.const_get(run_params_name)
    run_params = klass.new(@test_params)
    result = 0 	#0=pass, 1=timeout, 2=fail message detected
    
    ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
    if @test_params.params_chan.instance_variable_defined?(:@init_cmds)
        commands = parse_cmd('init_cmds')
        result, cmd = execute_cmd(commands)
    end
    if result > 0 
      set_result(FrameworkConstants::Result[:fail], "Error preparing DUT to run performance test while executing cmd: #{cmd.cmd_to_send}")
      return
    end
    
    test_type = @test_params.params_chan.test_type[0]
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["#{test_type} Performance Numbers",{:bgcolor => "green", :colspan => run_params.get_res_table_header.length.to_s},{:color => "red"}]],{:border => "1",:width=>"20%"})
    res_table_header = run_params.get_res_table_header()
    @results_html_file.add_row_to_table(res_table, res_table_header)
    
    test_cmd   		= run_params.get_test_cmd(test_type)
    test_regex 		= run_params.get_test_regex(test_type)
    test_timeout	= run_params.get_test_timeout(test_type)
    
    @equipment['dut1'].send_cmd(test_cmd, test_regex, test_timeout) 
   	result = 1 if @equipment['dut1'].is_timeout
   
	if result == 0 
	  test_values = @equipment['dut1'].response.scan(/A\s*Count:\s*(\d+).+?B\s*Count:\s*(\d+).+?C\s*Count:\s*(\d+).+?Kbits:\s*(\d+).+?usec:\s*(\d+)/mi)
	  6.times { |i|
		  table_row = run_params.get_table_row(test_values[i])
      	  @results_html_file.add_row_to_table(res_table, table_row)
	  }
	  set_result(FrameworkConstants::Result[:pass], "Test Pass.")
    elsif result == 1
      set_result(FrameworkConstants::Result[:fail], "Timeout executing #{test_type} performance test")
    elsif result == 2
      set_result(FrameworkConstants::Result[:fail], "Fail message received executing #{test_type} performance test")
    else
      set_result(FrameworkConstants::Result[:nry])
    end

    ensure 
      result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
  
 end

def clean
  super
end





