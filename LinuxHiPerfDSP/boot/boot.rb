# -*- coding: ISO-8859-1 -*-
# Return true if booting is required due to different test setup


module Boot   
    
  def boot_required?(old_params, new_params)
    old_test_string = get_test_string(old_params)
    new_test_string = get_test_string(new_params)
    old_test_string != new_test_string
  end
  
  def login_uut
    @equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10)
  end
	
  # if see match, return true; otherwise, wait for 100s and then return false
  # check if the prompt is been seen. TODO: May not right, since uboot has the same prompt
  def is_uut_up?
    # in order to distinquish from uboot prompt, use 'uname' to check if dut alive.
    # But, it only works for Linux. For other OS???
    #match = @equipment['dut1'].prompt
    @equipment['dut1'].send_cmd("cat /proc/cmdline", @equipment['dut1'].prompt, 5)
    @equipment['dut1'].send_cmd("cat /proc/version", /Linux/, 5)
    !@equipment['dut1'].timeout?
  end

  def is_uut_need_login?
    match = @equipment['dut1'].login_prompt 
    @equipment['dut1'].send_cmd("", match, 5)
    !@equipment['dut1'].timeout?  
  end

  private 
  
def get_test_string(params)
  test_string = ''
  if(params == nil)
    return nil
  end
  params.each_line {|element|
  test_string += element.strip
  }
  test_string
end
end