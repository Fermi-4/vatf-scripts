# -*- coding: ISO-8859-1 -*-
# This application can be used to test block device boot including qspi, spi, mmc, emmc, usbhost etc
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../update_mmc'
require File.dirname(__FILE__)+'/../../lib/utils'
   
include LspTestScript   

def setup
	@equipment['dut1'].set_api('psp')
end

def run
  result = 0
  blk_boot_media = ['hflash','ospi','qspi', 'spi', 'mmc', 'emmc', 'rawmmc-emmc', 'rawmmc-emmc-bootpart', 'nand', 'usbmsc']
  boot_media = @test_params.params_chan.boot_media[0].downcase
  
  this_params = {}
  set_bootloader_devs(this_params, boot_media)
  bparams = setup_host_side(this_params)
  set_bootloader_devs(this_params, boot_media)
  bparams.each{|k,v| puts "#{k}:#{v}"}
  if bparams['secondary_bootloader'].strip == '' and bparams['primary_bootloader'].strip == '' 
    raise "Bootloaders are not provided"
  end
  if blk_boot_media.include?(boot_media)
    puts "Updating bootloader..."

    bparams['primary_bootloader_dev'] = 'mmc' # So the board just power cycle
    puts "=============boot params for bootloader============="
    bparams.each{|k,v| puts "#{k}:#{v}"}
    bparams['dut'].set_bootloader(bparams)
    bparams['dut'].boot_loader.run(bparams)

    set_bootloader_devs(bparams, boot_media)
    set_mmcdev(bparams, boot_media)
    puts "=============boot params for systemloader============="
    bparams.each{|k,v| puts "#{k}:#{v}"}
    bparams['dut'].set_systemloader(bparams.merge({'systemloader_class' => SystemLoader::UbootFlashBootloaderSystemLoader}))
    bparams['dut'].system_loader.run(bparams)

    configure_emmc(bparams) if boot_media == 'rawmmc-emmc-bootpart'
    #bparams['dut'].update_bootloader(bparams)
  end    

  case boot_media
  when "usbeth"
    staf_mutex("usbeth_setup", 60000) do
      setup_usbeth_images(bparams)
      setup_host_for_usbeth_boot(bparams)
    end
  when "eth"
    staf_mutex("ethboot_setup", 60000) do
      setup_usbeth_images(bparams)
    end
  end

  counter = 0
  bootfail_cnt = 0
  loop_count = @test_params.params_chan.instance_variable_defined?(:@loop_count) ? @test_params.params_chan.loop_count[0].to_i : 1
  while counter < loop_count
    report_msg "Inside the loop counter = #{counter} "
    result_msg = ''

    begin
      #bparams['dut'].power_cycle(bparams)
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
        if bparams['dut'].name =~ /am437x-sk|am437x-idk/ and boot_media == "qspi" 
          # remove SD card so switch to qspi boot (MMC0->USB?->QSPI)
          if bparams['dut'].params.has_key?("microsd_switch")
            switch_to_host(bparams)
          else
            raise "Could not test qspi boot on am437x-sk or am437x-idk since there is no SDMux setup"
          end
        end
        bparams['dut'].boot_to_bootloader(bparams)
      end

      bparams['dut'].send_cmd("version", bparams['dut'].boot_prompt, 10)
      if bparams['dut'].timeout?
        result += 1  
        report_msg ("DUT failed to boot from #{boot_media} on iteration #{counter}.")
      else
        report_msg ("DUT is able to boot from #{boot_media} on iteration #{counter}.")
      end

      test_uboot = @test_params.params_chan.instance_variable_defined?(:@test_uboot) ? @test_params.params_chan.test_uboot[0].downcase : "no"
      if test_uboot != 'no'
        bparams['dut'].send_cmd("saveenv", /done|\.\.\s*ok|Writing\s+to\s+NAND.*OK/i, 10)
        
        if bparams['dut'].timeout? 
          result += 1 
          result_msg = result_msg + "saveenv failed when booting from #{boot_media}; "
        end

        mmcdev_nums = get_uboot_mmcdev_mapping()
        bparams['dut'].send_cmd("mmc rescan; mmc dev #{mmcdev_nums['mmc']}", bparams['dut'].boot_prompt, 10)
        if bparams['dut'].response.match(/Card\s+did\s+not\s+respond\s+to\s+voltage\s+select!/i)
          result += 1 
          result_msg = result_msg + "mmc card could not be detected when booting from #{boot_media}; "
        end
      end

      test_kernel = @test_params.params_chan.instance_variable_defined?(:@test_kernel) ? @test_params.params_chan.test_kernel[0].downcase : "no"
      if test_kernel == 'yes'
        raise "kernel is not provided and could not load kernel" if bparams['kernel'].strip == ''

        # load kernel from the boot_media
        # flash kernel/dtb to boot_media if it is storage type
        set_bootloader_devs(bparams, boot_media)
        set_mmcdev(bparams, boot_media)
        puts "=============boot params for systemloader============="
        bparams.each{|k,v| puts "#{k}:#{v}"}
        if blk_boot_media.include?(boot_media)
          puts "Updating kernel/dtb..."
          bparams['dut'].set_systemloader(bparams.merge({'systemloader_class' => SystemLoader::UbootFlashKernelSystemLoader}))
          bparams['dut'].system_loader.run(bparams)
        end

        bparams['dut'].set_systemloader(bparams.merge({'systemloader_class' => SystemLoader::UbootKernelSystemLoader}))
        bparams['dut'].system_loader.run(bparams)

      end

    rescue Exception => e
      result_msg = result_msg + "Test failed on iteration #{counter}: " + e.to_s
      report_msg result_msg + e.backtrace.to_s
      result += 1
      bootfail_cnt += 1
      bparams['dut'].reset_sysboot(bparams['dut'])
    ensure
      counter += 1
	  if @equipment['dut1'].name =~ /am437x-sk|am437x-idk/
	    switch_to_dut(bparams)
	  end
    end
  end # end of while loop

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test pass")
  else
    set_result(FrameworkConstants::Result[:fail], "This test failed #{bootfail_cnt.to_s} out of #{loop_count.to_s}.")
  end  

end 

def clean
  puts "cleaning..."
  @equipment['dut1'].reset_sysboot(@equipment['dut1'])
end

def switch_to_dut(params)
  return if !params['dut'].params.has_key?("microsd_switch")
  
  setup_ti_test_gadget(params)
  @equipment['ti_test_gadget'].set_interfaces(params['dut'].params)
  report_msg "Switching back to DUT..."
  @equipment['ti_test_gadget'].switch_microsd_to_dut(params['dut'])
end

# remove sd card by switching SDmux to host side
def switch_to_host(params)
  return if !params['dut'].params.has_key?("microsd_switch")

  setup_ti_test_gadget(params)
  @equipment['ti_test_gadget'].set_interfaces(params['dut'].params)

  #Resolve symlink and get nodes
  host_node = params['dut'].params['microsd_host_node']
  if File.symlink?(host_node)
    node = "/dev/#{File.readlink(host_node)}"
  else
    node = host_node
  end
  node = node.strip.sub(/\d*$/, '') # only keep base node like sdb not sdb1.

  begin
    report_msg "Switching to host..."
    @equipment['ti_test_gadget'].switch_microsd_to_host(params['dut'])
    sleep 2
    30.times {
      params['server'].send_cmd("ls #{node}[[:digit:]]*; echo $?", /^0[\0\n\r]+/im, 2)
      if params['server'].timeout?
        sleep 2
      else
        break
      end
    }
    params['server'].send_cmd("ls #{node}[[:digit:]]*; echo $?", /^0[\0\n\r]+/im, 2)
    raise "Failed to switch to host" if params['server'].timeout?
    report_msg "Switching to host done"
  end

end

def configure_emmc(params)
  partition_config = CmdTranslator::get_uboot_cmd({'cmd'=>'emmc_partition_config', 'version'=>"0.0", 'platform'=>params['dut'].name})
  boot_bus_width = CmdTranslator::get_uboot_cmd({'cmd'=>'emmc_boot_bus_width', 'version'=>"0.0", 'platform'=>params['dut'].name})
  rst_n_function = CmdTranslator::get_uboot_cmd({'cmd'=>'emmc_rst_n_function', 'version'=>"0.0", 'platform'=>params['dut'].name})
  params['dut'].send_cmd("mmc partconf #{partition_config}", params['dut'].boot_prompt, 5) if partition_config != ''
  params['dut'].send_cmd("mmc bootbus #{boot_bus_width}", params['dut'].boot_prompt, 5) if boot_bus_width != ''
  params['dut'].send_cmd("mmc rst-function #{rst_n_function}", params['dut'].boot_prompt, 5) if rst_n_function != ''
end

def set_mmcdev(params, media)
  return if ! media.downcase.include?("mmc")

  mmcdev_nums = get_uboot_mmcdev_mapping()
  case media.downcase
  when "rawmmc-emmc"
    params['mmcdev'] = mmcdev_nums['emmc']
    #mmc_dev = 1
  when "rawmmc-emmc-bootpart"
    params['mmcdev'] = mmcdev_nums['emmc']
    params['bootpart'] = 1 
  when "mmc"
    params['mmcdev'] = mmcdev_nums['mmc']
    #mmc_dev = 0
  end
end

def set_bootloader_devs(params, media)
  case media.downcase
  when "rawmmc-emmc"
    bootloader_dev = 'rawmmc-emmc'
  when "rawmmc-emmc-bootpart"
    bootloader_dev = 'rawmmc-emmc-bootpart'
  when "mmc"
    bootloader_dev = 'mmc'
  when "eth"
    bootloader_dev = "eth"
  else
    bootloader_dev = media 
  end
  params['sysfw_dev'] = bootloader_dev
  params['initial_bootloader_dev'] = bootloader_dev
  params['primary_bootloader_dev'] = bootloader_dev
  params['secondary_bootloader_dev'] = bootloader_dev
  params['kernel_dev'] = bootloader_dev
  params['dtb_dev'] = bootloader_dev

end

# copy the boot images into tftpboot and rename to the expected names
def setup_usbeth_images(params)
  soc_name = get_soc_name_for_platform(@test_params.platform.downcase)
  if params['primary_bootloader'] != ''
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
    when /am43xx-gpevm/, /am43xx-epos/, /am43xx-hsevm/
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

