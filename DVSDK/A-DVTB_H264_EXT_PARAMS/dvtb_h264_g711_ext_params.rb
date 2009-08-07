
NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'
OPERA_WAIT_TIME           = 30000

def setup
  @equipment['dut'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  @equipment['dut'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut'].respond_to?(:boot)# call bootscript if required

  #Setting the maximum number of sockets the dut can support
  @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
  #Setting the encoders and/or decoders parameters
  
  
  #Setting the engine type
  video_engine = case @test_params.params_chan.test_type[0]
          when /vpfe\w*vpbe/ : "encdec"
          when /encode/ : "encode"
          when /decode/ : "decode"
           end
  
  @equipment['dut'].set_param({"Class" => "engine", "Param" => "name", "Value" => video_engine})
  
  #Setting the video encoder and vpfe
  if @test_params.params_chan.test_type[0].include?("vpfe")
    if @test_params.params_chan.test_type[0].include?("resize")
        @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => get_video_driver_height(@test_params.params_chan.video_region[0])})
      @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => get_video_driver_width(@test_params.params_chan.video_region[0])})
      @equipment['dut'].set_param({"Class" => "resizer", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
      @equipment['dut'].set_param({"Class" => "resizer", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    else
      @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
      @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    end
    @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "input", "Value" => @test_params.params_chan.video_iface_type[0]})
    @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "format", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
  end
  
  if @test_params.params_chan.test_type[0].include?("encode")
      #Setting the video encoder
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "codec", "Value" => "h264enc"})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxHeight", "Value" => [576,@test_params.params_chan.video_height[0].to_i].max.to_s})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxFrameRate", "Value" => '30000'})  
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "framePitch", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "intraFrameInterval", "Value" => @test_params.params_chan.video_gop[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "forceIFrame", "Value" => @test_params.params_chan.video_force_iframe[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "rcAlgo", "Value" => @test_params.params_chan.video_rc_algo[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "qpMin", "Value" => @test_params.params_chan.video_qp_min[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "qpMax", "Value" => @test_params.params_chan.video_qp_max[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "qpInter", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "qpIntra", "Value" => @test_params.params_chan.video_qp_intra[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "lfDisableIdc", "Value" => @test_params.params_chan.video_lf_disable_idc[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "filterOffsetA", "Value" => @test_params.params_chan.video_filter_offset_a[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "filterOffsetB", "Value" => @test_params.params_chan.video_filter_offset_b[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxMBsPerSlice", "Value" => @test_params.params_chan.video_max_mb_per_slice[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxBytesPerSlice", "Value" => @test_params.params_chan.video_max_bytes_per_slice[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "sliceRefreshRowStartNumber", "Value" => @test_params.params_chan.video_slice_refresh_row_start_num[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "sliceRefreshNumber", "Value" => @test_params.params_chan.video_slice_refresh_num[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "constrainedIntraPredEnable", "Value" => @test_params.params_chan.video_constr_intra_pred_enabled[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "airMbPeriod", "Value" => @test_params.params_chan.video_air_mb_period[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "quartPelDisable", "Value" => @test_params.params_chan.video_quarter_pel_disable[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "picOrderCountType", "Value" => @test_params.params_chan.video_pic_order_cnt[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "log2MaxFNumMinus4", "Value" => @test_params.params_chan.video_log2_maxf_num_minus4[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "chromaQPIndexOffset", "Value" => @test_params.params_chan.video_chroma_qp_index_offset[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "secChromaQPOffset", "Value" => @test_params.params_chan.video_sec_chroma_qp_index_offset[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "searchRange", "Value" => @test_params.params_chan.video_search_range[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "levelIdc", "Value" => @test_params.params_chan.video_level[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "generateHeader", "Value" => '0'})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "dataEndianness", "Value" => @test_params.params_chan.video_data_endianness[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "profileIdc", "Value" => @test_params.params_chan.video_profile[0]})  
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "inputContentType", "Value" => @test_params.params_chan.video_input_content_type[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "entropyCodingMode", "Value" => @test_params.params_chan.video_entropy_coding[0]})    
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numRowsInSlice", "Value" => @test_params.params_chan.video_num_rows_per_slice[0]})  
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numframes", "Value" => get_video_num_frames})
    
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "transform8x8FlagIntraFrame", "Value" => @test_params.params_chan.video_transform_8x8_i_frame_flag[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "transform8x8FlagInterFrame", "Value" => @test_params.params_chan.video_transform_8x8_p_frame_flag[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "aspectRatioX", "Value" => @test_params.params_chan.video_aspect_ratio_x[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "aspectRatioY", "Value" => @test_params.params_chan.video_aspect_ratio_y[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "pixelRange", "Value" => @test_params.params_chan.video_pixel_range[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "timeScale", "Value" => @test_params.params_chan.video_time_scale[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numUnitsInTicks", "Value" => @test_params.params_chan.video_num_units_ticks[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "enableVUIparams", "Value" => @test_params.params_chan.video_enable_vui_params[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "reset_vIMCOP_every_frame", "Value" => @test_params.params_chan.video_reset_hdivc_every_frame[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "disableHDVICPeveryFrame", "Value" => @test_params.params_chan.video_disable_hdivc_every_frame[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "meAlgo", "Value" => @test_params.params_chan.video_me_algo[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "umv", "Value" => @test_params.params_chan.video_use_umv[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "seqScalingFlag", "Value" => @test_params.params_chan.video_sequence_scaling_flag[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "encQuality", "Value" => @test_params.params_chan.video_enc_quality[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "initQ", "Value" => ((@test_params.params_chan.video_qp_min[0].to_i+@test_params.params_chan.video_qp_max[0].to_i)/2).floor.to_s})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "maxDelay", "Value" => @test_params.params_chan.video_max_delay[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "meMultiPart", "Value" => @test_params.params_chan.video_me_multipart[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "enableBufSEI", "Value" => @test_params.params_chan.video_enable_buf_sei[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "enablePicTimSEI", "Value" => @test_params.params_chan.video_enable_pic_timing_sei[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "intraThrQF", "Value" => @test_params.params_chan.video_intra_thresh_qf[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "perceptualRC", "Value" => @test_params.params_chan.video_perceptual_rc[0]})
    @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "idrFrameInterval", "Value" => @test_params.params_chan.video_idr_frame_interval[0]})
  end
  
  #Setting the video decoder and vpbe
  if @test_params.params_chan.test_type[0].include?("vpbe")
    @equipment['dut'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "output", "Value" => @test_params.params_chan.video_iface_type[0]})
  end
  
  if @test_params.params_chan.test_type[0].include?("decode")
    #Making the video connection
    @connection_handler.make_video_connection({@equipment["dut"] => 0}, {@equipment["video_tester"] => 0, @equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
    #Setting the video decoder
    @equipment['dut'].set_param({"Class" => "viddec", "Param" => "codec", "Value" => "h264dec"})
    @equipment['dut'].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
    @equipment['dut'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment['dut'].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => "576"})
    @equipment['dut'].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => "720"})
    @equipment['dut'].set_param({"Class" => "viddec", "Param" =>"forceChromaFormat", "Value" => map_dut_chroma_format(@test_params.params_chan.video_output_chroma_format[0])})
  end
  
  #Setting the audio encoder and apfe
  if @test_params.params_chan.test_type[0].include?("apfe")
    #Setting the audio encoder
    @equipment['dut'].set_param({"Class" => "sphenc", "Param" => "numframes", "Value" => get_audio_num_frames(@test_params.params_control.audio_media_time[0]).to_s})
    @equipment['dut'].set_param({"Class" => "sphenc", "Param" =>"codec", "Value" => "g711enc"})
    @equipment['dut'].set_param({"Class" => "sphenc", "Param" =>"compandingLaw", "Value" => map_dut_audio_companding(@test_params.params_chan.audio_companding[0])})
    @equipment['dut'].set_param({"Class" => "sphenc", "Param" =>"frameSize", "Value" => get_audio_frame_size.to_s})
    @equipment['dut'].set_param({"Class" => "sphenc", "Param" =>"vadSelection", "Value" => "0"})
    #Setting ap_e parameters
    @equipment['dut'].set_param({"Class" => "audio" , "Param" => "seconds", "Value" => ((get_audio_num_frames(@test_params.params_control.audio_media_time[0])/@test_params.params_chan.audio_sampling_rate[0].to_f/get_audio_frame_size).to_i).to_s})
  end
  
  #Settings for the audio decoder and apbe
  if @test_params.params_chan.test_type[0].include?("apbe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment["dut"] => 0}, {@equipment["audio_player"] => 0, @equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])  
    #Setting the audio decoder
    @equipment['dut'].set_param({"Class" => "sphdec", "Param" => "numframes","Value" => get_audio_num_frames(@test_params.params_control.audio_media_time[0]).to_s})
    @equipment['dut'].set_param({"Class" => "sphdec", "Param" => "codec", "Value" => "g711dec"})
    @equipment['dut'].set_param({"Class" => "sphdec", "Param" => "compandingLaw", "Value" => map_dut_audio_companding(@test_params.params_chan.audio_companding[0])})
    #Setting ap_e parameters
    @equipment['dut'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => get_audio_frame_size.to_s})
  end
end


def run
  audio_ref_file = audio_test_file = audio_input_handle = audio_output_handle = nil   
  test_comment = ''
  test_done_result = nil
  video_channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
  audio_channel_number = get_chan_number(@test_params.params_control.audio_num_channels[0].to_i) 
  @connection_handler.make_video_connection({@equipment["video_tester"] => 0}, {@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},"sdi")
	@connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0}, {@equipment["video_tester"] => 0}, "sdi")	
	@connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0}, {@equipment["dut"] => video_channel_number, @equipment["tv0"] => 0},@test_params.params_chan.video_iface_type[0]) 
  @connection_handler.make_audio_connection({@equipment["audio_player"] => 0},{@equipment["dut"] => audio_channel_number, @equipment["tv0"] => 0}, 'mini35mm')   
  @connection_handler.make_audio_connection({@equipment["dut"] => audio_channel_number},{@equipment["audio_player"] => 0, @equipment['tv1'] => 0}, 'mini35mm')
  @connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment['tv1'] => 0}, @test_params.params_chan.video_iface_type[0])
   
  #======================== Processing Media ====================================================
  @test_params.params_chan.video_source.each do |vid_source|
    audio_ref_file = audio_test_file = audio_input_handle = audio_output_handle = nil   
    metric_window = get_metric_window
    if @test_params.params_chan.test_type[0].include?("vpfe") && @test_params.params_chan.test_type[0].include?("vpbe")
      ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      test_file = local_ref_file.gsub(".yuv","_test.avi")
      @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numframes", "Value" => get_video_num_frames(vid_source)})
      @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => get_video_num_frames(vid_source)})
      puts "Encoding+Decoding #{vid_source} ....."
      0.upto(video_channel_number) do |ch_num|
        @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        if ch_num == video_channel_number
          @equipment['dut'].h264ext_encoding_decoding()
        else
          @equipment['dut'].h264ext_encoding({"Target" => LOCAL_FILES_FOLDER+@test_params.params_chan.video_source[0].gsub(".avi","_test_ch"+ch_num.to_s+".264"), "threadId" => 'h264enc'})
        end
      end
      vid_enc_dec_params = {'ref_clip' => local_ref_file, 'test_clip' => test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                        'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => @test_params.params_chan.video_height[0],
                        'video_width' =>@test_params.params_chan.video_width[0], 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => @test_params.params_chan.video_frame_rate[0],
                        'metric_window' => metric_window
      }
      @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},{@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] =>0},@test_params.params_chan.video_iface_type[0])  
        video_tester_result = @equipment['video_tester'].video_out_to_video_in_test(vid_enc_dec_params){
         @connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},@test_params.params_chan.display_out[0])
				 sleep 1
         audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0
       }
      bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0
      @equipment['dut'].wait_for_threads
    elsif @test_params.params_chan.test_type[0].include?("vpfe")
      ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      test_file = local_ref_file.gsub(/\d+frames/,(get_te_video_num_frames(vid_source)*2).to_s+"frames").gsub(".yuv","_test_ch"+rand(video_channel_number+1).to_s+".264")
      vid_enc_params = {'ref_clip' => local_ref_file, 'test_file' =>  test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                        'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => @test_params.params_chan.video_height[0],
                        'video_width' =>@test_params.params_chan.video_width[0], 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => @test_params.params_chan.video_frame_rate[0],
                        'metric_window' => metric_window
                        }
      @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},{@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] =>0},@test_params.params_chan.video_iface_type[0])
      @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numframes", "Value" => (get_te_video_num_frames(vid_source)*2).to_s})
      @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => (get_te_video_num_frames(vid_source)*2).to_s})
      puts "Encoding #{vid_source} ....."
      video_tester_result = @equipment['video_tester'].video_out_to_file_test(vid_enc_params){
        0.upto(video_channel_number) do |ch_num|
          @equipment['dut'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
          @equipment['dut'].h264ext_encoding({"Target" => local_ref_file.gsub(/\d+frames/,(get_te_video_num_frames(vid_source)*2).to_s+"frames").gsub(".yuv","_test_ch"+ch_num.to_s+".264"), "threadId" => 'h264enc'})
        end
        audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0
        @equipment['dut'].wait_for_threads
        bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0
      }
    elsif @test_params.params_chan.test_type[0].include?("vpbe")
      #======================== Prepare reference files ==========================================================  
      ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder', vid_source)
      test_file = local_ref_file.sub(/\.\w*$/,'_test.avi')
      vid_dec_params = {'ref_clip' => local_ref_file, 'test_clip' =>  test_file, 'format' => @test_params.params_chan.video_signal_format[0],
                        'num_frames' => get_te_video_num_frames(vid_source), 'metric_window' => metric_window              
                        }
      @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},{@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] =>0},@test_params.params_chan.video_iface_type[0])
      puts "Decoding #{vid_source} ....."
      video_tester_result = @equipment['video_tester'].file_to_video_in_test(vid_dec_params){  
        @equipment['dut'].video_decoding({"Source" => LOCAL_FILES_FOLDER+vid_source, "threadId" => 'h264dec'})
        @connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["#{@test_params.params_chan.video_iface_type[0]}_converter"] => 0},@test_params.params_chan.video_iface_type[0])
        audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0  
      }
      @equipment['dut'].wait_for_threads
      bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0
    elsif @test_params.params_chan.test_type[0].include?("encoder")
      ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      test_file = local_ref_file.sub(/\.yuv$/,'_test.264')
      @equipment['dut'].set_param({"Class" => "h264extenc", "Param" => "numframes", "Value" => get_te_video_num_frames(vid_source).to_s})
      @equipment['dut'].h264ext_encoding({"Source" => local_ref_file , "Target" => test_file, "threadId" => 'h264enc'})
      puts "Encoding #{vid_source} ....."
      @equipment['dut'].wait_for_threads
      video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => local_ref_file, 
                                                                           'test_file' => test_file,
                                                                           'data_format' => @test_params.params_chan.video_input_chroma_format[0],
                                                                           'format' => get_video_tester_format,
                                                                           'video_height' => @test_params.params_chan.video_height[0],
                                                                           'video_width' =>@test_params.params_chan.video_width[0],
                                                                           'num_frames' => get_te_video_num_frames(vid_source),
                                                                           'frame_rate' => @test_params.params_chan.video_frame_rate[0],
                                                                           'metric_window' => metric_window})
            
    elsif @test_params.params_control.audio_num_channels[0].to_i > 0 
      audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) 
      @equipment['dut'].wait_for_threads
      stop_audio_process
    end
    if  !video_tester_result
      @results_html_file.add_paragraph("")
      test_done_result = FrameworkConstants::Result[:fail]
      test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{vid_source}\n"   
    else    
      video_done_result, video_done_comment = get_results(audio_ref_file, audio_test_file, test_file)
      test_comment += video_done_comment+"\n"
      test_done_result = video_done_result if test_done_result !=   FrameworkConstants::Result[:fail]
    end
  end
  rescue Exception => e
    test_done_result = FrameworkConstants::Result[:fail]
    test_comment += e.to_s
    stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0 && (audio_input_handle || audio_output_handle)
    @equipment['dut'].wait_for_threads
    raise e
  ensure
    set_result(test_done_result,test_comment) 
end

def clean

end



private 

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def map_dut_audio_companding(companding)
  case companding.strip.downcase
    when "alaw"
      1.to_s
    when "ulaw"
      2.to_s
    when "linear"
      0.to_s
    else
      raise "Companding type "+companding.to_s+" not supported"
    end
end

def run_audio_process(audio_channel_number)
  local_ref_file = ""
  audio_params = {  "alignment" => 2,
                      "bits_per_sample" => 16,
                      "channels" => 1,
                      "samples_per_sec" => 8000,
                      "avg_bytes_per_sec" => 16000,
            "device_type" => 'analog',
            "device_id" => 0,
                      }
  audio_input_handle = 0
  audio_output_handle = 0
  audio_input_handle = @equipment['audio_player'].open_wave_in_audio_device(audio_params)
  audio_output_handle = @equipment['audio_player'].open_wave_out_audio_device(audio_params)
  if @test_params.params_chan.test_type[0].include?("apfe") && @test_params.params_chan.test_type[0].include?("apbe")
    ref_file,local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/',@test_params.params_chan.audio_source[0]+".pcm")
    test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test.pcm"
    0.upto(audio_channel_number) do |ch_num|
      @equipment['dut'].speech_encoding_decoding  # Multiple Audio Channel are not supported yet
    end
    @equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
    @equipment['audio_player'].play_wave_audio(audio_output_handle, local_ref_file)
    elsif @test_params.params_chan.test_type[0].include?("apfe")  
    test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test"+get_audio_ext()
    pcm_ref_file, pcm_local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
    ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
    0.upto(audio_channel_number) do |ch_num|
      @equipment['dut'].speech_encoding({"Target" => test_file})  # Multiple Audio Channel are not supported yet
    end
    @equipment['audio_player'].play_wave_audio(audio_output_handle, pcm_local_ref_file)
  elsif @test_params.params_chan.test_type[0].include?("apbe")
      test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test.pcm"
    companded_ref_file, companded_local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
    ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
    @equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
    @equipment['dut'].speech_decoding({"Source" => companded_local_ref_file})
  end
  [local_ref_file,test_file,audio_input_handle, audio_output_handle]
end

def stop_audio_process(audio_input_handle, audio_output_handle)
   while !@equipment['audio_player'].wave_audio_play_done(audio_output_handle)
    sleep(1)
   end
   sleep(1)
   bytes_recorded = nil
   bytes_recorded = @equipment['audio_player'].stop_wave_audio_record(audio_input_handle) if @test_params.params_chan.test_type[0].include?("apbe")
   @equipment['audio_player'].stop_wave_audio_play(audio_output_handle) if @test_params.params_chan.test_type[0].include?("apfe")
   @equipment['audio_player'].close_wave_in_device(audio_input_handle)
   @equipment['audio_player'].close_wave_out_device(audio_output_handle)
   [bytes_recorded, nil, nil]   
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

def get_te_video_num_frames(vid_source)
    file_num_frames = /(\d+)frames/.match(vid_source).captures[0].to_i
    file_num_frames
end

def get_video_num_frames(vid_source)
    file_num_frames = /(\d+)frames/.match(vid_source).captures[0].to_i
    if @test_params.params_chan.test_type[0].include?("vpbe")
    ([@test_params.params_chan.video_frame_rate[0].to_i,30].max*@test_params.params_control.setup_delay[0].to_i+2*file_num_frames).to_s
  else
    [1024,file_num_frames+(3*@test_params.params_chan.video_frame_rate[0].to_i).round].min.to_s
  end
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round.to_s
end

def get_results(audio_ref_file,audio_test_file, video_file)
  test_done_result = FrameworkConstants::Result[:pass]
  @results_html_file.add_paragraph("")
    test_comment = " "  
  res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
  
  if @test_params.params_chan.test_type[0].include?("vpfe") || @test_params.params_chan.test_type[0].include?("vpbe")
    pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
    
    @results_html_file.add_row_to_table(res_table, [["h264 Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
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
    else
      if @equipment['video_tester'].get_mos_score < pass_fail_criteria[1].to_f #|| @equipment['video_tester'].get_jerkiness_score < 3.5 || @equipment['video_tester'].get_level_score > 2 ||  @equipment['video_tester'].get_blocking_score < 3.5 || @equipment['video_tester'].get_blurring_score < 3.5 || @equipment['video_tester'].get_frame_lost_count > 0 || @equipment['video_tester'].get_psnr_score < 28
        test_done_result = FrameworkConstants::Result[:fail]      
      end
        @results_html_file.add_row_to_table(res_table,["MOS",@equipment["video_tester"].get_mos_score])
        @results_html_file.add_row_to_table(res_table,["Blockiness",@equipment["video_tester"].get_blocking_score])
        @results_html_file.add_row_to_table(res_table,["Blurring",@equipment["video_tester"].get_blurring_score])  
        @results_html_file.add_row_to_table(res_table,["Frames Lost",@equipment["video_tester"].get_frame_lost_count])
        @results_html_file.add_row_to_table(res_table,["Jerkiness",@equipment["video_tester"].get_jerkiness_score])
        @results_html_file.add_row_to_table(res_table,["Level",@equipment["video_tester"].get_level_score])
        @results_html_file.add_row_to_table(res_table,["PSNR",@equipment["video_tester"].get_psnr_score])
    end
    
    if test_done_result == FrameworkConstants::Result[:fail]
      test_comment = "Test failed for file "+File.basename(video_file)+"."
      failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+'_.avi')
      File.copy(video_file, failed_file_name)
      @results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
    end
  end
  
  if (@test_params.params_chan.test_type[0].include?("apfe") || @test_params.params_chan.test_type[0].include?("apbe")) && @test_params.params_control.audio_num_channels[0].to_i > 0
    tid = @equipment['speech_tester'].pesq_start_calculation(audio_ref_file , 1, 0, audio_test_file, 1, 0, map_recorded_audio_format) 
    @equipment['speech_tester'].Wait(tid, OPERA_WAIT_TIME) 
    pesq_mos = @equipment['speech_tester'].PesqGetScore(tid)
    pesq_lq_mos = @equipment['speech_tester'].PesqGetMosLQOScore(tid)
    pesq_mos2 = @equipment['speech_tester'].PesqGetMosScore(tid)
    pesq_speech = @equipment['speech_tester'].PesqGetSpeechScore(tid)
    pesq_noise = @equipment['speech_tester'].PesqGetNoiseScore(tid)
    pesq_att = @equipment['speech_tester'].PesqGetAttenuation(tid)
    pesq_min_del = @equipment['speech_tester'].PesqGetMinDel(tid)
    pesq_nom_del = @equipment['speech_tester'].PesqGetNomDel(tid)
    pesq_max_del = @equipment['speech_tester'].PesqGetMaxDel(tid)
    
    if pesq_mos < 4.0 
      test_done_result = FrameworkConstants::Result[:fail]
      test_comment = test_comment.to_s+" Test failed for file "+File.basename(audio_ref_file)
      audio_test_file_ext = /\..*$/.match(audio_test_file)[0]
      audio_test_file_copy = audio_test_file.gsub(audio_test_file_ext,"_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+audio_test_file_ext)
      File.cp(audio_test_file,audio_test_file_copy)
            @results_html_file.add_paragraph(File.basename(audio_test_file_copy),nil,nil,"//"+audio_test_file_copy.gsub("\\","/"))
    end
    @results_html_file.add_row_to_table(res_table, [["G711 Scores #{File.basename(audio_ref_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
    @results_html_file.add_row_to_table(res_table,["MOS",pesq_mos])
    @results_html_file.add_row_to_table(res_table,["LQ_MOS",pesq_lq_mos])
    @results_html_file.add_row_to_table(res_table,["MOS2",pesq_mos2])
    @results_html_file.add_row_to_table(res_table,["Speech",pesq_speech])
    @results_html_file.add_row_to_table(res_table,["Noise",pesq_noise])
    @results_html_file.add_row_to_table(res_table,["Attenuation",pesq_att])
    @results_html_file.add_row_to_table(res_table,["Min_delay",pesq_min_del])
    @results_html_file.add_row_to_table(res_table,["Nom_delay",pesq_nom_del])
    @results_html_file.add_row_to_table(res_table,["Max_delay",pesq_max_del])
  end

  [test_done_result, test_comment]
end

def map_recorded_audio_format
  if @test_params.params_chan.test_type[0].include?("apfe") && @test_params.params_chan.test_type[0].include?("apbe")
      companding = "linear"
  else
      companding = @test_params.params_chan.audio_companding[0]
  end  
  if  companding == "ulaw" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
    FileFormat.new(0)
  elsif companding == "alaw" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
    FileFormat.new(1)
  elsif companding == "ulaw" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
    FileFormat.new(2)
  elsif companding == "alaw" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
    FileFormat.new(3)
  elsif companding == "linear" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
    FileFormat.new(4)
  elsif companding == "linear" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
    FileFormat.new(5)
  else
    raise "Unsupported G711 recorded audio format companding = "+@test_params.params_chan.audio_companding[0]+" sampling rate = "+@test_params.params_chan.audio_sampling_rate[0]
  end
end

def get_qmaster_avi_file(file_name)
  num_frames = /_(\d+)frames/.match(file_name).captures[0].to_i
  ref_bmp_file = YuvToBmpConverter.new
  ref_bmp_file.convert( {'inFile' => file_name,
                           'inSamplingFormat'  => 'yuv422',
                 'inComponentOrder' => 'yuv',
               'inFieldFormat'     => 'progressive',
               'inPixelFormat'     => 'packed',
               'inHeight'          => "#{@test_params.params_chan.video_height[0]}",
               'inWidth'           => "#{@test_params.params_chan.video_width[0]}",
               'outFile' => file_name.gsub(/\.yuv/, "_h264_g711_qmaster_dec.bmp"),  
               'outSamplingFormat' => 'BMP',
               'outFieldFormat'    => 'progressive',
               'outPixelFormat'    => "planar" })
  ref_avi_file = BmpToAviConverter.new
  ref_avi_file.convert({'start'             => file_name.gsub(/\.yuv/, '_h264_g711_qmaster_dec_0000.bmp'), 
              'end'               => file_name.gsub('.yuv','_h264_g711_qmaster_dec_'+'0'*(4-(num_frames-1).to_s.length)+(num_frames-1).to_s+'.bmp'), 
              'frameRate'         => @test_params.params_chan.video_frame_rate[0],
              'output'            => file_name.gsub('.yuv','_h264_g711_qmaster_dec.avi')})
  
  file_name.gsub('.yuv','_h264_g711_qmaster_dec.avi')
end

def get_audio_frame_size
  bytes_per_sample = 2
  audio_channels = 1
 # bytes_per_sample*@test_params.params_chan.audio_sampling_rate[0].to_i*audio_channels
  1024
end

def get_metric_window
  ti_logo_height = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[1].to_i
  ti_logo_width = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[0].to_i

  video_signal_height = @equipment['video_tester'].get_video_signal_height({'format' => @test_params.params_chan.video_signal_format[0]})
  video_signal_width = @equipment['video_tester'].get_video_signal_width({'format' => @test_params.params_chan.video_signal_format[0]})
  
  x_offset = [0,((video_signal_width - @test_params.params_chan.video_width[0].to_i)/2).ceil].max
  y_offset = [0,((video_signal_height - @test_params.params_chan.video_height[0].to_i)/2).ceil].max
  metric_window_width = @test_params.params_chan.video_width[0].to_i
  metric_window_height = @test_params.params_chan.video_height[0].to_i
  if rand < 0.5
    metric_window_width -= ti_logo_width
  else
      metric_window_height -= ti_logo_height
      y_offset+=ti_logo_height
  end
  [x_offset, y_offset, metric_window_width, metric_window_height] 
end

def get_video_tester_format
  [@test_params.params_chan.video_width[0].to_i,@test_params.params_chan.video_height[0].to_i, @test_params.params_chan.video_frame_rate[0].to_i]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end