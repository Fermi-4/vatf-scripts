require File.dirname(__FILE__)+'/../android_test_module' 

include AndroidTest

def run
   response = send_adb_cmd("shell \"su root ifconfig | grep prueth -A1 | grep -v '\\-\\-'\"", @equipment['dut1'])
   pru_info = {}
   response.scan(/([^\s]+).*?prueth[\r\n]+.*?inet.*?([\d\.]+)[^\r\n]+/).each { |v| pru_info[v[1]] = {'iface' => v[0]}}
   pru_check = case @equipment['dut1'].name
     when /am5.*/, /am6.*/
       pru_info.length() == 2
     else
       false
   end
   raise "Incorrect number of prueth interfaces detected #{response}" if !pru_check
   host_grep = ''
   pru_info.keys().each { |v| host_grep += ' -e ' + v.sub(/[^\.]+$/,'') }
   @equipment['server1'].send_cmd("ifconfig | grep -B1 #{host_grep} | grep -v '\\-\\-'")
   host_info = {}

   @equipment['server1'].response.scan(/([^\s]+).*[\r\n]\s+inet.*?([\d\.]+).*?$/).each do |h|
     peer = pru_info.select { |k, v| k.split('.')[0..2] == h[1].split('.')[0..2] }
     host_info[h[1]] = {'iface' => h[1], 'peer' => peer }
     peer.each { |k,v| v['peer'] = host_info }
   end

   result = ''
   host_info.each do |ip_addr, info|
     ping_res, trace = ping_test(ip_addr, pru_info, info)
     result += "Ping failed for #{info['peer']}:\n#{trace}\n" if !ping_res
   end

   if result != ''
     set_result(FrameworkConstants::Result[:fail], result)
   else
     set_result(FrameworkConstants::Result[:pass], "Ping passed on #{pru_info.length()} PRUETH interfaces")
   end
end

def ping_test(host_addr, pru_info, info)
  pru_info.each { |k, v| send_adb_cmd("shell su root ifconfig #{v['iface']} down", @equipment['dut1']) }
  result = true
  info['peer'].each do |k, v|
     send_adb_cmd("shell su root ifconfig #{v['iface']} up")
     sleep 3
     response = send_adb_cmd("shell su root ifconfig #{v['iface']}", @equipment['dut1'])
     ip_addr = response.match(/inet.*?([\d\.]+)/).captures[0]
     @equipment['server1'].send_cmd("ping -c 4 -I #{info['iface']} #{ip_addr}")
     result = result && @equipment['server1'].response.match(/ping.*?#{ip_addr}.*?from.*?#{host_addr}.*?4\s*packets\s*transmitted,\s*4\s*received/im)
  end
  [result, @equipment['server1'].response]
end
