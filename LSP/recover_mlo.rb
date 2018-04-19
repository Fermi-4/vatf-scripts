# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_test_module'
require File.dirname(__FILE__)+'/../lib/utils'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  #super
  #self.as(LspTestScript).run
  # First remove MLOs from MMC or eMMC (I don't care of eMMC)
  # make sure there is mmcblk*p1 mount
  scp_push_file(get_ip_addr, @test_params.primary_bootloader, "/MLO")
  @equipment['dut1'].send_cmd("mount", @equipment['dut1'].prompt, 20)
  mount = 0
  response = @equipment['dut1'].response
  if response.match(/mmcblk0p1/i)
      mount += 1
      @equipment['dut1'].send_cmd("cp /run/media/mmcblk0p1/MLO /run/media/mmcblk0p1/MLO-old", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk0p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk0p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("cp /MLO /run/media/mmcblk0p1/MLO", @equipment['dut1'].prompt, 20)
  end
    
  if response.match(/mmcblk1p1/i)
      mount += 1
      @equipment['dut1'].send_cmd("cp /run/media/mmcblk1p1/MLO /run/media/mmcblk0p1/MLO-old", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk1p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk1p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("cp /MLO /run/media/mmcblk1p1/MLO", @equipment['dut1'].prompt, 20)
  end
  if response.match(/mmcblk2p1/i)
      mount += 1
      @equipment['dut1'].send_cmd("cp /run/media/mmcblk2p1/MLO /run/media/mmcblk0p1/MLO-old", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk2p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("rm /run/media/mmcblk2p1/MLO", @equipment['dut1'].prompt, 20)
      @equipment['dut1'].send_cmd("cp /MLO /run/media/mmcblk2p1/MLO", @equipment['dut1'].prompt, 20)
  end
  @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("echo 3 > /proc/sys/vm/drop_caches", @equipment['dut1'].prompt, 60)
  
  if mount == 0
    raise "There is no MMC/eMMC being mounted after boot up"
  end
  
  # to check if the new MLO is ok
  setup

  set_result(FrameworkConstants::Result[:pass], "recovery pass")
end

def clean
  #super
  self.as(LspTestScript).clean
end





