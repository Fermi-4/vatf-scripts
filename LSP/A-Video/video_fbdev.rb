# -*- coding: ISO-8859-1 -*-
# require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript

def setup
  MessageBox.Show("Change the I/O for this test")
  super
end

def run
  begin
    @equipment['dut1'].send_cmd("#{@test_params.params_chan.cmd[0]}\n",@equipment['dut1'].prompt, 60)
    file_res_form = ResultForm.new("FbDev Test Result Form")
    file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  super
end


