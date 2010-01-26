# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
#Include System::Windows::Forms
include LspTestScript

def setup
  super
end

def run
  file_res_form = ResultForm.new("Change the IO before starting the test")
  file_res_form.show_result_form
  super
end

def clean
  super
end


