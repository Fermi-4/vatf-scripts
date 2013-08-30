# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require 'net/telnet'
# Default Server-Side Test script implementation for LSP releases


#################################################################################################################################################


include LspTestScript
def setup

#  super
  self.as(LspTestScript).setup

end


def run
  simultaneous_host_device_test=false
  test_cmd = Hash.new
  test_cmd = {'msc'=>"./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_S_PERF_VFAT_0001 ",
              'audio' =>"./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_audio -s USBHOST_S_FUNC_AUDIO_LOOPBACK_ACCESSTYPE_NONINTER_01 ",
              'video' => "./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_video -s USBHOST_M_FUNC_VIDEO_640_480 ",
              'mscxhci'=>"./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBXHCIHOST_S_PERF_VFAT_0001 ",
              'audioxhci' =>"./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_audio -s USBXHCIHOST_S_FUNC_AUDIO_LOOPBACK_ACCESSTYPE_NONINTER_01 ",
              'videoxhci' => "./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_video -s USBXHCIHOST_M_FUNC_VIDEO_640_480 ",
              }
  test_command = ''

  $result = 0
  command = "modprobe -r g_ether"
  #@equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  #command = "modprobe -r g_file_storage"
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
      usb_dev_cdc()
      @stop_test=true
    else
      $result = 1
      puts "#{cmds} does not match any case\n"
     if (!simultaneous_host_device_test)
       @stop_test=true
     end
  end
 end
  if $result == 0
    set_result(FrameworkConstants::Result[:pass], "Testcase Result is PASS.")  
    else
    set_result(FrameworkConstants::Result[:fail], "Testcase Result is FAIL.")
    command = "modprobe -r g_ether"
    @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
    command = "modprobe -r g_mass_storage"
    @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
     if (!simultaneous_host_device_test)
     @stop_test=true
    end

  end  

 stop_usbhost_test
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
    set_result(FrameworkConstants::Result[:fail], "#{command} command could not execute")
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
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,3)

  system ("sleep 1")

  #command = "modprobe -l"
  command = "find /lib/modules -name *.ko"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('g_mass_storage.ko')
    puts "g_mass_storage USB Module is available"
  else
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "g_mass_storage.ko module is not available.")  
     if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

    return     
  end

  command = "dmesg -c"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,10)

  system ("sleep 2")

#  Insert the msc gadget module
  
  case 
    when $cmd.match(/_msc_mmc/)
      
      command = "umount /media/mmcblk0p1"
      @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)      
      command = "modprobe g_mass_storage file=/dev/mmcblk0p1 stall=0 removable=1"
    
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
      puts "#{$cmd} does not match any case\n"
  end

  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('Error')
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "g_mass_storage.ko insertion fialed.")  
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

  if mscdev == mscmount then

    puts "Host does not detect any USB device"
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Testcase Result is FAIL.")
    # if (simultaneous_host_device_test)
     if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

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
  command = "modprobe -r g_mass_storage"
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

  #command = "modprobe -l"
  command = "find /lib/modules -name *.ko"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('g_ether.ko')
    puts "g_ether USB Module is available"
  else
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "g_ether.ko module is not available.")  
    #if (simultaneous_host_device_test)
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

    return     
  end

  command = "dmesg -c"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,2)
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt,10)

  system ("sleep 2")

  command = "modprobe g_ether"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)
  response = @equipment['dut1'].response
  if response.include?('not found')
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Module insertion is failed.")  
    #if (simultaneous_host_device_test)
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
    end

    return     
  end

  command = "dmesg"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,4)
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,4)
  response = @equipment['dut1'].response
  response_server = @equipment['server2'].response
  if response.include?('usb0')
    puts "g_ether module inserted succesfully"
  else
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "g_ether module insertion fialed.")  
    if (@test_params.params_control.instance_variable_defined?(:@simultaneous_host))
     @stop_test=true
  end
  return

  end
  puts "SERVER RESPONSE is #{response_server}\n"
  if (response_server.include?('cdc_ether') || response.server.include?('cdc_eem'))
    puts "SUCCESS"
    puts "g_ether registered on host succesfully"
    if (response_server.include?('cdc_ether'))
      usb_num=/usb(\d+)\s?:\s?register.*cdc_ether.*/.match(response_server).captures
    else
      usb_num=/usb(\d+)\s?:\s?register.*cdc_eem.*/.match(response_server).captures
    end
    usb_num=usb_num[0].to_i
    server_usb_interface='usb'+usb_num.to_s
    puts "USB_INTERFACE is #{server_usb_interface}\n"
  else
    puts "FAILURE"
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Ethernet gadget did not register on host side. Please check connections")  
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
    set_result(FrameworkConstants::Result[:fail], "DUT ip address is not assigned properlly.")  
    return 
  end

  #system ("sleep  60")

  command ="bash -c 'ifconfig #{server_usb_interface} #{@equipment['server2'].usb_ip} up'"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
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
      pingtest_cdc(server_usb_interface)

    when $cmd.match(/_cdc_floodping/)

      #Flood ping test
      floodpingtest_cdc(server_usb_interface)

    when $cmd.match(/_cdc_iperf/)

      #iperf test
      iperftest_cdc(server_usb_interface)

    else
      $result = 1
      puts "#{$cmd} does not match any case\n"

  end

#  Remove the ethernet gadget module
  system ("sleep 5")
  command = "modprobe -r g_ether"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,1)


end


def assign_server_ip(server_usb_interface)
  command ="bash -c 'ifconfig #{server_usb_interface} #{@equipment['server2'].usb_ip} up'"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  response = @equipment['server2'].response
  if response.include?('No such device')
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Linux system ip address is not assigned properly.")
    return
  end
  command ="ping -I #{server_usb_interface} #{@equipment['dut1'].usb_ip}"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt , 5)
  system ("sleep 1")
end


#ping test
def pingtest_cdc(server_usb_interface)
  packetsize = [64,4096,65500]
  assign_server_ip(server_usb_interface) 
  packetsize.each { |psize| 
  
  #Ping from DUT to host

  command ="ping -c 10 #{@equipment['server2'].usb_ip} -s #{psize}"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,15)
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
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,15)
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


# Flood ping test
def floodpingtest_cdc(server_usb_interface)
  packetsize = [64,4096,65500]
  assign_server_ip(server_usb_interface)
  packetsize.each { |psize|

  #Flood ping from host to DUT

  command="ping -f -c 10 #{@equipment['dut1'].usb_ip} -s #{psize}"
  @equipment['server2'].send_sudo_cmd(command, @equipment['server2'].prompt,15)
  response = @equipment['server2'].response
  if response.include?('0% packet loss')
    puts "Flood ping from host to DUT is successful "
  else
    $result = 1
    set_result(FrameworkConstants::Result[:fail], "Flood ping from host to DUT is failed.")
    return
  end

  }
end


#iperf test
def iperftest_cdc(server_usb_interface)

#  iperf test from host to DUT
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
    set_result(FrameworkConstants::Result[:fail], "iperf application initialisation failed.")  
    return 
  end

  command="iperf -c #{@equipment['dut1'].usb_ip} -w #{wsize}K -d -t 60"
  @equipment['server2'].send_cmd(command, @equipment['server2'].prompt,65)
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

#  iperf test from DUT to host

  puts "iperf test from dut to host is going to start"
  windowsize = [8,16,32,64,128]
  assign_server_ip(server_usb_interface)
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

  command="iperf -c #{@equipment['server2'].usb_ip} -w #{wsize}K -d -t 60"
  @equipment['dut1'].send_cmd(command, @equipment['dut1'].prompt,65)
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
