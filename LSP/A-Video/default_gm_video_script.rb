# -*- coding: ISO-8859-1 -*-
require 'rubygems'
require 'facets'

# Default Server-Side Test script implementation for LSP releases
include LspTestScript

class Video_run_params
    def initialize
    end
    
	def get_pretest_cmd(test_type)
        @pretest_cmd ? @pretest_cmd : nil  
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
	    ["Video Mode (Resolution)", "Frame Rate (Frames/Sec", "CPU Load (%)"]
    end
    
    def get_table_row(test_type, test_values)
        test_values.insert(0, test_type)		
    end  
end

class V4l2_capture_run_params < Video_run_params
    def initialize(params)
        dev_node        = params.params_chan.dev_node[0]
        buffers   		= params.params_chan.number_of_buffers[0] 
        frames   		= params.params_chan.number_of_frames[0] 
        mode   			= params.params_chan.mode[0] 
        input   			= params.params_chan.input[0] 
        options   			= params.params_chan.options[0] 

        @test_cmd  		= "pspTest ThruPut FRv4l2capture #{dev_node} #{buffers} #{frames} #{mode} #{input} #{options}"  
    	@test_regex 	= /Capture\s*frame\s*rate:\s*([\d|\.]+).*percentage\s*cpu\s*load:\s*([\d|\.]+)/mi
    	@test_timeout 	= 2+(frames.to_i/5)   # Assumes that the DUT is doing at least 5 frames per second
    end
end

class V4l2_display_run_params < Video_run_params
    def initialize(params)
        dev_node        = params.params_chan.dev_node[0]
        buffers   		= params.params_chan.number_of_buffers[0] 
        frames   		= params.params_chan.number_of_frames[0] 
        interface  		= params.params_chan.interface[0]
        mode   			= params.params_chan.mode[0] 
        @test_cmd   	= "pspTest ThruPut FRv4l2display #{dev_node} #{buffers} #{frames} #{interface} #{mode}"
    	@test_regex 	= /Display\s*frame\s*rate:\s*([\d|\.]+).*percentage\s*cpu\s*load:\s*([\d|\.]+)/mi
    	@test_timeout 	= 2+(frames.to_i/5)   # Assumes that the DUT is doing at least 5 frames per second
    end
end

class Fbdev_display_run_params < Video_run_params
    def initialize(params)
        dev_node        = params.params_chan.dev_node[0]
        buffers   		= params.params_chan.number_of_buffers[0] 
        frames   		= params.params_chan.number_of_frames[0] 
        interface  		= params.params_chan.interface[0]
        mode   			= params.params_chan.mode[0]
    	@test_cmd   	= "pspTest ThruPut FRfbdevdisplay #{dev_node} #{buffers} #{frames} #{mode} #{interface}"
    	@test_regex 	= /Display\s*frame\s*rate:\s*([\d|\.]+).*percentage\s*cpu\s*load:\s*([\d|\.]+)/mi
    	@test_timeout 	= 2+(frames.to_i/5)   # Assumes that the DUT is doing at least 5 frames per second
    end
end

class Usb_iso_video_run_params < Video_run_params
    def initialize(params)
        dev_node        	= params.params_chan.dev_node[0]
        frames   			= params.params_chan.number_of_frames[0] 
        file_size_divider	= params.params_chan.file_save_frames_divider[0]
        file_name			= params.params_chan.file_name[0]
		@pretest_cmd		= "insmod pwc_rtt.ko"
    	@test_cmd   		= "pspTest ThruPut FRusbisovideocapture #{dev_node} #{frames} #{frames.to_i/file_size_divider.to_i} #{file_name}" 
    	@test_regex 		= /Capture\s*frame\s*rate:\s*([\d|\.]+).*percentage\s*cpu\s*load:\s*([\d|\.]+)/mi
    	@test_timeout 		= 2+(frames.to_i/5)   # Assumes that the DUT is doing at least 5 frames per second
    end
    
    def get_res_table_header()
	    ["Frame Rate (Frames/Sec", "CPU Load (%)"]
    end
    
    def get_table_row(test_type, test_values)
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
    
	pretest_cmd   	= run_params.get_pretest_cmd(test_type)
    test_cmd   		= run_params.get_test_cmd(test_type)
    test_regex 		= run_params.get_test_regex(test_type)
    test_timeout	= run_params.get_test_timeout(test_type)
    
	@equipment['dut1'].send_cmd(pretest_cmd) if pretest_cmd
  sleep 1
    @equipment['dut1'].send_cmd(test_cmd, test_regex, test_timeout) 
   	result = 1 if @equipment['dut1'].is_timeout
   
	if result == 0 
	  test_values = test_regex.match(@equipment['dut1'].response).captures
	  mode = @test_params.params_chan.instance_variable_defined?(:@mode) ? @test_params.params_chan.mode[0]: "Test"
      table_row = run_params.get_table_row(mode,test_values)
      @results_html_file.add_row_to_table(res_table, table_row)
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





