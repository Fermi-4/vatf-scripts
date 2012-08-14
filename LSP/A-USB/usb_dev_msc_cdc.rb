# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require 'net/telnet'
# Default Server-Side Test script implementation for LSP releases


#################################################################################################################################################


include LspTestScript
def setup

#	super
	self.as(LspTestScript).setup

end


def run

	$result = 0

	cmds = @test_params.params_chan.instance_variable_get("@#{'cmd'}").to_s
	$cmd = cmds

	case  
		when cmds.match(/usb_dev_msc/) 
			usb_dev_msc()
		when cmds.match(/usb_dev_cdc/) 
			usb_dev_cdc()
		else
			$result = 1
			puts "#{cmds} does not match any case\n"
	end

	if $result == 0
		set_result(FrameworkConstants::Result[:pass], "Testcase Result is PASS.")	
		else
		set_result(FrameworkConstants::Result[:fail], "Testcase Result is FAIL.")
		command = "modprobe -r g_ether"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
		command = "modprobe -r g_file_storage"
		@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	end	

end

def clean
  self.as(LspTestScript).clean
end


##################################################################################################################################################



#MSC test
def usb_dev_msc()

	@equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string1.txt"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string1.txt"', @equipment['server2'].prompt , 30)

	command = "depmod -a"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)

	system ("sleep 1")


	command = "modprobe -l"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
        if response.include?('g_file_storage.ko')
		puts "g_file_storage USB Module is available"
	else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "g_file_storage.ko module is not available.")	
		return 		
        end


	command = "dmesg -c"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,2)

	system ("sleep 2")

def create_share_memory(command, response_pattern, next_command, timeout)

                        @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt, timeout)
                        response = @equipment['dut1'].response
                        if response.include?("#{response_pattern}")
                        return next_command
                        else
                                $result = 1
                                set_result(FrameworkConstants::Result[:fail], "#{command} command could not execute")
                        return
                        end
end

#	Insert the msc gadget module
	
	case 
		when $cmd.match(/_msc_mmc/)
			
			command = "umount /media/mmcblk0p1"
			@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)			
			command = "modprobe g_file_storage file=/dev/mmcblk0p1 stall=0 removable=1"
		
		when $cmd.match(/_msc_usb/)

			command = "umount /media/sda1"
			@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
			command = "modprobe g_file_storage file=/dev/sda1 stall=0 removable=1"

		when $cmd.match(/_msc_slave/)

			command = create_share_memory("dd if=/dev/zero of=/dev/shm/disk bs=1M count=52", "records", "fdisk /dev/shm/disk", 10)
                        command = create_share_memory(command, "m for help", "x", 1)
                        command = create_share_memory(command, "Expert command", "b", 1)
                        command = create_share_memory(command, "Partition", "1", 1)
                        command = create_share_memory(command, "You must set cylinders", "c", 1)
                        command = create_share_memory(command, "Number of cylinders", "1-1047000", 1)
                        command = create_share_memory(command, "Expert command", "w", 1)
                        command = create_share_memory(command, "Syncing disks", "mkfs.vfat /dev/shm/disk", 10)

			@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
			
			command = "modprobe g_file_storage file=/dev/shm/disk stall=0 removable=1"


		else
			$result = 1
			puts "#{$cmd} does not match any case\n"
	end

	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
	if response.include?('Error')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "g_file_storage.ko insertion fialed.")	
		return 		
       end

	system ("sleep 20")

	@equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string2.txt"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string2.txt"', @equipment['server2'].prompt , 30)
	mscdev= find_newdevice()
	mscmount= find_newmedia()
	puts "mscdev =#{mscdev}"
	puts "mscmount =#{mscmount}"

	if mscdev == mscmount then

		puts "Host does not detect any USB device"
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "Testcase Result is FAIL.")
		return
	
	end

	@equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
	mountfolder = 'test'
	@equipment['server2'].send_sudo_cmd("mkdir -p /media/#{mountfolder}", @equipment['server2'].prompt , 30)
	mscmount = "/media/#{mountfolder}"
	@equipment['server2'].send_sudo_cmd("mount #{mscdev} #{mscmount}", @equipment['server2'].prompt , 30)



	MSC_Format_Device("#{mscdev}","#{mscmount}")
case
	when $cmd.match(/_msc_slave/)	
		MSC_Mount_Device("#{mscdev}","#{mscmount}")
		MSC_Raw_Write("#{mscmount}","50")
		
		MSC_Mount_Device("#{mscdev}","#{mscmount}")  
		MSC_Raw_Read("#{mscmount}","50")

	else
	
	MSC_Mount_Device("#{mscdev}","#{mscmount}")
	MSC_Raw_Write("#{mscmount}","100")


	MSC_Mount_Device("#{mscdev}","#{mscmount}")  
	MSC_Raw_Read("#{mscmount}","100")

	MSC_Mount_Device("#{mscdev}","#{mscmount}")
	MSC_Raw_Write("#{mscmount}", "250")


	MSC_Mount_Device("#{mscdev}","#{mscmount}")  
	MSC_Raw_Read("#{mscmount}", "250")

	MSC_Mount_Device("#{mscdev}","#{mscmount}")
	MSC_Raw_Write("#{mscmount}", "500")


	MSC_Mount_Device("#{mscdev}","#{mscmount}")  
	MSC_Raw_Read("#{mscmount}", "500")

end

	# Remove the msc gadget module
	
	system ("sleep 10")
	command = "modprobe -r g_file_storage"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)

	@equipment['server2'].send_sudo_cmd("rm -rf  dev_string1.txt", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("rm -rf  dev_string2.txt", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("rm -rf  media_string1.txt", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("rm -rf  media_string2.txt", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("rm -rf /media/test", @equipment['server2'].prompt , 30)
end



#CDC test
def usb_dev_cdc()

	command = "depmod -a"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)

	system ("sleep 1")


	command = "modprobe -l"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
        if response.include?('g_ether.ko')
		puts "g_ether USB Module is available"
	else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "g_ether.ko module is not available.")	
		return 		
        end


	command = "dmesg -c"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,2)

	system ("sleep 2")

	command = "modprobe g_ether"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
        if response.include?('not found')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "Module insertion is failed.")	
		return 		
        end

	command = "dmesg"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,4)
	response = @equipment['dut1'].response
       if response.include?('usb0')
		puts "g_ether moduel inserted succesfully"
		else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "g_ether module insertion fialed.")	
		return 		
        end
	

	system ("sleep 10")

	command ="ifconfig usb0 #{@equipment['dut1'].usb_ip} up"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	response = @equipment['dut1'].response
        if response.include?('No such device')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "DUT ip address is not assigned properlly.")	
		return 
        end



	system ("sleep  60")

	command ="bash -c 'ifconfig usb0 #{@equipment['server2'].usb_ip} up'"
	@equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 30)
	response = @equipment['server2'].response
        if response.include?('No such device')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "Linux system ip address is not assigned properlly.")	
		return 
        end

	system ("sleep 10")


	case

		when $cmd.match(/_cdc_ping/)

			#Ping test
			pingtest_cdc()


		when $cmd.match(/_cdc_iperf/)

			#iperf test
			iperftest_cdc()

		
		else
			$result = 1
			puts "#{$cmd} does not match any case\n"

	end

#	Remove the ethernet gadget module
	system ("sleep 5")
	command = "modprobe -r g_ether"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)


end



#ping test
def pingtest_cdc()
	packetsize = [64,4096,65500]
	packetsize.each { |psize| 
	
	#Ping from DUT to host

	command ="ping -c 2 #{@equipment['server2'].usb_ip} -s #{psize}"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,4)
	response = @equipment['dut1'].response
        if response.include?('bytes from')
		puts "Ping from DUT to host is successful "
		else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "Ping from DUT to host is failed.")	
		return 
        end

	#Ping from host to DUT

	command="ping -c 10 #{@equipment['dut1'].usb_ip} -s #{psize}"
	@equipment['server2'].send_cmd(command, @equipment['server2'].prompt,1)
	response = @equipment['server2'].response
        if response.include?('bytes from')
		puts "Ping from host to DUT is successful "
		else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "Ping from host to DUT is failed.")	
		return 
        end

	}
end



#iperf test
def iperftest_cdc()

#	iperf test from host to DUT
	windowsize = [8,16,32,64]
	windowsize.each { |wsize|

	command ="kill -9 $(pidof iperf)"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	command = "iperf -s &"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)
	command ="ps | grep iperf"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)
	response = @equipment['dut1'].response
	command ="ps"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)
	response = @equipment['dut1'].response
        if response.include?('iperf')
		puts "iperf application started succesfully"
		else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "iperf application initialisation failed.")	
		return 
	end


	command="iperf -c #{@equipment['dut1'].usb_ip} -w #{wsize}K -d -t 10"
	@equipment['server2'].send_cmd(command, @equipment['server2'].prompt,1)
	response = @equipment['server2'].response
        if response.include?('Connection refused')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "iperf application is not started on DUT.")	
		return 
       end
	
	system ("sleep 10")

	command ="kill -9 $(pidof iperf)"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
	system ("sleep 3")
	}

#	iperf test from DUT to host

	puts "iperf test from dut to host is going to start"
	windowsize = [8,16,32,64]
	windowsize.each { |wsize|

	system ("kill -9 $(pidof iperf)")
	system ("iperf -s &")
	system ("ps | grep iperf")
	system ("ps | grep iperf")

	command ="ps"
	@equipment['server2'].send_cmd(command, @equipment['server2'].prompt,3)
	response = @equipment['dut1'].response
        if response.include?('iperf')
		puts "iperf application started succesfully"
		else
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "iperf application initialisation failed.")	
		return 
	end

	command="iperf -c #{@equipment['server2'].usb_ip} -w #{wsize}K -d -t 10"
	@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,15)
	response = @equipment['dut1'].response
        if response.include?('Connection refused')
		$result = 1
		set_result(FrameworkConstants::Result[:fail], "iperf application is not started on host.")	
		return 
       end
	
	system ("sleep 5")

	system ("kill -9 $(pidof iperf)")
	system ("ps | grep iperf")

	}


end

#Finding /dev point
def find_newdevice()
	dev=''
	File.foreach("dev_string2.txt") do |line|
	if dev2=line.match( %r{/dev/\w+} ).to_s then
	if dev2 =~ %r{/dev/} then
	dev_found = 'true'
	File.foreach("dev_string1.txt") do |line|
   	if dev1=line.match( %r{/dev/\w+} ).to_s
	if dev1 =~ %r{/dev/} then
	if  dev2 == dev1 then
	dev_found = 'false'
	end
	end
	end
	end
	if dev_found == 'true' then
	dev = dev2
  	end
   	end
	end
	end
return dev
end 

#Finding /media mount point
def find_newmedia()
	media =''
	File.foreach("media_string2.txt") do |line|
	if media2=line.match( %r{/media/.+} ).to_s then
        if media2 =~ %r{/media/} then
        media_found = 'true'
        File.foreach("media_string1.txt") do |line|
        if media1=line.match( %r{/media/.+} ).to_s
	if media1 =~ %r{/media/} then
	if  media2 == media1 then
	media_found = 'false'
	end
	end
	end
	end
	if media_found == 'true' then
        media = media2
	end
	end
        end
	end
return media
end


# MSC Format device

def MSC_Format_Device(mscdev,mscmount)

	@equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
	

end


# Mount MSC device

def MSC_Mount_Device(mscdev, mscmount)

	@equipment['server2'].send_sudo_cmd("mount #{mscdev} #{mscmount}", @equipment['server2'].prompt , 30)
end



# MSC Raw write using dd command

def MSC_Raw_Write(mscmount, mbsize)

	@equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("time dd of=#{mscmount}/#{mbsize}mb if=/dev/zero bs=1M count=#{mbsize}", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
	system ("sleep 5")

end


# MSC Raw read using dd command

def MSC_Raw_Read(mscmount, mbsize)
	
	@equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("time dd if=#{mscmount}/#{mbsize}mb of=/dev/zero bs=1M count=#{mbsize}", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
	@equipment['server2'].send_sudo_cmd("sleep 5", @equipment['server2'].prompt , 30)
end
