

INPUT_DIR = SiteInfo::VGDK_INPUT_CLIPS
WIRESHARK_DIR = ("C:/Program Files/Wireshark")
module GenCodecCfg
def genCodecCfg(codec,resolution,test_case_id,clip,multislice)
begin
if (!/yuv/.match(codec)) 
  ip_codec_dump_cfg = File.new("#{INPUT_DIR}/config/pktHdrs/TC#{test_case_id}/codec_dump_#{codec}_#{resolution}.cfg", "w")
  if(multislice == 1)
    ip_codec_dump_cfg.puts "#{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\multislice\\#{clip}.cap"
  else
    ip_codec_dump_cfg.puts "#{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\#{clip}.cap"
  end
  case codec
      when /h264/
          ip_codec_dump_cfg.puts("#{codec.upcase}\n")
          file_ext_name = "264"
      when "mpeg4"
          ip_codec_dump_cfg.puts("#{codec.upcase}\n")
          file_ext_name = "m4v"
      when "mpeg2"
          ip_codec_dump_cfg.puts("#{codec.upcase}\n")
          file_ext_name = "m2v"
      when "h263p"
          ip_codec_dump_cfg.puts("H263\n")
          file_ext_name = "263"
      else
          puts "#{codec} not supported\n"
  end
  if(multislice == 1)
      ip_codec_dump_cfg.puts("NAL_MODE\n")
  else
      ip_codec_dump_cfg.puts("FRAME_MODE\n")
  end
  case resolution
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
          puts "#{resolution} Not a supported resolution"
  end       
  ip_codec_dump_cfg.puts("#{INPUT_DIR}\\config\\autogenerated\\#{clip}.#{file_ext_name}")
  ip_codec_dump_cfg.puts("#{width}\n")
  ip_codec_dump_cfg.print("#{height}") # .print to prevent automatic newline that puts inserts
  ip_codec_dump_cfg.close    

end 
  Dir.chdir("#{WIRESHARK_DIR}")
  if(multislice == 1)
    system("tshark -r #{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\multislice\\#{clip}.cap -R \"rtp.marker == 1 \" -w #{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\multislice\\#{clip}_rtpmarker.cap")
  else
    system("tshark -r #{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\#{clip}.cap -R \"rtp.marker == 1 \" -w #{INPUT_DIR}\\in\\#{resolution}\\#{codec}\\#{clip}_rtpmarker.cap")
  end

rescue EOFError
    $stderr.print "File.open failed" + $!
    raise

end
end
end