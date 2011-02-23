require File.dirname(__FILE__)+'/../../android_test_module'
require File.dirname(__FILE__)+'/../../keyevents_module'

include AndroidTest
include AndroidKeyEvents
# Note: If testing 802.1x a radius server must be configured install and configured in the TEE and the access point
def setup
  self.as(AndroidTest).setup
  send_events_for(['__menu__', '__home__'])
  send_adb_cmd("shell am start -a android.settings.WIFI_SETTINGS")
  netcfg = send_adb_cmd("shell netcfg")
  iface = get_wifi_iface
  if !netcfg.match(/#{iface}/i) 
    send_events_for(['__directional_pad_up__', '__directional_pad_center__'])
    sleep 5
  end
  netcfg_up = send_adb_cmd("shell netcfg")
  raise "Unable to turn on wifi" if !netcfg_up.match(/#{iface}/i) 
  
  #@equipment['ap1'].connect({'type'=>'telnet'})
end

def run
  net_id = -1
  @test_params.params_chan.test_sequence.each do |action|
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
#          send_adb_cmd("shell wpa_cli set_network #{net_id} pairwise CCMP TKIP")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} group CCMP TKIP WEP104 WEP40")
#          send_adb_cmd("shell wpa_cli set_network #{net_id} eap TTLS PEAP TLS MSCHAPV2 GTC")
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
        while get_dut_ip_addr != '0.0.0.0' && current_trial < 5
          sleep 5
          current_trial += 1
        end
        raise "Unable to remove configured networks from dut" if current_trial >= 5 
      when 'enable'
        puts "Enabling network #{@test_params.params_chan.ssid[0]}"
        send_adb_cmd("shell wpa_cli enable_network #{net_id}")
        current_trial = 0
        while get_dut_ip_addr == '0.0.0.0' && current_trial < 5
          sleep 20
          puts send_adb_cmd("shell netcfg")
          current_trial += 1
        end
        raise "Unable to enable configured network in dut" if current_trial >= 5
      when 'disable'
        puts "Disabling network #{@test_params.params_chan.ssid[0]}"
        send_adb_cmd("shell wpa_cli disable_network #{net_id}")
      when 'select'
        puts "Selecting network #{@test_params.params_chan.ssid[0]}"
        net_id = get_net_id(@test_params.params_chan.ssid[0])
        send_adb_cmd("shell wpa_cli select_network #{net_id}")
        current_trial = 0
        while get_dut_ip_addr == '0.0.0.0' && current_trial < 5
          sleep 20
          puts send_adb_cmd("shell netcfg")
          current_trial += 1
        end
        raise "Unable to select configured networks in dut" if current_trial >= 5 
      when 'scan_results'
        send_adb_cmd("shell wpa_cli scan_results")
      when 'test'
        begin
          bw =[]
          time        = @test_params.params_control.time[0]
          port_number = @test_params.params_control.port_number[0].to_i
          ip_ver      = @test_params.params_control.ip_version[0]
          cpu_load_samples = @test_params.params_control.cpu_load_samples[0].to_i
          # Start netserver on the Host on a tcp port with following conditions:
          #   1) It is equal or higher that port_number specified in the test matrix
          #   2) It is not being used
          while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
            port_number = port_number + 2
          end
          @equipment['server1'].send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
          
          dut_ip = get_dut_ip_addr
          raise 'Dut does not have an IP address configured for the wifi interface' if dut_ip == '' || dut_ip == '0.0.0.0'
          server_lan_ip = get_server_lan_ip(dut_ip)
          raise 'Server/TEE does not have and ip address configured in the wifi LAN' if server_lan_ip == ''
          
          # Start netperf on the Target
          netperf_thread = Thread.new {
            @test_params.params_control.buffer_size.each do |bs|
              data = send_adb_cmd "shell netperf -H #{server_lan_ip} -l #{time} -p #{port_number} -- -s #{bs}"
              bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f
              puts data
            end
          }
          
          # Start top on target
          cpu_loads = []
          if @test_params.params_control.instance_variable_defined?(:@wlan_comp)
            cpu_info = ''
            cpu_load_samples = @test_params.params_control.cpu_load_samples[0].to_i
            delay = [time.to_i/cpu_load_samples,1].max
            cpu_info = send_adb_cmd("shell top -d #{delay} -n #{cpu_load_samples-1}")
            cpu_load_items = '(?:' + @test_params.params_control.wlan_comp[0] + ')'
            @test_params.params_control.wlan_comp[1..-1].each do |curr_comp|
              cpu_load_items += '|(?:' + curr_comp + ')'
            end
            cpu_loads = cpu_info.scan(/\d+\s+(\d+)(%)\s+\w+\s+\d+\s+\d+K\s+\d+K\s+\w+\s+\w+\s+(#{cpu_load_items})/im)
          end
          
          netperf_thread.join
          
          ensure
            if bw.length == 0 || (@test_params.params_control.instance_variable_defined?(:@wlan_comp) && cpu_loads.length == 0)
              set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated or cpu load could not be obtained. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf. Also verify that top includes the values specified in test parameter wlan_comp if wlan_comp was specified')
              puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
            else
              min_bw = @test_params.params_control.min_bw[0].to_f
              pretty_str, perfdata = get_perf_pretty_str(bw)
              
              if @test_params.params_control.instance_variable_defined?(:@wlan_comp)
                loads_results = Hash.new {|h,k| h[k] = {'name' => k+'_load', 'value' => [], 'units' => ''}}
                cpu_loads.each do |current_load|
                  loads_results[current_load[-1]]['value'] << current_load[0]
                  loads_results[current_load[-1]]['units'] = current_load[1]
                end
                perfdata = perfdata + loads_results.values
              end
              
              if mean(bw) > min_bw 
                set_result(FrameworkConstants::Result[:pass], pretty_str, perfdata)
                puts "Test Passed: AVG Throughput=#{mean(bw)} \n #{pretty_str}"
              else
                set_result(FrameworkConstants::Result[:fail], "Performance is less than #{min_bw} Mb/s. AVG Throughput=#{mean(bw)} \n #{pretty_str}", perfdata)
                puts "Test Failed: Performance is less than #{min_bw} Mb/s. AVG Throughput=#{mean(bw)} \n #{pretty_str}"
              end
            end
            # Kill netserver process on the host
            procs = send_host_cmd "ps ax | grep netserver"
            procs.scan(/^\s*(\d+)\s+.+?netserver\s+\-p\s+#{port_number}\s+\-#{ip_ver}/i) {|pid|
              @equipment['server1'].send_sudo_cmd("kill -9 #{pid[0]}") 
            }
        end  
      else
        raise "Action #{action} is not supported"
    end
  end
   
ensure
  
end

def get_available_networks
  results = {}
  net_results = send_adb_cmd("shell wpa_cli scan_results").lines
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
  nets_info = send_adb_cmd("shell wpa_cli list_networks").lines
  nets_info.each do |current_net|
    net_info = current_net.split(/\s+/)
    return true if net_info[1].downcase == net_name.strip.downcase && net_info[3].downcase == '[current]'
  end
  false
end

def get_wifi_iface
  sys_props = send_adb_cmd("shell getprop").lines
  iface = ''
  sys_props.each do |current_line|
     if (iface_info = current_line.match(/\[wifi.interface\]:\s+\[(.*?)\]/))
        iface = iface_info.captures[0].strip
     end
  end
  iface 
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
  addr = ''
  nets_ips = send_adb_cmd("shell netcfg")
  nets_ips.lines.each do |current_line|
    addr = current_line.split(/\s+/)[2] if current_line.match(/^#{iface}\s+(up)|(down)\s+[\d\.]{7,15}\s+.*/i)
  end
  addr 
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
