


OPERA_WAIT_TIME           = 30000

#include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() # method implemented in DvsdkTestScript module
  @equipment['dut1'].connect({'type'=>'telnet'})
  #Setting the maximum number of sockets the dut can 
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,0)
  #Setting the encoders and/or decoders parameters
  
  
  #Setting the engine type
  video_engine = case @test_params.params_chan.test_type[0]
          when /vpfe\w*vpbe/ : "encdec"
          when /encode/ : "encode"
          when /decode/ : "decode"
           end
  
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => video_engine})
  
  if @test_params.params_chan.test_type[0].include?("encode")
    #Setting the video encoder
    set_codec_param("codec", "video_codec")
    set_codec_param("encodingPreset", "video_encoder_preset")
    set_codec_param("rateControlPreset", "video_rate_control")
    set_codec_param("maxHeight", [576,@test_params.params_chan.video_height[0].to_i].max)
    set_codec_param("maxWidth", [720, @test_params.params_chan.video_width[0].to_i].max)
    set_codec_param("maxFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))  
    set_codec_param("maxBitRate", get_max_bit_rate(@test_params.params_chan.video_bit_rate[0]))
    set_codec_param("dataEndianness", "video_data_endianness")
    set_codec_param("maxInterFrameInterval", "video_inter_frame_interval")
    set_codec_param("inputChromaFormat", "video_input_chroma_format")
    set_codec_param("inputContentType", "video_input_content_type")
    set_codec_param("reconChromaFormat", "video_output_chroma_format")
    set_codec_param("topFieldFirstFlag", "video_top_field_first_flag")
    set_codec_param("inputHeight", "video_height")
    set_codec_param("inputWidth", "video_width")
    set_codec_param("refFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))
    set_codec_param("targetFrameRate", map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0]))
    set_codec_param("targetBitRate", "video_bit_rate")
    set_codec_param("intraFrameInterval", "video_gop")
    set_codec_param("generateHeader", 0)
    set_codec_param("captureWidth", "video_width")
    set_codec_param("forceFrame", "video_force_frame")
    set_codec_param("interFrameInterval", "video_inter_frame_interval")
    set_codec_param("mbDataFlag", "video_mb_data_flag")
    set_codec_param("framePitch", "video_width")
    set_codec_param("streamFormat", "video_stream_format")
    # Extended
    set_codec_param("profileIdc", "video_profile")  
    set_codec_param("levelIdc", "video_level")
    set_codec_param("entropyCodingMode", "video_entropy_coding")    
    set_codec_param("qpIntra", "video_qp_intra")
    set_codec_param("qpInter", "video_qp_inter")
    set_codec_param("qpMax", "video_qp_max")
    set_codec_param("qpMin", "video_qp_min")
    set_codec_param("rcAlgo", "video_rc_algo")
    set_codec_param("lfDisableIdc", "video_lf_disable_idc")
    set_codec_param("airRate", "video_air_mb_period")
    set_codec_param("transform8x8FlagIntraFrame", "video_transform_8x8_i_frame_flag")
    set_codec_param("transform8x8FlagInterFrame", "video_transform_8x8_p_frame_flag")
    set_codec_param("aspectRatioX", "video_aspect_ratio_x")
    set_codec_param("aspectRatioY", "video_aspect_ratio_y")
    set_codec_param("pixelRange", "video_pixel_range")
    set_codec_param("timeScale", "video_time_scale")
    set_codec_param("numUnitsInTicks", "video_num_units_ticks")
    set_codec_param("enableVUIparams", "video_enable_vui_params")
    set_codec_param("reset_vIMCOP_every_frame", "video_reset_imcop_every_frame")
    set_codec_param("disableHDVICPeveryFrame", "video_disable_hdivc_every_frame")
    set_codec_param("meAlgo", "video_me_algo")
    set_codec_param("umv", "video_use_umv")
    set_codec_param("seqScalingFlag", "video_sequence_scaling_flag")
    set_codec_param("encQuality", "video_enc_quality")
    set_codec_param("initQ", ((@test_params.params_chan.video_qp_min[0].to_i+@test_params.params_chan.video_qp_max[0].to_i)/2).floor)
    set_codec_param("maxDelay", "video_max_delay")
    set_codec_param("intraSliceNum", "video_slice_refresh_num")
    set_codec_param("meMultiPart", "video_me_multipart")
    set_codec_param("enableBufSEI", "video_enable_buf_sei")
    set_codec_param("enablePicTimSEI", "video_enable_pic_timing_sei")
    set_codec_param("intraThrQF", "video_intra_thresh_qf")
    set_codec_param("perceptualRC", "video_perceptual_rc")
    set_codec_param("idrFrameInterval", "video_idr_frame_interval")
    set_codec_param("mvSADoutFlag", "video_mv_sad_out_flag")
    set_codec_param("disableMVDCostFactor", "video_disable_mv_dcost_factor")
    set_codec_param("resetHDVICPeveryFrame", "video_reset_hdivc_every_frame")
    set_codec_param("numRowsInSlice", "video_num_rows_per_slice")  
    set_codec_param("filterOffsetA", "video_filter_offset_a")
    set_codec_param("filterOffsetB", "video_filter_offset_b")
    set_codec_param("chromaQPIndexOffset", "video_chroma_qp_index_offset")
    set_codec_param("secChromaQPOffset", "video_sec_chroma_qp_index_offset")
    set_codec_param("scalingFactor","video_sequence_scaling_factor")
    set_codec_param("sliceMode","video_slice_mode")
    set_codec_param("sliceCodingPreset","video_slice_coding_preset")
    set_codec_param("chromaConversionMode","video_chroma_conversion")
    set_codec_param("sliceUnitSize", @test_params.params_chan.video_slice_mode[0].strip.downcase == "mbunit" ? "video_max_mb_per_slice" : "video_max_bytes_per_slice") if @test_params.params_chan.instance_variable_defined?("@video_slice_mode")
    set_codec_param("picAFFFlag", "video_pic_aff_flag")
    set_codec_param("adaptiveMBs", "video_adaptive_mbs")
    set_codec_param("intra4x4EnableFlag", "video_transform_4x4_i_frame_flag")
    set_codec_param("me1080iMode", "video_me_1080i_mode")
    set_codec_param("mvDataFlag", "video_mv_data_flag")
    set_codec_param("transform8x8DisableFlag", "video_transform_8x8_disable_flag")
    set_codec_param("interlaceReferenceMode", "video_interlace_ref_mode")
    set_codec_param("enableARM926Tcm", "video_enable_arm926_tcm")
    set_codec_param("maxMBsPerSlice", "video_max_mb_per_slice")
    set_codec_param("maxBytesPerSlice", "video_max_bytes_per_slice")
    set_codec_param("sliceRefreshRowStartNumber", "video_slice_refresh_row_start_num")
    set_codec_param("constrainedIntraPredEnable", "video_constr_intra_pred_enabled")
    set_codec_param("quartPelDisable", "video_quarter_pel_disable")
    set_codec_param("picOrderCountType", "video_pic_order_cnt")
    set_codec_param("log2MaxFNumMinus4", "video_log2_maxf_num_minus4")
    set_codec_param("searchRange", "video_search_range")
    
  end
  
end


def run
  puts "Test Type: "+  @test_params.params_chan.test_type[0]
  channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("H264 G711 #{@test_params.params_chan.test_type[0]} Test Result Form")
    if @test_params.params_chan.test_type[0].include?("encode")
      vid_src_length = @test_params.params_chan.video_source.length
      0.upto(channel_number) do |ch_num|
        test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.video_source[ch_num % vid_src_length].gsub(/\.yuv$/,"_"+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+"fps_"+get_number_of_video_frames(@test_params.params_chan.video_source[ch_num % vid_src_length]).to_s+"frames_chan"+ch_num.to_s+"_test.264")
        set_codec_param("numframes", get_number_of_video_frames(@test_params.params_chan.video_source[ch_num % vid_src_length]))
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder/', @test_params.params_chan.video_source[ch_num % vid_src_length])
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        if @test_params.params_chan.video_codec[0].strip.downcase == 'h264extenc'
          @equipment['dut1'].h264ext_encoding({"Source" => local_ref_file,"Target" => test_file})
        elsif @test_params.params_chan.video_codec[0].strip.downcase == 'h264fhdextenc'
          @equipment['dut1'].h264fhdext_encoding({"Source" => local_ref_file,"Target" => test_file})
        end
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



private 

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
