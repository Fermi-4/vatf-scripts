# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/eth_info.rb'
include ETHInfo
INPUT_DIR = "\\\\gtsnowball\\System_Test\\Automation\\gtsystst\\video_files\\VGDK_logs\\input"

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

codec = ARGV[0]
resolution = ARGV[1]
core = ARGV[2].to_i
channel_start = ARGV[3].to_i
PC_UDP = ARGV[4].to_i
append = ARGV[5].to_i
test_case_id = ARGV[6].to_i
clip = ARGV[7]
multislice = ARGV[8].to_i
pkt_to_pkt_delay = ARGV[9].to_i
platform_info = Eth_info.new()
thk_ip = platform_info.get_platform_ip
thk_ip.each_pair { |key,value| value.gsub!(".",",")}
thk_mac = platform_info.get_platform_mac
thk_mac.each_pair { |key,value| value.gsub!(":",",")}
pc_mac = platform_info.get_pc_mac.gsub!(":",",")
pc_ip = platform_info.get_pc_ip.gsub!(".",",")

begin
if (append == 1) 
    pktHeaders = File.open("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/pktHeaders_#{codec}_#{resolution}.cfg", File::APPEND|File::RDWR)
else
    pktHeaders = File.new("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/pktHeaders_#{codec}_#{resolution}.cfg", "w")
end 
rescue EOFError
    $stderr.print "File.open failed" + $!
    raise

end
chan = channel_start
if(append == 0)
  pktHeaders.puts "#{pkt_to_pkt_delay}   /* enforce minDiff (millisec) between packets in a stream; -1 for default Timestamps */ "
end
pktHeaders.puts "header = #{thk_mac["CORE_#{core}"]},#{thk_ip["CORE_#{core}"]},#{THK_UDP[chan]},#{pc_mac},#{pc_ip},#{PC_UDP}"
pktHeaders.puts "\n"
pktHeaders.close   

begin
if (append == 1) 
    delays = File.open("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/delays_#{codec}_#{resolution}.cfg", File::APPEND|File::RDWR)
else
    delays = File.new("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/delays_#{codec}_#{resolution}.cfg", "w")
end 
rescue EOFError
    $stderr.print "File.open failed" + $!
    raise

end
delays.puts "0"
delays.close

begin
if (append == 0) 
     if (File.exists?"#{INPUT_DIR}/config/change_headers_#{codec}_#{resolution}.cfg")
       FileUtils.remove_file("#{INPUT_DIR}/config/change_headers_#{codec}_#{resolution}.cfg") 
     end
     change_headers = File.new("#{INPUT_DIR}/config/change_headers_#{codec}_#{resolution}.cfg", "w")
     puts "Created file #{INPUT_DIR}/config/change_headers_#{codec}_#{resolution}.cfg"
     change_headers.puts "2" #  options: 1= EXTRACT_PAYLOAD, 2=CHANGE_HEADERS, 3=MERGE_PCAP_FILES 
     change_headers.puts "1" #  number of input PCAP files 
     if /yuv/.match(codec)
       if(multislice == 1)
         change_headers.puts "#{INPUT_DIR}\\in\\#{resolution}\\multislice\\#{clip}.cap"
       else
         change_headers.puts "#{INPUT_DIR}\\in\\#{resolution}\\#{clip}.cap"
       end
     else
       if(multislice == 1)
         change_headers.puts "#{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\multislice\\#{clip}.cap"
       else
         change_headers.puts "#{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\#{clip}.cap"
       end
     end
     change_headers.puts "#{INPUT_DIR}\\out\\#{clip}_to_platform.cap"
     change_headers.close
end 
rescue EOFError
    $stderr.print $!
    raise
end

