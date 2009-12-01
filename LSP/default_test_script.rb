# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  #super
  self.as(LspTestScript).run
end

def clean
  #super
  self.as(LspTestScript).clean
end





