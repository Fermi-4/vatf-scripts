# -*- coding: ISO-8859-1 -*-

# Input prev_crc : fixnum CRC32 value of the last test run.
# Input params   : Array of parameter strings that uniquely identify a test setup
# Return true if booting is required due to different test setup
#require 'zlib'

module Boot   
    
  def boot_required?(old_params, new_params)
    old_params != new_params
  end
  
  def login_uut(device_object=@equipment['dut1'])
    device_object.send_cmd(device_object.login, device_object.prompt, 10)
  end
	
  # if see match, return true; otherwise, wait for 100s and then return false
  # check if the prompt is been seen. TODO: May not right, since uboot has the same prompt
  def is_uut_up?(device_object=@equipment['dut1'])
    # in order to distinquish from uboot prompt, use 'uname' to check if dut alive.
    # But, it only works for Linux. For other OS???
    3.times do |trial|
      device_object.send_cmd("uname -a", /Linux.+?#{device_object.prompt}/m, 10, false)
      break if !device_object.timeout?
    end
    !device_object.timeout?
  end

  def is_uut_need_login?(device_object=@equipment['dut1'])
    match = device_object.login_prompt 
    device_object.send_cmd("", match, 5)
    !device_object.timeout?  
  end

  
end
