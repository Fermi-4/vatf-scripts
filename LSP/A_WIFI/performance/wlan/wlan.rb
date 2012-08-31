require File.dirname(__FILE__)+'/../../../TARGET/dev_test2'

# Note: If testing 802.1x a radius server must be configured install and configured in the TEE and the access point
def setup
  super
  test_type = @test_params.params_control.type[0]
  test_cmd = test_type.match(/udp/i) ? "iperf -s -u -w 128k &" : "iperf -s &"
  if !is_iperf_running?(test_type)
    @equipment['server1'].send_cmd_nonblock(test_cmd, /Server\s+listening.*?#{test_type}\sport.*?/i, 10)
  end
  if !is_iperf_running?(test_type)
    raise "iperf can not be started. Please make sure iperf is installed at the #{@equipment['server1'].telnet_ip} server"    
  end
  enable_wlan
end

def is_iperf_running?(type)
  test_regex = type.match(/udp/i) ? /iperf\s+\-s\s+\-u/i : /iperf\s+\-s\s*$/i
  @equipment['server1'].send_cmd("ps ax", @equipment['server1'].prompt, 10)
  if !(@equipment['server1'].response.match(test_regex))
    return false
  else
    return true
  end
end

def run_wlan_test(test_seq)
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
         # network={
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
        @equipment['dut1'].send_cmd(" wpa_cli add_network", @equipment['dut1'].prompt)
        net_id = get_net_id(nil)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} ssid \\\"#{@test_params.params_chan.ssid[0]}\\\"", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} scan_ssid 1", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} key_mgmt #{@test_params.params_chan.key_mgmt[0].upcase}", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} priority 1", @equipment['dut1'].prompt)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} psk \\\"#{@test_params.params_chan.psk[0].strip}\\\"", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@psk)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} auth_alg #{@test_params.params_chan.auth_alg[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@auth_alg)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} wep_key0 #{@test_params.params_chan.wep_key0[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@wep_key0)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} wep_key1 #{@test_params.params_chan.wep_key1[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@wep_key1)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} wep_key2 #{@test_params.params_chan.wep_key2[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@wep_key2)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} wep_key3 #{@test_params.params_chan.wep_key3[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@wep_key3)
        @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} wep_tx_keyidx #{@test_params.params_chan.wep_tx_keyidx[0].strip}", @equipment['dut1'].prompt) if @test_params.params_chan.instance_variable_defined?(:@wep_tx_keyidx)

        # Commented out since 820.1x is not required
        #        if (@test_params.params_chan.sec_type[0].strip.downcase == "802.1x")
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} pairwise CCMP TKIP", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} group CCMP TKIP WEP104 WEP40", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} eap TTLS PEAP TLS MSCHAPV2 GTC", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} identity \"#{@test_params.params_chan.identity[0].strip}\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} anonymous_identity  \"#{@test_params.params_chan.identity[0].strip}\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} password \"#{@test_params.params_chan.password[0].strip}\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} ca_cert \"/ca.pem\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} client_cert \"/user.pem\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} private_key \"/user.prv\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} private_key_passwd \"#{@test_params.params_chan.prv_key_password[0].strip}\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} phase1 \"peaplabel=0\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} phase2 \"auth=#{@test_params.params_chan.authentication[0].upcase}\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} ca_cert2 \"/ca.pem\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} client_cert2 \"/user.pem\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} private_key2= \"/user.prv\"", @equipment['dut1'].prompt)
        #          @equipment['dut1'].send_cmd(" wpa_cli set_network #{net_id} private_key2_passwd \"#{@test_params.params_chan.prv_key2_password[0].strip}\"", @equipment['dut1'].prompt)
        #        end
      when 'remove'
        puts "Removing network #{@test_params.params_chan.ssid[0]}"
        @equipment['dut1'].send_cmd(" wpa_cli remove_network #{net_id}", @equipment['dut1'].prompt)
        
      when 'remove_all'
        puts "Removing all configured networks"
        get_nets_ids.each do |current_id|
          @equipment['dut1'].send_cmd(" wpa_cli remove_network #{current_id}", @equipment['dut1'].prompt)
        end
        iface = get_wifi_iface
        @equipment['dut1'].send_cmd(" ifdown #{iface}", @equipment['dut1'].prompt, 30)
	@equipment['dut1'].send_cmd(" ifup #{iface}", @equipment['dut1'].prompt, 30)

        current_trial = 0
        while get_dut_ip_addr != nil && current_trial < 5
          sleep 5
          current_trial += 1
        end
        raise "Unable to remove configured networks from dut" if current_trial >= 5 
      
      when 'enable'
        puts "Enabling network #{@test_params.params_chan.ssid[0]}"
        @equipment['dut1'].send_cmd(" wpa_cli enable_network #{net_id}", @equipment['dut1'].prompt)
	iface = get_wifi_iface
        @equipment['dut1'].send_cmd(" ifup #{iface}", @equipment['dut1'].prompt, 30)
        current_trial = 0
        while get_dut_ip_addr == nil && current_trial < 5
          sleep 20
          current_trial += 1
        end
        raise "Unable to enable configured network in dut" if current_trial >= 5
        # for wlan link power information
        @equipment['dut1'].send_cmd("iw #{iface} link", @equipment['dut1'].prompt, 30)
        
      when 'disable'
        puts "Disabling network #{@test_params.params_chan.ssid[0]}"
        @equipment['dut1'].send_cmd(" wpa_cli disable_network #{net_id}", @equipment['dut1'].prompt)
        
      when 'select'
        puts "Selecting network #{@test_params.params_chan.ssid[0]}"
        net_id = get_net_id(@test_params.params_chan.ssid[0])
        @equipment['dut1'].send_cmd(" wpa_cli select_network #{net_id}", @equipment['dut1'].prompt)
	#iface = get_wifi_iface
        #@equipment['dut1'].send_cmd("ifup #{iface}", @equipment['dut1'].prompt)
        current_trial = 0
        while get_dut_ip_addr == nil && current_trial < 5
          sleep 20
          current_trial += 1
        end
        raise "Unable to select configured networks in dut" if current_trial >= 5
        
      when 'scan_results'
        @equipment['dut1'].send_cmd(" wpa_cli scan_results", @equipment['dut1'].prompt)
        
      when 'test'
        begin
          log_file_name = File.join(@linux_temp_folder, 'test.log') 
          @equipment['server1'].send_cmd("mkdir -p #{@linux_temp_folder}", @equipment['server1'].prompt)
          log_file = File.new(log_file_name,'w')
          time      = @test_params.params_control.time[0].to_i
          test_type = @test_params.params_control.type[0]
          dut_ip    = get_dut_ip_addr
          raise 'Dut does not have an IP address configured for the wifi interface' if dut_ip == nil || dut_ip == '0.0.0.0'
          server_lan_ip = get_server_lan_ip(dut_ip)
          raise 'Server/TEE does not have and ip address configured in the wifi LAN' if server_lan_ip == ''
          
          # Start iperf on the Target
          if test_type.match(/tcp/i)
            @equipment['dut1'].send_cmd("iperf -c #{server_lan_ip} -m -f M -d -t #{time} -w #{@test_params.params_control.buffer_size[0].to_i/1024}K", @equipment['dut1'].prompt, time*2)  ##Dummy comment to make eclipse happy"
          else
            @equipment['dut1'].send_cmd("iperf -c #{server_lan_ip} -w 128k -l #{@test_params.params_control.packet_size[0]} -f M -u -t #{time} -b #{@test_params.params_control.bw[0]}", @equipment['dut1'].prompt, time*2)  ##Dummy comment to make eclipse happy"
          end
        
          log_file.write(@equipment['dut1'].response)
          
        ensure
          log_file.close if log_file != nil
           
        end  
      else
        raise "Action #{action} is not supported"
    end
  end
   
ensure
  
end

def run
  run_start_stats
  run_wlan_test(@test_params.params_chan.test_sequence)
  run_stop_stats
  run_save_results(true)
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

def get_available_networks
  results = {}
  @equipment['dut1'].send_cmd(" wpa_cli scan_results", @equipment['dut1'].prompt)
  net_results = @equipment['dut1'].response.lines
  net_results.each do |current_line|
    puts current_line
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
  @equipment['dut1'].send_cmd(" wpa_cli list_networks", @equipment['dut1'].prompt)
  nets_info = @equipment['dut1'].response.lines
  nets_info.each do |current_net|
    net_info = current_net.split(/\s+/)
    return true if net_info[1].downcase == net_name.strip.downcase && net_info[3].downcase == '[current]'
  end
  false
end

def get_wifi_iface
  @equipment['dut1'].send_cmd("ls /sys/class/net/ | awk '/.*wlan.*/{print $1}' | head -1", @equipment['dut1'].prompt)
  @equipment['dut1'].response.match(/(wlan\w+)/).captures[0]
end

def get_net_id(ssid)
  net_list = @equipment['dut1'].send_cmd(" wpa_cli list_networks", @equipment['dut1'].prompt)
  @equipment['dut1'].response.match(/(\d+)\s+#{ssid}/).captures[0]
end

def get_nets_ids
  net_list = @equipment['dut1'].send_cmd(" wpa_cli list_networks", @equipment['dut1'].prompt)
  nets_info = net_list.lines.to_a
  net_ids = []
  nets_info.each do |current_info|
    net_ids << current_info.split(/\s+/)[0] if !current_info.match(/^\s*(using interface)|(network id)|(Selected)|(wpa_cli).*/i) && !current_info.match(/#{@equipment['dut1'].prompt}/) 
  end
  net_ids
end

def get_dut_ip_addr
  get_ip_addr('dut1', 'wlan')
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

def enable_wlan
  iface = get_wifi_iface
  puts "WLAN interface is:#{iface}"
  @equipment['dut1'].send_cmd("ifconfig", /^#{iface}\s+/, 5)
  if @equipment['dut1'].timeout?
    #wpa_supplicant -Dnl80211 -i#{iface} -c/etc/wpa_supplicant.conf
    @equipment['dut1'].send_cmd("nohup wpa_supplicant -D#{@test_params.params_chan.wlan_driver[0]} -i#{iface} -c#{@test_params.params_chan.supplicant_conf_file[0]} &",/Association\s+completed/i, 10)   
  end
  @equipment['dut1'].send_cmd("ifconfig", /^#{iface}\s+/, 5)
  raise "Unable to turn on wifi" if @equipment['dut1'].timeout?
end
