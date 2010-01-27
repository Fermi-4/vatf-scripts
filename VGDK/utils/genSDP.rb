# -*- coding: ISO-8859-1 -*-
require 'FileUtils'
require 'pathname'
require File.dirname(__FILE__)+'/eth_info.rb'
include ETHInfo
MPLAYER_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..","..","Utils","Video_tools","MPlayer for Windows")
OUTPUT_DIR = "\\\\10.218.100.242\\video_files\\VGDK_logs\\output"


codec = ARGV[0]
res = ARGV[1]
core = ARGV[2].to_i
pc_udp   = ARGV[3].to_i
append = ARGV[4].to_i
test_case = ARGV[5].to_i
geom = ARGV[6].to_i
multislice = ARGV[7].to_i
test_iteration = ARGV[8]
clip_iter = ARGV[9].to_i
platform_info = Eth_info.new()
thk_ip = platform_info.get_platform_ip

geom_x = geom%1080
geom_y = 0
if(geom < 901)
    geom_y = 0
elsif (geom > 900 && geom < (12*180 + 1))
    geom_y = 180
elsif (geom > 12*180 && geom < (18*180 + 1))
    geom_y = 360
elsif (geom > 18*180 && geom < (24*180 + 1))
    geom_y = 540
elsif (geom > 24*18 && geom < (36*180 + 1))
    geom_y = 720
elsif (geom > 36*180 && geom < (42*180 + 1))
    geom_y = 900
elsif (geom > 42*180 && geom < (48*180 + 1))
    geom_y = 1080
elsif (geom > 48*180 && geom < (54*180 + 1))
    geom_y = 1260
end   
# puts "geom_x :#{geom_x}"
# puts "geom_y :#{geom_y}"
# puts "geom: #{geom}"
if(codec == "h264bp")
    if(res == "qcif")    
        sprop_parameter_sets = "Z0KAHtoLEXA=,aM48gA==;"
    elsif(res == "cif")
        sprop_parameter_sets = "Z0KAHtoFglIQAAA+gAAOpgBA,aM48gA=="
    elsif(res == "d1ntsc" || res == "d1pal")
        sprop_parameter_sets = "Z0KAHtoC0PSEAAAPoAADqYAQ,aM48gA=="
    end
    codec_name = "H264"
elsif (codec == "mpeg4")
    if(res == "qcif")    
        config = "000001B003000001B509000001000000012000C8888007D05841214103"
    elsif(res == "cif")
        config = "000001B005000001B509000001000000012000845D4C28582120A31F"
    end
    codec_name = "MP4V-ES"
elsif (codec == "h263p")
    codec_name = "H263-1998"
end


#begin subj_bat_file
begin
if(clip_iter == 0)
    if (append == 1) 
        subj_bat_file = File.open("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}_subj_bat.bat" , File::APPEND|File::RDWR)
    else
        subj_bat_file = File.new("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}_subj_bat.bat", "w")
        FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}")
        FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/trans_#{codec}_#{res}_cap")
        puts "Created bat file, #{codec}_#{res} dir and TC#{test_case} directories"
    end 
    subj_bat_file.puts("start \/MIN \/LOW \/D \"#{"#{MPLAYER_DIR}"}\" mplayer -vfm ffmpeg sdp://#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/t_rtp_#{pc_udp}.sdp -geometry #{geom_x}%:#{geom_y}% -fps 30")
    subj_bat_file.puts("PING 127.0.0.1 -n 1")
    subj_bat_file.close
end
rescue EOFError
    $stderr.print "File IO failed" + $!
    raise
end        
#end subj_bat_file
if(append == 0)
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/clipIter#{clip_iter}")
    FileUtils.mkdir("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/trans_#{codec}_#{res}_cap/clipIter#{clip_iter}")
end

# begin codec_dump_bat_file
begin
if (append == 1 || clip_iter > 0)        
    codec_dump_bat_file = File.open("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}_dump_bat.bat" , File::APPEND|File::RDWR)
else
    codec_dump_bat_file = File.new("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}_dump_bat.bat" , "w")
end
if(codec == "h264bp")
    codec_dump_bat_file.puts("start \/D \"#{"#{MPLAYER_DIR}"}\" mplayer sdp://#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/t_rtp_#{pc_udp}.sdp -dumpvideo -dumpfile #{OUTPUT_DIR}\\TC#{test_case}\\Iter#{test_iteration}\\trans_#{codec}_#{res}_cap\\clipIter#{clip_iter}\\trans_#{codec}_#{res}_#{pc_udp}_cap.264")
end
codec_dump_bat_file.puts("PING 127.0.0.1 -n 1")
codec_dump_bat_file.close        
rescue EOFError
    $stderr.print "File IO failed" + $!
    raise
end
# end codec_dump_bat_file

# begin sdpfile
begin
if(clip_iter == 0)
    sdpfile = File.new("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/t_rtp_#{pc_udp}.sdp", "w")
    puts "Created file t_rtp_#{pc_udp}.sdp"  
    sdpfile.puts("v=0\n");
    sdpfile.puts("o=- 0 0 IN IP4 127.0.0.1\n");
    sdpfile.puts("t=0 0\n");
    sdpfile.puts("c=IN IP4 #{thk_ip["CORE_#{core}"]}\n");
    sdpfile.puts("m=video #{pc_udp} RTP/AVP 96\n");
    sdpfile.puts("a=rtpmap:96 #{codec_name}/90000\n");
    if(codec == "h264bp")
        if(res == "d1ntsc" || res == "d1pal")
            sdpfile.puts("a=fmtp:96 packetization-mode=1; sprop-parameter-sets=#{sprop_parameter_sets}\n");
            sdpfile.puts("a=tool:libavformat")
            sdpfile.puts("s=No Name")
        else
        sdpfile.puts("a=fmtp:96 packetization-mode=1; profile-level-id=674280;sprop-parameter-sets=#{sprop_parameter_sets}\n");
        end
    elsif(codec == "mpeg4")
        sdpfile.puts("a=fmtp:96 profile-level-id=1; config=#{config}")
    elsif(codec == "h263p")
        sdpfile.puts("a=tool:libavformat 52.17.0")
    end
    sdpfile.close
end
rescue EOFError
    $stderr.print "File IO failed" + $!
    raise
end
# end sdpfile


# begin send_pkts_cfg_file 
begin
send_pkts_cfg_file = File.new("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/clipIter#{clip_iter}/#{pc_udp}.cfg", "w")
send_pkts_cfg_file.puts("3 \n")
send_pkts_cfg_file.puts("1 \n")
send_pkts_cfg_file.puts("#{Pathname.new("#{OUTPUT_DIR}\\outputCap\\TC#{test_case}").realpath}\\Iter#{test_iteration}\\#{pc_udp}_clipIter#{clip_iter}.cap delay = 0")
send_pkts_cfg_file.puts("#{Pathname.new("#{OUTPUT_DIR}\\outputCap\\TC#{test_case}").realpath}\\Iter#{test_iteration}\\#{pc_udp}_clipIter#{clip_iter}_merged.cap")
send_pkts_cfg_file.close
rescue EOFError
    $stderr.print "File IO failed" + $!
    raise
end
# end send_pkts_cfg_file

# begin codec_dump_cfg_file
begin
codec_dump_cfg_file = File.new("#{OUTPUT_DIR}/TC#{test_case}/Iter#{test_iteration}/#{codec}_#{res}/clipIter#{clip_iter}/#{pc_udp}_codec_dump.cfg", "w")
codec_dump_cfg_file.puts("#{Pathname.new("#{OUTPUT_DIR}\\outputCap\\TC#{test_case}").realpath}\\Iter#{test_iteration}\\#{pc_udp}_out_clipIter#{clip_iter}.cap")
case codec
    when "h264bp"
        codec_dump_cfg_file.puts("#{codec.upcase}\n")
    when "mpeg4"
        codec_dump_cfg_file.puts("#{codec.upcase}\n")
    when "h263p"
        codec_dump_cfg_file.puts("H263\n")
    when /yuv_/
        codec_dump_cfg_file.puts("YUV \n")
    else
        puts "#{codec} not supported\n"
end
if(multislice == 1)
    codec_dump_cfg_file.puts("NAL_MODE\n")
else
    codec_dump_cfg_file.puts("FRAME_MODE\n")
end
case codec
    when "h264bp"
        file_ext_name = "264"
    when "mpeg4"
        file_ext_name = "m4v"
    when "h263p"
        file_ext_name = "263"
    when /yuv_/
        file_ext_name = "yuv"
    else
       puts "#{codec} not supported\n"
end
case res
     when "qcif"
        width = "176"
        height = "144"
    when "cif"
        width = "352"
        height = "288"
    when "d1ntsc"
        width = "720"
        height = "480"
    when "d1pal"
        width = "720"
        height = "576"
    else
        puts "#{res} Not a supported resolution"
end       
codec_dump_cfg_file.puts("#{Pathname.new("#{OUTPUT_DIR}\\TC#{test_case}\\Iter#{test_iteration}\\trans_#{codec}_#{res}_cap").realpath}\\clipIter#{clip_iter}\\trans_#{codec}_#{res}_#{pc_udp}_cap.#{file_ext_name}")
codec_dump_cfg_file.puts("#{width}\n")
codec_dump_cfg_file.print("#{height}") # .print to prevent automatic newline that puts inserts
codec_dump_cfg_file.close    
rescue EOFError
    $stderr.print "File IO failed" + $!
    raise
end        




