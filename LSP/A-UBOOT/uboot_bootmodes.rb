# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/Platform_Specific_VarNames'
# Server-Side Test script implementation for LSP releases
   
include PlatformSpecificVarNames


def setup
	@equipment['dut1'].set_api('psp')
	connect_serial('dut1')
end

def run
	boot_params = { 
		'tester_from_cli'  => @tester.downcase,
		'target_from_db'   => @test_params.target.downcase,
		'platform_from_db' => @test_params.platform.downcase,
		'image_path' 		 => @test_params.kernel}
	#Check if DUT is already at boot_prompt
	@equipment['dut1'].send_cmd("\n", @equipment['dut1'].boot_prompt,1)
	#If DUT is not at boot_prompt do reboot with power_controller or soft reboot
	@equipment['dut1'].boot_to_bootloader(@power_handler) if @equipment['dut1'].timeout?
	
	cmds = @test_params.params_chan.instance_variable_get("@#{'cmd'}").to_s
	case  
		when cmds.match(/nfsboot/) 
			boot_from_nfs(boot_params)
		when cmds.match(/mmcboot/) 
			boot_from_mmc(boot_params)
		when cmds.match(/nandboot/) 
			boot_from_nand(boot_params)
		when cmds.match(/ramdiskboot/) 
			boot_from_ramdisk(boot_params)
		else
			puts "#{cmds} Unsupported bootmode\n"
	end
end


def boot_from_nfs(params)
	tester_from_cli = params['tester_from_cli']
	target_from_db = params['target_from_db']
	platform_from_db = params['platform_from_db']
	image_path = params['image_path']
	
	tmp_path = File.join(tester_from_cli.downcase.strip,target_from_db.downcase.strip,platform_from_db.downcase.strip)
	if image_path != nil && File.exists?(image_path) && @equipment['dut1'].get_image(image_path, @equipment['server1'], tmp_path) then
		puts "uImage copied to  #{tmp_path}"
		bootfile_path = File.join(tmp_path,File.basename(image_path))
	else
		raise "image #{image_path} does not exist, unable to copy"
	end
	
	command = "setenv serverip #{@equipment['server1'].telnet_ip}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
         command = "setenv bootfile #{bootfile_path}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv serverip #{@equipment['server1'].telnet_ip}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv nfspath #{@equipment['dut1'].nfs_root_path}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootargs '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'bootargs')}'"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootcmd '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'bootcmd')}'"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "boot"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].login_prompt, 120)
	command = "root"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
    if response.include?('@')
		set_result(FrameworkConstants::Result[:pass], "Test Pass.")	
    else
		set_result(FrameworkConstants::Result[:fail], "Test Failed.")
    end
end

def boot_from_mmc(params)
	command = "setenv bootargs #{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'mmcbootargs')}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
         command = "setenv bootfile uImage"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "mmc init"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,5)
	command = "setenv bootcmd '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'mmcbootcmd')}'"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "boot"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].login_prompt,120)
	command = "root"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	response = @equipment['dut1'].response
    if response.include?('@')
		set_result(FrameworkConstants::Result[:pass], "Test Pass.")	
    else
		set_result(FrameworkConstants::Result[:fail], "Test Failed.")
    end
end

def boot_from_nand(params)
	tester_from_cli = params['tester_from_cli']
	target_from_db = params['target_from_db']
	platform_from_db = params['platform_from_db']
	image_path = params['image_path']
	
	tmp_path = File.join(tester_from_cli.downcase.strip,target_from_db.downcase.strip,platform_from_db.downcase.strip)
	if image_path != nil && File.exists?(image_path) && @equipment['dut1'].get_image(image_path, @equipment['server1'], tmp_path) then
		puts "uImage copied to  #{tmp_path}"
		bootfile_path = File.join(tmp_path,File.basename(image_path))
	else
		raise "image #{image_path} does not exist, unable to copy"
	end
	command = "setenv serverip #{@equipment['server1'].telnet_ip}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootfile #{bootfile_path}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'downloaduimage')}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,20)
	response = @equipment['dut1'].response
	if response.include?('File not found')
		puts "Check bootfile name"
		set_result(FrameworkConstants::Result[:fail], "Test Failed.")
		return
	else	
		command = "#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'nanderaseforuimage')}"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,60)
		command = "#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'nandwriteforuimage')}"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,60)
		
		
		command = "setenv bootargs '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'bootargs')}'"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,120)
		command = "setenv bootcmd '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'nandbootcmd')}'"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
		command = "boot"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].login_prompt,120)
		command = "root"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
		response = @equipment['dut1'].response
		if response.include?('@')
			set_result(FrameworkConstants::Result[:pass], "Test Pass.")	
		else
			set_result(FrameworkConstants::Result[:fail], "Test Failed.")
		end
	end	
end

def boot_from_ramdisk(params)
	tester_from_cli = params['tester_from_cli']
	target_from_db = params['target_from_db']
	platform_from_db = params['platform_from_db']
	image_path = params['image_path']
	rd_path = @test_params.ramdisk
	tmp_path = File.join(tester_from_cli.downcase.strip,target_from_db.downcase.strip,platform_from_db.downcase.strip)
	if image_path != nil && File.exists?(image_path) && @equipment['dut1'].get_image(image_path, @equipment['server1'], tmp_path) then
		puts "uImage copied to  #{tmp_path}"
		bootfile_path = File.join(tmp_path,File.basename(image_path))
	else
		raise "image #{image_path} does not exist, unable to copy"
	end
	if rd_path != nil && File.exists?(rd_path) && @equipment['dut1'].get_image(rd_path, @equipment['server1'], tmp_path) then
		puts "uImage copied to  #{tmp_path}"
		ramdisk_img_path = File.join(tmp_path,File.basename(rd_path))
	else
		raise "Ramdisk image #{rd_path} does not exist, unable to copy"
	end
	command = "setenv serverip #{@equipment['server1'].telnet_ip}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootfile #{bootfile_path}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv ramdiskimage #{ramdisk_img_path}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootargs #{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'rambootargs')}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "setenv bootcmd '#{PlatformSpecificVarNames.translate_var_name(@test_params.platform,'rambootcmd')}'"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].boot_prompt,1)
	command = "boot"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].login_prompt,120)
	response = @equipment['dut1'].response
	command = "root"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
	if response.include?('@')
		set_result(FrameworkConstants::Result[:pass], "Test Pass.")	
	else
		set_result(FrameworkConstants::Result[:fail], "Test Failed.")
	end
end

def clean
end

def connect_serial(equipment)
      this_equipment = @equipment["#{equipment}"]
      puts "You are serially connecting to #{equipment}"
      if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
        this_equipment.connect({'type'=>'serial'})
      elsif !this_equipment.target.serial
        raise "You need Serial port connectivity to #{equipment}. Please check your bench file" 
      end
end
