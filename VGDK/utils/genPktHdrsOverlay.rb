# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/eth_info.rb'
include ETHInfo
INPUT_DIR = SiteInfo::VGDK_INPUT_CLIPS

THK_UDP = 
{
    0 => "32768",
    1 => "32770",
    2 => "32772",
    3 => "32774",
    4 => "32776",
    5 => "32778",
    6 => "32780",
    7 => "32782",
    8 => "32784",
    9 => "32786",
    10 => "32788",
    11 => "32790",

}
module GenPktHdrsOverlay
def genPktHdrsOverlay(codec,core,channel_start,pc_udp,append,test_case_id,clip,multislice,platform_info)
	thk_ip = {}
	thk_mac = {}
	pc_ip_addr = nil
	pc_mac_addr = nil
	# platform_info = Eth_info.new()
	platform_info.get_platform_ip.each_pair { |key,value|
	thk_ip[key] = value.gsub(".",",")}
	platform_info.get_platform_mac.each_pair { |key,value| 
	thk_mac[key] = value.gsub(":",",")}
	pc_ip_addr = platform_info.get_pc_ip
	pc_ip_addr = pc_ip_addr.gsub(".",",")
	pc_mac_addr = platform_info.get_pc_mac
	pc_mac_addr = pc_mac_addr.gsub(":",",")

    begin
    if (append == 1) 
        pktHeaders = File.open("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/pktHeaders_#{codec}.cfg", File::APPEND|File::RDWR)
    else
        pktHeaders = File.new("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/pktHeaders_#{codec}.cfg", "w")
    end 
    rescue EOFError
        $stderr.print "File.open failed" + $!
        raise

    end
    chan = channel_start
    if(append == 0)
      pktHeaders.puts "-1   /* enforce minDiff (millisec) between packets in a stream; -1 for default Timestamps */ "
    end
    pktHeaders.puts "header = #{thk_mac["CORE_#{core}"]},#{thk_ip["CORE_#{core}"]},#{THK_UDP[chan]},#{pc_mac_addr},#{pc_ip_addr},#{pc_udp}"
    pktHeaders.puts "\n"
    pktHeaders.close   

    begin
    if (append == 1) 
        delays = File.open("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/delays_#{codec}.cfg", File::APPEND|File::RDWR)
    else
        delays = File.new("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/delays_#{codec}.cfg", "w")
    end 
    rescue EOFError
        $stderr.print "File.open failed" + $!
        raise

    end
    delays.puts "0"
    delays.close
    begin
    if (append == 0) 
         if (File.exists?"#{INPUT_DIR}/config/change_headers_#{codec}.cfg")
           FileUtils.remove_file("#{INPUT_DIR}/config/change_headers_#{codec}.cfg") 
         end
         change_headers = File.new("#{INPUT_DIR}/config/change_headers_#{codec}.cfg", "w")
         puts "Created file #{INPUT_DIR}/config/change_headers_#{codec}.cfg"
         change_headers.puts "2" #  options: 1= EXTRACT_PAYLOAD, 2=CHANGE_HEADERS, 3=MERGE_PCAP_FILES 
         change_headers.puts "1" #  number of input PCAP files 
         change_headers.puts "#{INPUT_DIR}\\in\\overlay\\#{codec}\\#{clip}.cap"
         change_headers.puts "#{INPUT_DIR}\\out\\#{codec}_#{clip}_to_platform.cap"
         change_headers.close
    end 
    rescue EOFError
        $stderr.print $!
        raise
    end

end
end

