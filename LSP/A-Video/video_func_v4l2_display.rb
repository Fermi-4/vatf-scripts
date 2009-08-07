# -*- coding: ISO-8859-1 -*-
# require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript

def setup
    MessageBox.Show("Change the I/O for this test") if @test_params.params_chan.manual_pass_fail[0] == '1'
  	super
  	@equipment['dut1'].send_cmd("ls", /\.yuv/, 2)
  	@equipment['dut1'].send_cmd("cp -v /#{@tester}/#{@test_params.target}/#{@test_params.platform}/#{last_folder}/yuv/* #{@equipment['dut1'].executable_path}", @equipment['dut1'].prompt, 10) if @equipment['dut1'].is_timeout
end
           
def run
    result = 0
    ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)
    if @test_params.params_chan.instance_variable_defined?(:@init_cmds)
        commands = parse_cmd('init_cmds')
        result, cmd = execute_cmd(commands)
    end
    if result > 0 
      set_result(FrameworkConstants::Result[:fail], "Error preparing DUT to run V4L2 Display Test")
      return
    end
    
	dev_node 		=  @test_params.params_chan.dev_node[0]
	standard 		=  @test_params.params_chan.standard[0]
	interface 		=  @test_params.params_chan.interface[0]
	num_of_buffers 	=  @test_params.params_chan.num_of_buffers[0]
	num_of_frames 	=  @test_params.params_chan.num_of_frames[0]
	height 			=  @test_params.params_chan.height[0]
	width 			=  @test_params.params_chan.width[0]
	filename		=  @test_params.params_chan.filename[0]
	
	@equipment['dut1'].send_cmd("./v4l2DisplayTests -d #{dev_node} -s #{standard} -i #{interface} -c #{num_of_buffers} -n #{num_of_frames} -h #{height} -w #{width} -f #{filename}",/(\|TEST\s*RESULT\|PASS\|)|(\|TEST\s*RESULT\|FAIL\|)/, (num_of_frames.to_i/25)+5)
  	result = 1 if @equipment['dut1'].is_timeout 
  	result = 2 if /\|TEST\s*RESULT\|FAIL\|/.match(@equipment['dut1'].response)
  	if @test_params.params_chan.manual_pass_fail[0] == '1'  # Subjectively Pass/Fail tests
        begin
            file_res_form = ResultForm.new("V4L2 Display Test Result Form")
    	    file_res_form.show_result_form	
    	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
    	set_result(file_res_form.test_result,file_res_form.comment_text)
    else													# Automatically Pass/Fail tests
    	if result == 0 
            set_result(FrameworkConstants::Result[:pass], "Test Pass.")
        elsif result == 1
            set_result(FrameworkConstants::Result[:fail], "Timeout executing V4L2 #{standard} test on #{dev_node}")
        elsif result == 2
            set_result(FrameworkConstants::Result[:fail], "Fail message received while running V4L2 #{standard} test on #{dev_node}")
        else
            set_result(FrameworkConstants::Result[:nry])
        end    
    end
    
    ensure 
      result, cmd = execute_cmd(ensure_commands) if @test_params.params_chan.instance_variable_defined?(:@ensure)
end

def clean
  super
end


