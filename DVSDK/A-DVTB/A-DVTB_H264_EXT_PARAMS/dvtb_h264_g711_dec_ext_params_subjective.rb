


OPERA_WAIT_TIME           = 30000

#include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() # method implemented in DvsdkTestScript module

  #Setting the maximum number of sockets the dut can 
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,0)
  #Setting the encoders and/or decoders parameters
  
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'decode'})
  
  #Setting the video decoder
  set_codec_param("codec", "h264dec")
  set_codec_param("maxBitRate", get_max_bit_rate(@test_params.params_chan.video_bit_rate[0]))    
  set_codec_param("maxFrameRate", 30000)
  set_codec_param("maxHeight", [576, @test_params.params_chan.video_height[0].to_i].max)
  set_codec_param("maxWidth", [720, @test_params.params_chan.video_width[0].to_i].max)
  set_codec_param("forceChromaFormat", "video_output_chroma_format")
  set_codec_param("displayDelay", "video_display_delay")
  set_codec_param("resetHDVICPeveryFrame", "video_reset_hdivc_every_frame")
  set_codec_param("disableHDVICPeveryFrame", "video_disable_hdivc_every_frame")
  set_codec_param("displayWidth", "video_width")
  set_codec_param("frameSkipMode", "video_frame_skip_mode")
  set_codec_param("frameOrder", "video_frame_order")
  set_codec_param("newFrameFlag", "video_new_frame_flag")
  set_codec_param("mbDataFlag", "video_mb_data_flag")
  set_codec_param("presetLevelIdc","video_level")
  set_codec_param("presetProfileIdc","video_profile")
  set_codec_param("temporalDirModePred","video_temp_dir_mode")
  
end


def run
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("H264 Decoder Extended Parameters Test Result Form")
    @test_params.params_chan.video_source.each do |vid_source|
      #======================== Prepare reference files ==========================================================
      puts "Decoding #{vid_source} ....."
      local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder', vid_source)
      target_file = local_ref_file.sub(/\..*$/,'_dec_test_' + @test_params.params_chan.video_output_chroma_format[0]+'.yuv')
      # Start decoding function
      # @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => "0")
      set_codec_param("numframes", get_number_of_video_frames(vid_source))
      @equipment['dut1'].h264ext_decoding({"Source" => local_ref_file, "Target" => target_file, "threadId" => 'h264dec'})
      file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
      file_res_form.add_link(File.basename(target_file)){system("explorer #{target_file.gsub("/","\\")}")}
      @equipment['dut1'].wait_for_threads
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "h264extdec", "Param" => ""})
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

def get_number_of_video_frames(file)
  /(\d+)frames/.match(file).captures[0].to_i
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round
end

def get_audio_frame_size
  bytes_per_sample = 2
  audio_channels = 1
 # bytes_per_sample*@test_params.params_chan.audio_sampling_rate[0].to_i*audio_channels
  1024
end

def set_codec_param(param_name, param_value)
  if param_value.kind_of?(String)
    @equipment['dut1'].set_param({"Class" => @test_params.params_chan.video_codec[0], "Param" => param_name, "Value" => @test_params.params_chan.instance_variable_get('@'+param_value)[0]}) if @test_params.params_chan.instance_variable_defined?('@'+param_value)
  else
    @equipment['dut1'].set_param({"Class" => @test_params.params_chan.video_codec[0], "Param" => param_name, "Value" => param_value.to_s})
  end
end