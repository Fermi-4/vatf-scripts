# -*- coding: ISO-8859-1 -*-
# Script to run tests like ltp-ddt test with stress boot
require File.dirname(__FILE__)+'/dev_test2'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript

def run_save_results(return_non_zero)
  puts "run_save_results::skip saving result for each loop"
  return return_non_zero
end

def setup
  super
end

def run
  result = 0
  boot_result = 0

  test_loop = @test_params.params_control.loop_count[0].to_i
  i = 0
  while i < test_loop
    @equipment['dut1'].log_info("Inside the loop counter = #{i}");
    begin
      self.as(LspTestScript).setup
    rescue Exception => e
      puts "Failed to boot on loop #{i.to_s}: " + e.to_s + ": " + e.backtrace.to_s
      @equipment['dut1'].log_info("Failed to boot on loop #{i.to_s}")
      i += 1
      boot_result += 1
      next
    end

    rtn_non_zero = super
    if rtn_non_zero
      result = result +1
    end

    i = i+1
  end

  if result == 0 and boot_result == 0
      set_result(FrameworkConstants::Result[:pass], "Test Pass.")
  else
      set_result(FrameworkConstants::Result[:fail], "Test Failed #{result.to_s} of #{test_loop.to_s} times boot. Board failed to boot #{boot_result.to_s} times.")
  end
  
end

def clean
  #super
  self.as(LspTestScript).clean
end





