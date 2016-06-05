# -*- coding: ISO-8859-1 -*-

# Input prev_crc : fixnum CRC32 value of the last test run.
# Input params   : Array of parameter strings that uniquely identify a test setup
# Return true if booting is required due to different test setup
#require 'zlib'

module Boot   
    
  def boot_required?(old_params, new_params)
    old_params != new_params
  end
  
  def login_uut
    @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10)
  end
	
  # if see match, return true; otherwise, wait for 100s and then return false
  # check if the prompt is been seen. TODO: May not right, since uboot has the same prompt
  def is_uut_up?
    # in order to distinquish from uboot prompt, use 'uname' to check if dut alive.
    # But, it only works for Linux. For other OS???
    3.times do |trial|
      @equipment['dut1'].send_cmd("uname -a", /Linux.+?#{@equipment['dut1'].prompt}/m, 10, false)
      break if !@equipment['dut1'].timeout?
    end
    !@equipment['dut1'].timeout?
  end

  def is_uut_need_login?
    match = @equipment['dut1'].login_prompt 
    @equipment['dut1'].send_cmd("", match, 5)
    !@equipment['dut1'].timeout?  
  end

  
end