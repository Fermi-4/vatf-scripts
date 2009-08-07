# -*- coding: ISO-8859-1 -*-
#require 'C:\views\Snapshot\vatf_lsp120_a0850405_laptop_view\gtsystst_tp\TestPlans\LSP\default_lsp_script'
include LspTestScript

def setup
  super
  puts 'i2c child setup.'
end

def run
  super
  puts 'i2c child run'
end

def clean
  super
  puts 'i2c child clean'
end


