# -*- coding: ISO-8859-1 -*-
# require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
require '../TestPlans/LSP/M-Video/fbdev_func_common'
include LspTestScript
include Fbdev_sd_common

def setup
  begin
  	MessageBox.Show("Change the Input to #{get_input(@test_params.params_chan.input_vid[0])} and Output to #{get_output(@test_params.params_chan.output[0])} and Input format to #{get_in_fmt(@test_params.params_chan.in_fmt[0])}")
    rescue
        
  end
  #MessageBox.Show("Change the Input to #{@test_params.params_chan.input_vid[0]} and Output to #{@test_params.params_chan.Output[0]} and Input format to #{@test_params.params_chan.In_Fmt}")
  super
end

def run
  begin
    @equipment['dut1'].send_cmd("#{@test_params.params_chan.cmd[0]}\n",@equipment['dut1'].prompt, 60)
    file_res_form = ResultForm.new("Fbdev SD Result Form")
    file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  super
end


