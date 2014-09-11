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

end
