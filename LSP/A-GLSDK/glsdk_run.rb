require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/glsdk_utils.rb'

# Default Test script implementation for LSP releases
include LspTestScript

# GLSDK utilities
include GlsdkUtils

def setup
  super
end

def run
  setup_and_run_glsdk_framework()
end

def clean
  super
  # Clear @old_keys to ensure that the EVM reboots.
  @old_keys = ''
  setup
end
