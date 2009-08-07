# -*- coding: ISO-8859-1 -*-
# require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include System::Windows::Forms
include LspTestScript

def setup
  MessageBox.Show("Change the I/O this test")
  self.as(LspTestScript).setup
end

def run
  MessageBox.Show('Change the IO this test')
  begin
    @equipment['dut1'].send_cmd("\./audiolb -s 48 -f 8192 #{@test_params.params_chan.block[0]} #{@test_params.params_chan.mic[0]}", @equipment['dut1'].prompt, 60)
    file_res_form = ResultForm.new("Audio Test HW Result Form")
    file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  self.as(LspTestScript).clean
end


