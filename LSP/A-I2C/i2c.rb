# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
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


