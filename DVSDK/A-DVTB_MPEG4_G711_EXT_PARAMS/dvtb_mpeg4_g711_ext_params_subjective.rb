
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
  
  #Setting the maximum number of sockets the dut can support
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,0)
  #Setting the encoders and/or decoders parameters
  
  
  #Setting the engine type 
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'encode'})
  
  #Setting the video encoder and vpfe
  if @test_params.params_chan.test_type[0].include?("vpfe")
      #Setting the video encoder
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "codec", "Value" => "mpeg4enc"})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "maxHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "maxWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "maxFrameRate", "Value" => '30000'})
    if @test_params.params_chan.test_type[0].include?("resize")
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => get_video_driver_height(@test_params.params_chan.video_region[0])})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => get_video_driver_width(@test_params.params_chan.video_region[0])})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    else
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    end
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "input", "Value" => @test_params.params_chan.video_iface_type[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "format", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "intraFrameInterval", "Value" => @test_params.params_chan.video_gop[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "forceIFrame", "Value" => @test_params.params_chan.video_force_iframe[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "generateHeader", "Value" => '0'})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dataEndianness", "Value" => @test_params.params_chan.video_data_endianness[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "inputContentType", "Value" => @test_params.params_chan.video_input_content_type[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "encodeMode", "Value" => @test_params.params_chan.video_encode_mode[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "vbvBufferSize", "Value" => @test_params.params_chan.video_vbv_buffer_size[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "useUMV", "Value" => @test_params.params_chan.video_use_umv[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "subWindowHeight", "Value" => @test_params.params_chan.video_subwindow_height[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "subWindowWidth", "Value" => @test_params.params_chan.video_subwindow_width[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "intraPeriod", "Value" => @test_params.params_chan.video_gop[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "intraDcVlcThr", "Value" => @test_params.params_chan.video_intra_dl_vlc_thr[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "intraThres", "Value" => @test_params.params_chan.video_intra_thr[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "intraAlgo", "Value" => @test_params.params_chan.video_intra_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "numMBRows", "Value" => @test_params.params_chan.video_num_mb_rows[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "initQ", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "rcQ_MAX", "Value" => @test_params.params_chan.video_qp_max[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "rcQ_MIN", "Value" => @test_params.params_chan.video_qp_min[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "qChange", "Value" => @test_params.params_chan.video_q_change[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "qChangeRange", "Value" => @test_params.params_chan.video_q_range[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "initQ_P", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "meRange", "Value" => @test_params.params_chan.video_me_range[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "meAlgo", "Value" => @test_params.params_chan.video_me_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "skipMBAlgo", "Value" => @test_params.params_chan.video_mb_skip_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "iidc", "Value" => @test_params.params_chan.video_blk_size[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsIntraDcVlcThr", "Value" => @test_params.params_chan.video_intra_dl_vlc_thr[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsIntraThres", "Value" => @test_params.params_chan.video_intra_thr[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsIntraAlgo", "Value" => @test_params.params_chan.video_intra_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsNumMBRows", "Value" => @test_params.params_chan.video_num_mb_rows[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsInitQ", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsRcQ_MAX", "Value" => @test_params.params_chan.video_qp_max[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsRcQ_MIN", "Value" => @test_params.params_chan.video_qp_min[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsQChange", "Value" => @test_params.params_chan.video_q_change[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsQChangeRange", "Value" => @test_params.params_chan.video_q_range[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsInitQ_P", "Value" => @test_params.params_chan.video_qp_inter[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsMeRange", "Value" => @test_params.params_chan.video_me_range[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsMeAlgo", "Value" => @test_params.params_chan.video_me_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsSkipMBAlgo", "Value" => @test_params.params_chan.video_mb_skip_algo[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsUseUMV", "Value" => @test_params.params_chan.video_use_umv[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsIidc", "Value" => @test_params.params_chan.video_blk_size[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "dynParamsMVDataEnable", "Value" => @test_params.params_chan.video_mv_data_enable[0]})
    @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "rotation", "Value" => @test_params.params_chan.video_picture_rotation[0]})
  end
  
  #Setting the video decoder and vpbe
  if @test_params.params_chan.test_type[0].include?("vpbe")
    #Making the video connection
    @connection_handler.make_video_connection({@equipment["dut1"] => 0}, {@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
    #Setting the video decoder
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "codec", "Value" => "mpeg4dec"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => "576"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => "720"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"forceChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
  end
  
  #Setting the audio encoder and apfe
  if @test_params.params_chan.test_type[0].include?("apfe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment['audio_player'] => 0},{@equipment["dut1"] => 0, @equipment["tv0"] => 0})
    #Setting the audio encoder
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "numframes", "Value" => get_audio_num_frames(@test_params.params_control.media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"codec", "Value" => "g711enc"})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"compandingLaw", "Value" => @test_params.params_chan.audio_companding[0]})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"frameSize", "Value" => "1024"})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" =>"vadSelection", "Value" => "0"})
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio" , "Param" => "seconds", "Value" => @test_params.params_control.audio_media_time[0]})
  end
  
  #Settings for the audio decoder and apbe
  if @test_params.params_chan.test_type[0].include?("apbe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment["dut1"] => 0}, {@equipment["audio_player"] => 0, @equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])  
    #Setting the audio decoder
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "numframes","Value" => get_audio_num_frames(@test_params.params_control.audio_media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "codec", "Value" => "g711dec"})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "compandingLaw", "Value" => map_dut_audio_companding(@test_params.params_chan.audio_companding[0])})
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => "1024"})
  end
end


def run
  first_run = true
  video_tester_result = 0
  video_channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
    @connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["dut1"] => video_channel_number, @equipment["tv0"] => 0 }, @test_params.params_chan.video_iface_type[0])
     #======================== Processing Media ====================================================
    test_comment = ''
    begin
    file_res_form = ResultForm.new("Subjective DVSDK Dvtb #{@test_params.params_chan.test_type[0]} Test Result Form")
    if @test_params.params_chan.test_type[0].include?("vpfe") && @test_params.params_chan.test_type[0].include?("vpbe")
      @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "numframes", "Value" => get_video_num_frames})
      @equipment['dut1'].mpeg4ext_encoding_decoding
      @equipment['dut1'].wait_for_threads
        elsif @test_params.params_chan.test_type[0].include?("vpfe")
            @equipment['dut1'].set_param({"Class" => "mpeg4extenc", "Param" => "numframes", "Value" => get_video_num_frames})
            test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.video_source[0]+'_'+@test_params.params_chan.video_width[0]+'x'+@test_params.params_chan.video_height[0]+'_'+@test_params.params_chan.video_bit_rate[0].sub(/000$/,'Kbps').sub(/000K$/,'M')+'_ch'+video_channel_number.to_s+'.mpeg4'
            File.delete(test_file) if File.exists?(test_file)
            @equipment['dut1'].mpeg4ext_encoding({"Target" => test_file})
      @equipment['dut1'].wait_for_threads
      file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")} 
         end
      file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  @equipment['dut1'].get_param({"Class" => "mpeg4extenc"}) if file_res_form.test_result == FrameworkConstants::Result[:fail]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean

end


private 
def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def get_audio_num_frames(audio_time)
  (audio_time.to_f*@test_params.params_chan.audio_sampling_rate[0].to_f/get_audio_frame_size + @test_params.params_control.setup_delay[0].to_i*@test_params.params_chan.audio_sampling_rate[0].to_f/get_audio_frame_size ).round
end

def get_ref_file(start_directory, file_name)
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
  FileUtils.cp(ref_file, local_ref_file)
  [ref_file,local_ref_file]
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round.to_s
end

def get_video_num_frames
  (@test_params.params_chan.video_frame_rate[0].to_i * @test_params.params_control.media_time[0].to_i).to_s
end

def get_audio_frame_size
  bytes_per_sample = 2
  audio_channels = 1
 # bytes_per_sample*@test_params.params_chan.audio_sampling_rate[0].to_i*audio_channels
  1024
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end