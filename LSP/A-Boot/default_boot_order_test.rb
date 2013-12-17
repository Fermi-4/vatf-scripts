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


def connect_to_extra_equipment
  usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb_port'].keys[0]]
  if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
    usb_switch.connect({'type'=>'serial'})
  elsif usb_switch.respond_to?(:serial_server_port) && usb_switch.serial_server_port != nil
    usb_switch.connect({'type'=>'serial'})
  else
    raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the USB switch. Please check your bench file"
  end
end


def run
  status =  1
  @translated_boot_params = get_image()
  platform_boot_order = {}
  platform_boot_order['beagleboneblack'] = [:emmc_boot, :uart_boot, :usb_boot] 
  platform_boot_order['am335x-evm'] = [:uart_boot,:nand_boot] 
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
  puts "DHCP starting ..."
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
  #now update the dhcp file with boot image locations.
  line_to_insert = "filename " + "\"" + @translated_boot_params['primary_bootloader_SPL_image_name'] + "\"; #" + @test_params.platform.downcase
  insert_line_to_a_file("#" + @test_params.platform.downcase,line_to_insert,dhcp_conf_file_full_path)
  line_to_insert = "filename " + "\"" + @translated_boot_params['secondary_bootloader_image_name'] + "\"; #uboot_image" 
  insert_line_to_a_file('#uboot_image',line_to_insert,dhcp_conf_file_full_path)
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
  dhcp_service_restart = CmdTranslator::get_ubuntu_cmd({'cmd'=>'dhcp_service_restart', 'version'=>get_ubuntu_version()})
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


# Function does sanity integrity test on uboot, after the system booted from chosen media.
# Input parameters: None 
# Return Parameter: pass or fail.  

def uboot_sanity_test()
  puts "STARTED SANITY TEST .........."
  @equipment['dut1'].send_cmd('', @equipment['dut1'].boot_prompt, 2)
  @equipment['dut1'].send_cmd("help", @equipment['dut1'].boot_prompt, 2)
  uboot_commands = @equipment['dut1'].response.to_s.split(/\n/)
  puts "list of cmd commands are: " 
  uboot_commands.each{ | cmd |
    if !cmd.to_s.include?('boot') and !cmd.to_s.include?('load') and  !cmd.to_s.include?('mtest') and  !cmd.to_s.include?('reset') and  !cmd.to_s.include?('dhcp')
    puts cmd.to_s.split(/-/)[0]
    @equipment['dut1'].send_cmd(cmd.to_s.split(/-/)[0], @equipment['dut1'].boot_prompt, 2) 
    puts "#{@equipment['dut1'].response}"
    sleep 1
   end  
  }
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  if @equipment['dut1'].timeout?
    return 1
  else 
    return 0
  end 
end
 
# Function sets ip address from the dut.
# Input parameters: None 
# Return Parameter: None.  

def set_dut_ipaddr()
  # Force dut not to do tftp automatically. 
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
  # Set DUT IP 
  set_dut_ipaddr()
  uboot_cmd = "setenv serverip #{@equipment['server1'].telnet_ip}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/current_device\Wpart\s+0\W\s+is\s+current\s+device/)
  raise "Device is not selected" if device_set == nil
  # Load MLO
  uboot_cmd = "tftp ${loadaddr}  #{@translated_boot_params['primary_bootloader_MLO_image_name']}"
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
  uboot_cmd = "tftp ${loadaddr} #{@translated_boot_params['secondary_bootloader_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load = @equipment['dut1'].response.to_s.scan(/done/)
  raise "u-boot.img tftp load failed" if tftp_load == nil
  # Write boot image to device
  uboot_cmd = 'mmc write ${loadaddr} 300 400'
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  mmc_write = @equipment['dut1'].response.to_s.scan(/blocks\s+write:\s+OK/)
  raise "MMC write failed" if mmc_write == nil

end 


# Function restores sd media.
# Input parameters: None 
# Return Parameter: None.  
# This function is not test because sd is not part of the boot order 
# for now. 
def restore_or_invalidate_sd(part,block, mlo_location) 
  # Set DUT IP 
  set_dut_ipaddr()
  #set server ip
  uboot_cmd = "setenv serverip #{@equipment['server1'].telnet_ip}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  # Set device either to EMMC = 1 or MMC = 0
  uboot_cmd = "mmc dev #{part}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  current_device = "mmc#{part}"
  device_set = @equipment['dut1'].response.to_s.scan(/current_device\Wpart\s+0\W\s+is\s+current\s+device/)
  raise "Device is not selected" if device_set == nil
  # Load MLO
  uboot_cmd = "tftp ${loadaddr} #{@translated_boot_params['primary_bootloader_MLO_image_name']}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  tftp_load =  @equipment['dut1'].response.to_s.scan(/done/)
  raise "MLO tftp load failed" if tftp_load == nil
  uboot_cmd "fatwrite mmc 0 ${loadaddr} MLO #{block}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
  
end 


# Function does invalidate either emmc or mmc(SD) media.
# Input parameters: part partition 
# Return Parameter: None.  

def invalidate_mmc(part)
   puts "INVALIDATING >>>>>>>>>>>>>"
  # Set DUT IP 
  set_dut_ipaddr()
  #set server ip
  uboot_cmd = "setenv serverip #{@equipment['server1'].telnet_ip}"
  @equipment['dut1'].send_cmd(uboot_cmd, @equipment['dut1'].boot_prompt, 2)
 # Set device either to EMMC = 1 or MMC = 0
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

# Function does reboot dut.
# Input parameters: None 
# Return Parameter: None.  

def reboot_dut(regexp)
  @equipment['dut1'].power_cycle(@translated_boot_params)
  @equipment['dut1'].wait_for(regexp,200)
  raise "Platform did not boot successfully"  if @equipment['dut1'].timeout?
end

# Function does boot the dut from UART.
# Input parameters: None 
# Return Parameter: pass or fail. 

def uart_boot()
  puts "turn OFF USB Swtich !!!!!!!!!" 
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  @equipment['dut1'].wait_for(@equipment['dut1'].boot_prompt,20)
  if @equipment['dut1'].timeout?
    invalidate_mmc(1)
    invalidate_mmc(0)
  end
  @equipment['dut1'].disconnect()
  boot_to_bootloader()
  status =  uboot_sanity_test()
  restore_mmc(1)
  restore_mmc(0)
  puts "turn ON USB Switch !!!!!!!!!" 
  @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
  return status 
end 

# Function does configuration and booting to boot loader.
# Input parameters: None 
# Return Parameter: None. 

def boot_to_bootloader()
  @translated_boot_params['dut'].set_bootloader(@translated_boot_params) if !@equipment['dut1'].boot_loader
  @translated_boot_params['dut'].boot_to_bootloader @translated_boot_params
  @equipment['dut1'].connect({'type'=>'serial'}) if !@equipment['dut1'].target.serial
  @equipment['dut1'].send_cmd("",@equipment['dut1'].boot_prompt, 2)
  raise 'Bootloader was not loaded properly. Failed to get bootloader prompt' if @equipment['dut1'].timeout?
end 

# Function does boot the dut from USB(RNDIS).
# Input parameters: None 
# Return Parameter: pass or fail.  

def usb_boot()
  puts "USB BOOTING .........."
  init_dhcp()
  invalidate_mmc(1)
  invalidate_mmc(0) 
  regexp = /cccccc/i
  reboot_dut(regexp)
  #refressh dhcp because it is taking so long.
  #restarting dhcp to early is not initiating bootp
  sleep 5
  #refressh dhcp because it is taking so long.
  restart_dhcp()
  regexp = /BOOTP\s+broadcast/i
  @equipment['dut1'].wait_for(regexp,250)
  puts "BOOTP sent ..."
  #refresh dhcp 
  restart_dhcp()
  regexp = /Bytes\s+transferred/i
  @equipment['dut1'].wait_for(regexp,200)
  puts "Image loaded"
  #Sleep for image loading time
  sleep 5
  status = uboot_sanity_test()
  restore_mmc(1)
  restore_mmc(0)
  return status 
end 



# Function does boot the dut from SD.
# Input parameters: None 
# Return Parameter: pass or fail.  

def sd_boot()
  invalidate_mmc(1)
  regexp = /Hit\s+any\s+key\s+to\s+stop\s+autoboot/i
  reboot_dut(regexp)
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  status = uboot_sanity_test()
  restore_mmc(1)
  return status
end 

# Function does boot the dut from EMMC.
# Input parameters: None 
# Return Parameter: pass or fail.  

def emmc_boot()
  invalidate_mmc(0)
  regexp = /Hit\s+any\s+key\s+to\s+stop\s+autoboot/i 
  reboot_dut(regexp)
  @equipment['dut1'].send_cmd("", @equipment['dut1'].boot_prompt, 2)
  status = uboot_sanity_test()
  restore_mmc(0)
  return status 
end 

# Function does MLO loading from the network.
# Input parameters: None 
# Return Parameter: translated_params.  

def get_image
  params={}
  params['primary_bootloader_MLO'] = @test_params.instance_variable_defined?(:@primary_bootloader_MLO) ? @test_params.primary_bootloader_MLO : ''
  params['primary_bootloader_MLO_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_mlo_dev) ? @test_params.params_chan.primary_bootloader_mlo_dev[0] : ''
  params['primary_bootloader_SPL'] = @test_params.instance_variable_defined?(:@primary_bootloader_SPL) ? @test_params.primary_bootloader_SPL : ''
  params['primary_bootloader_SPL_dev'] = @test_params.params_chan.instance_variable_defined?(:@primary_bootloader_spl_dev) ? @test_params.params_chan.primary_bootloader_spl_dev[0] : ''                               
  translated_params = setup_host_side(params)
  return translated_params
end 

# Function erases emmc
# Input parameters: part (partition), block (starting block), count  
# Return Parameter: None.  

def erase_emmc_device(part,blocks, count) 
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


def dhcp_spl_config
  dhcp_spl_config  = """
#OpenTest: Boot images spl loading block

## Match the ROM and U-Boot SPL strings for am335x
if substring (option vendor-class-identifier, 0, 10) = \"DM814x ROM\" {
  filename \"spl_usb/u-boot-spl.bin\"; #DM814x
} elsif substring (option vendor-class-identifier, 0, 10) = \"AM335x ROM\" {
  filename \"spl_usb/u-boot-spl.bin\"; #beagleboneblack,am335x-evm
} elsif substring (option vendor-class-identifier, 0, 17) = \"AM335x U-Boot SPL\" {
  filename \"spl_usb/u-boot.img\"; #uboot_image
} else {
  filename \"spl_usb/uImage-3.2.0+\";
}

allow bootp;
subnet 192.168.0.0 netmask 255.255.255.0 {
}

subnet 192.168.122.0 netmask 255.255.255.0 {
}

subnet 192.168.1.0 netmask 255.255.255.0 {
  max-lease-time 120;
  range dynamic-bootp 192.168.1.2 192.168.1.10;
}

subnet 192.168.2.0 netmask 255.255.255.0 {
  max-lease-time 120;
  range dynamic-bootp 192.168.2.2 192.168.2.10;
}
 """     
return dhcp_spl_config 
end 

