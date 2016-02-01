# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  result = 0
  if !@equipment['dut1'].boot_log.match(/ultra\s+high\s+speed/)
    result = 1
  end
  if result == 0
      set_result(FrameworkConstants::Result[:pass], "Test Pass.")
  elsif result == 1
      set_result(FrameworkConstants::Result[:fail], "The UHS card failed to enumerated as UHS card!")
  else
      set_result(FrameworkConstants::Result[:nry])
  end
  
end

def clean
  #super
  self.as(LspTestScript).clean
end





