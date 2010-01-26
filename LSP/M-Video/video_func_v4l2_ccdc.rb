# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require '../TestPlans/LSP/M-Video/v4l2_func_common'
include LspTestScript
include V4l2_sd_common

def setup
  begin
  	MessageBox.Show("Change the Output to #{get_output(@test_params.params_chan.output[0])}")
    rescue
        
  end
  #MessageBox.Show("Change the Input to #{@test_params.params_chan.input_vid[0]} and Output to #{@test_params.params_chan.Output[0]} and Input format to #{@test_params.params_chan.In_Fmt}")
  super
end

def run
  begin
    @equipment['dut1'].send_cmd("#{@test_params.params_chan.cmd[0]}\n",@equipment['dut1'].prompt, 60)
    file_res_form = ResultForm.new("V4L2 MICRON Result Form")
    file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  super
end


