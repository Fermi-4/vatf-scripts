require File.dirname(__FILE__)+'\usb_data_structures'
require File.dirname(__FILE__)+'\usb_host_systems'

include Bootscript, Boot
include System::Windows::Forms

USB_DEV_TEST_DIR = '/usb_slave_msc_test_dir/'

def setup
   host = get_current_host
   modules_dir = './'
   dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path}\\#{@tester}\\#{@test_params.target}\\#{@test_params.platform}"
   boot_params = {'dut' => @equipment['dut'], 'platform' => @test_params.platform, 'image_path' => @test_params.image_path['kernel'], 'tftp_path' => @equipment['server1'].tftp_path, 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' =>  dst_folder}
   boot_params["bootargs"] = @test_params.params_chan.bootargs[0].strip if @test_params.params_chan.instance_variable_defined?(:@bootargs)
   @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys() + @test_params.params_chan.bootargs[0]) : (get_keys()) 
	 boot_dut(boot_params) if Boot::boot_required?(@old_keys, @new_keys)
	backing_files = create_backing_files
	case @test_params.params_chan.backing_file_type[0].downcase.strip
		when 'file'
			prepare_read_only_file_partitions(backing_files)
		when 'device'
			prepare_read_only_device_partitions(backing_files)
	end
	#raise "Host does not support usb host controller specified for test" if !host.check_usb_host_controller({"host_controller_type" => @test_params.params_chan.host_controller[0].strip.downcase})
	@equipment['dut'].send_cmd("cd /#{@tester}/#{@test_params.target}/#{@test_params.platform}/bin/\n", /#{@equipment['dut'].prompt}/, 10)
	if !@test_params.params_chan.instance_variable_defined?(:@bootargs)
		param_string = ' file='+backing_files[0]
		ro_string = ' ro=1'
		1.upto(backing_files.length-1)do |idx| 
			param_string += ','+backing_files[idx]
			ro_string +=',1'
		end
		ro_string.gsub!('1','0') if @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true' 
		param_string += ro_string if @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'default'
		if @test_params.params_chan.usb_dev_removable[0].strip.downcase == 'true'
			param_string += ' removable=1'
		elsif @test_params.params_chan.usb_dev_removable[0].strip.downcase == 'false'
			param_string += ' removable=0'
		end
		param_string += ' vendor='+@test_params.params_chan.usb_dev_vendor[0].strip.downcase if @test_params.params_chan.usb_dev_vendor[0].strip.downcase != 'default'
		param_string += ' luns='+backing_files.length.to_s if @test_params.params_chan.usb_dev_luns[0].strip.downcase != 'default'
		param_string += ' transport='+@test_params.params_chan.usb_dev_transport[0].strip.downcase if @test_params.params_chan.usb_dev_transport[0].strip.downcase != 'default'
		param_string += ' protocol='+@test_params.params_chan.usb_dev_protocol[0].strip.downcase if @test_params.params_chan.usb_dev_protocol[0].strip.downcase != 'default'
		param_string += ' product='+@test_params.params_chan.usb_dev_product[0].strip.downcase if @test_params.params_chan.usb_dev_product[0].strip.downcase != 'default'
		param_string += ' release='+@test_params.params_chan.usb_dev_release[0].strip.downcase if @test_params.params_chan.usb_dev_release[0].strip.downcase != 'default'
		param_string += ' buflen='+@test_params.params_chan.usb_dev_buflen[0].strip.downcase if @test_params.params_chan.usb_dev_buflen[0].strip.downcase != 'default'
		if @test_params.params_chan.usb_dev_stall[0].strip.downcase == 'true'
			param_string += ' stall=1'
		elsif @test_params.params_chan.usb_dev_stall[0].strip.downcase == 'false'
			param_string += ' stall=0'
		end
		send_linux_command('insmod '+modules_dir+'musb_hdrc.ko')
		raise "Unable to insert musb_hdrc.ko module" if @equipment['dut'].timeout?
		send_linux_command('insmod '+modules_dir+'g_file_storage.ko '+param_string) 
		raise "Unable to insert g_file_storage.ko module" if @equipment['dut'].timeout?
	else
		0.upto(backing_files.length-1) do |lun_number|
			send_linux_command('echo '+backing_files[lun_number]+' > /sys/devices/platform/musb_hdrc/gadget/gadget-lun'+lun_number.to_s+'/file')
			raise "Unable to set bakcing file for lun #{lun_number}" if @equipment['dut'].timeout?
		end
	end
		rescue Exception => e
			if !@test_params.params_chan.instance_variable_defined?(:@bootargs)
				send_linux_command('rmmod '+modules_dir+'g_file_storage.ko')  
				send_linux_command('rmmod '+modules_dir+'musb_hdrc.ko')  
			end
			raise e
		
end

def run
    host = get_current_host
	test_result = FrameworkConstants::Result[:fail]
	result_comment = ''
	result_comment += check_module_info if !@test_params.params_chan.instance_variable_defined?(:@bootargs)
    usb_dev_connected = false
	host_dir = host.executable_path
	dev_drives = nil
	host_mount_points = nil
	dev_info = nil
	dev_luns = 1
	dev_luns = @test_params.params_chan.usb_dev_luns[0].to_i if @test_params.params_chan.usb_dev_luns[0] != 'default'
	usb_test_dir = USB_DEV_TEST_DIR
	device_file_name = 'usb_slave_msc_'+@test_params.params_chan.file_size[0].upcase.strip+'_test.dat'
	file_name_change_count = 0
	mnt_and_fmt_timeout = (720*@test_params.params_chan.backing_file_size[0].to_i/180).ceil
	@test_params.params_chan.test_sequences.each do |current_sequence|
	    actions_and_times = current_sequence.split('*')
		actions = actions_and_times[0]
		num_times = 1
		num_times = actions_and_times[1].to_i if actions_and_times[1]
		actions_array = actions.split('+')
		if actions_array[0].strip.downcase != 'connect' && !usb_dev_connected
			dev_drives = connect_device(host,dev_luns)
			host_mount_points = host.mount_usb_device({"dev_drives" => dev_drives, "host_mount_point" => @test_params.params_chan.host_mount_point[0], "timeout" => mnt_and_fmt_timeout, "format_flag" => @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'})
			if dev_drives.length > 0
				usb_dev_connected = true
			else
				result_comment = "connect operation failed no new drives where detected"
			end
		end
		num_times.times do |iter|
		    actions_array.each do |current_action|
				case current_action.strip.downcase
					when 'connect'
						first_sys = host.get_usb_system_string
						dev_drives = connect_device(host,dev_luns)
						host_mount_points = host.mount_usb_device({"dev_drives" => dev_drives, "host_mount_point" => @test_params.params_chan.host_mount_point[0], "timeout" => mnt_and_fmt_timeout, "format_flag" => @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'})
						second_sys = host.get_usb_system_string
						check_string = ''
						if dev_drives.length > 0
							usb_dev_connected = true
							sys_diff = get_string_diff(first_sys, second_sys)
							dev_info = get_device_descriptors(sys_diff)
							check_string = check_descriptors(dev_info)
							result_comment += actions+iter.to_s+":"+check_string+"\n" if check_string.strip != ''
						else
							result_comment = actions+iter.to_s+":connect operation failed no devices were detected\n"
						end
						if dev_drives.length > 0 && check_string != ''
							@results_html_file.add_paragraph("")
							res_table = @results_html_file.add_table([["ITER#{iter.to_s} DESCRIPTORS",{:bgcolor => "336600", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"30%"})
							dev_info.each do |desc_type, desc_array|
								@results_html_file.add_row_to_table(res_table, [[desc_type.capitalize+' Descriptors',{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
								desc_array.each do |descriptor|
									descriptor.instance_variables.each do |inst_var|
										@results_html_file.add_row_to_table(res_table,[inst_var,descriptor.instance_variable_get(inst_var).to_s]) if !(descriptor.instance_variable_get(inst_var).kind_of?(Array))
									end
								end
							end
						end
					when 'format'
						if dev_drives
							dev_drives.each do |current_drive| 
								host.unmount_usb_device({"dev_drives" => current_drive}) 
								result_comment += actions+iter.to_s+":format operation on #{current_drive.to_s}  was not successful\n" if (host.format_device({"dev_drive" => current_drive.to_s, "timeout" => mnt_and_fmt_timeout}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
								host.mount_usb_device({"dev_drives" => current_drive, "host_mount_point" => @test_params.params_chan.host_mount_point[0], "format_flag" => @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'})
							end
						end
					when 'read'
					    if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":read operation on #{current_drive.to_s}  was not successful\n" if !host.copy_file({"src_file" => current_drive.to_s+usb_test_dir+device_file_name, "dst_file" => host_dir+device_file_name, "f_size" => @test_params.params_chan.file_size[0]})
							end
						end
					when 'filechk'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":filechk operation on #{current_drive.to_s}  was not successful\n" if (host.file_check({"ref_file" => host_dir+'usb_slave_msc_'+@test_params.params_chan.file_size[0].upcase.strip+'_ref.dat', "test_file" => current_drive.to_s+usb_test_dir+device_file_name}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'write'
						if host_mount_points
							host_mount_points.each do |current_drive|
								host.make_dir({"dir_path" => current_drive.to_s+usb_test_dir}) if !host.dir_check({"dir_path" => current_drive.to_s+usb_test_dir})
								result_comment += actions+iter.to_s+":write operation on #{current_drive.to_s}  was not successful\n" if (host.copy_file({"src_file" => host_dir+'usb_slave_msc_'+@test_params.params_chan.file_size[0].upcase.strip+'_ref.dat', "dst_file" => current_drive.to_s+usb_test_dir+device_file_name, "f_size" => @test_params.params_chan.file_size[0]}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'read/write'
						if host_mount_points
							(host_mount_points.length/2).floor.times do |current_index|
								result_comment += actions+iter.to_s+":read/write operation from #{host_mount_points[current_index*2].to_s}  to #{host_mount_points[current_index*2+1].to_s} was not successful\n" if (host.copy_file({"src_file" => host_mount_points[current_index*2].to_s+usb_test_dir+device_file_name, "dst_file" => host_mount_points[current_index*2+1].to_s+usb_test_dir+device_file_name, "f_size" => @test_params.params_chan.file_size[0]}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'mkdir'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":mkdir operation on #{current_drive.to_s}  was not successful\n" if !host.make_dir({"dir_path" => current_drive.to_s+usb_test_dir}) && @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'
							end
						end
					when 'dirchk'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":dirchk operation on #{current_drive.to_s}  was not successful\n" if !host.dir_check({"dir_path" => current_drive.to_s+usb_test_dir})
							end
						end
					when 'rmdir'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":rmdir operation on #{current_drive.to_s}  was not successful\n" if (host.remove_dir({"dir_path" => current_drive.to_s+usb_test_dir}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'move'
						if host_mount_points
							file_name_change_count+=1
							new_file_name = device_file_name.sub(/_test.*\.dat$/,'_test_'+file_name_change_count.to_s+'.dat')
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":move operation on #{current_drive.to_s}  was not successful\n" if (host.move_file({"file_path" => current_drive.to_s+usb_test_dir+device_file_name, "new_file_path" => current_drive.to_s+usb_test_dir+new_file_name}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
							device_file_name = new_file_name if @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'
						end
					when 'rename'
						if host_mount_points
							file_name_change_count+=1
							new_file_name = device_file_name.sub(/_test.*\.dat$/,'_test_'+file_name_change_count.to_s+'.dat')
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":rename operation on #{current_drive.to_s}  was not successful\n" if (host.rename_file({"file_path" => current_drive.to_s+usb_test_dir+device_file_name, "new_file_name" => new_file_name}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
							device_file_name = new_file_name if @test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'
						end
					when 'defragment'
						if dev_drives
							dev_drives.each do |current_drive|
								result_comment += actions+iter.to_s+":defragment operation on #{current_drive.to_s}  was not successful\n" if (host.defrag_device({"dev_drive" => current_drive.to_s}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'delete'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":delete operation on #{current_drive.to_s}  was not successful\n" if (host.delete_file({"file_path" => current_drive.to_s+usb_test_dir+device_file_name}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'chkdsk'
						if dev_drives
							dev_drives.each do |current_drive|
								result_comment += actions+iter.to_s+":chkdsk operation on #{current_drive.to_s}  was not successful\n" if !host.check_disk({"dev_drive" => current_drive.to_s, "host_mount_point" => @test_params.params_chan.host_mount_point[0], "timeout" => [10,10*@test_params.params_chan.backing_file_size[0].to_i/180].max})
							end
						end
					when 'properties'
						if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":properties operation on #{current_drive.to_s}  was not successful\n" if (host.change_properties({"file_path" => current_drive.to_s+usb_test_dir+device_file_name}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'delete_all'
					    if host_mount_points
							host_mount_points.each do |current_drive|
								result_comment += actions+iter.to_s+":delete all operation on #{current_drive.to_s}  was not successful\n" if (host.remove_dir({"dir_path" => current_drive.to_s+'/*'}) != (@test_params.params_chan.usb_dev_read_only[0].strip.downcase != 'true'))
							end
						end
					when 'disconnect'
						first_sys = host.get_usb_system_string
						host.unmount_usb_device({"dev_drives" => dev_drives})
					    disconnect_device(host, dev_luns)
						second_sys = host.get_usb_system_string
						sys_diff = get_string_diff(second_sys, first_sys)
						dev_info2 = get_device_descriptors(sys_diff)
						result_comment += "Problems with disconnect operation" if dev_info && check_descriptors(dev_info, dev_info2).strip != ''
						usb_dev_connected = false
					else
						result_comment += actions+iter.to_s+':Unsupported '+ current_action + ' operation specified in test sequence'
				end
			end
			result_comment += actions+iter.to_s+":Number of partitions detected is not equal to number of LUNs/partitions specified\n" if dev_drives.length != dev_luns
		end
	end
	test_result = FrameworkConstants::Result[:pass] if result_comment == ''
	rescue Exception => e
		result_comment +=e.to_s
	ensure
		
		@equipment['usb_sw'].connect_port(0)
		sleep 15
		
=begin
		begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
			a = MessageBox.Show("Disconnect usb target from "+@test_params.params_chan.host_os[0].strip.to_s+" host") if usb_dev_connected
			a =nil
			rescue  Exception 
		end
=end
		
		set_result(test_result,result_comment.strip)
end

def clean
	if !@test_params.params_chan.instance_variable_defined?(:@bootargs)
		send_linux_command('rmmod g_file_storage.ko')  
		send_linux_command('rmmod musb_hdrc.ko')  
	end
end

private
def get_keys
  keys = @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s
  keys
end

def get_current_host
    case @test_params.params_chan.host_os[0].strip.downcase
		when /win.*/
			host = WinHost.new(@equipment[@test_params.params_chan.host_os[0].strip.downcase+'_host'])
		when /linux/
      @equipment[@test_params.params_chan.host_os[0].strip.downcase+'_host'].switch_to_sudo_super_user
			LinuxHost.new(@equipment[@test_params.params_chan.host_os[0].strip.downcase+'_host'])
		when /mac/
			nil #nil until mac host is implemented
		else
			nil
	end
end

def connect_device(host,dev_luns)
		host_drives1 = host.check_host_drives
=begin
		begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
			a = MessageBox.Show("Connect usb target to "+@test_params.params_chan.host_os[0].strip.to_s+" host")
			a = nil
			rescue  Exception
		end
=end
		
		puts " "
		puts "--------------- usb_slave_msc - run ---360a---------------"
		puts " "
		puts "Connecting the USB port to a Windows PC."
		puts " "
		puts "--------------- usb_slave_msc - run ---362b---------------"
		
		@equipment['usb_sw'].connect_port(1)
		sleep 15
		
		host_drives2 = []
		num_tries = 0
		
		while host_drives2.length - host_drives1.length < dev_luns && num_tries < 20
			sleep 15				# changed from 1 second to 15 seconds due to amount of time it took for the USB connection to come up - 05-22-2009
			host_drives2 = host.check_host_drives
			num_tries += 1
		end
		(host_drives2 - host_drives1)
end

def disconnect_device(host, dev_luns)
		host_drives1 = host.check_host_drives
=begin
		begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
			a = MessageBox.Show("Disconnect usb target from "+@test_params.params_chan.host_os[0].strip.to_s+" host")
			a =nil
			rescue  Exception 
    end	
=end

		puts " "
		puts "--------------- usb_slave_msc - run ---360a---------------"
		puts " "
		puts "Disconnecting the USB port from the Windows PC."
		puts " "
		puts "--------------- usb_slave_msc - run ---362b---------------"
		
		@equipment['usb_sw'].connect_port(0)
		sleep 15
		
		host_drives2 = []
		num_tries = 0
		
		while host_drives1.length - host_drives2.length < dev_luns && num_tries < 20
			sleep 1
			host_drives2 = host.check_host_drives
			num_tries += 1
		end
		
		puts num_tries
		(host_drives1 - host_drives2)
end

def create_backing_files
		dev_luns = 1
		dev_luns = @test_params.params_chan.usb_dev_luns[0].to_i if @test_params.params_chan.usb_dev_luns[0] != 'default'
		backing_files, reboot_flag = case @test_params.params_chan.backing_file_type[0].strip.downcase
									when 'device'
										create_device_partitions(dev_luns)
									when 'file'
										create_file_partitions(dev_luns)
								 end
		if reboot_flag
			send_create_partition_cmd('reboot',/.*MontaVista\(R\)\s*Linux\(R\).*login:/im,600)
			if @equipment['dut'].response.downcase.include?('login')
				#@equipment['dut'].send_cmd(@equipment['dut'].login.to_s, /(#{@equipment['dut'].telnet_login}.*Welcome\s+to\s+MontaVista.*#{@equipment['dut'].prompt})|(Password).*/im)
				@equipment['dut'].send_cmd(@equipment['dut'].login.to_s, /(#{@equipment['dut'].telnet_login}.*MontaVista.*#{@equipment['dut'].prompt})|(Password).*/im)
				if @equipment['dut'].response.downcase.include?('password')
					@equipment['dut'].send_cmd(@equipment['dut'].telnet_passwd.to_s, /#{@equipment['dut'].telnet_passwd}.*#{@equipment['dut'].prompt}/im)
				end
			end
			mount_device(false) if @test_params.params_chan.backing_file_type[0].strip.downcase == 'file'
		end
		
		backing_files
		rescue Exception => e
		@equipment['dut'].send_cmd('q', /.*/m)
		raise
end

def create_device_partitions(dev_luns)
	device = '/dev/'+@test_params.params_chan.usb_device[0].strip
	fdisk_def_regex = /.+Command\s*\(m\s*for\s*help\):/im
	@equipment['dut'].send_cmd('fdisk '+device,fdisk_def_regex)
	@equipment['dut'].send_cmd('p',/Disk.*#{device}.+#{fdisk_def_regex}/im)
	cylinders_info = @equipment['dut'].response.strip.scan(/\d+\s+heads,\s+\d+\s+sectors\/track,\s+(\d+)\s+cylinders\s+Units\s+=\s+cylinders\s+of\s+\d+\s+\*\s+\d+\s+=\s+(\d+)\s+bytes/im)
	current_partitions = @equipment['dut'].response.strip.scan(/#{device}p{0,1}(\d+)\s+(\d+)\s+(\d+)\s+[\d\+]+\s+(\w+)[^\r\n]+/)
	start_cylinder = 1 
	delete_partitions = current_partitions.length != dev_luns
	current_partitions.each do |part_info|
		if (part_info[2].to_i-part_info[1].to_i) != (@test_params.params_chan.backing_file_size[0].to_i * 10485760/cylinders_info[0][1].to_i).floor || part_info[3].strip.downcase != get_partition_type(@test_params.params_chan.host_os[0].downcase)
			delete_partitions = true
		end
	end
	
	if delete_partitions
		current_partitions.each do |part_info|	 
			@equipment['dut'].send_cmd('d',/(.*Partition\s+number\s+\(1-4\):)|(.*Command\s+\(m\s+for\s+help\):)/im)
			if @equipment['dut'].response.downcase.include?('partition number (1-4):')
				@equipment['dut'].send_cmd(part_info[0].strip,fdisk_def_regex)
			end
		end
	end
	
	if (cylinders_info[0][0].to_i - start_cylinder) * cylinders_info[0][1].to_i < dev_luns * @test_params.params_chan.backing_file_size[0].to_i * 10485760
		raise 'Not enough space available to create '+dev_luns.to_s+' partintions of size '+@test_params.params_chan.backing_file_size[0]
	end
	
	if delete_partitions
		1.upto(dev_luns) do |lun_number|
			send_create_partition_cmd('n', /p\s*primary\s*partition/i)
			send_create_partition_cmd('p', /(Partition\s*number.*:)|(Selected\s*partition\s*4)/i)
			send_create_partition_cmd(lun_number.to_s, /First\s*cylinder.*:/i) if !@equipment['dut'].response.downcase.include?('selected partition 4')
			last_cylinder = start_cylinder+(@test_params.params_chan.backing_file_size[0].to_i * 10485760/cylinders_info[0][1].to_i).floor
			send_create_partition_cmd(start_cylinder.to_s, /.+Last\s*cylinder\s*or\s*\+size\s*or\s*\+sizeM\s*or\s*\+sizeK.*:/im)
			send_create_partition_cmd(last_cylinder.to_s, fdisk_def_regex)
			start_cylinder = last_cylinder+1
			send_create_partition_cmd('t', /(.*Partition\s*number.*:)|(.*Hex\s+code\s+\(type\s+L\s+to\s+list\s+codes\):)/im)
			if @equipment['dut'].response.downcase.include?('partition number (1-4):')
				send_create_partition_cmd(lun_number.to_s, /.*Hex\s+code\s+\(type\s+L\s+to\s+list\s+codes\):/im)
			end
			send_create_partition_cmd(get_partition_type(@test_params.params_chan.host_os[0].downcase), fdisk_def_regex)
		end
	end
	
	if delete_partitions
		send_create_partition_cmd('w', /The\s*partition\s*table\s*has\s*been\s*altered.*Syncing disks.*#{@equipment['dut'].prompt}/im,300)
	else
		@equipment['dut'].send_cmd('q', /#{@equipment['dut'].prompt}/im)
	end
	
	[[device],delete_partitions]
end

def create_file_partitions(dev_luns)
	@equipment['dut'].send_cmd('mount',/mount.*#{@equipment['dut'].prompt}/m)
	mounted_partitions = @equipment['dut'].response.scan(/(\S+)\s*on\s*#{@test_params.params_chan.dev_mount_point[0]}/)
	mounted_partitions.each{|part| send_linux_command('umount '+part[0])}
	mount_device
	backing_files = Array.new
	reboot_flag = false
	dev_luns.times do |lun_number|
	    base_backing_file_path = @test_params.params_chan.dev_mount_point[0]+'/'+@test_params.params_chan.base_backing_file_name[0]+'_'+@test_params.params_chan.usb_device[0]+'_lun'
		backing_file_path =  base_backing_file_path+lun_number.to_s
		@equipment['dut'].send_cmd('ls -l '+backing_file_path,/^[-\w]+\s*\d+\s*\w+\s*\w+\s*\d+\s*\w+\s*\d+\s*[\w:]+\s*#{backing_file_path}/m,2)
		backing_file_size = @equipment['dut'].response.scan(/^[-\w]+\s*\d+\s*\w+\s*\w+\s*(\d+)\s*\w+\s*\d+\s*[\w:]+\s*#{backing_file_path}/m)
		
		if backing_file_size.length < 1 || backing_file_size[0][0].to_i != (10485760*@test_params.params_chan.backing_file_size[0].to_i)
		    send_linux_command('rm -f '+base_backing_file_path+'*',50) if lun_number == 0 && backing_file_size.length > 0
			send_linux_command('dd bs=1M count=' + @test_params.params_chan.backing_file_size[0] + ' if=/dev/zero of='+ backing_file_path,4800*@test_params.params_chan.backing_file_size[0].to_i/180)
			raise 'Unable to create backing file ' if @equipment['dut'].timeout?
		end
		
		fdisk_def_regex = /Command\s*\(m\s*for\s*help\):/i
		send_create_partition_cmd('fdisk '+backing_file_path, fdisk_def_regex)		
		send_create_partition_cmd('p', fdisk_def_regex)
		partitions_info = @equipment['dut'].response.to_s.scan(/#{backing_file_path}\s*p\d+\s+\d+\s+\d+\s+\d+\s+(\w+)\s+[^\r\n]+/im)
		
		if partitions_info.length > 0 && partitions_info[0][0].strip.to_s.downcase != get_partition_type(@test_params.params_chan.host_os[0].downcase) 
		   send_create_partition_cmd('d', fdisk_def_regex)
		   send_create_partition_cmd('p', fdisk_def_regex)
		   partitions_info = @equipment['dut'].response.to_s.scan(/#{backing_file_path}\s*p\d+\s+\d+\s+\d+\s+\d+\s+(\w+)\s+[^\r\n]+/im)
		end
		
		if partitions_info.length < 1
		  sectors_per_track = 8   #desired number of sectors per track, defined by the user  
			bytes_per_track = sectors_per_track * 512 #512 bytes is the sector size used by g_file_storage 
			number_of_heads = [@test_params.params_chan.backing_file_size[0].to_i*10*1048576/bytes_per_track,255].min.to_i  #number of heads
			number_of_cylinders = (@test_params.params_chan.backing_file_size[0].to_i*10*1048576/(number_of_heads*bytes_per_track)).to_i
			expert_def_regex = /Expert\s*command\s*\(m\s*for\s*help\):/i
			send_create_partition_cmd('x', expert_def_regex)
			send_create_partition_cmd('s', /Number\s*of\s*sectors.*:/i)
			send_create_partition_cmd(sectors_per_track.to_s, /Warning:\s*setting\s*sector\s*offset\s*for\s*DOS\s*compatiblity.*Expert\s*command\s*\(m\s*for\s*help\):/im)
			send_create_partition_cmd('h', /Number\s*of\s*heads.*:/i)
			send_create_partition_cmd(number_of_heads.to_s, expert_def_regex)
			send_create_partition_cmd('c', /Number\s*of\s*cylinders.*:/)
			send_create_partition_cmd(number_of_cylinders.to_s, /(The\s*number\s*of\s*cylinders\s*for\s*this\s*disk\s*is\s*set\s*to\s*#{number_of_cylinders}.*)|(.*Expert\s*command\s*\(m\s*for\s*help\):)/im)
			send_create_partition_cmd('r', fdisk_def_regex)
			send_create_partition_cmd('n', /p\s*primary\s*partition/i)
			send_create_partition_cmd('p', /Partition\s*number.*:/i)
			send_create_partition_cmd('1', /First\s*cylinder.*:/i)
			send_create_partition_cmd('', /Using\s*default\s*value\s*1.*Last\s*cylinder\s*or\s*\+size\s*or\s*\+sizeM\s*or\s*\+sizeK.*:/im)
			send_create_partition_cmd('', /Using\s*default\s*value.*Command\s*\(m\s*for\s*help\):/im)
			reboot_flag = true
		end
		
		@equipment['dut'].send_cmd('p', fdisk_def_regex)
		partitions_info = @equipment['dut'].response.to_s.scan(/#{backing_file_path}\s*p\d+\s+\d+\s+\d+\s+\d+\s+(\w+)\s+[^\r\n]+/im)
		
		if partitions_info[0][0].strip.to_s.downcase != get_partition_type(@test_params.params_chan.host_os[0].downcase)
			send_create_partition_cmd('t', /Selected\s*partition\s*1.*Hex\s*code\s*\(type\s*L\s*to\s*list\s*codes\):/im)
			send_create_partition_cmd(get_partition_type(@test_params.params_chan.host_os[0].downcase), /Changed\s*system\s*type\s*of\s*partition\s*\w+\s*to\s*\w+.*Command\s*\(m\s*for\s*help\):/im)
			reboot_flag = true
		end
		
		if reboot_flag
			send_create_partition_cmd('w', /The\s*partition\s*table\s*has\s*been\s*altered.*Syncing disks.*#{@equipment['dut'].prompt}/im,300)
		else
			@equipment['dut'].send_cmd('q', /#{@equipment['dut'].prompt}/im)
		end
		backing_files << backing_file_path
	end
    
	[backing_files, reboot_flag]

end

def mount_device(check_partition=true)
  if check_partition
		send_linux_command('e2fsck -n /dev/' + @test_params.params_chan.usb_device[0], 500)
		
		if @equipment['dut'].timeout?
			send_linux_command('mkfs -t ext3 /dev/' + @test_params.params_chan.usb_device[0],500)
			raise 'Unable to create file system in device' if @equipment['dut'].timeout?
		end 
	end
	
	send_linux_command( 'mount -t ext3 /dev/' + @test_params.params_chan.usb_device[0] + ' ' +@test_params.params_chan.dev_mount_point[0])
	
	if @equipment['dut'].timeout?
		send_linux_command('mkfs -t ext3 /dev/' + @test_params.params_chan.usb_device[0],500)
		send_linux_command('mount -t ext3 /dev/' + @test_params.params_chan.usb_device[0] + ' ' +@test_params.params_chan.dev_mount_point[0])
		raise 'Unable to create file system in device' if @equipment['dut'].timeout?
	end 
	
end

def prepare_read_only_device_partitions(partitioned_device)
	modules_dir = './'
	device_file_name = 'usb_slave_msc_'+@test_params.params_chan.file_size[0].upcase.strip+'_test.dat'
	
	if (@test_params.params_chan.usb_dev_read_only[0] == 'true')
		if @test_params.params_chan.host_os[0].downcase.include?('win')
			@equipment['dut'].send_cmd('fdisk -lu '+partitioned_device.to_s,/fdisk -lu.+#{@equipment['dut'].prompt}/im)
			cylinders_info = @equipment['dut'].response.strip.scan(/\d+\s+heads,\s+\d+\s+sectors\/track,\s+(\d+)\s+cylinders.+Units\s+=\s+sectors\s+of\s+\d+\s+\*\s+\d+\s+=\s+(\d+)\s+bytes/im)
			current_partitions = @equipment['dut'].response.strip.scan(/(#{partitioned_device.to_s}p\d+)\s+(\d+)\s+(\d+)\s+[\d\+]+\s+(\w+)[^\r\n]+/im)
			current_partitions.each do |part_info|
				send_linux_command('mkfs -t vfat '+part_info[0],500)
				send_linux_command('ls /mnt/loop',2)
				send_linux_command('mkdir /mnt/loop') if @equipment['dut'].timeout?
				send_linux_command('mount -t vfat '+part_info[0]+' /mnt/loop')
				send_linux_command('rm -rf /mnt/loop/*')
				send_linux_command('mkdir /mnt/loop'+USB_DEV_TEST_DIR)
				send_linux_command('cat  /proc/interrupts > /mnt/loop'+USB_DEV_TEST_DIR+device_file_name)
				send_linux_command('umount '+part_info[0])
			end
		end
	end
end

def create_loop_device

	puts " "
	puts "--------------- usb_slave_msc - create_loop_device ---588a---------------"

	modules_dir = './'
	send_linux_command('modinfo loop')
	
	if @equipment['dut'].timeout?
		@equipment['dut'].send_cmd('insmod '+modules_dir+'loop.ko',/insmod.+#{@equipment['dut'].prompt}/im)
		raise "Error 1: Unable to insert loop.ko kernel module partition is not ready for read_only operation" if !@equipment['dut'].response.match(/(.*loop:\s+loaded.+)|(.+File exists.*)/im)
	end
	
	puts "--------------- usb_slave_msc - create_loop_device ---598b---------------"
	send_linux_command('ls /dev/loop0')
	
	if @equipment['dut'].timeout?
		send_linux_command('mknod /dev/loop0 b 7 0')
		raise "Error 2:  Unable to create loop device for read only partition" if @equipment['dut'].timeout?
	end

	puts "--------------- usb_slave_msc - create_loop_device ---606b---------------"

end

def prepare_read_only_file_partitions(partitions_array)
	#modules_dir = @equipment['dut'].executable_path.sub(/(\/|\\)$/,'')+'/'

	@equipment['dut'].send_cmd("cd /#{@tester}/#{@test_params.target.downcase}/#{@test_params.platform.downcase}/bin/\n", /#{@equipment['dut'].prompt}/, 10)

  modules_dir = './'
	device_file_name = 'usb_slave_msc_'+@test_params.params_chan.file_size[0].upcase.strip+'_test.dat'
	partitions_array.each_index do |idx|
		
		if (idx < @test_params.params_chan.usb_dev_read_only.length && @test_params.params_chan.usb_dev_read_only[idx] == 'true') || (@test_params.params_chan.usb_dev_read_only.length == 1 && @test_params.params_chan.usb_dev_read_only[0] == 'true')
			create_loop_device
			if @test_params.params_chan.host_os[0].downcase.include?('win')
				begin
					@equipment['dut'].send_cmd('fdisk -lu '+partitions_array[idx],/#{partitions_array[idx]}\s*p\d+\s*\d+\s*\d+\s*\d+\s*\w+\s*\w+.*/im)
					raise "Problems found while obtaining partiton information" if @equipment['dut'].timeout?
					partition_offset = @equipment['dut'].response.scan(/#{partitions_array[idx]}\s*p\s*\d+\s*(\d+)\s*\d+\s*\d+\s*\w+\s*\w+.*/)[0][0].to_i * 512
					send_linux_command('losetup -o '+partition_offset.to_s+' /dev/loop0 '+partitions_array[idx])
					send_linux_command('ls /mnt/loop',2)
					send_linux_command('mkdir /mnt/loop') if @equipment['dut'].timeout?
					send_linux_command('mount -t vfat /dev/loop0 /mnt/loop')
					send_linux_command('rm -rf /mnt/loop/*')
					send_linux_command('mkdir /mnt/loop'+USB_DEV_TEST_DIR)
					send_linux_command('cat  /proc/interrupts > /mnt/loop'+USB_DEV_TEST_DIR+device_file_name)
					ensure
						send_linux_command('umount /dev/loop0')
						send_linux_command('losetup -d /dev/loop0')
				end
			end
		end
	end
	ensure
		send_linux_command('rmmod '+modules_dir+'loop.ko')
end

def send_create_partition_cmd(command,expected_reg_ex,timeout=10)
	@equipment['dut'].send_cmd(command, expected_reg_ex, timeout)
	raise 'Problem creating partition in backing file' if @equipment['dut'].timeout?
end

def get_string_diff(first_string, second_string)
  first_array = first_string.strip.split(/[\n\r]+/)
  sec_array = second_string.strip.split(/[\n\r]+/)
  ref_array = first_array
  second_array = sec_array 
  if sec_array.length < first_array.length
	ref_array = sec_array
	second_array = first_array 
  end

  bottom_up = 0
  top_down = second_array.length
  length_diff = second_array.length-ref_array.length
  (second_array.length-1).downto(0) do |idx|
	
	if ref_array[idx-length_diff] != second_array[idx]	
	    bottom_up = idx
		break
	end
  end
  
	0.upto(second_array.length-1) do |idx|
	
	if ref_array[idx] != second_array[idx]	
	    top_down = idx
		break
	end
  end
  second_array[top_down..bottom_up]
end

def get_usb_descriptor_field(info_string,field_name = nil)
	field_value = info_string.strip.split(/ +/)
	
	if field_name
		if field_value[0].downcase.eql?(field_name.strip.downcase)
			field_value[1].strip
		else
			raise 'usb descriptor field ' + field_name + ' not found in ' + info_string.strip
		end
	else
		[field_value[0],field_value[1].strip]
	end
end

def get_device_descriptors(port_string)
	offset = 0
    result = {	"device" => Array.new,
				"config" => Array.new,
				"interface" => Array.new,
				"string" => Array.new,
				"endpoint" => Array.new,
				"device_qualifier" => Array.new,
				"other_speed_config" => Array.new,
				"class_specific" => Array.new
	}
	
	if port_string.kind_of?(Array)
		info_lines = port_string
	else
		info_lines = port_string.strip.split(/[\r\n]+/)
	end
	
	descriptor_table = USBDataStructures.get_descriptors_table

	while info_lines[offset] && !info_lines[offset].downcase.include?('blength')
		offset+=1
	end
	
	puts "--------------------------  usb_slave_msc - get_device_descriptors --- 700 --------------------------------------"
	
	while offset < info_lines.length
		if offset < info_lines.length
			desc_length = get_usb_descriptor_field(info_lines[offset], 'bLength')
			desc_type = get_usb_descriptor_field(info_lines[offset+1], 'bDescriptorType').hex
			offset+=1
			
			if descriptor_table.has_key?(desc_type)
				current_descriptor = USBDataStructures.const_get(descriptor_table[desc_type]).new
			else
				current_descriptor = USBDataStructures.const_get(descriptor_table[desc_type]).new(desc_type)
			end
			
			current_descriptor.length = desc_length
			
			while info_lines[offset] && !info_lines[offset].downcase.include?('blength')
				if info_lines[offset].match(/\s+[A-Za-z]+\d*\s*\d.*/)
					field, value = get_usb_descriptor_field(info_lines[offset])
					current_descriptor.set_descriptor_field(field,value)
				end
				offset+=1
			end
				
			case desc_type
				when 1
					result['device'] << current_descriptor
				when 2
					result['config'] << current_descriptor
				when 3
					result['string'] << current_descriptor
				when 4
					result['interface'] << current_descriptor
				when 5
					result['endpoint'] << current_descriptor
				when 6
					result['device_qualifier'] << current_descriptor
				when 7	
					result['other_speed_config'] << current_descriptor
				else
				    result['class_specific'] << current_descriptor
			end
		end
  end
		
	puts "--------------------------  usb_slave_msc - get_device_descriptors --- 745 --------------------------------------"
	
	result
end

def check_descriptors(dev_descriptors, ref_descriptors = nil)
	
	puts "--------------------------  usb_slave_msc - check_descriptors --- 753 --------------------------------------"

	result_comment = ''
	if !ref_descriptors
		ref_descriptors = {	"device" => Array.new,
							"config" => Array.new,
							"interface" => Array.new,
							"string" => Array.new,
							"endpoint" => Array.new,
							"device_qualifier" => Array.new,
							"other_speed_config" => Array.new,
							"class_specific" => Array.new
		}
		#Well known Device Descriptor Fields
		ref_descriptors['device'][0] = USBDataStructures::DeviceDescriptor.new
		ref_descriptors['device'][0].length = /(12)|(18)$/	
		ref_descriptors['device'][0].set_descriptor_field('bcdUSB' , /((0200)|(2\.00))$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceClass' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceSubClass' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceProtocol' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bMaxPacketSize0' , /((40)|(64))$/)
		ref_descriptors['device'][0].set_descriptor_field('idVendor' , /#{@test_params.params_chan.usb_dev_vendor[0].downcase.strip.gsub(/^0x/,'')}$/)
		ref_descriptors['device'][0].set_descriptor_field('idVendor' , /(0x)*0525$/) if @test_params.params_chan.usb_dev_vendor[0].downcase.strip == 'default'
		ref_descriptors['device'][0].set_descriptor_field('idProduct' , /#{@test_params.params_chan.usb_dev_product[0].downcase.strip.gsub(/^0x/,'')}$/)
		ref_descriptors['device'][0].set_descriptor_field('idProduct' , /(0x)*a4a5$/i) if @test_params.params_chan.usb_dev_product[0].downcase.strip == 'default'
		ref_descriptors['device'][0].set_descriptor_field('bcdDevice' , /((#{@test_params.params_chan.usb_dev_release[0].downcase.strip.gsub(/^0x/,'')})|(#{(@test_params.params_chan.usb_dev_release[0].downcase.strip.gsub(/^0x0/,'')).insert(1,'.')}))$/)
		ref_descriptors['device'][0].set_descriptor_field('bcdDevice' , /((0316)|(3\.16))$/) if @test_params.params_chan.usb_dev_release[0].downcase.strip == 'default'
		ref_descriptors['device'][0].set_descriptor_field('iManufacturer' , /0*1$/)
		ref_descriptors['device'][0].set_descriptor_field('iProduct' , /0*2$/)
		ref_descriptors['device'][0].set_descriptor_field('bNumConfigurations' , /0*1$/)
		
		puts "--------------------------  usb_slave_msc - check_descriptors --- 784 --------------------------------------"
		
		#Well known configuration descriptor Fields
		ref_descriptors['config'][0] = USBDataStructures::ConfigDescriptor.new
		ref_descriptors['config'][0].length = /0*9$/
		ref_descriptors['config'][0].set_descriptor_field('wTotalLength' , /((0020)|(32))$/)
		ref_descriptors['config'][0].set_descriptor_field('bNumInterfaces' , /0*1$/)
		
		puts "--------------------------  usb_slave_msc - check_descriptors --- 792 --------------------------------------"
		
		#Well known interface descriptors fields
		ref_descriptors['interface'][0] = USBDataStructures::InterfaceDescriptor.new
		ref_descriptors['interface'][0].length = /0*9$/
		ref_descriptors['interface'][0].set_descriptor_field('bNumEndpoints', /0*2$/)
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceClass', /0*8$/)
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceSubClass' , get_device_subclass(@test_params.params_chan.usb_dev_protocol[0]))
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceProtocol' , get_device_transport_protocol(@test_params.params_chan.usb_dev_transport[0]))
		
		puts "--------------------------  usb_slave_msc - check_descriptors --- 802 --------------------------------------"
		
		#Well known endpoint descriptor fields
		ref_descriptors['endpoint'][0] = USBDataStructures::InterfaceDescriptor.new
		ref_descriptors['endpoint'][0].length = /0*7$/
		ref_descriptors['endpoint'][0].set_descriptor_field('bmAttributes' , /0*2$/)
		ref_descriptors['endpoint'][0].set_descriptor_field('wMaxPacketSize' , /0200$/)
		ref_descriptors['endpoint'][1] = ref_descriptors['endpoint'][0]
	end

	puts "--------------------------  usb_slave_msc - check_descriptors --- 812 --------------------------------------"

	#Checking Device Descriptor
	result_comment += 'device detected had more than one device descriptor' if dev_descriptors['device'].length != 1
	result_comment += compare_descriptors(ref_descriptors['device'], dev_descriptors['device'], 'Device')
	result_comment += compare_descriptors(ref_descriptors['config'], dev_descriptors['config'], 'Configuration')
	dev_descriptors['config'].each do |config_descriptor|
		result_comment += 'device detected has wrong Configuration Attributes value' if (config_descriptor.bmAttributes.hex & 0x9F) != 0x80
	end

	puts "--------------------------  usb_slave_msc - check_descriptors --- 822 --------------------------------------"

	result_comment += compare_descriptors(ref_descriptors['interface'], dev_descriptors['interface'], 'Interface')
	result_comment += compare_descriptors(ref_descriptors['endpoint'], dev_descriptors['endpoint'], 'Endpoint')
	ep_sum = 0
	dev_descriptors['endpoint'].each do |ep_descriptor|
		ep_sum += ep_descriptor.bEndpointAddress.hex & 0x80
	end
	result_comment += 'device detected has wrong address in one of it\'s enpoints' if ep_sum != 0x80
	result_comment = result_comment.strip
end

def compare_descriptors(ref_descriptor_array, dev_descriptor_array, descriptor_type) 
    result_comment = ''
		puts "--------------------------  usb_slave_msc - compare_descriptors --- 836 --------------------------------------"

	ref_descriptor_array.each_index do |current_index|
		
		puts "--------------------------  usb_slave_msc - compare_descriptors --- 840 --------------------------------------"
		
		ref_descriptor_array[current_index].instance_variables.each do |dev_descriptor_field|
			
		puts "--------------------------  usb_slave_msc - compare_descriptors --- 844 --------------------------------------"
			
			if !dev_descriptor_field.include?("type") && !ref_descriptor_array[current_index].instance_variable_get(dev_descriptor_field).kind_of?(Array) && !(dev_descriptor_array[current_index].instance_variable_get(dev_descriptor_field).match(ref_descriptor_array[current_index].instance_variable_get(dev_descriptor_field)))
				puts "--------------------------  usb_slave_msc - compare_descriptors --- 847 --------------------------------------"
				result_comment += "device detected has wrong #{descriptor_type} descriptor value for #{dev_descriptor_field}\n"
				puts "--------------------------  usb_slave_msc - compare_descriptors --- 849 --------------------------------------"
			end
			
			puts "--------------------------  usb_slave_msc - compare_descriptors --- 851 --------------------------------------"
		end
			puts "--------------------------  usb_slave_msc - compare_descriptors --- 853 --------------------------------------"
	end
	
			puts "--------------------------  usb_slave_msc - compare_descriptors --- 856 --------------------------------------"
	
	puts result_comment
	
	result_comment
end
	
def get_device_subclass(usb_proto)
	case usb_proto.strip.downcase
		when 'scsi','default'
			/0*6$/
		when 'rbc'
			/0*1$/
		when /(atapi)|(8020)/
			/0*2$/
		when 'qic'
			/0*3$/
		when 'ufi'
			/0*4$/
		when '8070'
			/0*5$/
		else
			usb_proto
	end
end
	
def get_device_transport_protocol(usb_proto)
	case usb_proto.strip.downcase
		when 'bbb', 'default'
			/((50)|(80))$/
		when 'cb'
			/0+/
		when 'cbi'
			/0{0,1}1$/
		else
			usb_proto
	end
end

def check_module_info
    result = ''
	modules_dir = './'
	@equipment['dut'].send_cmd("cat /proc/modules",/g_file_storage\s*\d+\s*\d+.*Live.*/im)
	result += "cat /proc/modules failed\n" if @equipment['dut'].timeout?
	@equipment['dut'].send_cmd("modinfo -d #{modules_dir}g_file_storage.ko",/File-backed\s*Storage\s*Gadget.*/im)
	result += "modinfo -d failed\n" if @equipment['dut'].timeout?
	@equipment['dut'].send_cmd("modinfo -l #{modules_dir}g_file_storage.ko",/Dual\s*BSD\/GPL.*/im)
	result += "modinfo -l failed\n" if @equipment['dut'].timeout?
	@equipment['dut'].send_cmd("modinfo -a #{modules_dir}g_file_storage.ko",/Alan\s*Stern.*/im)
	result += "modinfo -a failed\n" if @equipment['dut'].timeout?
	@equipment['dut'].send_cmd("modinfo -p #{modules_dir}g_file_storage.ko",/buflen:.+release:.+product:.+vendor:.+transport:.+stall:.+removable:.+luns:.+ro:.+file:.+\#/im)
	result += "modinfo -p failed\n" if @equipment['dut'].timeout?
	result
end

def get_partition_type(host_type)
	case host_type.strip.downcase
		when /win.*/
			'b'
		when /linux.*/
			'83'
		when /mac.*/
			'a8'
	end
end

def send_linux_command(command, timeout = 20)
	@equipment['dut'].send_cmd(command,/#{command.slice(/^[^\s]+/)}.+#{@equipment['dut'].prompt}/im,timeout)
	@equipment['dut'].send_cmd("echo $?",/echo\s+\$\?\D*0.*#{@equipment['dut'].prompt}/im,1)
	@equipment['usb_sw'].connect_port(0)
end