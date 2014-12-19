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
    get_ifconfig_common(dev, iface_type, "ip")
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
end
