# -*- coding: ISO-8859-1 -*-
# This application can be used to test block device boot including qspi, spi, mmc, emmc, usbhost etc
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
  install_fdtput()
end

def run
  result = 0
  result_msg = ''
  boot_media = @test_params.params_chan.boot_media[0].downcase
  
  this_params = {}
  set_bootloader_devs(this_params, boot_media)
  bparams = setup_host_side(this_params)
  bparams.each{|k,v| puts "#{k}:#{v}"}
  if bparams['secondary_bootloader'].strip == '' 
    raise "Bootloaders are not provided"
  end
  if bparams['dtb'].strip == '' 
    raise "DTB is not provided"
  end
  if bparams['kernel'].strip == ''
    raise "Kernel uImage is not provided"
  end

  # modify dtb to add needed bootargs
  @equipment['server1'].send_cmd("fdtput -v -t s #{File.join(@equipment['server1'].tftp_path, bparams['dtb_image_name'])} \"/chosen\" bootargs #{bparams['dut'].boot_args} ")

  puts "Updating bootloader, kernel and dtb..."
  #bparams['dut'].update_bootloaderkernel(bparams)

  bparams['primary_bootloader_dev'] = 'mmc' # So the board just power cycle
  puts "=============boot params for bootloader============="
  bparams.each{|k,v| puts "#{k}:#{v}"}
  bparams['dut'].set_bootloader(bparams)
  bparams['dut'].boot_loader.run(bparams)

  set_bootloader_devs(bparams, boot_media)
  puts "=============boot params for systemloader============="
  bparams.each{|k,v| puts "#{k}:#{v}"}
  bparams['dut'].set_systemloader(bparams.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderKernelSystemLoader}))
  bparams['dut'].system_loader.run(bparams)

  #By now, all images should be flashed into qspi. 
  # Change to qspi boot, then power cycle
  begin

    # Verify if the board can boot using the updated bootloader
    sleep 2
    bparams['dut'].set_sysboot(bparams['dut'], boot_media)
    bparams['dut'].power_cycle(bparams)
    bparams['dut'].connect({'type'=>'serial'})
    bparams['dut'].wait_for(/Booting\s+linux.*kernel\s+command\s+line:.*/im)
    raise "The DUT did not boot to kernel" if bparams['dut'].timeout?
    raise "Should not go to UBoot in Falcon mode." if bparams['dut'].response.match(/Hit\s+any\s+key\s+to\s+stop\s+autoboot/i)
    bparams['dut'].wait_for(bparams['dut'].login_prompt, 5) # just like to collect more log; do not expect to see login prompt
  rescue Exception => e
    bparams['dut'].reset_sysboot(bparams['dut'])
    raise e

  end

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test fail! "+result_msg)
  end  

end 

def clean
  puts "cleaning..."
  @equipment['dut1'].reset_sysboot(@equipment['dut1'])
end


def set_bootloader_devs(params, media)
  bootloader_dev = media 
  params['primary_bootloader_dev'] = bootloader_dev
  params['secondary_bootloader_dev'] = bootloader_dev
  params['dtb_dev'] = bootloader_dev
  params['kernel_dev'] = bootloader_dev
end

# install  if it is not in host
def install_fdtput()
  @equipment['server1'].send_cmd("which fdtput; echo $?", /^0[\0\n\r]+/im, 2)
  @equipment['server1'].send_sudo_cmd("apt-get install device-tree-compiler", @equipment['server1'].prompt, 600) if @equipment['server1'].timeout?
  @equipment['server1'].send_cmd("which fdtput; echo $?", /^0[\0\n\r]+/im, 5)
  raise "fdtput is not installed!" if @equipment['server1'].timeout?
end

def copy_with_path(src, dst)
  if File.exist?(src)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  else
    raise "File: #{src} doesn't exist"
  end
end

