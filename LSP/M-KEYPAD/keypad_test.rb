# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  begin
    @equipment['dut1'].send_cmd("keypad_test &", @equipment['dut1'].prompt, 20)
    file_res_form = ResultForm.new("Keypad Test Result Form")
    file_res_form.show_result_form
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
  self.as(LspTestScript).clean
end


