# -*- coding: ISO-8859-1 -*-
require 'rubygems'
require 'facets'

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

class Audio_run_params
    def initialize
    end
    
    def get_test_cmd(test_type)
        test_type == 'Write' ? @write_cmd : @read_cmd
    end
    
    def get_test_regex(test_type)
        test_type == 'Write' ? @write_regex : @read_regex
    end
    
    def get_res_table_header()
	    ["Test Type", "Word Length (bits)", "No. Channels/sample", "Sampling Rate (Hz)", "Duration (Sec)", "No. bits/sec", "CPU Load (%)"]
    end
    
    def get_table_row(test_type, test_values)
        test_values.insert(0, test_type)		
    end  
end

class Alsa_run_params < Audio_run_params
    def initialize
    	@write_cmd   = 'ThruPut FRaudioalsawrite'
    	@read_cmd    = 'ThruPut FRaudioalsaread'
    	@write_regex = /audio:\s*write:.*bits:\s*(\d+).*sample:\s*(\d+).*Hz:\s*(\d+).*Sec:\s*([\d|\.]+).*bits\/Sec:\s*(\d+).*cpu\s*load:\s*([\d|\.]+)/mi
        @read_regex  = /audio:\s*read:.*bits:\s*(\d+).*sample:\s*(\d+).*Hz:\s*(\d+).*Sec:\s*([\d|\.]+).*bits\/Sec:\s*(\d+).*cpu\s*load:\s*([\d|\.]+)/mi
    end
end

class Oss_run_params < Audio_run_params
    def initialize
    	@write_cmd   = 'ThruPut FRaudiowrite'
    	@read_cmd    = 'ThruPut FRaudioread'
        @write_regex = /audio:\s*write:.*bits:\s*(\d+).*sample:\s*(\d+).*Hz:\s*(\d+).*Sec:\s*([\d|\.]+).*bits\/Sec:\s*(\d+).*cpu\s*load:\s*([\d|\.]+)/mi
        @read_regex  = /audio:\s*read:.*bits:\s*(\d+).*sample:\s*(\d+).*Hz:\s*(\d+).*Sec:\s*([\d|\.]+).*bits\/Sec:\s*(\d+).*cpu\s*load:\s*([\d|\.]+)/mi
    end
end

def setup
  self.as(LspTestScript).setup
end

def run
    run_params_name = @test_params.params_chan.test_type[0]+'_run_params'
    klass = Object.const_get(run_params_name)
    run_params = klass.new()
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
    
    @results_html_file.add_paragraph("")
    res_table = @results_html_file.add_table([["#{@test_params.params_chan.test_type[0]} Performance Numbers",{:bgcolor => "green", :colspan => run_params.get_res_table_header.length.to_s},{:color => "red"}]],{:border => "1",:width=>"20%"})
    res_table_header = run_params.get_res_table_header()
    @results_html_file.add_row_to_table(res_table, res_table_header)
    sampling_rates   = @test_params.params_chan.sampling_rate[0].split(' ')
    buffer_sizes     = @test_params.params_chan.buffer_size[0].split(' ')
    dev_node         = @test_params.params_chan.dev_node[0]
    data_size        = @test_params.params_chan.data_size[0]
    ['Write', 'Read'].each {|type|
        test_cmd   = run_params.get_test_cmd(type)
        test_regex = run_params.get_test_regex(type)
        sampling_rates.each {|sampling_rate|
            buffer_sizes.each {|buffer_size|
                if result==0
                    @equipment['dut1'].send_cmd("pspTest #{test_cmd} #{dev_node} #{sampling_rate} #{buffer_size} #{data_size}",
                                                test_regex,
                                                10+(data_size.to_i/sampling_rate.to_i/4))   
                    result = 1 if @equipment['dut1'].is_timeout
                    break if result > 0
                    test_values = test_regex.match(@equipment['dut1'].response).captures
                    table_row = run_params.get_table_row(type,test_values)
                    @results_html_file.add_row_to_table(res_table, table_row)
                end
            }
      	}
	}
    if result == 0 
      set_result(FrameworkConstants::Result[:pass], "Test Pass.")
    elsif result == 1
      set_result(FrameworkConstants::Result[:fail], "Timeout executing #{@test_params.params_chan.test_type[0]} performance test")
    elsif result == 2
      set_result(FrameworkConstants::Result[:fail], "Fail message received executing #{@test_params.params_chan.test_type[0]} performance test")
    else
      set_result(FrameworkConstants::Result[:nry])
    end

    ensure 
      result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
  
 end

def clean
  super
end





