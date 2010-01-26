# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  begin
    @equipment['dut1'].send_cmd("audiolb -s #{@test_params.params_chan.frate[0]} -f #{@test_params.params_chan.fsize[0]} -b", @equipment['dut1'].prompt, 60)
    file_res_form = ResultForm.new("Audio Test Result Form")
    file_res_form.show_result_form	
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  @equipment['dut1'].send_cmd("\cC", @equipment['dut1'].prompt, 3)
  @equipment['dut1'].send_cmd("\cC") if @equipment['dut1'].timeout?
  self.as(LspTestScript).clean
end


