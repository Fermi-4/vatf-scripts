# -*- coding: ISO-8859-1 -*-
# This script is to test DFU by updating MLO/u-boot.img via DFU
#  
# Currently, this script only support update MMC and eMMC. But it can be extended to update NAND via DFU as well

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  install_dfu_util()
  install_usbboot()
end

def run
  result = 0
  params = {}
  params['primary_bootloader'] = @test_params.instance_variable_defined?(:@primary_bootloader) ? @test_params.primary_bootloader : ''
  params['primary_bootloader_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_src_dev) ? @test_params.params_chan.primary_bootloader_src_dev[0] : 'eth'
  params['secondary_bootloader'] = @test_params.instance_variable_defined?(:@secondary_bootloader) ? @test_params.secondary_bootloader : ''
  params['secondary_bootloader_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_src_dev) ? @test_params.params_chan.secondary_bootloader_src_dev[0] : 'eth'
  if params['secondary_bootloader'].strip == '' 
    raise "Bootloaders are not provided"
  end
  params['primary_bootloader_dev'] = 'spldfu'

  bparams = setup_host_side(params)
  bparams.each{|k,v| puts "#{k}:#{v}"}
  
  begin 
    staf_mutex("spldfu_boot", 600000) do
      bparams['dut'].set_sysboot(bparams['dut'], 'spldfu')
      bparams['dut'].power_cycle(bparams)
      bparams['dut'].connect({'type'=>'serial'})
      @equipment['server1'].send_sudo_cmd("usbboot -S #{bparams['primary_bootloader']}", /reading/i, 30) 
      @equipment['dut1'].wait_for(/Trying\s+to\s+boot\s+from\s+USB\s+DFU/i, 60)
      if @equipment['dut1'].timeout?
        set_result(FrameworkConstants::Result[:fail], "The board could not boot from USB DFU")  
      end
      sleep 3
      @equipment['server1'].send_sudo_cmd("sudo dfu-util -l", @equipment['server1'].prompt, 60) 
      if ! @equipment['server1'].response.match(/Found\s+DFU:/i)
        raise "dfu-util failed to find DFU devices"
      end

      start_server_thread("dfu-util c 1 -i 0 -a 0 -D #{bparams['secondary_bootloader']} -R", /(starting\s+download:.*finished!.*done!)|(Download\s+done.*Done!)/im, 600) do
        @equipment['dut1'].wait_for(/U-Boot/, 600)
        10.times do
          @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
          break if !@equipment['dut1'].timeout?
        end
      end

    end

  rescue Exception => e
    bparams['dut'].reset_sysboot(bparams['dut'])
    raise e
  end

  set_result(FrameworkConstants::Result[:pass], "Test Pass")

end

def start_server_thread(cmd, exp, timeout)
  Thread.abort_on_exception = true
  thr = Thread.new {
    @equipment['server1'].send_sudo_cmd(cmd, exp, timeout)
    raise "Server failed to get the expected response " if @equipment['server1'].timeout?
    @equipment['server1'].response
  }
  yield
  rtn = thr.value
end

# install dfu-util if it is not in host
def install_dfu_util()
  @equipment['server1'].send_cmd("which dfu-util;echo $?", /^0[\0\n\r]+/m, 5)
  @equipment['server1'].send_sudo_cmd("apt-get install dfu-util", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which dfu-util;echo $?", /^0[\0\n\r]+/m, 5)
  raise "Could not install dfu-util!" if @equipment['server1'].timeout?
end

def install_usbboot()
  @equipment['server1'].send_cmd("which usbboot; echo $?", /^0[\0\n\r]+/m, 5) 
  raise "usbboot tool needs to be copied to '/usr/bin/'" if @equipment['server1'].timeout?
end

def clean
  puts "cleaning..."
  @equipment['dut1'].reset_sysboot(@equipment['dut1'])
end















