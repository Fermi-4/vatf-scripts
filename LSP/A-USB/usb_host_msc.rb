# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'\usb_data_structures'
require File.dirname(__FILE__)+'\usb_host_systems'

#include Bootscript
include System::Windows::Forms
include LspTestScript

USB_DEV_TEST_DIR = '/usb_test/'

def setup
    @equipment['linux_host'].disconnect
		@@is_config_step_required = false
		
		puts " "
		puts "--------------- usb_host_msc - run ---16a---------------"
		puts " "
		puts "Disconnecting the USB port from the USB hub."
		
		@equipment['usb_sw'].connect_port(0)
		sleep 10
		
		puts " "
		puts "--------------- usb_host_msc - run ---24b---------------"
		
    super
end

def run
    @equipment['linux_host'].connect
    host = LinuxHost.new(@equipment['linux_host'])
    test_result = FrameworkConstants::Result[:fail]
    result_comment = ''
    usb_dev_connected = false
    dev_drives = Array.new
    host_mount_points = Array.new
    host_dir = host.executable_path
    dev_test_dir = USB_DEV_TEST_DIR
    device_file_name = Array.new
    dev_info = Array.new
    devices = @test_params.params_chan.usb_device[0].split('-')
    mnt_and_fmt_timeout = (1440*@test_params.params_chan.dev_file_size[0].to_i/180).ceil + 360 # Adding 360 seconds for USB Host case, where the whole HD is formated - 02-17-2009
    file_name_change_count = 0
    @test_params.params_chan.test_sequences.each do |current_sequence|
	  actions_and_times = current_sequence.split('*')
		actions = actions_and_times[0]
		num_times = 1
		num_times = actions_and_times[1].to_i if actions_and_times[1]
		actions_array = actions.split('+')
			
		if actions_array[0].strip.downcase != 'connect' && !usb_dev_connected
			# Connect even if test sequence does not have connect on it
				devices.each_index {|dev_index|
				this_dev_drives = connect_device(host,dev_index)
				
				if this_dev_drives.length > 0
					host_mount_points << host.mount_usb_device({"dev_drives" => this_dev_drives, "fs" =>  @test_params.params_chan.dev_fs[dev_index], "host_mount_point" => @test_params.params_chan.dev_mount_point[dev_index], "timeout" => mnt_and_fmt_timeout, "format_flag" => true})
					dev_drives << this_dev_drives
					usb_dev_connected = true
				else
					result_comment = "connect operation failed no new drives where detected"
				end
			}
		end
			
			num_times.times do |iter|
		    actions_array.each do |current_action|
					case current_action.strip.downcase
							when 'connect' 	# Connect USB devices to Host and add elements to dev_drives and host_mount_points arrays
                  devices.each_index {|dev_index|
				          first_sys = host.get_usb_system_string({"vendor"=>@test_params.params_chan.dev_vendor[dev_index]})
		              this_dev_drives = connect_device(host,dev_index)
		              check_string = ''
									
		              if this_dev_drives.length > 0
										host_mount_points << host.mount_usb_device({"dev_drives" => this_dev_drives, "fs" =>  @test_params.params_chan.dev_fs[dev_index], "host_mount_point" => @test_params.params_chan.dev_mount_point[dev_index], "timeout" => mnt_and_fmt_timeout, "format_flag" => true})
										dev_drives << this_dev_drives
										second_sys = host.get_usb_system_string({"vendor"=>@test_params.params_chan.dev_vendor[dev_index]})
		                usb_dev_connected = true
		                sys_diff = get_string_diff(first_sys,second_sys)
			              dev_info << get_device_descriptors(sys_diff)
			              check_string = check_descriptors(dev_index, dev_info[dev_index])
			              result_comment += actions+iter.to_s+":"+check_string+"\n" if check_string.strip != ''
		              else
			              result_comment = actions+iter.to_s+":connect operation failed no devices were detected\n"
		              end
											
		              if this_dev_drives.length > 0 && check_string != ''
										@results_html_file.add_paragraph("")
			              res_table = @results_html_file.add_table([["Device #{@test_params.params_chan.dev_description[dev_index]} ITER#{iter.to_s} DESCRIPTORS",{:bgcolor => "336600", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
											dev_info[dev_index].each do |desc_type, desc_array|
												@results_html_file.add_row_to_table(res_table, [[desc_type.capitalize+' Descriptors',{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
												desc_array.each do |descriptor|
													descriptor.instance_variables.each do |inst_var|
														@results_html_file.add_row_to_table(res_table,[inst_var,descriptor.instance_variable_get(inst_var).to_s]) if !(descriptor.instance_variable_get(inst_var).kind_of?(Array))
													end
												end
											end
		              end
			            }
							when 'format'	# Format (by calling mkfs) the USB device partition
                  
		              if dev_drives.length > 0
			              dev_drives.each_with_index do |dev, dev_index| 
                      dev.each do |current_drive|
						            host.unmount_usb_device({"dev_drives" => current_drive}) 
			                  result_comment += actions+iter.to_s+":format operation on #{current_drive.to_s}  was not successful\n" if !(host.format_device({"dev_drive" => current_drive.to_s, "fs" =>  @test_params.params_chan.dev_fs[dev_index], "timeout" => mnt_and_fmt_timeout}))
			                  host.mount_usb_device({"dev_drives" => current_drive, "fs" =>  @test_params.params_chan.dev_fs[dev_index], "host_mount_point" => @test_params.params_chan.dev_mount_point[dev_index]})
                      end
                    end
                  end
              when 'read'		# Read data from USB devices to Host
	                    if host_mount_points.length > 0
                        host_mount_points.each_with_index do |dev, dev_index|
													dev.each do |current_drive|
				                    result_comment += actions+iter.to_s+":read operation on #{current_drive.to_s}  was not successful\n" if !host.copy_file({"src_file" => current_drive.to_s+dev_test_dir+device_file_name[dev_index], "dst_file" => host_dir+device_file_name[dev_index], "f_size" => @test_params.params_chan.dev_file_size[dev_index]})
			                    end
												end
											end
	            when 'filechk'	# Check that data file in USB devices matches reference file in Host
											if host_mount_points.length > 0
												host_mount_points.each_with_index do |dev, dev_index|
													dev.each do |current_drive|
														result_comment += actions+iter.to_s+":filechk operation on #{current_drive.to_s}  was not successful\n" if !(host.file_check({"ref_file" => host_dir+device_file_name[dev_index].sub(/_test.*dat/,'_ref.dat'), "test_file" => current_drive.to_s+dev_test_dir+device_file_name[dev_index]}))
													end
												end
											end
	            when 'write'	# Write data from Host to USB devices
											if host_mount_points.length > 0
												host_mount_points.each_with_index do |dev, dev_index|
													device_file_name[dev_index] = 'usb_slave_msc_'+@test_params.params_chan.dev_file_size[dev_index].upcase.strip+'_test.dat'
													dev.each do |current_drive|
		                		    host.make_dir({"dir_path" => current_drive.to_s+dev_test_dir}) if !host.dir_check({"dir_path" => current_drive.to_s+dev_test_dir})
				                    result_comment += actions+iter.to_s+":write operation on #{current_drive.to_s}  was not successful\n" if !(host.copy_file({"src_file" => host_dir+device_file_name[dev_index].sub(/_test\.dat/,'_ref.dat'), "dst_file" => current_drive.to_s+dev_test_dir+device_file_name[dev_index], "f_size" => @test_params.params_chan.dev_file_size[dev_index]}))
													end
												end
											end
	            when 'read/write'	# Read file from USB device 1 and write it to USB device 2. If single device read/write is done between partitions
											if host_mount_points.length > 1
												file_size = [@test_params.params_chan.dev_file_size[0].sub(/G$/i,'000000000').sub(/M$/i,'000000').to_i,@test_params.params_chan.dev_file_size[1].sub(/G$/i,'000000000').sub(/M$/i,'000000').to_i].min.to_s.sub(/000000000$/,'G').sub(/000000$/,'M')
												temp_file_name = 'usb_slave_msc_'+file_size.upcase.strip+'_ref.dat'
												host.copy_file({"src_file" => host_dir+temp_file_name, "dst_file" => host_mount_points[0][0].to_s+dev_test_dir+temp_file_name.sub(/_ref\.dat/,'_test.dat'), "f_size" => file_size})
												result_comment += actions+iter.to_s+":read/write operation from #{host_mount_points[0][0].to_s}  to #{host_mount_points[1][0].to_s} was not successful\n" if !(host.copy_file({"src_file" => host_mount_points[0][0].to_s+dev_test_dir+temp_file_name.sub(/_ref\.dat/,'_test.dat'), "dst_file" => host_mount_points[1][0].to_s+dev_test_dir+temp_file_name.sub(/_ref\.dat/,'_test.dat'), "f_size" => file_size}))
											else
												(host_mount_points[0].length/2).floor.times do |current_index|
				                result_comment += actions+iter.to_s+":read/write operation from #{host_mount_points[0][current_index*2].to_s}  to #{host_mount_points[0][current_index*2+1].to_s} was not successful\n" if !(host.copy_file({"src_file" => host_mount_points[0][current_index*2].to_s+dev_test_dir+device_file_name[0], "dst_file" => host_mount_points[0][current_index*2+1].to_s+dev_test_dir+device_file_name[0], "f_size" => @test_params.params_chan.dev_file_size[0]}))
												end
											end
	            when 'mkdir'	# Create directory on USB Devices
		                if host_mount_points.length > 0
                      host_mount_points.each_with_index do |dev, dev_index|
												dev.each do |current_drive|
			                		result_comment += actions+iter.to_s+":mkdir operation on #{current_drive.to_s}  was not successful\n" if !host.make_dir({"dir_path" => current_drive.to_s+dev_test_dir}) 
												end
											end
										end
	            when 'dirchk' 	# Checks that directory exist on USB Devices
										if host_mount_points.length > 0
                      host_mount_points.each_with_index do |dev, dev_index|
		                		dev.each do |current_drive|
			                		result_comment += actions+iter.to_s+":dirchk operation on #{current_drive.to_s}  was not successful\n" if !host.dir_check({"dir_path" => current_drive.to_s+dev_test_dir}) 
												end
											end
		                end
							when 'rmdir'	# Remove directory on USB devices
										if host_mount_points.length > 0
											host_mount_points.each_with_index do |dev, dev_index|
		                		dev.each do |current_drive|
			                		result_comment += actions+iter.to_s+":rmdir operation on #{current_drive.to_s}  was not successful\n" if !(host.remove_dir({"dir_path" => current_drive.to_s+dev_test_dir})) 
												end
											end
		                end
		          when 'move' 	# Move a file from dev_test_dir to new directory in USB Devices
										if host_mount_points.length > 0
											old_test_dir = dev_test_dir
											dev_test_dir = dev_test_dir.sub(/\/*$/,'_new/')
											host_mount_points.each_with_index do |dev, dev_index|
												dev.each do |current_drive|
													host.make_dir({"dir_path" => current_drive.to_s+dev_test_dir})
		                			result_comment += actions+iter.to_s+":move operation on #{current_drive.to_s}  was not successful\n" if !(host.move_file({"file_path" => current_drive.to_s+old_test_dir+device_file_name[dev_index], "new_file_path" => current_drive.to_s+dev_test_dir+device_file_name[dev_index]}))
												end
			                end
										end
	            when 'rename'	# Rename a file in USB Devices
		                if host_mount_points.length > 0
			                file_name_change_count+=1
			                host_mount_points.each_with_index do |dev, dev_index|
                      old_device_file_name = device_file_name[dev_index]
                      device_file_name[dev_index] = device_file_name[dev_index].sub(/_test.*\.dat$/,'_test_'+file_name_change_count.to_s+'.dat')
		                		dev.each do |current_drive|
				                	result_comment += actions+iter.to_s+":rename operation on #{current_drive.to_s}  was not successful\n" if !(host.rename_file({"file_path" => current_drive.to_s+dev_test_dir+old_device_file_name, "new_file_name" => device_file_name[dev_index]}))
												end
			                end
										end
	            when 'delete'	# Delete a file in USB Devices
		                if host_mount_points.length > 0
                      host_mount_points.each_with_index do |dev, dev_index|
		                		dev.each do |current_drive|
				                	result_comment += actions+iter.to_s+":delete operation on #{current_drive.to_s}  was not successful\n" if !(host.delete_file({"file_path" => current_drive.to_s+dev_test_dir+device_file_name[dev_index]}))
												end
			                end
		                end
	            when 'chkdsk'	# Verifies integrity of filesystem in the USB device (only for Linux FSs. Always pass for VFAT FS)
                    
										if dev_drives.length > 0
			                dev_drives.each_with_index do |dev, dev_index| 
                        dev.each_with_index do |current_drive, partition_index|
                            result_comment += actions+iter.to_s+":chkdsk operation on #{current_drive.to_s}  was not successful\n" if !host.check_disk({"dev_drive" => current_drive.to_s, "fs" =>  @test_params.params_chan.dev_fs[dev_index], "host_mount_point" => @test_params.params_chan.dev_mount_point[dev_index], "timeout" => [10,10*@test_params.params_chan.dev_file_size[dev_index].to_i/180].max})
                        end
			                end
		                end
	            when 'properties'	# Verifies that file properties in the USB device can be changed
		                
										if host_mount_points.length > 0
                      host_mount_points.each_with_index do |dev, dev_index|
		                		dev.each do |current_drive|
				                	result_comment += actions+iter.to_s+":properties operation on #{current_drive.to_s}  was not successful\n" if !(host.change_properties({"file_path" => current_drive.to_s+dev_test_dir+device_file_name[dev_index]}))
												end
			                end
		                end
	            when 'delete_all'	# Removed all files and directories in the USB device mountpoint.
	                  if host_mount_points.length > 0
                      host_mount_points.each_with_index do |dev, dev_index|
												dev.each do |current_drive|
													result_comment += actions+iter.to_s+":delete all operation on #{current_drive.to_s}  was not successful\n" if !(host.remove_dir({"dir_path" => current_drive.to_s+'/*'}))
												end
			                end
		                end
	            when 'disconnect'	# Disconnect USB devices from Host and delete elements to dev_drives and host_mount_points arrays
							if devices.length > 0 
									devices.each_index {|dev_index| 
		                first_sys = host.get_usb_system_string({"vendor"=>@test_params.params_chan.dev_vendor[dev_index]})
		                host.unmount_usb_device({"dev_drives" => dev_drives[0], "host_mount_point" => host_mount_points[0]})
		                disconnect_device(host, dev_index)
	                  second_sys = host.get_usb_system_string({"vendor"=>@test_params.params_chan.dev_vendor[dev_index]})
		                sys_diff = get_string_diff(second_sys, first_sys)
		                dev_info2 = get_device_descriptors(sys_diff)
		                check_des_result = check_descriptors(0, dev_info[0], dev_info2).strip 
		                host_mount_points.delete_at(0)
		                dev_drives.delete_at(0)
		                dev_info.delete_at(0)
		                result_comment += "Problems with disconnect operation: #{check_des_result}. " if check_des_result != ''
		                usb_dev_connected = false
									}
									end
	            else
		                result_comment += actions+iter.to_s+':Unsupported '+ current_action + ' operation specified in test sequence'
	            end
			end
		end
	end
	test_result = FrameworkConstants::Result[:pass] if result_comment == ''
	
	rescue Exception => e
		result_comment +=e.to_s
    raise
	ensure

	@equipment['usb_sw'].connect_port(0)
	sleep 10

=begin
		begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
			if devices.length > 0 
			    devices.each_index {|dev_index| 
				    host.unmount_usb_device({"dev_drives" => dev_drives[dev_index], "host_mount_point" => host_mount_points[dev_index]})
				}
			end
		
			a = MessageBox.Show("Disconnect usb devices from DUT") if usb_dev_connected
			a =nil
			
			rescue  Exception 

		end
=end
		set_result(test_result,result_comment.strip)
end

def clean
end
    
		
private
def send_linux_command(command, timeout = 10)
	@equipment['dut1'].send_cmd(command,/#{command.slice(/^[^\s]+/)}.+#{@equipment['dut1'].prompt}/im,timeout)
	@equipment['dut1'].send_cmd("echo $?",/echo\s+\$\?\s+0.*#{@equipment['dut1'].prompt}/im,1)
end
		
def connect_device(host, dev_index)
	host_drives1 = host.check_host_drives

	puts " "
	puts "--------------- usb_host_msc - run ---283a---------------"
	puts " "
	puts "Connecting the USB port to a USB hub."

	@equipment['usb_sw'].connect_port(4)
	sleep 15

	puts " "
	puts "--------------- usb_host_msc - run ---289b---------------"
	
=begin
	begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
		a = MessageBox.Show("Connect #{@test_params.params_chan.dev_description[dev_index]} to the DUT")
		a = nil
		rescue  Exception
	end
=end
	
	host_drives2 = []
	num_tries = 0
	
	while host_drives2.length - host_drives1.length < @test_params.params_chan.dev_partitions[dev_index].to_i && num_tries < 20
		sleep 1
		host_drives2 = host.check_host_drives
		num_tries += 1
	end
	(host_drives2 - host_drives1)
end

def disconnect_device(host, dev_index)
	host_drives1 = host.check_host_drives
	
=begin
	begin #this is done because of messagebox problem needs to be removed once connection switch is integrated to test
		a = MessageBox.Show("Disconnect #{@test_params.params_chan.dev_description[dev_index]} from the DUT")
		a =nil
		rescue  Exception 
  end	
=end

	puts " "
	puts "--------------- usb_host_msc - run ---321a---------------"
	puts " "
	puts "Disconnecting the USB port from the USB hub."

	@equipment['usb_sw'].connect_port(0)
	sleep 10

	puts " "
	puts "--------------- usb_host_msc - run ---329b---------------"

	host_drives2 = []
	num_tries = 0
	
	while host_drives1.length - host_drives2.length < @test_params.params_chan.dev_partitions[dev_index].to_i && num_tries < 20
		sleep 1
		host_drives2 = host.check_host_drives
		num_tries += 1
	end
	(host_drives1 - host_drives2)
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
	field_value = info_string.strip.split(/\s+/)
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
	result
end

def get_device_class(usb_proto)
    case usb_proto.strip.downcase
		when 'audio'
			/0*1$/
		when 'cdc'
			/0*2$/
		when 'hid'
			/0*3$/
		when 'physical'
			/0*5$/
		when 'image'
			/0*6$/
		when 'printer'
			/0*7$/
		when 'mass storage'
			/0*8$/
		when 'hub'
			/0*9$/
		when 'cdc-data'
			/0*10$/
		when 'smart card'
			/0*11$/
		when 'video'
			/0*14$/
		else
			usb_proto
	end
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

def compare_descriptors(ref_descriptor_array, dev_descriptor_array, descriptor_type) 
    result_comment = ''
	ref_descriptor_array.each_index do |current_index|
		ref_descriptor_array[current_index].instance_variables.each do |dev_descriptor_field|
			if !dev_descriptor_field.include?("type") && !ref_descriptor_array[current_index].instance_variable_get(dev_descriptor_field).kind_of?(Array) && !(dev_descriptor_array[current_index].instance_variable_get(dev_descriptor_field).match(ref_descriptor_array[current_index].instance_variable_get(dev_descriptor_field)))
				result_comment += "device detected has wrong #{descriptor_type} descriptor value for #{dev_descriptor_field}\n"
			end
		end
	end
	result_comment
end

def check_descriptors(dev_index, dev_descriptors, ref_descriptors = nil)
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
		ref_descriptors['device'][0].set_descriptor_field('bcdUSB' , /((0200)|(#{@test_params.params_chan.dev_speed[dev_index].downcase.strip}))$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceClass' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceSubClass' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bDeviceProtocol' , /0+$/)
		ref_descriptors['device'][0].set_descriptor_field('bMaxPacketSize0' , /((40)|(64))$/)
		ref_descriptors['device'][0].set_descriptor_field('idVendor' , /#{@test_params.params_chan.dev_vendor[dev_index].downcase.strip.gsub(/^0x/,'')}/)
		ref_descriptors['device'][0].set_descriptor_field('idProduct' , /#{@test_params.params_chan.dev_product[dev_index].downcase.strip.gsub(/^0x/,'')}/)
		ref_descriptors['device'][0].set_descriptor_field('bcdDevice' , /#{@test_params.params_chan.dev_release[dev_index].downcase.strip.gsub(/^0x/,'')}$/)
		ref_descriptors['device'][0].set_descriptor_field('iManufacturer' , /\d+$/)
		ref_descriptors['device'][0].set_descriptor_field('iProduct' , /\d+/)
		ref_descriptors['device'][0].set_descriptor_field('bNumConfigurations' , /0*1$/)
		
		#Well known configuration descriptor Fields
		ref_descriptors['config'][0] = USBDataStructures::ConfigDescriptor.new
		ref_descriptors['config'][0].length = /0*9$/
		ref_descriptors['config'][0].set_descriptor_field('wTotalLength' , /((0020)|(32))$/)
		ref_descriptors['config'][0].set_descriptor_field('bNumInterfaces' , /0*1$/)
		
		#Well known interface descriptors fields
		ref_descriptors['interface'][0] = USBDataStructures::InterfaceDescriptor.new
		ref_descriptors['interface'][0].length = /0*9$/
		ref_descriptors['interface'][0].set_descriptor_field('bNumEndpoints', /0*2$/)
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceClass',  get_device_class(@test_params.params_chan.dev_class[dev_index])) 
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceSubClass' , get_device_subclass(@test_params.params_chan.dev_protocol[dev_index]))
		ref_descriptors['interface'][0].set_descriptor_field('bInterfaceProtocol' , get_device_transport_protocol(@test_params.params_chan.dev_transport[dev_index]))
		
		#Well known endpoint descriptor fields
		ref_descriptors['endpoint'][0] = USBDataStructures::InterfaceDescriptor.new
		ref_descriptors['endpoint'][0].length = /0*7$/
		ref_descriptors['endpoint'][0].set_descriptor_field('bmAttributes' , /0*2$/)
		ref_descriptors['endpoint'][0].set_descriptor_field('wMaxPacketSize' , /0200$/)
    #ref_descriptors['endpoint'][0].set_descriptor_field('wMaxPacketSize' , /0040$/)   #Use 200 for usb 2.0 and 40 for usb 1.1
		ref_descriptors['endpoint'][1] = ref_descriptors['endpoint'][0]
	end

	#Checking Device Descriptor
	result_comment += 'device detected had more than one device descriptor' if dev_descriptors['device'].length != 1
	result_comment += compare_descriptors(ref_descriptors['device'], dev_descriptors['device'], 'Device')
	result_comment += compare_descriptors(ref_descriptors['config'], dev_descriptors['config'], 'Configuration')
	dev_descriptors['config'].each do |config_descriptor|
		result_comment += 'device detected has wrong Configuration Attributes value' if (config_descriptor.bmAttributes.hex & 0x9F) != 0x80
	end
	result_comment += compare_descriptors(ref_descriptors['interface'], dev_descriptors['interface'], 'Interface')
	result_comment += compare_descriptors(ref_descriptors['endpoint'], dev_descriptors['endpoint'], 'Endpoint')
	ep_sum = 0
	dev_descriptors['endpoint'].each do |ep_descriptor|
		ep_sum += ep_descriptor.bEndpointAddress.hex & 0x80
	end
	result_comment += 'device detected has wrong address in one of it\'s enpoints' if ep_sum != 0x80
	result_comment = result_comment.strip
end




