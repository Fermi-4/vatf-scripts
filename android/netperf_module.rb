module NetperfModule
def start_netperf()
          bw =[]
          time        = @test_params.params_chan.time[0]
          port_number = @test_params.params_chan.port_number[0].to_i
          ip_ver      = @test_params.params_chan.ip_version[0]
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
   #       netperf_thread = Thread.new {
            @test_params.params_chan.buffer_size.each do |bs|
              puts "shell netperf -H #{server_lan_ip} -l #{time} -p #{port_number} -- -s #{bs}"
              data = send_adb_cmd "shell netperf -H #{server_lan_ip} -l #{time} -p #{port_number} -- -s #{bs}"
              bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f
            end
    #      }
   #netperf_thread.join
  # I should put the thread in my main file  
  if bw.length == 0 
              set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated or cpu load could not be obtained. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf. Also verify that top includes the values specified in test parameter wlan_comp if wlan_comp was specified')
              puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
end 
  return mean(bw) 
end #function end

def start_lan_netperf()
          bw =[]
          time        = @test_params.params_chan.time[0]
          port_number = @test_params.params_chan.port_number[0].to_i
          ip_ver      = @test_params.params_chan.ip_version[0]
          # Start netserver on the Host on a tcp port with following conditions:
          #   1) It is equal or higher that port_number specified in the test matrix
          #   2) It is not being used
          while /^tcp.*:#{port_number}/im.match(send_host_cmd "netstat -a | grep #{port_number}") do
            port_number = port_number + 2
          end
          @equipment['server1'].send_sudo_cmd("netserver -p #{port_number} -#{ip_ver}")
          
	   # Start netperf on the Target
	  @test_params.params_chan.buffer_size.each do |bs|
	    data = send_adb_cmd "shell netperf -H #{@equipment['server1'].telnet_ip} -l #{time} -p #{port_number} -- -s #{bs}"
	    bw << /^\s*\d+\s+\d+\s+\d+\s+[\d\.]+\s+([\d\.]+)/m.match(data).captures[0].to_f
	  end

   #netperf_thread.join
  # I should put the thread in my main file  
  if bw.length == 0 
              set_result(FrameworkConstants::Result[:fail], 'Netperf data could not be calculated or cpu load could not be obtained. Verify that you have netperf installed in your host machine by typing: netperf -h. If you get an error, you need to install netperf. On a ubuntu system, you may type: sudo apt-get install netperf. Also verify that top includes the values specified in test parameter wlan_comp if wlan_comp was specified')
              puts 'Test failed: Netperf data could not be calculated, make sure Host PC has netperf installed and that the DUT is running'
end 
  return mean(bw) 
end #function end





def get_dut_ip_addr
  iface = get_wifi_iface
  addr = ''
  nets_ips = send_adb_cmd("shell netcfg")
  puts "NETS_IPS #{nets_ips}"
  nets_ips.lines.each do |current_line|
     puts "LINE LINE LINE #{current_line}"
    addr = current_line.split(/\s+/)[2] if current_line.match(/^#{iface}\s+(up)|(down)\s+[\d\.]{7,15}\s+.*/i)
  end
  addr 
end

def get_wifi_iface
  send_adb_cmd("shell getprop wifi.interface").strip
end

def get_server_lan_ip(dut_ip)
  ip_addr = ''
   @equipment['server1'].send_cmd("ifconfig")
   @equipment['server1'].response.lines.each do |current_line|
    if (line_match = current_line.match(/^\s+inet\s+addr:/))
      host_ip = current_line.scan(/inet\s+addr:([0-9]+.[0-9]+.[0-9]+.[0-9]+)/)[0][0]
      cmd = "shell ping -c3 #{host_ip}"
      ping_data = send_adb_cmd cmd
      if ping_data.scan(/3\s+packets\s+transmitted,\s+3\s+received/).to_s != nil 
       return host_ip 
       end
    end
  end
  return "" 
end

def play_video 
  fps_values = Array.new()
  endable_fps = "setprop debug.video.showfps 1"
  cmd = "shell " + endable_fps
  #send fps enable command 
  data = send_adb_cmd cmd
  cmd = "push " + @test_params.params_chan.host_file_path[0] + "/" + @test_params.params_chan.file_name[0] +  " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send file push command 
  data = send_adb_cmd cmd
  if data.scan(/[0-9]+\s*KB\/s\s*\([0-9]+\s*bytes\s*in/)[0] == nil
    puts "#{data}"
    exit 
  end
  i = 0
  while  i <  @test_params.params_chan.time[0].to_i
  cmd = "logcat -c "
  response = send_adb_cmd cmd 
  cmd = "shell am start -W -n #{CmdTranslator.get_android_cmd({'cmd'=>'gallery_movie_cmp', 'version'=>@equipment['dut1'].get_android_version })} -a action.intent.anction.VIEW -d"  + " " + @test_params.params_chan.target_file_path[0] + "/" + @test_params.params_chan.file_name[0]
  #send intent command to play the clip
  data = send_adb_cmd  cmd
  sleep 180
  i  =  i  + 180
  cmd  = "logcat -d "
  response = send_adb_cmd cmd 
  count = 0
  response .split("\n").each{|line|
  if line.include?("FPS")
   if count != 0  
    line = line.scan(/([0-9]*\.[0-9]+)/)
    fps_values << line[0][0]
  end 
 end
 count = count + 1 
 }

end 

return  mean(fps_values)
end 

def mean(a)
 array_sum = 0.0
 a.each{|elem|
  array_sum = array_sum + elem.to_f
 }
 mean = array_sum/a.size
 return mean
end

def get_down_ifaces_info(equipment)
  result = []
  if_info=equipment.send_cmd("netcfg", equipment.prompt).split("\n")
  if_info.each{|st|
  next if !st.include?("eth")
  result << st  
  } 
  return result 
end

def enable_ethernet(equipment)
  ifaces = get_down_ifaces_info(equipment)
  cur_ifaces = []
  ifaces.each do |cur_iface|
      cur_iface = cur_iface.scan(/(eth[0-9]+)\s*[a-zA-Z]+\s*[0-9]+.[0-9]+.[0-9]+.[0-9]+/)[0][0]
      cur_ifaces << cur_iface.to_s
      next if cur_iface.include?("UP")
      equipment.send_cmd("netcfg #{cur_iface} up", equipment.prompt)
      sleep 6
      equipment.send_cmd("netcfg #{cur_iface} dhcp", equipment.prompt)
      sleep 6
  end
  return cur_ifaces
end

def configure_adb_over_ethernet(equipment=@equipment['dut1'], port)
  ifaces = enable_ethernet(equipment)
  sleep 2
  equipment.send_cmd("setprop service.adb.tcp.port #{port}", equipment.prompt)
  puts "Configured PORT ..."
  sleep 2
  equipment.send_cmd("stop adbd", equipment.prompt)
  puts "Stop ADBD  ..."
  sleep 2
  equipment.send_cmd("start adbd", equipment.prompt)
  puts "Start ADBD  ..."
  equipment.send_cmd("netcfg", /#{ifaces[0]}\s+UP\s*[0-9]+.[0-9]+.[0-9]+.[0-9]+\/23/)
  response = equipment.response
  dut_ip = response.to_s.scan(/#{ifaces[0]}\s+UP\s*([0-9]+.[0-9]+.[0-9]+.[0-9]+)/)
  dut_ip.each{|ip|
   next if ip.include?("127")
    dut_ip = ip
  }
  raise "NO IP alocated for dut" if dut_ip.size == 0
  count = 0
  for i in (1..5) 
   ENV['ADBHOST']="#{dut_ip[0]}"
   sleep 1
   puts "killing adb server"
   equipment.send_host_cmd "adb kill-server"
   puts "Starting adb server"
   equipment.send_host_cmd "adb start-server"
   sleep 10
   device = `adb devices`
   puts device
   count = count + 1 
   if device.to_s.include?("emulator-5554") 
    break 
   end 
 end 
 if count >= 5 
  raise "Device is not listed for ADB connection."
 end 
end 


end 
