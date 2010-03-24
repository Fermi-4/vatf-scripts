


OPERA_WAIT_TIME           = 30000

#include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() # method implemented in DvsdkTestScript module
  @equipment['dut1'].connect({'type'=>'telnet'})
  #Setting the maximum number of sockets the dut can support
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,0)
  #Setting the encoders and/or decoders parameters
  
  
  #Setting the engine type 
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'encode'})
  
  #Setting the video encoder and vpfe
  if @test_params.params_chan.test_type[0].include?("encode")
      #Setting the video encoder
    set_codec_param("codec", "video_codec")
    set_codec_param("maxHeight", [576,@test_params.params_chan.video_height[0].to_i].max)
    set_codec_param("maxWidth", [720,@test_params.params_chan.video_width[0].to_i].max)
    set_codec_param("maxBitRate", get_max_bit_rate(@test_params.params_chan.video_bit_rate[0]))
    set_codec_param("targetBitRate", "video_bit_rate")
    set_codec_param("maxFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))
    set_codec_param("inputHeight", "video_height")
    set_codec_param("inputWidth", "video_width")
    set_codec_param("refFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))
    set_codec_param("targetFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))
    set_codec_param("intraFrameInterval", "video_gop")
    set_codec_param("rateControlPreset", "video_rate_control")
    set_codec_param("encodingPreset", "video_encoder_preset")
    set_codec_param("forceIFrame", "video_force_iframe")
    set_codec_param("inputChromaFormat", "video_input_chroma_format")
    set_codec_param("reconChromaFormat", "video_output_chroma_format")
    set_codec_param("generateHeader", 0)
    set_codec_param("captureWidth", "video_signal_format")
    set_codec_param("dataEndianness", "video_data_endianness")
    set_codec_param("inputContentType", "video_input_content_type")
    set_codec_param("maxInterFrameInterval", "video_inter_frame_interval")
    set_codec_param("interFrameInterval", "video_inter_frame_interval")
    set_codec_param("encodeMode", "video_encode_mode")
    # new
    set_codec_param("levelIdc", "video_level")
    set_codec_param("profileIdc", "video_profile")
    set_codec_param("useVOS", "video_use_vos")
    set_codec_param("useGOV", "video_use_gov")
    set_codec_param("useVOLatGOV", "video_use_vol_at_gov")
    set_codec_param("useQpel", "video_use_qpel")
    set_codec_param("useInterlace", "video_use_interlace")
    set_codec_param("aspectRatio", "video_aspect_ratio")
    set_codec_param("pixelRange", "video_pixel_range")
    set_codec_param("timerResolution", "video_timer_resolution")
    set_codec_param("reset_vIMCOP_every_frame", "video_reset_imcop_every_frame")
    set_codec_param("Four_MV_mode","video_four_mv_mode")
    set_codec_param("PacketSize", "video_packet_size")
    set_codec_param("useHEC", "video_use_hec")
    set_codec_param("useGOBSync", "video_use_gob_sync")
    set_codec_param("rcAlgo", "video_rc_algo") 
    set_codec_param("maxDelay", "video_max_delay")
    set_codec_param("perceptualRC", "video_perceptual_rc")
    set_codec_param("insert_End_Seq_code", "video_insert_end_seq_code")
    set_codec_param("qpIntra", "video_qp_intra")
    set_codec_param("qpInter", "video_qp_inter")
    set_codec_param("qpInit", "video_qp_init")
    set_codec_param("qpMax", "video_qp_max")
    set_codec_param("qpMin", "video_qp_min")
    
    set_codec_param("EncQuality_mode", "video_enc_quality")
    set_codec_param("useRVLC", "video_use_rvlc")
    
    set_codec_param("useDataPartition", "video_use_data_pratition")
    set_codec_param("airRate", "video_air_rate")
    # End new
    set_codec_param("vbvBufferSize", "video_vbv_buffer_size")
    set_codec_param("useUMV", "video_use_umv")
    set_codec_param("subWindowHeight", "video_subwindow_height")
    set_codec_param("subWindowWidth", "video_subwindow_width")
    set_codec_param("intraPeriod", "video_gop")
    set_codec_param("intraDcVlcThr", "video_intra_dl_vlc_thr")
    set_codec_param("intraThres", "video_intra_thr")
    set_codec_param("intraAlgo", "video_intra_algo")
    set_codec_param("numMBRows", "video_num_mb_rows")
    set_codec_param("qChange", "video_q_change")
    set_codec_param("qChangeRange", "video_q_range")
    set_codec_param("meRange", "video_me_range")
    set_codec_param("meAlgo", "video_me_algo")
    set_codec_param("skipMBAlgo", "video_mb_skip_algo")
    set_codec_param("iidc", "video_blk_size")
    set_codec_param("intraDcVlcThr", "video_intra_dl_vlc_thr")
    set_codec_param("intraThres", "video_intra_thr")
    set_codec_param("intraAlgo", "video_intra_algo")
    set_codec_param("numMBRows", "video_num_mb_rows")
    
    set_codec_param("qChange", "video_q_change")
    set_codec_param("qChangeRange", "video_q_range")
    set_codec_param("meRange", "video_me_range")
    set_codec_param("skipMBAlgo", "video_mb_skip_algo")
    set_codec_param("iidc", "video_blk_size")
    set_codec_param("mvDataEnable", "video_mv_data_enable")
    set_codec_param("rotation", "video_picture_rotation")
  end
  
end


def run
  channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
  begin
    file_res_form = ResultForm.new("MPEG4 #{@test_params.params_chan.test_type[0]} Test Result Form")
    if @test_params.params_chan.test_type[0].include?("encode")
      vid_src_length = @test_params.params_chan.video_source.length
      0.upto(channel_number) do |ch_num|
        test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.video_source[ch_num % vid_src_length].gsub(/\.yuv$/,"_"+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+"fps_"+get_number_of_video_frames(@test_params.params_chan.video_source[ch_num % vid_src_length]).to_s+"frames_chan"+ch_num.to_s+"_test.mpeg4")
        set_codec_param("numframes", get_number_of_video_frames(@test_params.params_chan.video_source[ch_num % vid_src_length]))
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder/', @test_params.params_chan.video_source[ch_num % vid_src_length])
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        @equipment['dut1'].mpeg4ext_encoding({"Source" => local_ref_file,"Target" => test_file})
      end
      @equipment['dut1'].wait_for_threads
    elsif @test_params.params_chan.test_type[0].include?("decode")
      @test_params.params_chan.video_source.each do |vid_source|
        #======================== Prepare reference files ==========================================================
        puts "Decoding #{vid_source} ....."
        local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder/', vid_source)
        # Start decoding function
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"numframes", "Value" => get_number_of_video_frames(vid_source)})
        @equipment['dut1'].video_decoding({"Source" => local_ref_file})
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        if @test_params.params_control.audio_num_channels[0].to_i > 0
          audio_ref_file, audio_file = run_audio_process(file_res_form)
          file_res_form.add_link(File.basename(audio_ref_file)){system("explorer #{audio_ref_file.gsub("/","\\")}")}
        end
        @equipment['dut1'].wait_for_threads
      end
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => @test_params.params_chan.video_codec[0], "Param" => ""})
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean

end

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000)
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
    else
      start_directory.each do |start_dir|
        ref_file = Find.file(start_dir) { |f| File.basename(f) =~ /#{file_name}/}
        break if ref_file.to_s != ""
      end
      File.makedirs(SiteInfo::LOCAL_FILES_FOLDER) if !File.exist?(SiteInfo::LOCAL_FILES_FOLDER)
      local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
      FileUtils.cp(ref_file, local_ref_file) if File.size?(local_ref_file) != File.size(ref_file)
      ref_file = local_ref_file
  end 
  ref_file
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def get_number_of_video_frames(file)
        /(\d+)frames/.match(file).captures[0].to_i
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round
end

def set_codec_param(param_name, param_value)
  if param_value.kind_of?(String)
    @equipment['dut1'].set_param({"Class" => @test_params.params_chan.video_codec[0], "Param" => param_name, "Value" => @test_params.params_chan.instance_variable_get('@'+param_value)[0]}) if @test_params.params_chan.instance_variable_defined?('@'+param_value)
  else
    @equipment['dut1'].set_param({"Class" => @test_params.params_chan.video_codec[0], "Param" => param_name, "Value" => param_value.to_s})
  end
end



