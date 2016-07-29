# -*- coding: ISO-8859-1 -*-
# This application can be used to test block device boot including qspi, spi, mmc, emmc, usbhost etc
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
end

def run
  result = 0
  blk_boot_media = ['qspi', 'spi', 'mmc', 'emmc', 'rawmmc-emmc', 'nand', 'usbmsc']
  boot_media = @test_params.params_chan.boot_media[0].downcase
  
  this_params = {}
  set_bootloader_devs(this_params, boot_media)
  bparams = setup_host_side(this_params)
  bparams.each{|k,v| puts "#{k}:#{v}"}

  if blk_boot_media.include?(boot_media)
    puts "Updating bootloader..."
    bparams['dut'].update_bootloader(bparams)
  end    

  case boot_media
  when /usbeth/
    staf_mutex("usbeth_setup", 60000) do
      setup_host_for_usbeth_boot(bparams)
      setup_usbeth_images(bparams)
    end
  end

  begin

    # Verify if the board can boot using the updated bootloader
    sleep 2
    # powercycle or reset the board to check
    bparams['dut'].boot_loader = nil
    case boot_media
    when /usbeth/
      staf_mutex("usbeth_boot", 600000) do
        bparams['dut'].boot_to_bootloader(bparams)
      end
    else
      bparams['dut'].boot_to_bootloader(bparams)
    end

  rescue Exception => e
    bparams['dut'].reset_sysboot(bparams['dut'])
    raise e
    
  end

  bparams['dut'].send_cmd("version", bparams['dut'].boot_prompt, 10)
  result += 1 if bparams['dut'].timeout? 

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test fail")
  end  

end 

def clean
  puts "cleaning..."
  @equipment['dut1'].reset_sysboot(@equipment['dut1'])
end


def set_bootloader_devs(params, media)
  case media.downcase
  when "rawmmc-emmc"
    bootloader_dev = 'rawmmc-emmc'
    mmc_dev = 1
  when "mmc"
    bootloader_dev = 'mmc'
    mmc_dev = 0
  else
    bootloader_dev = media 
  end
  params['primary_bootloader_dev'] = bootloader_dev
  params['secondary_bootloader_dev'] = bootloader_dev
  params['mmcdev'] = mmc_dev if defined?(mmc_dev)
end

# copy the boot images into tftpboot and rename to the expected names
def setup_usbeth_images(params)
  if params['primary_bootloader'] != ''
    soc_name = get_soc_name_for_platform(@test_params.platform.downcase)
    srcfile = File.join(params['server'].tftp_path, params['primary_bootloader_image_name'] )
    dstfile = File.join(params['server'].tftp_path, "usbspl/u-boot-spl\.bin\.#{soc_name}")
    copy_with_path(srcfile, dstfile)
  end
  if params['secondary_bootloader'] != ''
    srcfile = File.join(params['server'].tftp_path, params['secondary_bootloader_image_name'] )
    dstfile = File.join(params['server'].tftp_path, "usbspl/u-boot\.img\.#{soc_name}")
    copy_with_path(srcfile, dstfile)
  end

end

def get_soc_name_for_platform(platform)
  case platform.downcase
    when /beaglebone/, /am335x-evm/
      rtn = 'am335x'
    when /am43xx-gpevm/, /am43xx-epos/
      rtn = 'am43xx'
    else
      rtn = platform.downcase
  end
  rtn
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
  filename \"usbspl/uImage-3.2.0+\";
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
