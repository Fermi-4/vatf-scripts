
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
  
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'decode'})
  
  
  
  @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
  @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
  @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "format", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
  @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
  @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "output", "Value" => @test_params.params_chan.video_iface_type[0]})

  #Making the video connection
  @connection_handler.make_video_connection({@equipment["dut1"] => 0}, {@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
  #Setting the video decoder
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" => "codec", "Value" => "h264dec"})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" => "maxFrameRate", "Value" => '30000'})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" => "maxHeight", "Value" => [576, @test_params.params_chan.video_height[0].to_i].max.to_s})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"forceChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"displayDelay", "Value" => @test_params.params_chan.video_display_delay[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"resetHDVICPeveryFrame", "Value" => @test_params.params_chan.video_reset_hdivc_every_frame[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"disableHDVICPeveryFrame", "Value" => @test_params.params_chan.video_disable_hdivc_every_frame[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"displayWidth", "Value" => @test_params.params_chan.video_width[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"frameSkipMode", "Value" => @test_params.params_chan.video_frame_skip_mode[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"frameOrder", "Value" => @test_params.params_chan.video_frame_order[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"newFrameFlag", "Value" => @test_params.params_chan.video_new_frame_flag[0]})
  @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"mbDataFlag", "Value" => @test_params.params_chan.video_mb_data_flag[0]})
  

  #Settings for the audio decoder and apbe
  if @test_params.params_chan.audio_output_driver.include?("apbe")
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
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("H264 Decoder Extended Parameters Test Result Form")
    @test_params.params_chan.video_source.each do |vid_source|
      #======================== Prepare reference files ==========================================================
      puts "Decoding #{vid_source} ....."
      ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder', vid_source)
      # Start decoding function
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => "0"})
      @equipment['dut1'].set_param({"Class" => "h264extdec", "Param" =>"numframes", "Value" => get_number_of_video_frames(vid_source)})
      @equipment['dut1'].h264ext_decoding({"Source" => local_ref_file, "threadId" => 'h264dec'})
      file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
      if @test_params.params_control.audio_num_channels[0].to_i > 0 && @test_params.params_chan.audio_output_driver.include?("apbe")
        audio_ref_file, audio_file = run_audio_process(file_res_form)
        file_res_form.add_link(File.basename(audio_ref_file)){system("explorer #{audio_ref_file.gsub("/","\\")}")}
      end
      @equipment['dut1'].wait_for_threads
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "h264extdec", "Param" => ""})
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
  if file_name.strip.downcase == "from_encoder"
    start_directory = LOCAL_FILES_FOLDER
    file_name = /\w*#{@test_params.params_chan.video_width[0]+'x'+@test_params.params_chan.video_height[0]}_\w*#{(@test_params.params_chan.video_bit_rate[0].to_i/1000).floor.to_s}\w*bps_\w*\.264$/i
  end 
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}" 
  FileUtils.cp(ref_file, local_ref_file) if file_name.kind_of?(String)
  [ref_file,local_ref_file]
end

def get_number_of_video_frames(file)
  if /(\d+)frames/.match(file)
    /(\d+)frames/.match(file).captures[0]
  else
    '300'
  end
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
  ref_file,local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech', @test_params.params_chan.audio_source[0])
  @equipment['dut1'].speech_decoding({"Source" => local_ref_file, "threadId" => 'g711dec'})
  [local_ref_file,test_file]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end