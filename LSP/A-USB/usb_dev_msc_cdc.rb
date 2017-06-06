# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require 'net/telnet'
require File.dirname(__FILE__)+'/../../lib/utils'

include LspTestScript

def setup
  self.as(LspTestScript).setup
end


def run
  simultaneous_host_device_test=false
  packet_count=100
  test_duration=60
  module_name="ether"
  zlp_test=0
 if (@test_params.params_control.instance_variable_defined?(:@module_name))
  module_name=@test_params.params_control.module_name[0] 
 end
 if (@test_params.params_control.instance_variable_defined?(:@test_duration))
  test_duration=@test_params.params_control.test_duration[0].to_f
 end
 if (@test_params.params_control.instance_variable_defined?(:@packet_count))
  packet_count=@test_params.params_control.packet_count[0].to_f
 end
 if (@test_params.params_control.instance_variable_defined?(:@zlp_test))
  zlp_test=@test_params.params_control.zlp_test[0].to_f
 end

  mutex_timeout = test_duration>packet_count ? test_duration*5 : packet_count*5
  staf_mutex("usbdevice", mutex_timeout*1000) do

     test_cmd = Hash.new
     test_cmd = {'msc'=>"./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_S_PERF_VFAT_0001 ",
              'audio' =>"./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_audio -s USBHOST_S_FUNC_AUDIO_LOOPBACK_ACCESSTYPE_NONINTER_01 ",
              'video' => "./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_video -s USBHOST_M_FUNC_VIDEO_640_480 ",
              }
     test_command = ''

  
     # Preserve current governor
     prev_gov = create_save_cpufreq_governors
     #Change to performance governor
     enable_cpufreq_governor
  
     $result = 0
     $result_message = ""
     command = "modprobe -r g_ether"
     @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
     command = "modprobe -r g_ncm"
     @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
     command = "modprobe -r g_mass_storage"
     @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)

     cmds = @test_params.params_chan.instance_variable_get("@#{'cmd'}").to_s
     $cmd = cmds
  
     if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
        puts "This test uses device and host in parallel and params is #{@test_params.params_control.simultaneous_host[0]}\n"
        simultaneous_host_device_test = true
        puts "This test uses device and host in parallel and params is #{@test_params.params_control.simultaneous_host[0]}\n"
        host_type=@test_params.params_control.simultaneous_host[0]
        case host_type
        when 'msc', 'video', 'audio', 'mscxhci', 'audioxhci', 'videoxhci'
            test_command = test_cmd[host_type]
        else
            puts "Unsupported Host Device type in test parameter - #{host_type}\n"
            $result = 1
            $result_message = "Testcase has an unsupported device type as parameter"
            set_result(FrameworkConstants::Result[:fail], "Testcase has an unsupported device type as parameter.")
            return
        end
        start_usbhost_test(test_command)
        @stop_test = false
     end

     @stop_test=false
     while (!@stop_test)
        case  
        when cmds.match(/usb_dev_msc/) 
            usb_dev_msc()
            @stop_test=true
        when cmds.match(/usb_dev_cdc/) 
            usb_dev_cdc(packet_count, test_duration, module_name, zlp_test)
            @stop_test=true
        else
            $result = 1
            $result_message = "#{cmds} does not match any case"
            puts "#{cmds} does not match any case\n"
            if (!simultaneous_host_device_test)
               @stop_test=true
            end
        end
     end
     if $result == 0
       set_result(FrameworkConstants::Result[:pass], "Testcase Result is PASS.")  
     else
       set_result(FrameworkConstants::Result[:fail], $result_message)
       command = "modprobe -r g_ether"
       @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
       command = "modprobe -r g_ncm"
       @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
       command = "modprobe -r g_mass_storage"
       @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
       if (!simultaneous_host_device_test)
          @stop_test=true
       end

     end  

     stop_usbhost_test
 # Restore previous governor
     restore_cpufreq_governors(prev_gov)

  end
end

def clean
  self.as(LspTestScript).clean
end


def create_share_memory(command, response_pattern, next_command, timeout)
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt, timeout)
  response = @equipment['dut1'].response
  if response.include?("#{response_pattern}")
    return next_command
  else
    $result = 1
    $result_message = "#{command} command could not be executed"
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end
    return
  end
end

##################################################################################################################################################



#MSC test
def usb_dev_msc()

  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string1.txt"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string1.txt"', @equipment['server2'].prompt , 30)

  command = "depmod -a"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,20)

  system ("sleep 1")

  #command = "modprobe -l"
  command = "find /lib/modules -name *.ko"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,20)
  response = @equipment['dut1'].response
  if response.include?('g_mass_storage.ko')
    puts "g_mass_storage USB Module is available"
  else
    $result = 1
    $result_message = "g_mass_storage.ko module is not available"
     if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

    return     
  end

  command = "dmesg -c"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,30)

  system ("sleep 2")

#  Insert the msc gadget module
  
  case 
    when $cmd.match(/_msc_mmc/)
      device = get_sd_partition.strip+'p3'
      sd_dev = '/dev/'+device
      @equipment['dut1'].send_cmd("ls -al #{sd_dev}",@equipment['dut1'].prompt,1)
      if (@equipment['dut1'].response.include?("No such file or directory"))
        $result = 1
        $result_message = "MMC/SD does not contain a third partition"
        #set_result(FrameworkConstants::Result[:fail], "MMC/SD does not contain a third partition.")  
        return
      end
      sd_drive = '/media/'+device
      command = "umount "+sd_drive
      @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)      
      command = "modprobe g_mass_storage file="+sd_dev+" stall=0 removable=1"
      @equipment['server2'].send_sudo_cmd("dmesg -c", @equipment['server2'].prompt, 5)
    
    when $cmd.match(/_msc_usb/)
      command = "umount /media/sda1"
      @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
      command = "modprobe g_mass_storage file=/dev/sda1 stall=0 removable=1"

    when $cmd.match(/_msc_slave/)
      command = create_share_memory("dd if=/dev/zero of=/dev/shm/disk bs=1M count=52", "52+0 records", "mknod /dev/loop0 b 7 0", 10)
      command = create_share_memory(command, "#", "losetup /dev/loop0 /dev/shm/disk", 5)
      command = create_share_memory(command, "#", "echo $?", 2)
      command = create_share_memory(command, "0", "mkfs.vfat /dev/loop0", 3)

      @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
      
      command = "modprobe g_mass_storage file=/dev/loop0 stall=0 removable=1"

    else
      $result = 1
      $result_message = "$cmd does not match any case"
    end

  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  @equipment['server2'].send_sudo_cmd("dmesg", @equipment['server2'].prompt, 5)
  dmesg_output = @equipment['server2'].response
  if response.include?('Error')
    $result = 1
    $result_message = "g_mass_storage.ko insertion failed"
     #if (simultaneous_host_device_test)
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

    return     
  end

  system ("sleep 20")

  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /dev > dev_string2.txt"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd('bash -c "df | grep /media > media_string2.txt"', @equipment['server2'].prompt , 30)
  mscdev= find_newdevice()
  mscmount= find_newmedia()
  puts "mscdev =#{mscdev}"
  puts "mscmount =#{mscmount}"
  if (mscdev == '')
     # check dmesg
    mscdev=dmesg_output.match /sd\S/ 
    puts "MSCDEV is #{mscdev}\n"
  end
  if (mscdev == '')

    puts "Host does not detect any USB device"
    $result = 1
    $result_message = "Host PC did not detect a USB device"
    # if (simultaneous_host_device_test)
     if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
       @stop_test=true
    end
    return
  end
  if (mscmount != '')
     @equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
  end
  mountfolder = 'test'
  @equipment['server2'].send_sudo_cmd("mkdir -p /media/#{mountfolder}", @equipment['server2'].prompt , 30)
  mscmount = "/media/#{mountfolder}"
  @equipment['server2'].send_sudo_cmd("mount #{mscdev} #{mscmount}", @equipment['server2'].prompt , 30)

  MSC_Unmount_Device("#{mscdev}","#{mscmount}")
  case
  when $cmd.match(/_msc_slave/)  
    MSC_Mount_Device("#{mscdev}","#{mscmount}")
    MSC_Raw_Write("#{mscmount}","150")
    
    MSC_Mount_Device("#{mscdev}","#{mscmount}")  
    MSC_Raw_Read("#{mscmount}","150")

    puts "DONE Mount, raw read, raw write\n"
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
  command = "modprobe -r g_mass_storage"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)

  @equipment['server2'].send_sudo_cmd("rm -rf  dev_string1.txt", @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("rm -rf  dev_string2.txt", @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("rm -rf  media_string1.txt", @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("rm -rf  media_string2.txt", @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("rm -rf /media/test", @equipment['server2'].prompt , 30)
end


#CDC test
def usb_dev_cdc(packet_count, test_duration, module_name, zlp_test)
  gadget_name = "g_#{module_name}"
  command = "depmod -a"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,20)

  system ("sleep 1")

  #command = "modprobe -l"
  command = "find /lib/modules -name *.ko"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,20)
  response = @equipment['dut1'].response
  if response.include?("#{gadget_name}.ko")
    puts "#{gadget_name} USB Module is available"
  else
    $result = 1
    $result_message = "#{gadget_name}.ko module is not available"
    #if (simultaneous_host_device_test)
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end
    return     
  end

  command = "dmesg -c"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,30)
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt,10)

  system ("sleep 2")

  command = "modprobe #{gadget_name}"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('not found')
    $result = 1
    $result_message = "Module insertion failed"
    #if (simultaneous_host_device_test)
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end
    return     
  end
  sleep 10
  command = "dmesg"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,4)
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,4)
  response = @equipment['dut1'].response
  response_server = @equipment['server2'].response
  if response.include?('usb0')
    puts "#{gadget_name} module inserted succesfully"
  else
    $result = 1
    $result_message = "#{gadget_name} module insertion failed"
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
  end
  return

  end
  if (response_server.include?('cdc_ether') || response_server.include?('cdc_eem') || response_server.include?('cdc_ncm'))
    puts "#{gadget_name} registered on host succesfully"
    if (response_server.include?('cdc_ether'))
      usb_num=/usb(\d+)\s?:\s?register.*cdc_ether.*/.match(response_server).captures
    elsif (response_server.include?('cdc_ncm'))
      usb_num=/usb(\d+)\s?:\s?register.*cdc_ncm.*/.match(response_server).captures
    else
      usb_num=/usb(\d+)\s?:\s?register.*cdc_eem.*/.match(response_server).captures
    end
    usb_num=usb_num[0].to_i
    server_usb_interface='usb'+usb_num.to_s
    puts "USB_INTERFACE is #{server_usb_interface}\n"
  else
    puts "FAILURE"
    $result = 1
    $result_message = "Ethernet gadget did not register on host side. Please check connections."
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end
    return     
  end
  
  system ("sleep 10")

  command ="ifconfig usb0 #{@equipment['dut1'].usb_ip} up"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('No such device')
    $result = 1
    $result_message = "DUT IP Address is not assigned properly"
    return 
  end

  #system ("sleep  60")

  command ="bash -c 'ifconfig #{server_usb_interface} #{@equipment['server2'].usb_ip} up'"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  response = @equipment['server2'].response
  if response.include?('No such device')
    $result = 1
    $result_message = "Linux system ip address is not assigned properly"
    return 
  end

  system ("sleep 10")


  case

    when $cmd.match(/_cdc_ping/)

      #Ping test
      pingtest_cdc(server_usb_interface, packet_count, zlp_test)

    when $cmd.match(/_cdc_floodping/)

      #Flood ping test
      floodpingtest_cdc(server_usb_interface, packet_count)

    when $cmd.match(/_cdc_iperf/)

      #iperf test
      iperftest_cdc(server_usb_interface, test_duration)

    else
      $result = 1
      $result_message = "#{cmd} does not match any case"
  end

#  Remove the ethernet gadget module
  system ("sleep 5")
  command = "modprobe -r g_ether"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  command = "modprobe -r g_ncm"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)


end


def assign_server_ip(server_usb_interface)
  command ="bash -c 'ifconfig #{server_usb_interface} #{@equipment['server2'].usb_ip} up'"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  response = @equipment['server2'].response
  if response.include?('No such device')
    $result = 1
    $result_message = "Linux system ip address is not assigned properly"
    return
  end
  command ="ping -I #{server_usb_interface} #{@equipment['dut1'].usb_ip} -c 3"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  system ("sleep 1")
end


#ping test
def pingtest_cdc(server_usb_interface, packet_count, zlp_test=0)
  packetsize=Array.new
  if (zlp_test==1)
     packet_count=3
     (470..500).each do |n|
       packetsize.push n
     end
  else
     packetsize = [64,512,4096,8192,65500]
  end

  test_timeout = packet_count + 15
  assign_server_ip(server_usb_interface) 
  packetsize.each { |psize| 
  #Ping from DUT to host

  command ="ping -c #{packet_count} #{@equipment['server2'].usb_ip} -s #{psize}"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,test_timeout)
  response = @equipment['dut1'].response
  if response.include?(' 0% packet loss')
    puts "Ping from DUT to host is successful "
    else
    $result = 1
    $result_message = "Ping from DUT to host failed"
    return 
  end

  #Ping from host to DUT

  command="ping -c #{packet_count} #{@equipment['dut1'].usb_ip} -s #{psize}"
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,test_timeout)
  response = @equipment['server2'].response
  if response.include?(' 0% packet loss')
    puts "Ping from host to DUT is successful "
  else
    $result = 1
    $result_message = "Ping from host to DUT failed"
    return 
  end

  }
end


# Flood ping test
def floodpingtest_cdc(server_usb_interface, packet_count)
  test_timeout = packet_count + 15
  packetsize = [64,4096,65500]
  assign_server_ip(server_usb_interface)
  packetsize.each { |psize|

  #Flood ping from host to DUT

  command="ping -f -c #{packet_count} #{@equipment['dut1'].usb_ip} -s #{psize}"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt,test_timeout)
  response = @equipment['server2'].response
  if response.include?(' 0% packet loss')
    puts "Flood ping from host to DUT is successful "
  else
    $result = 1
    $result_message = "Flood ping from host to DUT failed"
    return
  end

  }
end


#iperf test
def iperftest_cdc(server_usb_interface, test_duration)

#  iperf test from host to DUT
  test_timeout = test_duration+15
  windowsize = [8,16,32,64,128]
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
    $result_message = "IPERF application initialization failed"
    return 
  end

  command="iperf -c #{@equipment['dut1'].usb_ip} -w #{wsize}K -d -t #{test_duration}"
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,test_timeout)
  response = @equipment['server2'].response
  if response.include?('Connection refused')
    $result = 1
    $result_message = "IPERF application could not be started on DUT"
    return 
  end
  
  command ="kill -9 $(pidof iperf)"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  system ("sleep 3")
  }

#  iperf test from DUT to host

  windowsize = [8,16,32,64,128]
  assign_server_ip(server_usb_interface)
  output_string = ''
  windowsize.each { |wsize|

  system ("kill -9 $(pidof iperf)")
  system ("iperf -s &")
  system ("ps | grep iperf")
  system ("ps | grep iperf")

  command ="ps"
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,3)
  response = @equipment['server2'].response
  if response.include?('iperf')
    puts "iperf application started succesfully"
  else
    $result = 1
    $result_message = "IPERF application initialization failed on server"
    return 
  end

  command="iperf -c #{@equipment['server2'].usb_ip} -w #{wsize}K -d -t #{test_duration}"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt, test_timeout)
  response = @equipment['dut1'].response
  if response.include?('Connection refused')
    $result = 1
    $result_message = "IPERF application not started on host"
    return 
  end
  
  system ("sleep 5")

  system ("kill -9 $(pidof iperf)")
  system ("ps | grep iperf")
  match_string=response.scan(/\d+.\d+\sMbits\/sec/)
  if (match_string.length == 0)
    $result = 1
    $result_message += "IPERF response does not have performance numbers for #{wsize}"
  end
  throughput = match_string[0].split(' Mbits/sec')[0].to_f+match_string[1].split(' Mbits/sec')[0].to_f
  output_string += " Packetsize="+wsize.to_s+"_Throughput="+throughput.to_s
  puts "Throughput is #{throughput}\n"
  }
 return output_string
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


# MSC Unmount device

def MSC_Unmount_Device(mscdev,mscmount)

  @equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
  

end


# Mount MSC device

def MSC_Mount_Device(mscdev, mscmount)

  @equipment['server2'].send_sudo_cmd("mount #{mscdev} #{mscmount}", @equipment['server2'].prompt , 30)
end



# MSC Raw write using dd command

def MSC_Raw_Write(mscmount, mbsize)

  @equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("time dd of=#{mscmount}/#{mbsize}mb if=/dev/zero bs=1M count=#{mbsize} oflag=direct", @equipment['server2'].prompt , 120)
  response = @equipment['server2'].response
  @equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
  system ("sleep 5")
  return response
end


# MSC Raw read using dd command

def MSC_Raw_Read(mscmount, mbsize)
  
  @equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("time dd if=#{mscmount}/#{mbsize}mb of=/dev/zero bs=1M count=#{mbsize}", @equipment['server2'].prompt , 120)
  response = @equipment['server2'].response
  @equipment['server2'].send_sudo_cmd('bash -c "echo 3 > /proc/sys/vm/drop_caches"', @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("umount #{mscmount}", @equipment['server2'].prompt , 30)
  @equipment['server2'].send_sudo_cmd("sleep 5", @equipment['server2'].prompt , 30)
  return response
end

def start_usbhost_test(test_cmd)
  @usbhost_thread = Thread.new(){
  i=0
  Thread.pass
  Thread.current['stop']=false
  time = Time.now
  @eth_ip_addr = get_ip_addr()   # get_ip_addr() is defined at default_target_test.rb
  raise "Can't run the test because DUT does not seem to have an IP address configured" if !@eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_port = 23
  @equipment['dut1'].connect({'type'=>'telnet'})
  @equipment['dut1'].target.telnet.send_cmd("cd /opt/ltp", @equipment['dut1'].prompt, 5)
  @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
  @equipment['dut1'].target.telnet.send_cmd('cd /opt/ltp')
  @equipment['dut1'].target.telnet.send_cmd(test_cmd, @equipment['dut1'].prompt,600)
  @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
  if ( @equipment['dut1'].target.telnet.timeout? )
     set_result(FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to complete the usbhost test")
     @stop_test = true
  end
  result_count=/Total Failures\s?:\s?(\d+)/.match(@equipment['dut1'].target.telnet.response).captures
  result_count=result_count[0].to_i
  if (result_count > 0)
    set_result(FrameworkConstants::Result[:fail], "LTP Test has failed. Please check logs regarding failure.")
    @stop_test = true
  end

    @stop_test=true
}
end

def stop_usbhost_test
  if @usbhost_thread
    @usbhost_thread["stop"]=true
  end
end

# Function to find the block which matches SD type to differentiate between SD and EMMC block types
def get_sd_partition
  cmd = "ls /dev/mmcblk* |grep boot |head -1 |sed s'/boot[0-9]*//'"
  @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt)
  response = @equipment['dut1'].response
  dev_node = get_stripped_partition(response)
  if (dev_node == "")
   # the target does not have emmc so just find out the partition with boot sector
   mmc_cmd = "ls /dev/mmcblk* |grep -E \".*blk[[:digit:]]+$\" |head -1"
   @equipment['dut1'].send_cmd(mmc_cmd, @equipment['dut1'].prompt)
   mmc_response = @equipment['dut1'].response
   mmc_node = get_stripped_partition(mmc_response)
  else
    cmd = "ls /dev/mmcblk* |sed s\",/dev/#{dev_node}.*$,,g\" |grep -E \".*blk[[:digit:]]+$\" |head -1"
    @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt)
    response = @equipment['dut1'].response
    mmc_node = get_stripped_partition(response)
  end
  if mmc_node == ""
    set_result(FrameworkConstants::Result[:fail], "No SD or MMC block device is found on host.")
    return
  else
    return mmc_node
  end
end

# Function to remove cmd, dut prompt from input which is dut_response and return mmc device node name
def get_stripped_partition(response)
  response = response.lines.to_a[1..-1].join.strip
  response = response.gsub(/root@.*#/,'')
  response = response.gsub('/dev/','')
  response = response.strip
  return response
end
