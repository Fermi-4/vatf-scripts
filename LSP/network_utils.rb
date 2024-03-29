# Functions used to collect or set network information.
module NetworkUtils
  
  def get_ifconfig_common(dev='dut1', iface_type='eth', get_mode="ip")
    this_equipment = @equipment["#{dev}"]
    this_equipment.send_cmd("eth=`ls /sys/class/net/ | awk '/.*#{iface_type}.*/{print $1}' | head -1`;ifconfig $eth", this_equipment.prompt)
    case get_mode
      when "ip"
        ifconfig_data =/([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=\s+(Bcast))/.match(this_equipment.response)
      when "mac"
        ifconfig_data =/([0-9a-zA-Z]+\:[0-9a-zA-Z]+\:[0-9a-zA-Z]+\:[0-9a-zA-Z]+\:[0-9a-zA-Z]+\:[0-9a-zA-Z]+)(?=\s+)/.match(this_equipment.response)
      when "ipv6_global"
        ifconfig_data =/([0-9a-zA-Z:]*)(?=\/\d*\s+(Scope:Global))/.match(this_equipment.response)
      when "ipv6_global_netmask"
        ifconfig_data =/(\/\d*)(?=\s+(Scope:Global))/.match(this_equipment.response)
      when "ipv6_link"
        ifconfig_data =/([0-9a-zA-Z:]*)(?=\/\d*\s+(Scope:Link))/.match(this_equipment.response)
      when "ipv6_link_netmask"
        ifconfig_data =/(\/\d*)(?=\s+(Scope:Link))/.match(this_equipment.response)
    end
    ifconfig_data ? ifconfig_data[1] : nil
  end

  def get_ip_addr(dev='dut1', iface_type='eth')
    addr = get_ifconfig_common(dev, iface_type, "ip")
    restart_networking(dev) if !addr
    get_ifconfig_common(dev, iface_type, "ip")
  end

  def restart_networking(dev='dut1')
    @equipment[dev].send_cmd("/etc/init.d/networking restart", @equipment[dev].prompt, 15)
  end
    
  def get_mac_addr(dev='dut1', iface_type='eth')
    get_ifconfig_common(dev, iface_type, "mac")
  end
    
  def get_ipv6_global_addr(dev='dut1', iface_type='eth')
    get_ifconfig_common(dev, iface_type, "ipv6_global")
  end

  def get_ipv6_global_netmask(dev='dut1', iface_type='eth')
    get_ifconfig_common(dev, iface_type, "ipv6_global_netmask")
  end

  def get_ipv6_link_addr(dev='dut1', iface_type='eth')
    get_ifconfig_common(dev, iface_type, "ipv6_link")
  end

  def get_ipv6_link_netmask(dev='dut1', iface_type='eth')
    get_ifconfig_common(dev, iface_type, "ipv6_link_netmask")
  end
  
  def get_eth_interfaces(dev='dut1')
    interface_arr = Array.new
    this_equipment = @equipment["#{dev}"]
    this_equipment.send_cmd("ls /sys/class/net|grep eth")
    eth_interface_list = this_equipment.response
    eth_interface_arr = eth_interface_list.split(/[\n\r]+/)
    eth_interface_arr.each{|eth|
      if (eth.match(/eth\d/))
         interface_arr << eth
      end
    }
    return interface_arr
  end

  def get_eth_interface_by_ipaddress(dev='dut1', ip_address)
    this_equipment = @equipment["#{dev}"]
    eth_iface = nil
    this_equipment.send_cmd("ifconfig", this_equipment.prompt)
    temp = this_equipment.response.gsub("\n","").scan(/eth[0-9a-zA-Z\s:.]*\W*inet addr:[0-9.]+/)
    temp.each do |eth_item|
      if eth_item.include?(ip_address)
        eth_iface = eth_item.scan(/eth[0-9]*/)[0]
        break
      end
    end
    eth_iface ? eth_iface : nil
  end

  def get_ip_address_by_interface(dev='dut1', eth_iface='eth0')
    this_equipment = @equipment["#{dev}"]
    ip_addr = nil
    #Bring up ethernet interface in case it did not come up autommatically. Skip eth0 because nfs may be in use.
    if (eth_iface != 'eth0')
       this_equipment.send_cmd("ifup #{eth_iface}", this_equipment.prompt)
    end
    this_equipment.send_cmd("ifconfig #{eth_iface} | grep \"inet addr\"")
    ip_addr =  this_equipment.response.split(":")[1].split("Bcast")[0].strip!
  end

  def convert_mac_to_ipv6_addr(mac_addr, ipv6_prefix)
    mac_items = mac_addr.downcase.split(":")
    ipv6_addr = (ipv6_prefix.include?(":") ? ipv6_prefix.gsub("::", ":") : ipv6_prefix + ":")
    item_count = 1
    separator_count = 1
    # Mimic the way that the link-local address is automatically derived on Linux
    mac_items.each do |item|
      ipv6_addr += (separator_count == 1 ? ":" : "") + (item_count == 4 ? "fe" : "") + item + (item_count == 3 ? "ff" : "")
      separator_count += 1 if item_count == 3 || item_count == 4
      separator_count = (separator_count += 1) % 2
      item_count += 1
    end
    return ipv6_addr
  end

  def set_global_ipv6_addr(dev, eth_iface, ipv6_global_addr, netmask="/64")
    this_equipment = @equipment["#{dev}"]
    command_to_send = "ip addr add #{ipv6_global_addr}#{netmask} dev #{eth_iface}"
    if dev.downcase.include?("server")
      this_equipment.send_sudo_cmd(command_to_send, this_equipment.prompt)
    else
      this_equipment.send_cmd(command_to_send, this_equipment.prompt)
    end
  end

  def get_equipment_param_value(dev='dut1', variable)
    @equipment["#{dev}"].instance_variable_defined?(:@params) ? \
                          (@equipment["#{dev}"].params[variable] != nil) ? \
                               @equipment["#{dev}"].params[variable] : nil \
                    : nil
  end

  def set_ipv6_global_addr_if_not_exist(dev='dut1', eth_iface='eth0', ipv6_prefix="2000::", netmask="/64")
    ipv6_global_addr = get_ipv6_global_addr(dev, eth_iface)
    # If interface does not already have an IPv6 global address then set it from the bench file or create it using the interface's MAC address
    if !ipv6_global_addr
      static_ipv6_address_from_bench_file = get_equipment_param_value(dev, "static_ipv6_global_address")
      if static_ipv6_address_from_bench_file
        # Use IPv6 global address from bench file
        ipv6_global_addr = static_ipv6_address_from_bench_file
      else
        # Create IPv6 global address from interface's MAC address
        mac_addr = get_mac_addr(dev, eth_iface)
        ipv6_global_addr = convert_mac_to_ipv6_addr(mac_addr, ipv6_prefix)
      end
      # Set IPv6 global address on interface
      set_global_ipv6_addr(dev, eth_iface, ipv6_global_addr, netmask)
    end
    ipv6_global_addr ? ipv6_global_addr : nil
  end
  
  def get_iperf_cmd(type="client", ipaddr=nil, port=nil, proto="udp", interval=nil, len=nil, bw=nil, time=nil, is_ipv6=false, bind_addr=nil)
    iperf_cmd = ""
    iperf_cmd += "iperf "
    type == "client" ? iperf_cmd += "-c #{ipaddr} " : iperf_cmd += "-s "
    port != nil ? iperf_cmd += "-p #{port} " : iperf_cmd
    proto != nil ? (proto == "tcp" ? iperf_cmd : iperf_cmd += "-u " ) : iperf_cmd += "-u "
    interval != nil ? iperf_cmd += "-i #{interval} " : iperf_cmd
    len != nil ? iperf_cmd += "-l #{len} " : iperf_cmd
    bw != nil ? iperf_cmd += "-b #{bw} " : iperf_cmd
    time != nil ? iperf_cmd += "-t #{time} " : iperf_cmd
    type == "client" ? iperf_cmd += "> #{port}.txt & " : iperf_cmd 
    # iperf_cmd += "& "
    puts "iperf command is "
    puts "#{iperf_cmd}"
    iperf_cmd
  end
  
  def get_iperf_reported_bw(log)
    x = log.match(/^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+([\d\.]+)\s+([\w\/]+)/m).captures[0].to_f
    x_unit = log.match(/^\[[\s\d]+\]\sServer\s+Report:.+?sec[\s\d\.]+[KMG]Bytes\s+([\d\.]+)\s+([KMG])bits\/sec/m).captures[1].to_s
    (x.to_s + "#{x_unit}")
  end
  
  def convert_to_mbps(x,unit_x)
    if unit_x == /M/
      return x
    elsif unit_x == /K/
      return x.to_f/1000
    end
  end
  
  def common_units?(a,b)
    unit_x = a.match(/\d+(M|G|K)/).captures[0].to_s
    unit_y = b.match(/\d+(M|G|K)/).captures[0].to_s
    if unit_x == unit_y
     true
    else
      false
    end
  end
  
  def split_units(rate)
    x = rate.match(/(\d+.*\d*)[M|G|K]/).captures[0].to_f
    unit_x = rate.match(/\d+(M|G|K)/).captures[0].to_s
	return x,unit_x
  end
  def get_values(a,b)
    # returns values in common units, to make comparisons easier. 
    # For example if a=3M,b=5K, will return 3000000,"",5000,""
    # For example if a=3K,b=5K, will return 3,K,5,K
    x, unit_x = split_units(a)
    y, unit_y = split_units(b)
    if common_units?(a,b)
     return x,y,unit_x,unit_y
    else
      return convert_to_bits_per_sec(a),convert_to_bits_per_sec(b),"",""
    end
  end
 
  def get_percent_error(measured_bw,expected_bw)
    x,y,unit_x,unit_y = get_values(measured_bw,expected_bw)
    x = x.abs
    y = y.abs
    puts "x: #{x}"  
    puts "y: #{y}"
    return (((y-x)/y)*100).abs.to_f
  end
  
  def convert_to_bytes_per_sec(bitrate)
    if bitrate.match(/M/)
      return (bitrate.match(/([0-9]*\.[0-9]+|[0-9]+)M/).captures[0].to_f*1000000)/8
    elsif bitrate.match(/K/)
      return (bitrate.match(/([0-9]*\.[0-9]+|[0-9]+)K/).captures[0].to_f*1000)/8
    else
      return bitrate/8
    end
  end

  def convert_to_bits_per_sec(bitrate)
    if bitrate.match(/M/)
      return (bitrate.match(/([0-9]*\.[0-9]+|[0-9]+)M/).captures[0].to_f*1000000)
    elsif bitrate.match(/K/)
      return (bitrate.match(/([0-9]*\.[0-9]+|[0-9]+)K/).captures[0].to_f*1000)
    else
      return bitrate
    end
  end

  def convert_to_mbps(bytes_per_sec)
    return bytes_per_sec.to_f*8/1000000
  end
  
  def run_dhclient(dev,interface)
    this_equipment = @equipment["#{dev}"]
    this_equipment.send_cmd("/sbin/dhclient #{interface}",this_equipment.prompt,10)
  end
  
  def run_down_up_udhcpc(dev, interface)
    this_equipment = @equipment["#{dev}"]
    this_equipment.send_cmd("ifconfig #{interface} down", this_equipment.prompt, 10)
    this_equipment.send_cmd("ifconfig #{interface} up", this_equipment.prompt, 10)
    this_equipment.send_cmd("udhcpc -i #{interface}", this_equipment.prompt, 10)
  end

   # Get the name of local interface that is talking to remote IP
   def get_local_iface_name(this_equipment=@equipment['dut1'],remote_ipaddr)
    this_equipment.send_cmd("ip route get #{remote_ipaddr}")
    return this_equipment.response.match(/dev\s(\w+\d+)/)[1].to_s
   end
   
  # Get the IP address of remote interface talking with local_if 
  def get_remote_ip(local_if,local_dev,remote_dev)
    # get name of remote interface talking with local interface 
    remote_if = get_local_iface_name(@equipment["#{remote_dev}"],get_ifconfig_common(local_dev, local_if, get_mode="ip"))
    # get ip of remote interface talking with local interface 
    return get_ifconfig_common(remote_dev, remote_if, get_mode="ip") 
  end

  def get_eth_server(interface_name, local_device='dut1', remote_device='server1')

    ip_addr = ''
    ip_addr = get_remote_ip(interface_name, local_device, remote_device)
    if (ip_addr == '')
       return [FrameworkConstants::Result[:fail], "Server #{remote_device} does not have ethernet interface corresponding to dut's #{interface_name} where dut is #{local_device}. Please emsure host machine has an interface on subnet of each dut interface.\n"]
    end
    ip_addr

  end

  def set_eth_sys_control_optimize(device='dut1')
 
    @equipment[device].send_cmd("sysctl -w net.core.rmem_max=33554432", @equipment[device].prompt, 3)
    @equipment[device].send_cmd("sysctl -w net.core.wmem_max=33554432", @equipment[device].prompt, 3)
    @equipment[device].send_cmd("sysctl -w net.core.rmem_default=33554432", @equipment[device].prompt, 3)
    @equipment[device].send_cmd("sysctl -w net.core.wmem_default=33554432", @equipment[device].prompt, 3)
    @equipment[device].send_cmd("sysctl -w net.ipv4.udp_mem='4096 87380 33554432'", @equipment[device].prompt, 3)
    @equipment[device].send_cmd("sysctl -w net.ipv4.route.flush=1", @equipment[device].prompt, 3)

  end

  # Function to get active eth interfaces that are implemented by driver
  def get_interfaces_by_driver(dev, driver)
    interfaces = get_active_interfaces(dev)
    
    ret = []
    # Check each active interface on the device 
    interfaces.each do |iface|
      # Get iface driver info 
      dev.send_cmd("ethtool -i #{iface} | grep driver", dev.prompt)
      iface_driver = dev.response.scan(/driver:\s+(.*)/)[0][0].strip()

      # Return interface if it is implemented by the requested driver
      ret.push(iface) if get_networking_drivers(driver).include?(iface_driver) 
    end
    
    # Could not find interface
    raise "Could not find an active interface implemented by #{driver} to run test!" if ret.empty?
    
    return ret 
  end

  # Function to get all interfaces with an active link 
  def get_active_interfaces(dev)
    dev.send_cmd("ls /sys/class/net")
    interfaces = dev.response.split(" ")
    interfaces = interfaces.reject{|val| val.empty? || val !~ /eth\d+/}

    ret = []
    # Check if link is active, if not try next interface 
    interfaces.each { |val|
      iface = val.scan(/(eth\d+)/)[0][0].strip
      ret.push(iface) if has_active_link(dev, iface)
    }

    return ret
  end
  
  # Function to check if eth interface has an active link
  def has_active_link(dev, iface)
    dev.send_cmd("cat /sys/class/net/#{iface}/operstate", dev.prompt)
    return dev.response !~ /down/
  end

  # Function to get the rate at which the interface is currently running
  def get_line_rate(dev, iface) 
    dev.send_cmd("cat /sys/class/net/#{iface}/speed", dev.prompt)
    speed = dev.response.scan(/^(\d+)/)[0][0].to_i
    return speed
  end

  # Gets server IP from dut ip 
  def get_server_ip_from_dut(dut_ip) 
    @equipment['server1'].send_cmd("ip route get #{dut_ip}", @equipment['server1'].prompt)
    server_ip = @equipment['server1'].response.scan(/src\s*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/)
    raise "Could not get IP of server from IP of DUT!" if server_ip.empty?
    return server_ip[0][0]
  end
end