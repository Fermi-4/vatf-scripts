# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require File.dirname(__FILE__)+'/eth_info.rb'
include ETHInfo
INPUT_DIR = "\\\\gtsnowball\\System_Test\\Automation\\gtsystst\\video_files\\VGDK_logs\\input"
VIDEO_TOOLS_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "..","Utils","Video_tools")

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
core = ARGV[1].to_i
channel_start = ARGV[2].to_i
PC_UDP = ARGV[3].to_i
append = ARGV[4].to_i
test_case_id = ARGV[5].to_i
clip = ARGV[6]
multislice = ARGV[7].to_i
platform_info = Eth_info.new()
thk_ip = platform_info.get_platform_ip
thk_ip.each_pair { |key,value| value.gsub!(".",",")}
thk_mac = platform_info.get_platform_mac
thk_mac.each_pair { |key,value| value.gsub!(":",",")}
pc_mac = platform_info.get_pc_mac.gsub(":",",")
pc_ip = platform_info.get_pc_ip.gsub(".",",")

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
    pktHeaders.puts "header = #{thk_mac["CORE_#{core}"]},#{thk_ip["CORE_#{core}"]},#{THK_UDP[chan]},#{pc_mac},#{pc_ip},#{PC_UDP}"
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



