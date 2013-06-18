require 'fileutils'

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  @equipment['dut1'].send_cmd("uname -a", /#{@equipment['dut1'].prompt}/, 20)
end

def clean
end