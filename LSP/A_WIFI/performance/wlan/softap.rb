require File.dirname(__FILE__)+'/../../../TARGET/dev_test2'

# Requires a wlan_client - which is nothing but a linux machine with a wifi adapter. Sudo access is required. Linux server machine can be used as linux_wlan_client. Sample bench entry for a ralink-based adapter provided below. If adapter uses a different interface name, configure corresponding bench entry accordingly.
##Linux WLAN Client - PC which has a wifi adapter
#linux_wlan_client = EquipmentInfo.new("linux_wlan_client")
#linux_wlan_client.driver_class_name = "LinuxLocalHostDriver"
#linux_wlan_client.telnet_ip = '128.247.106.208'
#linux_wlan_client.telnet_port = 23
#linux_wlan_client.telnet_login = 'root'
#linux_wlan_client.telnet_passwd = 'root'
#linux_wlan_client.prompt = /aparnab@aparnab-desktop/m
#linux_wlan_client.boot_prompt = /\$/m
#linux_wlan_client.params = {'wlan_interface'=>'ra0'}

def setup
  super
  enable_softap
  connect_to_softap
  run_quick_test
end

def enable_softap
  #steps to enable softap on dut
  @equipment['dut1'].send_cmd("ls /etc/*.conf")
  raise 'Dut does not have hostapd.conf in etc folder. Please check path specified. ' if !@equipment['dut1'].response.index("hostapd.conf")
  # make backup and ensure it is removed during cleanup
  @equipment['dut1'].send_cmd("cp /etc/hostapd.conf /home/root/hostapd.conf")
  # modify the SSID in conf file to be unique for test
  @equipment['dut1'].send_cmd("sed -i \"s|ssid=TexasInstruments_0001|ssid=TexasInstruments_softap_test|g\" /home/root/hostapd.conf ")
  # add check to see that aptest.sh is present
  @equipment['dut1'].send_cmd("ls /usr/bin/*.sh")
  raise 'Dut does not have aptest.sh in /usr/bin folder. Please check path specified. ' if !@equipment['dut1'].response.index("aptest.sh")
  # make copy of aptest and modify to point to hostapd.conf created above
  @equipment['dut1'].send_cmd("cp /usr/bin/aptest.sh /usr/bin/aptest_temp.sh")
  @equipment['dut1'].send_cmd("sed -i \"s|hostapd -B /etc/hostapd.conf|hostapd -B /home/root/hostapd.conf|g\" /usr/bin/aptest_temp.sh ")
end

def run_softap
  @equipment['dut1'].send_cmd("killall hostapd")
  @equipment['dut1'].send_cmd(". /usr/bin/aptest_temp.sh&", @equipment['dut1'].prompt, 5)
end

def connect_to_softap
  #steps to prepare wpa_supplicant conf file to be able to connect client's wireless interface to softap on dut 
  wpa_supplicant_conf_file = File.new(File.join( SiteInfo::LINUX_TEMP_FOLDER,'wpa_supplicant.conf'),'w')
  wpa_supplicant_conf_file.puts("ctrl_interface=/etc/wpa_supplicant")
  wpa_supplicant_conf_file.puts("network={")
  wpa_supplicant_conf_file.puts("ssid=\"TexasInstruments_softap_test\"")
  wpa_supplicant_conf_file.puts("key_mgmt=NONE")
  wpa_supplicant_conf_file.puts("}")
  wpa_supplicant_conf_file.close
end

def run_client
  # connect wlan client on PC to AP on target DUT
  wlan_interface = get_client_interface
  @equipment['wlan_client'].send_sudo_cmd("ifconfig #{wlan_interface} down", @equipment['wlan_client'].prompt, 10)
  @equipment['wlan_client'].send_sudo_cmd("rm /etc/wpa_supplicant/#{wlan_interface}", @equipment['wlan_client'].prompt, 10)
  @equipment['wlan_client'].send_sudo_cmd("killall wpa_supplicant")
  @equipment['wlan_client'].send_sudo_cmd("wpa_supplicant -Dwext -i#{wlan_interface} -d -B -c #{File.join( SiteInfo::LINUX_TEMP_FOLDER,'wpa_supplicant.conf')}", @equipment['wlan_client'].prompt, 10)
  @equipment['wlan_client'].send_sudo_cmd("dhclient #{wlan_interface}", @equipment['wlan_client'].prompt, 30)
end

def run_quick_test
  run_softap
  run_client
  ap_ip =  get_dut_ip_addr
  client_ip = get_client_ip
  @equipment['dut1'].send_cmd("ping #{client_ip} -c 3")
  @equipment['wlan_client'].send_cmd("ping #{ap_ip} -c 3",@equipment['wlan_client'].prompt,30)
end

def is_iperf_running?(type)
  #test_cmd = test_type.match(/udp/i) ? "iperf -s -u -B #{client_ip} -w 128k &" : "iperf -s -B #{client_ip}&"
  #test_regex = type.match(/udp/i) ? /iperf\s+\-s\s+\-u/i : /iperf\s+\-s\s*$/i
  test_regex = type.match(/udp/i) ? /iperf\s+\-s\s+\-u/i : /iperf\s+\-s/i
  @equipment['wlan_client'].send_cmd("ps ax", @equipment['wlan_client'].prompt, 10)
  if !(@equipment['wlan_client'].response.match(test_regex))
    return false
  else
    return true
  end
end

def run
  #default is 1 iteration
  # if iteration is defined take that value
  num_of_iterations = 1
  if @test_params.params_control.instance_variable_defined?(:@num_of_iterations)
    num_of_iterations = @test_params.params_control.num_of_iterations[0].to_i 
  end
  loop_count=0
  while (loop_count < num_of_iterations)
    puts "ITERATION IS #{loop_count}\n"
    run_start_stats
    run_softap
    run_client
    run_perf
    run_stop_stats
    loop_count = loop_count+1
  end
  run_save_results(true)
end

def run_perf
  test_type = @test_params.params_control.type[0]
  client_ip = get_client_ip
  test_cmd = test_type.match(/udp/i) ? "iperf -s -u -B #{client_ip} -w 128k &" : "iperf -s -B #{client_ip}&"
  if !is_iperf_running?(test_type)
    @equipment['wlan_client'].send_cmd_nonblock(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)
  end
  if !is_iperf_running?(test_type)
    raise "iperf can not be started. Please make sure iperf is installed at the #{client_ip} wlan_client PC"    
  end
   log_file_name = File.join(@linux_temp_folder, 'test.log') 
   @equipment['wlan_client'].send_cmd("mkdir -p #{@linux_temp_folder}", @equipment['wlan_client'].prompt)
   log_file = File.new(log_file_name,'w')
   time = @test_params.params_control.time[0].to_i
   test_type = @test_params.params_control.type[0]
   dut_ip    = get_dut_ip_addr
   raise 'Dut does not have an IP address configured for the wifi interface' if dut_ip == nil || dut_ip == '0.0.0.0'
   client_ip = get_client_ip
   raise 'Client does not have and ip address configured in the wifi LAN' if client_ip == ''
          
   # Start iperf on the Target
   if test_type.match(/tcp/i)
     @equipment['dut1'].send_cmd("iperf -c #{client_ip} -m -f M -d -t #{time} -w #{@test_params.params_control.buffer_size[0].to_i/1024}K", @equipment['dut1'].prompt, time*2)  ##Dummy comment to make eclipse happy"
   else
     @equipment['dut1'].send_cmd("iperf -c #{client_ip} -w 128k -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{time} -b #{@test_params.params_control.bw[0]}", @equipment['dut1'].prompt, time*2)  ##Dummy comment to make eclipse happy"
   end
   log_file.write(@equipment['dut1'].response)
   ensure
   log_file.close if log_file != nil
end  
  
def run_determine_test_outcome(return_non_zero)
  perf_data = get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)
  test_type = @test_params.params_control.type[0]
  if test_type.match(/tcp/i)
    perf_data.each{|d|
      sum = 0.0
      d['value'].each {|v| sum += v}
      d['value'] = sum
    }  
  end
  
  if perf_data == nil || perf_data.size == 0
    return [FrameworkConstants::Result[:fail], 
            "Performance data could not be captured \n",
            perf_data]
  else
    return [FrameworkConstants::Result[:pass],
            "Test passed \n",
            perf_data]
  end
end

def get_wifi_iface
  @equipment['dut1'].send_cmd("ls /sys/class/net/ | awk '/.*wlan.*/{print $1}' | head -1", @equipment['dut1'].prompt)
  @equipment['dut1'].response.match(/(wlan\w+)/).captures[0]
end

def get_dut_ip_addr
  get_ip_addr('dut1', 'wlan')
end

def get_client_ip
  ip_addr = ''
  wlan_interface = get_client_interface
  @equipment['wlan_client'].send_cmd("ifconfig #{wlan_interface}|grep \"inet addr\"")
  ip_addr = @equipment['wlan_client'].response.match(/inet addr:\d*.\d*.\d*.\d*/i).to_s.sub!("inet addr:",'')
  ip_addr
end

def get_client_interface
   raise 'Add and install wlan adapter on wlan_client PC and define the interface in bench file. ' if !@equipment['wlan_client'].params['wlan_interface']
   return @equipment['wlan_client'].params['wlan_interface']
end

def clean
  super
  # remove hostapd and aptest temp files in target
  # remove temp file on client
  # kill instances of iperf on both client and server
  @equipment['dut1'].send_cmd("rm /home/root/hostapd.conf")
  @equipment['dut1'].send_cmd("rm /usr/bin/aptest_temp.sh")
  wpa_supplicant_conf_file = File.join( SiteInfo::LINUX_TEMP_FOLDER,'wpa_supplicant.conf')
  @equipment['wlan_client'].send_cmd("rm #{wpa_supplicant_conf_file}", @equipment['wlan_client'].prompt, 10)
  @equipment['wlan_client'].send_sudo_cmd("killall iperf", @equipment['wlan_client'].prompt, 10)
  @equipment['dut1'].send_cmd("killall iperf", @equipment['dut1'].prompt, 10)
end
