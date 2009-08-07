
NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'
OPERA_WAIT_TIME           = 30000

def setup
  @equipment['dut1'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  #@equipment['dut1'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut1'].respond_to?(:boot)# call bootscript if required

  #Setting the maximum number of sockets the dut can 
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
  #Setting the encoders and/or decoders parameters
  
  
  #Setting the engine type
  video_engine = case @test_params.params_chan.test_type[0]
          when /vpfe\w*vpbe/ : "encdec"
          when /encode/ : "encode"
          when /decode/ : "decode"
           end
  
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => video_engine})
  
  #Setting the video encoder and vpfe
  if @test_params.params_chan.test_type[0].include?("vpfe")
    if @test_params.params_chan.test_type[0].include?("resize")
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => get_video_driver_height(@test_params.params_chan.video_region[0])})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => get_video_driver_width(@test_params.params_chan.video_region[0])})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "width", "Value" => @test_params.params_chan.video_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "height", "Value" => @test_params.params_chan.video_signal_format[0]})
    else
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_signal_format[0]})
    end
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => get_video_num_frames})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "input", "Value" => @test_params.params_chan.video_iface_type[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "format", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
  end
  
  if @test_params.params_chan.test_type[0].include?("encode")
      #Setting the video encoder
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "codec", "Value" => "h264enc"})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxHeight", "Value" => [576,@test_params.params_chan.video_height[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxFrameRate", "Value" => '30000'})  
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "framePitch", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "intraFrameInterval", "Value" => @test_params.params_chan.video_gop[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "forceIFrame", "Value" => @test_params.params_chan.video_force_iframe[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "rcAlgo", "Value" => @test_params.params_chan.video_rc_algo[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "qpMin", "Value" => @test_params.params_chan.video_qp_min[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "qpMax", "Value" => @test_params.params_chan.video_qp_max[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "qpInter", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "qpIntra", "Value" => @test_params.params_chan.video_qp_intra[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "lfDisableIdc", "Value" => @test_params.params_chan.video_lf_disable_idc[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "filterOffsetA", "Value" => @test_params.params_chan.video_filter_offset_a[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "filterOffsetB", "Value" => @test_params.params_chan.video_filter_offset_b[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxMBsPerSlice", "Value" => @test_params.params_chan.video_max_mb_per_slice[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxBytesPerSlice", "Value" => @test_params.params_chan.video_max_bytes_per_slice[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "sliceRefreshRowStartNumber", "Value" => @test_params.params_chan.video_slice_refresh_row_start_num[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "sliceRefreshNumber", "Value" => @test_params.params_chan.video_slice_refresh_num[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "constrainedIntraPredEnable", "Value" => @test_params.params_chan.video_constr_intra_pred_enabled[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "airMbPeriod", "Value" => @test_params.params_chan.video_air_mb_period[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "quartPelDisable", "Value" => @test_params.params_chan.video_quarter_pel_disable[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "picOrderCountType", "Value" => @test_params.params_chan.video_pic_order_cnt[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "log2MaxFNumMinus4", "Value" => @test_params.params_chan.video_log2_maxf_num_minus4[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "chromaQPIndexOffset", "Value" => @test_params.params_chan.video_chroma_qp_index_offset[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "secChromaQPOffset", "Value" => @test_params.params_chan.video_sec_chroma_qp_index_offset[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "searchRange", "Value" => @test_params.params_chan.video_search_range[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "levelIdc", "Value" => @test_params.params_chan.video_level[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "generateHeader", "Value" => '0'})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "dataEndianness", "Value" => @test_params.params_chan.video_data_endianness[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "profileIdc", "Value" => @test_params.params_chan.video_profile[0]})  
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "inputContentType", "Value" => @test_params.params_chan.video_input_content_type[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "entropyCodingMode", "Value" => @test_params.params_chan.video_entropy_coding[0]})    
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "numRowsInSlice", "Value" => @test_params.params_chan.video_num_rows_per_slice[0]})  
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "numframes", "Value" => get_video_num_frames})
    
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "transform8x8FlagIntraFrame", "Value" => @test_params.params_chan.video_transform_8x8_i_frame_flag[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "transform8x8FlagInterFrame", "Value" => @test_params.params_chan.video_transform_8x8_p_frame_flag[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "aspectRatioX", "Value" => @test_params.params_chan.video_aspect_ratio_x[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "aspectRatioY", "Value" => @test_params.params_chan.video_aspect_ratio_y[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "pixelRange", "Value" => @test_params.params_chan.video_pixel_range[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "timeScale", "Value" => @test_params.params_chan.video_time_scale[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "numUnitsInTicks", "Value" => @test_params.params_chan.video_num_units_ticks[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "enableVUIparams", "Value" => @test_params.params_chan.video_enable_vui_params[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "reset_vIMCOP_every_frame", "Value" => @test_params.params_chan.video_reset_hdivc_every_frame[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "disableHDVICPeveryFrame", "Value" => @test_params.params_chan.video_disable_hdivc_every_frame[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "meAlgo", "Value" => @test_params.params_chan.video_me_algo[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "umv", "Value" => @test_params.params_chan.video_use_umv[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "seqScalingFlag", "Value" => @test_params.params_chan.video_sequence_scaling_flag[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "encQuality", "Value" => @test_params.params_chan.video_enc_quality[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "initQ", "Value" => ((@test_params.params_chan.video_qp_min[0].to_i+@test_params.params_chan.video_qp_max[0].to_i)/2).floor.to_s})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "maxDelay", "Value" => @test_params.params_chan.video_max_delay[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "meMultiPart", "Value" => @test_params.params_chan.video_me_multipart[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "enableBufSEI", "Value" => @test_params.params_chan.video_enable_buf_sei[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "enablePicTimSEI", "Value" => @test_params.params_chan.video_enable_pic_timing_sei[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "intraThrQF", "Value" => @test_params.params_chan.video_intra_thresh_qf[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "perceptualRC", "Value" => @test_params.params_chan.video_perceptual_rc[0]})
    @equipment['dut1'].set_param({"Class" => "h264extenc", "Param" => "idrFrameInterval", "Value" => @test_params.params_chan.video_idr_frame_interval[0]})
  end
  
  #Setting the video decoder and vpbe
  if @test_params.params_chan.test_type[0].include?("vpbe")
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "output", "Value" => @test_params.params_chan.video_iface_type[0]})
  end
  
  if @test_params.params_chan.test_type[0].include?("decode")
    #Making the video connection
    @connection_handler.make_video_connection({@equipment["dut"] => 0}, {@equipment["video_tester"] => 0, @equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
    #Setting the video decoder
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "codec", "Value" => "h264dec"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => "576"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => "720"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"forceChromaFormat", "Value" => map_dut_chroma_format(@test_params.params_chan.video_output_chroma_format[0])})
  end
  
  #Setting the audio encoder and apfe
  if @test_params.params_chan.test_type[0].include?("apfe")
      @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0]] => 0},{@equipment["dut1"] => 0, @equipment["tv0"] => 0}, @test_params.params_chan.audio_iface_type[0])
    #Setting the audio encode
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "numframes", "Value" => get_audio_num_frames(@test_params.params_control.media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"codec", "Value" => "g711enc"})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"compandingLaw", "Value" => map_dut_audio_companding(@test_params.params_chan.audio_companding[0])})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"frameSize", "Value" => get_audio_frame_size.to_s})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"vadSelection", "Value" => "0"})
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio" , "Param" => "seconds", "Value" => ((get_audio_num_frames(@test_params.params_control.media_time[0])/@test_params.params_chan.audio_sampling_rate[0].to_f/get_audio_frame_size).to_i).to_s})
  end
  
  #Settings for the audio decoder and apbe
  if @test_params.params_chan.test_type[0].include?("apbe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment["dut1"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])  
    #Setting the audio decoder
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "numframes","Value" => get_audio_num_frames(@test_params.params_control.media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "codec", "Value" => "g711dec"})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "compandingLaw", "Value" => map_dut_audio_companding(@test_params.params_chan.audio_companding[0])})
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => get_audio_frame_size.to_s})
  end
end


def run
  puts "Test Type: "+  @test_params.params_chan.test_type[0]
  if @test_params.params_chan.test_type[0].include?("vpfe")
    channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
    @connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["dut1"] => channel_number, @equipment['tv0'] => 0}, @test_params.params_chan.video_iface_type[0])
  end
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("H264 G711 #{@test_params.params_chan.test_type[0]} Test Result Form")
    if @test_params.params_chan.test_type[0].include?("vpfe")
      0.upto(channel_number) do |ch_num|
        test_file = LOCAL_FILES_FOLDER+"video_"+@test_params.params_chan.video_source[0]+"_"+@test_params.params_chan.video_width[0]+"x"+@test_params.params_chan.video_height[0]+"_"+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+"fps_"+get_video_num_frames+"frames_chan"+ch_num.to_s+"_test.264"
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        @equipment['dut1'].h264ext_encoding({"Target" => test_file})
      end
      audio_ref_file, audio_test_file = run_audio_process(file_res_form) if @test_params.params_control.audio_num_channels[0].to_i > 0
      @equipment['dut1'].wait_for_threads
    elsif @test_params.params_chan.test_type[0].include?("vpbe")
      @test_params.params_chan.video_source.each do |vid_source|
        #======================== Prepare reference files ==========================================================
        puts "Decoding #{vid_source} ....."
        ref_file, local_ref_file = get_ref_file('Video', vid_source)
        # Start decoding function
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => "0"})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"numframes", "Value" => get_number_of_video_frames(vid_source)})
        @equipment['dut1'].video_decoding({"Source" => local_ref_file, "threadId" => 'h264dec'})
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
    @equipment['dut1'].get_param({"Class" => "vpfe", "Param" => ""})
    @equipment['dut1'].get_param({"Class" => "h264extenc", "Param" => ""})
    @equipment['dut1'].get_param({"Class" => "viddec", "Param" => ""})
    @equipment['dut1'].get_param({"Class" => "vpbe", "Param" => ""})
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)

end

def clean

end



private 

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def get_audio_num_frames(audio_time)
  (audio_time.to_f*@test_params.params_chan.audio_sampling_rate[0].to_f/get_audio_frame_size).round
end

def get_audio_ext
  if @test_params.params_chan.audio_companding[0].include?("ulaw")
    ".u"
  else
    ".a"
  end
end

def get_ref_file(start_directory, file_name)
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
  FileUtils.cp(ref_file, local_ref_file)
  [ref_file,local_ref_file]
end

def get_video_num_frames
  (@test_params.params_control.media_time[0].to_f*@test_params.params_chan.video_frame_rate[0].to_f).round.to_s
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def get_number_of_video_frames(file)
        /(\d+)frames/.match(file).captures[0]
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round.to_s
end

def get_audio_frame_size
    bytes_per_sample = 2
    audio_channels = 1
   # bytes_per_sample*@test_params.params_chan.audio_sampling_rate[0].to_i*audio_channels
    1024
end

def run_audio_process(result_form)
  local_ref_file = ""
  if @test_params.params_chan.test_type[0].include?("apfe") && @test_params.params_chan.test_type[0].include?("apbe") 
    @equipment['dut1'].speech_encoding_decoding
  elsif @test_params.params_chan.test_type[0].include?("apfe")  
    test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_codec[0]+"_"+@test_params.params_chan.audio_companding[0]+"_"+@test_params.params_chan.audio_source[0]+get_audio_ext()
    result_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
    @equipment['dut1'].speech_encoding({"Target" => test_file, "threadId" => 'g711enc'})
  elsif @test_params.params_chan.test_type[0].include?("apbe")
    ref_file,local_ref_file = get_ref_file('Speech', @test_params.params_chan.audio_source[0])
    @equipment['dut1'].speech_decoding({"Source" => local_ref_file, "threadId" => 'g711dec'})
  end
  [local_ref_file,test_file]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end