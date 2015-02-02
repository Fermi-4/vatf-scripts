require File.dirname(__FILE__)+'/../default_test_module' 
include LspTestScript
include BootLoader

#Description
#This file has execution skeleton for boot orders. Different platform 
#have different available booting media and booting orders. The boot order
#for each platform is defined in platform_boot_order hash tables. Boot related 
#unique steps which are required by the platform must be defined on the file 
#that defines the test case for that platform. The recommended filename is 
#[platfrom_name]_boot_order_test.rb. 

#Test setup needed to run the test 
#1) Usb connection with the host using the USB switch
 #dut.params = {'usb_port' => {'1' => 1}}  
#2) Direct Serial Connect with the host 
 #dut.serial_port = active connected serial port
 #dut.serial_params = {"baud" => 115200, "data_bits" => 8, "stop_bits" => 1, "parity" => SerialPort::NONE}
#3) Devantech Relay connection for resetting the board as defined in sample bench.rb
# Devantech / robot-electronics.co.uk relay.  Uses default port and user/pass
# This device is used to trigger the reset signal on a board, and the board
# is powered by something else.
#pwr = EquipmentInfo.new("power_controller", "rly16.IP.ADDR")
#pwr.telnet_ip = 'IP.ADDR'
#pwr.driver_class_name = 'DevantechRelayController'
#4) Ethernet connection 

def setup
  @equipment['dut1'].connect({'type'=>'serial'})
  connect_to_extra_equipment() 
end


def run
  status =  1
  @translated_boot_params = get_image()
  platform_boot_order = {}
  platform_boot_order['beaglebone-black'] = [:emmc_boot, :uart_boot, :usbrndis_boot] 
  platform_boot_order['am335x-evm'] = [:uart_boot,:nand_boot] 
  platform_boot_order['am43xx-gpevm'] = [:nand_boot, :usbhost_boot, :usbrndis_boot] 
  platform_boot_order[@test_params.platform.downcase].each{|func|
     test_method=self.method(func)
     status = test_method.call()
     if status > 0 
      puts "Boot Order Test failed at #{func}"
     break
     end 
  }    

  if status < 1
    set_result(FrameworkConstants::Result[:pass], "Boot Order Test Pass","")
  else
    set_result(FrameworkConstants::Result[:fail], "Boot Order Test Fail","")   
  end  
end

def get_ubuntu_version()
   @equipment['server1'].send_cmd("lsb_release -a", @equipment['server1'].prompt, 10)
   return @equipment['server1'].response.scan(/Release:\s+([0-9]+.[0-9]+)/)[0][0] 
end 

# Function does DHCP initialization.
# Input parameters: None 
# Return Parameter: None.  

def init_dhcp()
  puts "INIT DHCP and START DHCP ..."
  dhcp_conf_file_full_path = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp_conf_file', 'version'=>get_ubuntu_version()})
  package_name = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp-server', 'version'=>get_ubuntu_version()})
  @equipment['server1'].send_cmd("dpkg -s  #{package_name} |  grep Status", @equipment['server1'].prompt, 240)
  if @equipment['server1'].response.scan(/Status:\s+install\s+ok\s+installed/)[0] == nil
     puts "DHCP server was not installed!\n"
     puts "DHCP server installing now ...!\n"
     ubuntu_package_installer(package_name)
  end  
  if check_config_dhcp(dhcp_conf_file_full_path) ==  1
    append_config_dhcp(dhcp_conf_file_full_path)
  end
  dhcp_sever_setup_file_full_path = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp_sever_setup_file', 'version'=>get_ubuntu_version()})
  line_to_insert = "INTERFACES=\"usb0\""
  insert_line_to_a_file('INTERFACES=',"INTERFACES=\"usb0\"",dhcp_sever_setup_file_full_path)
  restart_dhcp()
end 

# Function does configuration appending to newly installed dhcp file.
# Input parameters: file_full_path = location of the file  
# Return Parameter: None.  

def append_config_dhcp(file_full_path)
  puts "Appending spl configuration to dhcp config ..."
  dhcp_spl_config = dhcp_spl_config()
  dhcp_spl_config.split(/\n/).each do |line|
    string_append = "'$ a" + line + "'" 
    @equipment['server1'].send_sudo_cmd("sudo sed -i #{string_append} #{file_full_path}", @equipment['server1'].prompt, 180)
  end 
end 

# Function does open dhcp file and checkes for configuration.
# Input parameters: file_full_path = location of the file  
# Return Parameter: status  


def check_config_dhcp(file_full_path)
  status = 0
  fh = File.open(file_full_path, 'r')
  if fh
    file_txt = fh.read() 
    #if configuration doesn't exist append the configuration
    if file_txt.to_s.scan(/#OpenTest:\s+Boot\s+images\s+spl\s+loading\s+block/)[0] == nil
      status = 1
    else 
      status = 0
    end 
  else 
    raise file_full_path + " does't exit"
  end 
  fh.close
  return status
end

# Function does line replace in the file.
# Input parameters: pattern= pattern to search, line_to_insert = line to insert, file_full_path = location of the file  
# Return Parameter: None.  

def insert_line_to_a_file(pattern, line_to_insert,file_full_path)
  sed_cmd_param = "'/" + pattern + "/c " + line_to_insert + "'"  
  @equipment['server1'].send_sudo_cmd("sudo sed -i #{sed_cmd_param} #{file_full_path}", @equipment['server1'].prompt, 180) 
end 

# Function does dhcp restart.
# Input parameters: None 
# Return Parameter: None.  

def restart_dhcp()
  puts "RESTARTING DHCP ..."
  dhcp_service_restart = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp_service_restart', 'version'=>get_ubuntu_version()})
  puts "####dhcp_service_restart command: " + dhcp_service_restart
  @equipment['server1'].send_sudo_cmd(dhcp_service_restart, @equipment['server1'].prompt, 240)
  @equipment['server1'].send_cmd("ps -ef | grep  dhcp", @equipment['server1'].prompt, 240)
  if @equipment['server1'].response.scan(/dhcpd.conf\s+usb0/) == nil 
     raise "DHCP server did not start!\n"
  end 
end 



# Function does package installation on ubuntu machin.
# Input parameters: package_name is the name of the package. 
# Return Parameter: None  

def ubuntu_package_installer(package_name)
  
  #-y option is used because the package is authentic. No need interactive confirmation.  
  puts package_name 
  @equipment['server1'].send_sudo_cmd("apt-get install -y #{package_name}", @equipment['server1'].prompt, 180)
  #check the package was installed properly. 
  @equipment['server1'].send_cmd("dpkg -s  #{package_name} |  grep Status", @equipment['server1'].prompt, 240)
  if @equipment['server1'].response.scan(/Status:\s+install\s+ok\s+installed/)[0] == nil
   raise "Package named #{package_name} was not installed properly"
  end
    
end 


def dhcp_spl_config
  dhcp_spl_config  = """
#OpenTest: Boot images spl loading block

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

allow bootp;
subnet 192.168.0.0 netmask 255.255.255.0 {
}

subnet 192.168.2.0 netmask 255.255.255.0 {
  max-lease-time 120;
  range dynamic-bootp 192.168.2.2 192.168.2.10;
}
 """     
return dhcp_spl_config 
end 



# Function does sanity integrity test on uboot, after the system booted from chosen media.
# Input parameters: None 
# Return Parameter: pass or fail.  

def uboot_sanity_test()
  puts "UBOOT SANITY TEST .........."
  @equipment['dut1'].send_cmd('print ver', @equipment['dut1'].boot_prompt, 2)
  #@equipment['dut1'].send_cmd("help", @equipment['dut1'].boot_prompt, 5)
  #@equipment['dut1'].send_cmd("printenv", @equipment['dut1'].boot_prompt, 5)
  # TODO: check if we can boot to kernel

  if @equipment['dut1'].timeout?
    return 1
  else 
    return 0
  end 

  # may add test to boot to kernel here

end
 
# Function sets ip address from the dut.
# Input parameters: None 
# Return Parameter: None.  

def set_dut_ipaddr()
  # Force dut not to do tftp automatically. 
  @equipment['dut1'].send_cmd("setenv serverip #{@equipment['server1'].telnet_ip}", @equipment['dut1'].boot_prompt, 2)
  @equipment['dut1'].send_cmd("setenv autoload no", @equipment['dut1'].boot_prompt, 2)
  # Force dut not to do tftp automatically. 
  dhcp = CmdTranslator::get_uboot_cmd({'cmd'=>'dhcp', 'version'=>'0.0'})
  @equipment['dut1'].send_cmd(dhcp, @equipment['dut1'].boot_prompt, 10)
  #if there was no ip allocated raise exception.
  dut_ipaddr = @equipment['dut1'].response.to_s.scan(/DHCP\s+client\s+bound\s+to\s+address\s+([0-9]+.[0-9]+.[0-9]+.[0-9]+)/)
  raise "Dut ip is not set." if dut_ipaddr == nil
end

# Function restores sd and emmc media.
# Input parameters: part partition.
# Return Parameter: None.  

def restore_mmc(part) 
  puts "RESTORING MMC Part " + part.to_s + " ..."

  set_dut_ipaddr()
  # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/current_device\Wpart\s+0\W\s+is\s+current\s+device/)
  raise "Device is not selected" if device_set == nil
  # Load MLO
  uboot_cmd = "tftp ${loadaddr}  #{@translated_boot_params['primary_bootloader_mmc_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load =  @equipment['dut1'].response.to_s.scan(/done/)
  raise "MLO tftp load failed" if tftp_load == nil
  # Write MLO to device 
  uboot_cmd = 'mmc write ${loadaddr} 100 100'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write =  @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil
  uboot_cmd = 'mmc write ${loadaddr} 200 100'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil
  # Load uboot image
  uboot_cmd = "tftp ${loadaddr} #{@translated_boot_params['secondary_bootloader_mmc_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load = @equipment['dut1'].response.to_s.scan(/done/)
  raise "u-boot.img tftp load failed" if tftp_load == nil
  # Write boot image to device
  uboot_cmd = 'mmc write ${loadaddr} 300 400'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

end 


# Function does invalidate either emmc or mmc(SD) media.
# Input parameters: part partition 
# Return Parameter: None.  

def invalidate_mmc(part)
  puts "INVALIDATING MMC part " + part.to_s + " ..."
  set_dut_ipaddr()
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/current_device\Wpart\s+0\W\s+is\s+current\s+device/)
  raise "Device is not selected" if device_set == nil
  # Load MLO
  uboot_cmd = "mw ${loadaddr} ffffffff 100"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  uboot_cmd = "md ${loadaddr}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mem_data = @equipment['dut1'].response.to_s.scan(/ffffffff /)
  raise "write garbage data to memory failed" if mem_data == nil
 
  # Write MLO to device 
  uboot_cmd = 'mmc write ${loadaddr} 100 100'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil
  uboot_cmd = 'mmc write ${loadaddr} 200 100'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

end 

# Function does reboot dut.and stop at boot prompt
# Input parameters: None 
# Return Parameter: None.  
def reboot_dut()
  puts "REBOOTING DUT ..."
  @equipment['dut1'].power_cycle(@translated_boot_params)
  connect_to_equipment('dut1')
  30.times {
    @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 1)
    break if !@equipment['dut1'].timeout?
  }

end


# Function does configuration and booting to boot loader.
# Input parameters: None 
# Return Parameter: None. 
def boot_to_bootloader()
  puts "#########boot_to_bootloader###########"
  @translated_boot_params['dut'].set_bootloader(@translated_boot_params) if !@equipment['dut1'].boot_loader
  @translated_boot_params.each{|k,v| puts "#{k}:#{v}"}

  @translated_boot_params['dut'].boot_to_bootloader @translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 2)
  raise 'Bootloader was not loaded properly. Failed to get to bootloader prompt' if @equipment['dut1'].timeout?
end 

# Function does MLO loading from the network.
# Input parameters: None 
# Return Parameter: translated_params.  
def get_image
  params={}
  params['primary_bootloader_mmc'] = @test_params.instance_variable_defined?(:@primary_bootloader_mmc) ? @test_params.primary_bootloader_mmc : ''
  params['primary_bootloader_mmc_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_mmc_src_dev) ? @test_params.params_chan.primary_bootloader_mmc_src_dev[0] : 'eth'
  params['secondary_bootloader_mmc'] = @test_params.instance_variable_defined?(:@secondary_bootloader_mmc) ? @test_params.secondary_bootloader_mmc : ''
  params['secondary_bootloader_mmc_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_mmc_src_dev) ? @test_params.params_chan.secondary_bootloader_mmc_src_dev[0] : 'eth'

  params['primary_bootloader_usbspl'] = @test_params.instance_variable_defined?(:@primary_bootloader_usbspl) ? @test_params.primary_bootloader_usbspl : ''
  params['primary_bootloader_usbspl_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_usbspl_src_dev) ? @test_params.params_chan.primary_bootloader_usbspl_src_dev[0] : 'eth'                               
  params['secondary_bootloader_usbspl'] = @test_params.instance_variable_defined?(:@secondary_bootloader_usbspl) ? @test_params.secondary_bootloader_usbspl : ''
  params['secondary_bootloader_usbspl_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_usbspl_src_dev) ? @test_params.params_chan.secondary_bootloader_usbspl_src_dev[0] : 'eth'                               
  params['primary_bootloader_nand'] = @test_params.instance_variable_defined?(:@primary_bootloader_nand) ? @test_params.primary_bootloader_nand : ''
  params['primary_bootloader_nand_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_nand_src_dev) ? @test_params.params_chan.primary_bootloader_nand_src_dev[0] : 'eth'
  params['secondary_bootloader_nand'] = @test_params.instance_variable_defined?(:@secondary_bootloader_nand) ? @test_params.secondary_bootloader_nand : ''
  params['secondary_bootloader_nand_src_dev'] = @test_params.params_chan.instance_variable_defined?(:@secondary_bootloader_nand_src_dev) ? @test_params.params_chan.secondary_bootloader_nand_src_dev[0] : 'eth'

  translated_params = setup_host_side(params)

  # copy the usbspl images to image names specified in dhcp if there is usbspl images
  if params['primary_bootloader_usbspl'] != ''
    soc_name = get_soc_name_for_platform(@test_params.platform.downcase)
    srcfile = File.join(translated_params['server'].tftp_path, translated_params['primary_bootloader_usbspl_image_name'] ) 
    dstfile = File.join(translated_params['server'].tftp_path, "usbspl/u-boot-spl\.bin\.#{soc_name}")
    copy_with_path(srcfile, dstfile)
  end
  if params['secondary_bootloader_usbspl'] != ''
    srcfile = File.join(translated_params['server'].tftp_path, translated_params['secondary_bootloader_usbspl_image_name'] ) 
    dstfile = File.join(translated_params['server'].tftp_path, "usbspl/u-boot\.img\.#{soc_name}")
    copy_with_path(srcfile, dstfile)
  end

  return translated_params
end 

# Function erases emmc
# Input parameters: part (partition), block (starting block), count  
# Return Parameter: None.  

def erase_emmc_device(part, blocks, count) 
  puts "ERASE MMC part " + part.to_s + " ..."
  # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/Card\+did\+not\+respond\+to\+voltage\+select/)
  raise "Device is not selected" if device_set == nil
  # Ensure we are able to talk with this mmc device
  uboot_cmd = "mmc erase #{blocks} #{count}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/erase:\s+OK/)
  raise "MMC erase failed" if mmc_write == nil

end 

# Function erase nand
# Input
# Return
def erase_nand
  puts "ERASE NAND..."
  @equipment['dut1'].send_cmd("nand erase.chip", @equipment['dut1'].boot_prompt, 5)
  rtn = @equipment['dut1'].response.to_s.scan(/OK/)
  puts "rtn:"+rtn.to_s
  raise "Erase nand failed" if ! @equipment['dut1'].response.to_s.scan(/OK/)
end


# Function does boot from nand.
# Input parameters: None 
# Return Parameter: pass or fail. 
def flash_nand()
  puts "#### FLASH NAND BOOT START ####"
  #@equipment['dut1'].send_cmd("#check_prompt", @equipment['dut1'].boot_prompt, 2)
  raise "flash_nand::Dut is not in uboot prompt" if ! @equipment['dut1'].at_prompt?({'prompt'=>@equipment['dut1'].boot_prompt})

  #Because platform booted from UART, needed to change from uart to nand 
  @translated_boot_params['primary_bootloader_dev'] = 'nand'
  @translated_boot_params['primary_bootloader_src_dev'] = @translated_boot_params['primary_bootloader_nand_src_dev']
  @translated_boot_params['primary_bootloader'] = @translated_boot_params['primary_bootloader_nand']
  @translated_boot_params['primary_bootloader_image_name'] = @translated_boot_params['primary_bootloader_nand_image_name']
  @translated_boot_params['secondary_bootloader_dev'] = 'nand'
  @translated_boot_params['secondary_bootloader_src_dev'] = @translated_boot_params['secondary_bootloader_nand_src_dev']
  @translated_boot_params['secondary_bootloader'] = @translated_boot_params['secondary_bootloader_nand']
  @translated_boot_params['secondary_bootloader_image_name'] = @translated_boot_params['secondary_bootloader_nand_image_name']
  # since just set nand to primary/secondary_bootloader_dev, need call add_dev_loc_to_params again
  # to set nand partition location names 
  @translated_boot_params = add_dev_loc_to_params(@translated_boot_params, 'primary_bootloader')
  @translated_boot_params = add_dev_loc_to_params(@translated_boot_params, 'secondary_bootloader')

  @translated_boot_params.each{|k,v| puts "#{k}:#{v}"}
  boot_loader = UbootFlashBootloaderSystemLoader.new()
  boot_loader.run(@translated_boot_params)

end


def flash_usbhost()
  @equipment['dut1'].send_cmd("usb start", @equipment['dut1'].boot_prompt, 5)
  raise "No usb host device being found" if ! @equipment['dut1'].response.match(/[0-9]+\s+Storage\s+Device.*found/i)
  set_dut_ipaddr()
  uboot_cmd = "tftp ${loadaddr}  #{@translated_boot_params['primary_bootloader_mmc_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load =  @equipment['dut1'].response.to_s.scan(/done/)
  raise "MLO tftp load failed" if tftp_load == nil
  @equipment['dut1'].send_cmd("fatwrite usb 0 ${loadaddr} MLO ${filesize}", @equipment['dut1'].boot_prompt, 5)
  raise "fatwrite usb failed! Please check if usbmsc has fat partition on it." if ! @equipment['dut1'].response.match(/bytes\s+written/)

  uboot_cmd = "tftp ${loadaddr}  #{@translated_boot_params['secondary_bootloader_mmc_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load =  @equipment['dut1'].response.to_s.scan(/done/)
  raise "u-boot.img tftp load failed" if tftp_load == nil
  @equipment['dut1'].send_cmd("fatwrite usb 0 ${loadaddr} u-boot.img ${filesize}", @equipment['dut1'].boot_prompt, 5)
  raise "fatwrite usb failed" if ! @equipment['dut1'].response.match(/bytes\s+written/)
  
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

def copy_with_path(src, dst)
  if File.exist?(src)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  else
    raise "File: #{src} doesn't exist"
  end
end
