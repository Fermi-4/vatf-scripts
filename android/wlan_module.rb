require File.dirname(__FILE__)+'/android_test_module'


module WlanModule
include AndroidTest

def run_wlan_test(test_seq, server = @equipment['server1'],initial_bw,flag)
  pass_fail = 0
  mean_bw  = 0
  send_events_for("__home__")
  net_id = -1
  test_seq.each do |action|
    case action.strip.downcase
      when 'add'
         puts "Adding and configuring network #{@test_params.params_chan.ssid[0]}"
         #Configuration as explained in wpa_supplicant.conf manual for testing purposes (man wpa_supplicant.conf)
         #5. Catch  all example that allows more or less all configuration modes.
         # The configuration options are used based on what security policy  is
         # used  in  the  selected  SSID. This is mostly for testing and is not
         # recommended for normal use.

         # ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel
         # network={pass_fail
         #      ssid="example"
         #      scan_ssid=1
         #      key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
         #      pairwise=CCMP TKIP
         #      group=CCMP TKIP WEP104 WEP40
         #      psk="very secret passphrase"
         #      eap=TTLS PEAP TLS
         #      identity="user@example.com"
         #      password="foobar"
         #      ca_cert="/etc/cert/ca.pem"
         #      client_cert="/etc/cert/user.pem"
         #      private_key="/etc/cert/user.prv"
         #      private_key_passwd="password"
         #      phase1="peaplabel=0"
         #      phase2="auth=MSCHAPV2"
         #      ca_cert2="/etc/cert/ca2.pem"
         #      client_cert2="/etc/cer/user.pem"
         #      private_key2="/etc/cer/user.prv"
         #      private_key2_passwd="password"
         # }
        send_adb_cmd("shell wpa_cli add_network")
        net_id = get_net_id(nil)
        send_adb_cmd("shell wpa_cli set_network #{net_id} ssid '\\\"#{@test_params.params_chan.ssid[0]}\\\"'")
        send_adb_cmd("shell wpa_cli set_network #{net_id} scan_ssid 1")
        send_adb_cmd("shell wpa_cli set_network #{net_id} key_mgmt #{@test_params.params_chan.key_mgmt[0].upcase}")
        send_adb_cmd("shell wpa_cli set_network #{net_id} priority 1")
        send_adb_cmd("shell wpa_cli set_network #{net_id} psk '\\\"#{@test_params.params_chan.psk[0].strip}\\\"'") if @test_params.params_chan.instance_variable_defined?(:@psk)
        send_adb_cmd("shell wpa_cli set_network #{net_id} auth_alg #{@test_params.params_chan.auth_alg[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@auth_alg)
        send_adb_cmd("shell wpa_cli set_network #{net_id} wep_key0 #{@test_params.params_chan.wep_key0[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@wep_key0)
        send_adb_cmd("shell wpa_cli set_network #{net_id} wep_key1 #{@test_params.params_chan.wep_key1[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@wep_key1)
        send_adb_cmd("shell wpa_cli set_network #{net_id} wep_key2 #{@test_params.params_chan.wep_key2[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@wep_key2)
        send_adb_cmd("shell wpa_cli set_network #{net_id} wep_key3 #{@test_params.params_chan.wep_key3[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@wep_key3)
        send_adb_cmd("shell wpa_cli set_network #{net_id} wep_tx_keyidx #{@test_params.params_chan.wep_tx_keyidx[0].strip}") if @test_params.params_chan.instance_variable_defined?(:@wep_tx_keyidx)
 
# Commented out since 820.1x is not required
#        if (@test_params.params_chan.sec_type[0].strip.downcase == "802.1x")
#          send_adb_cmd("she#{iface}ll wpa_cli set_network #{net_id} pairwise CCMP TKIP")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} group CCMP TKIP WEP104 WEP40")
#          send_adb_cmd("shewpa_cli set_network 0 scan_ssid 1 2>ll wpa_cli set_network #{net_id} eap TTLS PEAP TLS MSCHAPV2 GTC")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} identity \"#{@test_params.params_chan.identity[0].strip}\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} anonymous_identity  \"#{@test_params.params_chan.identity[0].strip}\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} password \"#{@test_params.params_chan.password[0].strip}\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} ca_cert \"/ca.pem\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} client_cert \"/user.pem\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} private_key \"/user.prv\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} private_key_passwd \"#{@test_params.params_chan.prv_key_password[0].strip}\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} phase1 \"peaplabel=0\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} phase2 \"auth=#{@test_params.params_chan.authentication[0].upcase}\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} ca_cert2 \"/ca.pem\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} client_cert2 \"/user.pem\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} private_key2= \"/user.prv\"")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} private_key2_passwd \"#{@test_params.params_chan.prv_key2_password[0].strip}\"")
#        end
      when 'remove'
        puts "Removing network #{@test_params.params_chan.ssid[0]}"
        send_adb_cmd("shell wpa_cli remove_network #{net_id}")
      when 'remove_all'
        puts "Removing all configured networks"
        get_nets_ids.each do |current_id|
          send_adb_cmd("shell wpa_cli remove_network #{current_id}")
        end
        current_trial = 0
        while !get_wlan_state.include?('stop') && !get_wlan_state.include?('') && !get_wlan_state.include?('failed') && current_trial < 5
          sleep 10
          current_trial += 1
        end
        raise "Unable to remove configured networks from dut" if current_trial >= 5 
      when 'enable'
        puts "Enabling network #{@test_params.params_chan.ssid[0]}"
        send_adb_cmd("logcat -c")
        send_adb_cmd("shell wpa_cli enable_network #{net_id}")
        current_trial = check_wifi_connected
        raise "Unable to enable configured network in dut" if current_trial >= 5
      when 'disable'
        puts "Disabling network #{@test_params.params_chan.ssid[0]}"
        send_adb_cmd("shell wpa_cli disable_network #{net_id}")
      when 'select'
        puts "Selecting network #{@test_params.params_chan.ssid[0]}"
        net_id = get_net_id(@test_params.params_chan.ssid[0])
	      send_adb_cmd("logcat -c")
        send_adb_cmd("shell wpa_cli select_network #{net_id}")
	      current_trial = check_wifi_connected
        raise "Unable to select configured networks in dut" if current_trial >= 5 
      when 'scan_results'
        send_adb_cmd("shell wpa_cli scan_results")
      when 'scan_results'
        send_adb_cmd("shell wpa_cli scan_results")
      when 'test'
          puts "RUNNING Wlan test "
          begin 
          bw =[]
          time        = @test_params.params_control.time[0]
          port_number = @test_params.params_control.port_number[0].to_i
          ip_ver      = @test_params.params_control.ip_version[0]
          # Start netserver on the Host on a tcp port with following conditions:
          #   1) It is equal or higher that port_number specified in the test matrix
          #   2) It is not being used
          while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
            port_number = port_number + 2
          end
          puts "STARTING NETSERVER ........"
          puts "netserver -p #{port_number} -#{ip_ver}"
          server.send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
          
          dut_ip = get_dut_ip_addr
          raise 'Dut does not have an IP address configured for the wifi interface' if dut_ip == '' || dut_ip == '0.0.0.0'
          server_lan_ip = get_server_lan_ip(dut_ip)
          raise 'Server/TEE does not have and ip address configured in the wifi LAN' if server_lan_ip == ''
          
          # Start netperf on the Target
          sys_stats = nil
          0.upto(1) do |iter|
            netperf_thread = Thread.new {
              @test_params.params_control.buffer_size.each do |bs|
                data = send_adb_cmd "shell netperf -H #{server_lan_ip} -l #{time} -p #{port_number} -- -s #{bs}"
                bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f if iter == 0
              end
            }
           netperf_thread.join
         end
         ensure
         if bw.length == 0 
            set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated  Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf. Or System resume failed ')
             puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
         else
            mean_bw = mean(bw)
            if flag == true 
               if mean_bw > initial_bw  
                puts "Test Passed: On presuspend BW=#{mean_bw} greater than minimum  BW=#{initial_bw} " 
                pass_fail = 1 
              else
               puts "Test Fail: On presuspend BW=#{mean_bw} less than minimum  BW=#{initial_bw} " 
              end
          else 
              if mean_bw > (initial_bw - 2)  
                puts "Test Passed: On resume BW=#{mean_bw} equal presuspend BW=#{initial_bw} " 
                pass_fail = 1 
              else
               puts puts "Test Fail: On resume BW=#{mean_bw} is less than presuspend BW=#{initial_bw} "
              end
          end 
         end
        # Kill netserver process on the host
        procs = send_host_cmd "ps ax | grep netserver"
        procs.scan(/^\s*(\d+)\s+.+?netserver\s+\-p\s+#{port_number}\s+\-#{ip_ver}/i) {|pid|
        server.send_sudo_cmd("kill -9 #{pid[0]}") 
        }
      end 
   else 
     raise "Action #{action} is not supported"
  end 
 end 
 ensure
  return [mean_bw,pass_fail]
end


def get_available_networks
  results = {}
  net_results = send_adb_cmd("shell wpa_cli scan_results").lines
  net_results.each do |current_line|
    if current_line.match(/[\w:]+\s+\d+\s+\d+\s+([\w\-\+\[\]]+)*\s+(.*)/)
      net_info = current_line.split(/\s+/)
      if net_info.length > 4
        results[net_info[-1]] = {"bssid" => net_info[0].strip, "freq" => net_info[1].strip, "sig_level" => net_info[2].strip, 
                                  "flags" => net_info[3].strip, "ssid" => net_info[4].strip} 
      elsif net_info.length > 3 && !net_info[-1].strip.match(/\[[\-\w+]+\]/)
        results[net_info[-1]] = {"bssid" => net_info[0].strip, "freq" => net_info[1].strip, "sig_level" => net_info[2].strip, 
                                 "flags" => nil, "ssid" => net_info[3].strip}
      end
    end
  end
  results
end

def net_connected?(net_name)
  nets_info = send_adb_cmd("shell wpa_cli list_networks").lines
  nets_info.each do |current_net|
    net_info = current_net.split(/\s+/)
    return true if net_info[1].downcase == net_name.strip.downcase && net_info[3].downcase == '[current]'
  end
  false
end

def get_wifi_iface
  send_adb_cmd("shell getprop wifi.interface").strip
end

def get_net_id(ssid)
  net_list = send_adb_cmd("shell wpa_cli list_networks")
  nets_info = net_list.lines.to_a
  net_id = -1 
  if ssid
    net_id = nets_info[-1].split(/\s+/)[0]
  else
    nets_info.each do |current_info|
      net_id = current_info.split(/\s+/)[0] if current_info.match(/^\d+\s+#{ssid}.*/)
    end
  end
  net_id
end

def get_nets_ids
  net_list = send_adb_cmd("shell wpa_cli list_networks")
  nets_info = net_list.lines.to_a
  net_ids = []
  nets_info.each do |current_info|
    net_ids << current_info.split(/\s+/)[0] if !current_info.match(/^(using interface)|(network id).*/i) 
  end
  net_ids
end

def get_perf_pretty_str(bw)
  perfdata = []
  bsizes = @test_params.params_control.buffer_size
  result = "Buffer Size \t Throughput \n"
  bsizes.length.times {|i|
    result= result + "#{bsizes[i]}\t#{bw[i]}\n"
    perfdata << {'name'=> "Throughput_#{bsizes[i]}", 'value' => bw[i].to_f, 'units' => 'Mb/s'}
  }
  [result,perfdata]
end


def get_dut_ip_addr
  iface = get_wifi_iface
  send_adb_cmd("shell getprop dhcp.#{iface}.ipaddress").strip 
end

def get_wlan_state
  iface = get_wifi_iface
  send_adb_cmd("shell getprop dhcp.#{iface}.reason").strip
end

def get_server_lan_ip(dut_ip)
ip_addr = ''
  @equipment['server1'].send_cmd("ifconfig")
  #          inet addr:158.218.103.11  Bcast:158.218.103.255  Mask:255.255.254.0
   @equipment['server1'].response.lines.each do |current_line|
    if (line_match = current_line.match(/^\s+inet\s+addr:(#{dut_ip.gsub('.','\.').sub(/\d+$/,'\d+')})\s+Bcast:.*/))
      ip_addr = line_match.captures[0]
    end
  end
  ip_addr
end

def mean(a)
 a.sum.to_f / a.size
end

def check_wifi_connected
  iface = get_wifi_iface
  current_trial = 0
  wifi_connected_comp, wifi_connected_regex = CmdTranslator.get_android_cmd({'cmd'=>'wifi_connected_ack_info', 'version'=>@equipment['dut1'].get_android_version })
  while !send_adb_cmd("logcat -d -s #{wifi_connected_comp}").match(wifi_connected_regex) && current_trial < 5
    sleep 20
    puts send_adb_cmd("shell getprop dhcp.#{iface}.ipaddress")
    current_trial += 1
  end
  current_trial
end


def enable_wlan
  send_events_for(['__menu__', '__home__'])
  send_adb_cmd("shell am start -a android.settings.WIFI_SETTINGS")
  netcfg = send_adb_cmd("shell netcfg")
  iface = get_wifi_iface.split(':')[0]
  if !netcfg.match(/#{iface}/i) 
    send_adb_cmd("shell svc wifi enable")
    sleep 5
  end
  netcfg_up = send_adb_cmd("shell netcfg")
  raise "Unable to turn on wifi" if !netcfg_up.match(/#{iface}/i) 
end

end 
