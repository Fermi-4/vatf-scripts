#=============================================================================================================
# Test Script for DvtbH264Loopback.atp.rb test recipe
# History:
#   0.1: [CH, 7/6/7] First Draft
#   0.2: [AH, 9/20/07]
#=============================================================================================================




include DvsdkTestScript

class H264Params
    attr_reader :codec_name, :enc_codec_name, :enc_thread_name, :dec_codec_name, :dec_thread_name
    def initialize
        @codec_name 		= 'H264'
        @enc_codec_name 	= 'h264enc'
        @enc_thread_name 	= 'h264enc'
        @dec_codec_name 	= 'h264dec'
        @dec_thread_name 	= 'h264dec'
    end
end

class MPEG4Params
    attr_reader :codec_name, :enc_codec_name, :enc_thread_name, :dec_codec_name, :dec_thread_name
    def initialize
        @codec_name 		= 'MPEG4'
        @enc_codec_name 	= 'mpeg4enc'
        @enc_thread_name 	= 'mpeg4enc'
        @dec_codec_name 	= 'mpeg4dec'
        @dec_thread_name 	= 'mpeg4dec'
    end
end

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() #method implemented in DvsdkTestScript module
  
  codec_class = @test_params.params_control.codec_class[0]+"Params"
  codec_object = Object.const_get(codec_class).new

  @equipment["dut1"].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i, 0)
  # Set engine params
  @equipment["dut1"].set_param({"Class" => "engine", "Param" => "name", "Value" => "encdec"})
  #@equipment["dut1"].set_param({"Class" => "engine", "Param" => "trace","Value" => "0"})
  if @test_params.params_chan.operation[0] =~ /encode/
    # Set encoder params
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "codec", "Value" => codec_object.enc_codec_name})
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]}) 
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})  
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]}) 
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})  
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]}) 
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxBitRate", "Value" => (@test_params.params_chan.video_bit_rate[0].to_i*1.1).round.to_s})							   
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "intraFrameInterval", "Value" => @test_params.params_chan.video_gop[0]})  
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "generateHeader", "Value" => @test_params.params_chan.video_gen_header[0]})   
    @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_width[0]})  
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
   # @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "forceIframe", "Value" => "#{@test_params.params_chan.video_force_iframe[0]}"})   
  end
  if @test_params.params_chan.operation[0] =~ /decode/  
    # Set decoder params
    @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "codec", "Value" => codec_object.dec_codec_name})
    @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => (@test_params.params_chan.video_bit_rate[0].to_i*1.1).round.to_s}) 
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => @test_params.params_chan.video_width[0]})
    data_format  = @test_params.params_chan.operation[0] =~ /encode/ ? @test_params.params_chan.video_input_chroma_format[0] : @test_params.params_chan.video_output_chroma_format[0]  # encode+decode only specifies input format, while decode only specifies  output format
    @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "forceChromaFormat", "Value" => data_format})    
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "displayWidth", "Value" => @test_params.params_chan.video_width[0]})
  end
end


def run
  result_comment = " "
  result_type = FrameworkConstants::Result[:pass]
  local_ref_files = Array.new
  num_frames = test_done_result = nil
  test_comment = ''
  codec_class = @test_params.params_control.codec_class[0]+"Params"
  codec_object = Object.const_get(codec_class).new
  
  max_num_files = @test_params.params_control.max_num_files[0].to_i 
  file_counter = 0  
  @test_params.params_chan.video_source.each do |vid_source|
      break if (file_counter == max_num_files and max_num_files > 0)
      #======================== Prepare reference files ==========================================================
      ref_dir  = @test_params.params_chan.operation[0] =~ /encode/ ? "Video/Encoder" : "Video/Decoder"
      ref_file = get_ref_file(ref_dir,vid_source)
      local_ref_files << ref_file
      num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
      @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "numframes", "Value" => num_frames.to_s}) if @test_params.params_chan.operation[0] =~ /encode/
      @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "numframes", "Value" => num_frames.to_s}) if @test_params.params_chan.operation[0] =~ /decode/

      # Start encoding and/or decoding function
      case @test_params.params_chan.operation[0]
      when /encode\+decode/ 
        @equipment["dut1"].video_encoding_decoding({"Target" => ref_file.sub(/\.yuv/, "_out.yuv"), "Source" => ref_file, "threadId" => codec_object.dec_thread_name, "timeout" => num_frames*3})
      when /decode/         
        @equipment["dut1"].video_decoding({"Target" => ref_file.sub(/#{get_video_file_extension(@test_params.params_control.codec_class[0])}/, "_out.yuv"), "Source" => ref_file, "threadId" => codec_object.dec_thread_name, "timeout" => num_frames*2})
      else
        @equipment["dut1"].video_encoding({"Target" => ref_file.sub(/\.yuv/, "_test"+get_video_file_extension(@test_params.params_control.codec_class[0])), "Source" => ref_file, "threadId" => codec_object.enc_thread_name, "timeout" => num_frames*2})
      end
      @equipment["dut1"].wait_for_threads(num_frames*3)
      file_counter += 1
  end
  local_ref_files.each do |local_ref_file|                      
      #======================== Prepare process file =============================================================
      metric_window = get_metric_window
      test_file = ''
      case @test_params.params_chan.operation[0]
      when /encode\+decode/ 
        test_file = local_ref_file.sub(/\.yuv/, "_out.yuv")
      when /decode/         
        test_file = local_ref_file.sub(/#{get_video_file_extension(@test_params.params_control.codec_class[0])}/, "_out.yuv")
        if @test_params.params_control.codec_class[0].downcase.include?('mpeg4')   # Required due to video clarity lack of support for MPEG4
          out_file = local_ref_file.sub(/\..+$/,'_'+@test_params.params_chan.video_output_chroma_format[0]+'_rawconv.yuv') 
          get_raw_video_file(local_ref_file,out_file, @test_params.params_chan.video_output_chroma_format[0]) 
          local_ref_file = out_file
        end
      else
        test_file = local_ref_file.sub(/\.yuv/, "_test"+get_video_file_extension(@test_params.params_control.codec_class[0]))
        if @test_params.params_control.codec_class[0].downcase.include?('mpeg4')   # Required due to video clarity lack of support for MPEG4
          out_file = test_file.sub(/\..+$/,'_'+@test_params.params_chan.video_input_chroma_format[0]+'_rawconv.yuv') 
          get_raw_video_file(test_file,out_file, @test_params.params_chan.video_input_chroma_format[0]) 
          test_file = out_file
        end
      end
      
      #======================== Call Objective quality equipment ====================================================================
      data_format  = @test_params.params_chan.operation[0] =~ /encode/ ? @test_params.params_chan.video_input_chroma_format[0] : @test_params.params_chan.video_output_chroma_format[0]
      video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => local_ref_file, 
                                                                         'test_file' => test_file,
                                                                         'data_format' => data_format,
                                                                         'format' => get_video_tester_format,
                                                                         'video_height' => @test_params.params_chan.video_height[0],
                                                                         'video_width' =>@test_params.params_chan.video_width[0],
                                                                         'num_frames' => num_frames,
                                                                         'frame_rate' => 30,
                                                                         'metric_window' => metric_window})
      if  !video_tester_result
        @results_html_file.add_paragraph("")
        test_done_result = FrameworkConstants::Result[:fail]
        test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{local_ref_file}\n"   
      else  	
    		video_done_result, video_done_comment = get_results(test_file)
    		test_comment += video_done_comment+"\n" if video_done_comment.strip.to_s != ''
    		test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
      end
   end
   set_result(test_done_result, test_comment)
end

def clean
 
end



private 

def get_pixel_and_data_format
    if @test_params.params_chan.video_input_chroma_format[0].match(/p/) == nil 
        ref_file_pixel_format = 'packed'
	    raw_data_format = 'uyv'
    else
        ref_file_pixel_format = 'planar'
	    raw_data_format = 'yuv'
    end
    [ref_file_pixel_format,raw_data_format]
end

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def get_video_tester_format
    [@test_params.params_chan.video_width[0].to_i,@test_params.params_chan.video_height[0].to_i, 30]
end

def get_video_file_extension(format)
  case format
  when /H264/i   : '.264'
  when /MPEG4/i   : '.mpeg4'
  else '.yuv'
  end
end

def get_metric_window
    ti_logo_height = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[1].to_i
    ti_logo_width = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[0].to_i
	
    #video_signal_height = @equipment['video_tester'].get_video_signal_height({'format' => @test_params.params_chan.video_signal_format[0]})
    #video_signal_width = @equipment['video_tester'].get_video_signal_width({'format' => @test_params.params_chan.video_signal_format[0]})
    
    metric_window_width = @test_params.params_chan.video_width[0].to_i
    metric_window_height = @test_params.params_chan.video_height[0].to_i
    
    x_offset = [0,((metric_window_width - metric_window_width)/2).ceil].max
    y_offset = [0,((metric_window_height - metric_window_height)/2).ceil].max
    
    if rand < 0.5
    	metric_window_width -= ti_logo_width
    else
        metric_window_height -= ti_logo_height
        y_offset+=ti_logo_height
    end
    [x_offset, y_offset, metric_window_width, metric_window_height] 
end

def get_local_file_regex(type)
  case type
  when /video/i
    /^#{@test_params.params_chan.resolution[0]}_#{@test_params.params_chan.bit_rate[0]}.*\.#{@test_params.params_chan.codec[0].gsub(/h264/,"264")}$/i
  when /audio/i
    // # Todo
  when /speech/i
    // # Todo
  else
    /#{@test_params.params_chan.picture_resolution[0]}.*\.jpg$/i
  end
end

def get_ref_file(strt_directory, file_name)
  start_directory = strt_directory
  if start_directory.kind_of?(String)
    start_directory = [start_directory]
  end
  ref_file = nil
  case file_name.strip.downcase 
  when 'from_encoder'
    start_directory = SiteInfo::LOCAL_FILES_FOLDER
    filename_regex = get_local_file_regex(strt_directory)
    ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{filename_regex}/}
  when 'from_web'
    start_directory = SiteInfo::LOCAL_FILES_FOLDER+'JPEG_Files'
    filename_regex = get_local_file_regex(strt_directory)
    ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{filename_regex}/}
  else
    start_directory.each do |start_dir|
      ref_file = Find.file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+start_dir) { |f| File.basename(f) =~ /#{file_name}/}
      break if ref_file.to_s != ""
    end
    File.makedirs(SiteInfo::LOCAL_FILES_FOLDER) if !File.exist?(SiteInfo::LOCAL_FILES_FOLDER)
    local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
    FileUtils.cp(ref_file, local_ref_file) if File.size?(local_ref_file) != File.size(ref_file)
    ref_file = local_ref_file
  end 
  ref_file
end

def get_results(video_file)
    codec_class = @test_params.params_control.codec_class[0]+"Params"
    codec_object = Object.const_get(codec_class).new
    test_done_result = FrameworkConstants::Result[:pass]
    @results_html_file.add_paragraph("")
    test_comment = " "
    perf_data = get_perf_data()
    perf_data.each_pair {|k,v| test_comment += "#{k}=#{v}, "}
    	
    
    res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
    pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
    
    @results_html_file.add_row_to_table(res_table, [["#{codec_object.codec_name} Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
    if pass_fail_criteria[0] == 'jnd'
      if @equipment['video_tester'].get_jnd_scores({'component' => 'y'}).max > pass_fail_criteria[1].to_f || @equipment['video_tester'].get_jnd_scores({'component' => 'chroma'}).max > pass_fail_criteria[1].to_f
        test_done_result = FrameworkConstants::Result[:fail]
      end
      @results_html_file.add_row_to_table(res_table,["AVG_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y'})])
      @results_html_file.add_row_to_table(res_table,["MIN_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'min'})])
      @results_html_file.add_row_to_table(res_table,["MAX_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'max'})])
      @results_html_file.add_row_to_table(res_table,["AVG_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma'})])
      @results_html_file.add_row_to_table(res_table,["MIN_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'min'})])
      @results_html_file.add_row_to_table(res_table,["MAX_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'max'})])
      @results_html_file.add_row_to_table(res_table,["AVG_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y'})])
      @results_html_file.add_row_to_table(res_table,["MIN_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'min'})])
      @results_html_file.add_row_to_table(res_table,["MAX_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'max'})])
      @results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb'})])
      @results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'min'})])
      @results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'max'})])
      @results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr'})])
      @results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'min'})])
      @results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'max'})])
    end
    
    if test_done_result == FrameworkConstants::Result[:fail]
      test_comment += ",Test failed for file "+File.basename(video_file)+"."
      file_ext = File.extname(video_file)
      failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+file_ext)
      File.copy(video_file, failed_file_name)
      @results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
    end
    [test_done_result, test_comment]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end

def get_raw_video_file(mpeg4_src_file, raw_video_dst_file, format)
    file_converter = Mpeg4ToYuvConverter.new
    file_converter.convert({'Source' => mpeg4_src_file, 'Target' => raw_video_dst_file, 'data_format' => format})
end

def get_perf_data
  perf = {}
  perf.merge!(get_fps_perf_data)
  perf.merge!(get_video_quality_data)
end

def get_fps_perf_data
  @equipment["dut1"].send_cmd("exit",@equipment["dut1"].prompt)
  @equipment["dut1"].send_cmd("cat perf-data.csv", /Frame#,.+#{@equipment["dut1"].prompt}/,30)
  avg_sec_per_frame = nil
  data = @equipment["dut1"].response
  #puts "\n--------------------------------------->\n#{data}"
  fps_array  = data.scan(/\(us\),\s*(\d+)/).flatten
  #puts "\n--------------------------------------->\n Array size=#{fps_array.size}"
  frames  = data.scan(/Frame#,\s*\d+/).flatten
  num_frames = /Frame#,\s*(\d+)/.match(frames.last).captures[0].to_i
  #puts "\n--------------------------------------->\n # Frames=#{num_frames}"
  avg_sec_per_frame = 1000/ ((fps_array.inject( nil ) { |sum,x| sum ? sum+(x.to_i/1000) : x.to_i/1000 }).to_f / num_frames)  if fps_array
  avg_sec_per_frame = 0 if !avg_sec_per_frame 
  @equipment["dut1"].send_cmd("./dvtb-r",/$/)
  {'fps' => avg_sec_per_frame }
end

def get_video_quality_data
  return {} if !@equipment["video_tester"]
  {
  'y_jnd' => @equipment["video_tester"].get_jnd_score({'component' => 'y'}),
  'c_jnd' => @equipment["video_tester"].get_jnd_score({'component' => 'chroma'}),
  'y_psnr' => @equipment["video_tester"].get_psnr_score({'component' => 'y'}),
  'cr_psnr' => @equipment["video_tester"].get_psnr_score({'component' => 'cr'}),
  'cb_psnr' => @equipment["video_tester"].get_psnr_score({'component' => 'cb'}),
  }
end


