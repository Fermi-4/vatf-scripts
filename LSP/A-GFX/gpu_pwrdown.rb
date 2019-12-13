# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && /etc/init.d/weston stop && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep && echo "weston stop failed"',@equipment['dut1'].prompt,10)
  raise "Could not stop Weston" if @equipment['dut1'].response.scan(/weston\s*stop\s*failed/im).length > 1
end

def run
  read_addr = '0x4e20000018'
  read_result = '0x08470000'
  pvr_ko = 'pvrsrvkm'
  @equipment['dut1'].send_cmd('',@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("devmem2 #{read_addr}", @equipment['dut1'].prompt)
  read_match = @equipment['dut1'].response.match(/Read\s*at\s*address\s*#{read_addr}.*?:\s*#{read_result}/im)
  if !read_match
    set_result(FrameworkConstants::Result[:fail], "Test failed: wrong value read #{@equipment['dut1'].response}")
    return
  end
  @equipment['dut1'].send_cmd('lsmod | grep -i pvr', @equipment['dut1'].prompt)
  lsmod_match = @equipment['dut1'].response.match(/#{pvr_ko}/im)
  if !lsmod_match
    set_result(FrameworkConstants::Result[:fail], "Test failed: PVR module not loaded #{@equipment['dut1'].response}")
    return
  end
  @equipment['dut1'].send_cmd("modprobe -r #{pvr_ko}", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("devmem2 #{read_addr}", @equipment['dut1'].prompt, 20)
  if !@equipment['dut1'].timeout?
    set_result(FrameworkConstants::Result[:fail], "Test failed: #{@equipment['dut1'].response}")
  else
    set_result(FrameworkConstants::Result[:pass], "Test passed")
  end
end
