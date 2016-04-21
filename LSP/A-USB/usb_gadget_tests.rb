require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/usb_dev_msc_cdc'
require File.dirname(__FILE__)+'/../../lib/utils'

def setup
  @equipment['dut1'].set_api('psp')
  self.as(LspTargetTestScript).setup
  if (@test_params.params_control.instance_variable_defined?(:@module_name) && @test_params.params_control.instance_variable_defined?(:@gadget_types))
   if !check_config_module(@test_params.params_control.module_name[0])
      set_result(FrameworkConstants::Result[:fail], "Gadget_module is not present on target filesystem")
      return
   end
 else
    set_result(FrameworkConstants::Result[:fail], "Module name or gadget types or both are not defined in test case parameter.")
    return
 end
end

def run
  
  modprobe_remove_all
  test_type = @test_params.params_control.instance_variable_defined?(:@test_type) ? @test_params.params_control.test_type[0] : 'insert_remove'
  iterations = @test_params.params_control.instance_variable_defined?(:@iterations) ? @test_params.params_control.iterations[0].to_i : 5 

  mutex_timeout = iterations*60000
  staf_mutex("usbdevice", mutex_timeout) do

     case 
     when test_type.match(/insert_remove/)
       run_stress_insert_remove(iterations)
     when test_type.match(/performance/)
       run_performance
     else
       set_result(FrameworkConstants::Result[:fail], "Unsupported Test Type")
       return
     end

  end
end

# Function for running simultaneous device tests in parallel when using g_multi module
def run_performance
  perf_data = []
 # Collect data from test params
  module_name = @test_params.params_control.module_name[0]
  gadget_types = @test_params.params_control.gadget_types
  mount_type = @test_params.params_control.instance_variable_defined?(:@dev_type) ? @test_params.params_control.dev_type[0] : 'msc_mmc'
  block_num = @test_params.params_control.instance_variable_defined?(:@number_of_blocks) ? @test_params.params_control.number_of_blocks[0] : 1

# Sanity check that modules are loading correctly
  modprobe_on_device(module_name, gadget_types, 'insert')
  if !check_enum_on_target(module_name)
     set_result(FrameworkConstants::Result[:fail], "Gadget not detected on target.")
     return
  end
  if !check_enum_on_host(gadget_types)
     set_result(FrameworkConstants::Result[:fail], "One or more gadgets not detected on host.")
     return
  end
  modprobe_on_device(module_name, gadget_types, 'remove')


# Collect mount directory and other details
  device_details = Hash.new
  device_details = check_mount_interface_on_host(gadget_types)
  puts "DEVICE_DETAILS is #{device_details}\n"
  mode='all'

# Spawn the threads

  t1 = Thread.new{ start_usb_dev_cdc(device_details['interface']) }
  sleep 20 # starting msc thread a few seconds later to ensure iperf test is setup
  t2 = Thread.new{ start_usb_dev_msc(device_details['mscmount'], device_details['mscdev'], mode, block_num) }
  t1.join
  t2.join
  msc_file_name = File.join(@linux_temp_folder, 'msc_test.log') 
  cdc_file_name = File.join(@linux_temp_folder, 'cdc_test.log') 
  File.open(msc_file_name, 'r').each {|line|
         read_val = line.split('_')[0].split('Read= ')[1].split(' MB/s')[0]
         perf_data << {'name' => "ReadThroughput", 'value' => read_val, 'units' => "MB/s"}
         write_val = line.split('_')[1].split('Write= ')[1].split(' MB/s')[0]
         perf_data << {'name' => "WriteThroughput", 'value' => write_val, 'units' => "MB/s"}
         }
  File.open(cdc_file_name, 'r').each {|line|
         array_throughput = line.split(' ')
         array_throughput.each {|throughput|
             psize = throughput.split('_')[0].split('Packetsize=')[1]
             psize = 'Throughput_for_'+psize.to_s+'KByte'
             throughput = throughput.split('_')[1].split('Throughput=')[1]
             perf_data << {'name' => psize, 'value' => throughput, 'units' => "Mbits/s"}
            }
         }
  set_result(FrameworkConstants::Result[:pass], "Performance data is are collected.",perf_data)
end

def run_stress_insert_remove(iterations)
  module_name = @test_params.params_control.module_name[0]
  gadget_types = @test_params.params_control.gadget_types
  loop_count = 0
  device_test = 0
  host_test = 0
  while (loop_count<iterations)
      loop_count = loop_count+1
      modprobe_on_device(module_name, gadget_types, 'insert')
      if check_enum_on_target(module_name)
         device_test=device_test+1
      end
      if check_enum_on_host(gadget_types)
         host_test=host_test+1
      end
      modprobe_on_device(module_name,gadget_types, 'remove')
  end # of while
  if ((loop_count == device_test) && (loop_count == host_test))
      set_result(FrameworkConstants::Result[:pass], "In #{loop_count} iterations, device detected gadget #{device_test} times and host detected gadget #{host_test} times.")
  else
      set_result(FrameworkConstants::Result[:fail], "In #{loop_count} iterations, device detected gadget #{device_test} times and host detected gadget #{host_test} times.")
  end
end

def check_config_module(module_name)
  @equipment['dut1'].send_cmd("ls /lib/modules/*/kernel/drivers/usb/gadget/g_#{module_name}.ko",@equipment['dut1'].prompt)
  if !@equipment['dut1'].response.match(/#{module_name}/)
    return false
  else
    return true
  end
end

def modprobe_remove_all
  @equipment['dut1'].send_cmd("lsmod",@equipment['dut1'].prompt)
  lsmod_response = @equipment['dut1'].response
  lsmod_response.each_line do |line|
      if (line.match(/\Ag_*/))
        puts "Found a gadget at #{line}\n"
        gadget = line.split(' ')[0]
        puts "Gadget is #{gadget}\n"
        @equipment['dut1'].send_cmd("modprobe -r #{gadget}",@equipment['dut1'].prompt)
      end
  end
end

def modprobe_on_device(module_name,gadget_types,action)
  if (action == 'remove')
    @equipment['server2'].send_sudo_cmd("dmesg -c",@equipment['server2'].prompt)  
    cmd = 'modprobe -r'
    @equipment['dut1'].send_cmd("#{cmd} g_#{module_name}",@equipment['dut1'].prompt)  
    @equipment['server2'].send_cmd("dmesg",@equipment['server2'].prompt)  
    dut_response = @equipment['dut1'].response
    host_response = @equipment['server1'].response
    if (!dut_response.match(/USB disconnect/))
      set_result(FrameworkConstants::Result[:fail], "Disconnect message not seen on target during module removal.")
      return
    end
    if (!host_response.match(/USB disconnect/))
      set_result(FrameworkConstants::Result[:fail], "Disconnect message not seen on host during module removal.")
      return
    end
  else
   cmd = 'modprobe'
   extra_params = ''
   dir_path = Hash.new
   dir_path = {'msc_mmc'=>'mmcblk1p1','msc_usb'=>'sda1','msc_slave'=>'loop0'}
   if gadget_types.include? 'mass_storage'
     mount_type = @test_params.params_control.instance_variable_defined?(:@dev_type) ? @test_params.params_control.dev_type[0] : 'msc_mmc'
   # special cases like g_mass_storage to be handled here and action is not remove
     extra_params = 'file=/dev/'+dir_path[mount_type].to_s+' stall=0 removable=1'

      if (mount_type.match(/msc_slave/))
          command = create_share_memory("dd if=/dev/zero of=/dev/shm/disk bs=1M count=52", "52+0 records", "mknod /dev/loop0 b 7 0", 10)
          command = create_share_memory(command, "#", "losetup /dev/loop0 /dev/shm/disk", 5)
          command = create_share_memory(command, "#", "echo $?", 2)
          command = create_share_memory(command, "0", "mkfs.vfat /dev/loop0", 3)
      end

     command = "umount /media/"+dir_path[mount_type].to_s
     @equipment['dut1'].send_cmd("#{command}",@equipment['dut1'].prompt)
   end
   @equipment['server2'].send_sudo_cmd("dmesg -c",@equipment['server2'].prompt)  
   puts "EXTRA_PARAMS is #{extra_params}\n"
   @equipment['dut1'].send_cmd("#{cmd} g_#{module_name} #{extra_params}",@equipment['dut1'].prompt)  
   #@equipment['server2'].send_cmd("dmesg",@equipment['server2'].prompt)  
  end
end

def check_enum_on_target(module_name)
  # Hash for each gadget and expected logs - for instance mass_storage would lead to "Mass Storage Function"
  # And multi could lead to  multiple gadgets
  dut_module_string = Hash.new
  dut_module_string = {'mass_storage'=>'gadget:\s+g_mass_storage\s+ready','ether'=>'gadget:\s+g_ether\s+ready',
                       'serial'=>'gadget:\s+g_serial\s+ready', 'cdc' => 'gadget:\s+g_cdc\s+ready',
                       'multi' => 'gadget:\s+g_multi\s+ready'}
  # Verify that string matches with gadget type
  dut_response = @equipment['dut1'].response
  module_found = false
  puts "DUT_RESPONSe is #{dut_response}\n"
  if dut_response.match(dut_module_string[module_name])
   puts "FOUND #{dut_module_string[module_name]} in check_enum_target\n"
   module_found = true
  else
   puts "NOT FOUND #{dut_module_string[module_name]} in check_enum_target\n"
   module_found = false
  end
  return module_found
end

def check_enum_on_host(gadget_types)
  # Hash for each gadget and expected logs - for instance mass_storage would lead to "Mass Storage Function"
  host_gadget_string = Hash.new
  host_gadget_string = {'mass_storage'=>'usb-storage:\s+device scan complete','ether'=>'CDC Ethernet Device',
                       'serial'=>'ttyACM\d+:\s+USB\s+ACM\s+device'}
  sleep 10
  @equipment['server2'].send_cmd("dmesg",@equipment['server2'].prompt)  
  host_response = @equipment['server2'].response
  # Verify that string matches with gadget type
  gadget_found = false
  gadget_types.each do |gadget|
       if host_response.match(host_gadget_string[gadget])
            puts "FOUND in host #{host_gadget_string[gadget]}"
            gadget_found = true
       else
            puts "NOT FOUND in host #{host_gadget_string[gadget]}"
            gadget_found = false
       end                    
  end
  return gadget_found
end

def check_mount_interface_on_host(gadget_types)
  module_name = @test_params.params_control.module_name[0]
  @equipment['server2'].send_sudo_cmd("dmesg -c",@equipment['server2'].prompt)  
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string1.txt"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string1.txt"', @equipment['server2'].prompt , 30)
  modprobe_on_device(module_name, gadget_types, 'insert')
  system("sleep 20")
  @equipment['server2'].send_cmd("dmesg",@equipment['server2'].prompt)  
  host_response =  @equipment['server2'].response
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string2.txt"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string2.txt"', @equipment['server2'].prompt , 30)
  mscdev= find_newdevice()
  mscmount = find_newmedia()
  puts "mscdev =#{mscdev}"
  puts "mscmount =#{mscmount}"
  @equipment['server2'].send_sudo_cmd("rm dev_string1.txt",@equipment['server2'].prompt)
  @equipment['server2'].send_sudo_cmd("rm media_string1.txt",@equipment['server2'].prompt)
  @equipment['server2'].send_sudo_cmd("rm dev_string2.txt",@equipment['server2'].prompt)
  @equipment['server2'].send_sudo_cmd("rm media_string2.txt",@equipment['server2'].prompt)
  if mscdev == mscmount then
    puts "Host does not detect any USB device"
    set_result(FrameworkConstants::Result[:fail], "No new USB mount is reported on host.")
    return
  end
  interface_name = host_response.match(/usb\d: register 'cdc_ether'/)[0]
  puts "HOST_RESPONSE is #{host_response}\n"
  puts "INTERFACE_NAME is #{interface_name}\n"
  if interface_name == ''
    set_result(FrameworkConstants::Result[:fail], "Testcase Result is FAIL.")
    return
  else
  interface_name = interface_name.split(':')[0]
  puts "INTERFACE is #{interface_name}\n"
  end  
  params = Hash.new
  params = {'mscdev'=>mscdev, 'mscmount'=>mscmount, 'interface'=>interface_name}
  return params
end

#MSC test
def start_usb_dev_msc(mscmount, mscdev, mode, blocknum)
  puts "ENTERED start_usb_dev_msc test\n"
  @equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
  mountfolder = 'test'
  @equipment['server2'].send_sudo_cmd("mkdir -p /media/#{mountfolder}", @equipment['server2'].prompt , 30)
  
  mscmount = "/media/#{mountfolder}"
  @equipment['server2'].send_sudo_cmd("mount #{mscdev} #{mscmount}", @equipment['server2'].prompt , 30)
  @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)    
  out_file = File.new(File.join(@linux_temp_folder,'msc_test.log'),'w')
  MSC_Unmount_Device("#{mscdev}","#{mscmount}")
  MSC_Mount_Device("#{mscdev}","#{mscmount}")
  write_response = MSC_Raw_Write("#{mscmount}", blocknum)
  MSC_Mount_Device("#{mscdev}","#{mscmount}")
  read_response = MSC_Raw_Read("#{mscmount}", blocknum)
  read_throughput = read_response.match(/\d+.\d*\sMB\/s/)
  write_throughput = write_response.match(/\d+.\d*\sMB\/s/)
  puts "WRITE response is #{write_throughput}\n"
  puts "READ response is #{read_throughput}\n"
  test_output = "Read= "+read_throughput.to_s+'_'+"Write= "+write_throughput.to_s
  out_file.write(test_output)
  out_file.close
  out_file_name = File.join(@linux_temp_folder, 'msc_test.log')
  add_log_to_html(out_file_name)

  @equipment['server2'].send_sudo_cmd("rm -rf /media/test", @equipment['server2'].prompt , 30)
end




#CDC test
def start_usb_dev_cdc(usb_interface)

    server_usb_interface=usb_interface
    puts "USB_INTERFACE is #{server_usb_interface}\n"
    system ("sleep 10")
    command ="ifconfig usb0 #{@equipment['dut1'].usb_ip} up"
    @linux_temp_folder = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s)    
    out_file = File.new(File.join(@linux_temp_folder,'cdc_test.log'),'w')
    @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
    response = @equipment['dut1'].response
    if response.include?('No such device')
     $result = 1
     set_result(FrameworkConstants::Result[:fail], "DUT ip address is not assigned properly.")
    return
    end

  command ="bash -c 'ifconfig #{server_usb_interface} #{@equipment['server2'].usb_ip} up'"
 @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  response = @equipment['server2'].response
  if response.include?('No such device')
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Linux system ip address is not assigned properly.")
    return
  end
  system ("sleep 10")
  #throughtput_hash = Hash.new
  output_string=''
  #throughput_hash = iperftest_cdc(server_usb_interface)
  output_string = iperftest_cdc(server_usb_interface)
  #out_file.write(throughput_hash)
  out_file.write(output_string)
  out_file.close
  out_file_name = File.join(@linux_temp_folder, 'cdc_test.log')
  add_log_to_html(out_file_name)
  #puts "HASH is #{throughput_hash}\n"
end

