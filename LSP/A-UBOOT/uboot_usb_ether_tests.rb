# -*- coding: ISO-8859-1 -*-
# This script set the uboot to use usb_ether interface and load kernel
# using this interface and boot to kernel.

require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../update_mmc'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
  @equipment['dut1'].set_api('psp')


end

def run
  result = 0


  bparams = setup_host_side()
  bparams['dut'].set_bootloader(bparams) if !@equipment['dut1'].boot_loader
  bparams['dut'].set_systemloader(bparams) if !@equipment['dut1'].system_loader

  bparams['dut'].boot_to_bootloader bparams
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 5)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?

  bparams.each{|k,v| puts "#{k}:#{v}"}
  if bparams['kernel'].strip == '' 
    raise "kernel is not provided"
  end

  staf_mutex("usb_ether_setup", 60000) do
    setup_usbeth_images(bparams)
    setup_host_for_usbeth_boot(bparams)
  end

  counter = 0
  loop_count = @test_params.params_chan.instance_variable_defined?(:@loop_count) ? @test_params.params_chan.loop_count[0].to_i : 1
  while counter < loop_count
    report_msg "Inside the loop counter = #{counter} "
    result_msg = ''

    sleep 1
    bparams['dut'].send_cmd("setenv ethact usb_ether", bparams['dut'].boot_prompt, 5)
    # it should load zImage when do dhcp
    bparams['dut'].send_cmd("dhcp", bparams['dut'].boot_prompt, 120)
    if ! bparams['dut'].response.match(/Using\s+usb_ether\s+device/i)
      result += 1
    end
 
    bparams['bootargs'] = bparams['dut'].boot_args if !bparams['bootargs']
    bparams['dut'].set_systemloader(bparams)
    bparams['dut'].system_loader.run(bparams)

    counter += 1
  end # end of while loop

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test failed; usb_ether interface was not used")
  end  

end 

def clean
  puts "cleaning..."
end

# copy the boot images into tftpboot and rename to the expected names
def setup_usbeth_images(params)
  #soc_name = get_soc_name_for_platform(@test_params.platform.downcase)
  if params['kernel'] != ''
    srcfile = File.join(params['server'].tftp_path, params['kernel_image_name'] )
    dstfile = File.join(params['server'].tftp_path, "usbspl/zImage")
    copy_with_path(srcfile, dstfile)
  end

end

def setup_host_for_usbeth_boot(params)
  # Add boot images block into dhcp conf file
  linux_version = get_linux_version(params)
  dhcp_conf_file_orig = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp_conf_file', 'version'=>linux_version})
  # The dhcp conf file ends with '.usbeth' should be passed to dhcpd command
  dhcp_conf_file = dhcp_conf_file_orig + ".usbeth"
  params['server'].send_sudo_cmd("cp #{dhcp_conf_file_orig} #{dhcp_conf_file}", params['server'].prompt, 60)
  append_config_dhcp(params, dhcp_conf_file)

end

# append boot images to end of dhcp config file
def append_config_dhcp(params, file_full_path)
  puts "Appending boot image configuration to dhcp config ..."
  dhcp_spl_config = dhcp_spl_config()
  dhcp_spl_config.split(/\n/).each do |line|
    string_append = "'$ a" + line + "'"
    params['server'].send_sudo_cmd("sudo sed -i #{string_append} #{file_full_path}", params['server'].prompt, 180)
  end
end

def dhcp_spl_config
  dhcp_spl_config  = """
#OpenTest: Boot Images Block Start

subnet 192.168.2.0 netmask 255.255.255.0 {
  max-lease-time 300;
  range dynamic-bootp 192.168.2.51 192.168.2.254;
}

## Match the ROM and U-Boot SPL strings for am335x and am43xx
if substring (option vendor-class-identifier, 0, 10) = \"DM814x ROM\" {
  filename \"usbspl/u-boot-spl.bin\"; #DM814x
} elsif substring (option vendor-class-identifier, 0, 10) = \"AM335x ROM\" {
  filename \"usbspl/u-boot-spl.bin.am335x\"; #beaglebone-black,am335x-evm
} elsif substring (option vendor-class-identifier, 0, 17) = \"AM335x U-Boot SPL\" {
  filename \"usbspl/u-boot.img.am335x\"; #uboot_image
} elsif substring (option vendor-class-identifier, 0, 10) = \"AM43xx ROM\" {
filename \"usbspl/u-boot-spl.bin.am43xx\"; #am43xx-gpevm
} elsif substring (option vendor-class-identifier, 0, 17) = \"AM43xx U-Boot SPL\" {
filename \"usbspl/u-boot.img.am43xx\"; #uboot_image
} else {
  filename \"usbspl/zImage\";
}

#OpenTest: Boot Images Block End
  """
  return dhcp_spl_config
end

def get_linux_version(params)
   params['server'].send_cmd("lsb_release -a", params['server'].prompt, 10)
   return params['server'].response.scan(/Release:\s+([0-9]+.[0-9]+)/)[0][0]
end

def copy_with_path(src, dst)
  if File.exist?(src)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  else
    raise "File: #{src} doesn't exist"
  end
end

