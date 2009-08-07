# -*- coding: ISO-8859-1 -*-
# require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
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


