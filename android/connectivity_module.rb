module ConnectivityModule
def get_down_ifaces_info
  result = []
  if_info=send_adb_cmd("shell netcfg").split("\n")
  if_info.each do |cur_info|
    cur_iface = cur_info.split(/\s+/)
    result << cur_iface[0] if cur_iface[1].downcase.strip == 'down'
  end
  result
end

def enable_ethernet
  ifaces = get_down_ifaces_info
  ifaces.each do |cur_iface|
    if cur_iface.match(/eth\d+/)
      send_adb_cmd("shell netcfg #{cur_iface} up")
      sleep 6
      send_adb_cmd("shell netcfg #{cur_iface} dhcp")
    end
  end
end
end 
