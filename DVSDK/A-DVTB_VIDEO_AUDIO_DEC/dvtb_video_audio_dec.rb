
NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
  @equipment['dut1'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  @equipment['dut1'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut1'].respond_to?(:boot)# call bootscript if required
  
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.num_channels[0].to_i,@test_params.params_control.num_channels[0].to_i)
    
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'decode'})
  
  if @test_params.params_chan.video_codec[0].strip.downcase != 'off'
    #Making the video connection
    @connection_handler.make_video_connection({@equipment["dut1"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
    #Setting the video decoder
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "codec", "Value" => @test_params.params_chan.video_codec[0].strip.downcase + 'dec'})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => [576,@test_params.params_chan.video_height[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"forceChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"dataEndianness", "Value" => @test_params.params_chan.video_data_endianness[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"decodeHeader", "Value" => @test_params.params_chan.video_decode_mode_flag[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"displayWidth", "Value" => @test_params.params_chan.video_display_width[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"frameSkipMode", "Value" => @test_params.params_chan.video_frame_skip_mode[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"frameOrder", "Value" => @test_params.params_chan.video_frame_order[0]})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"newFrameFlag", "Value" => @test_params.params_chan.video_new_frame_flag[0]})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"mbDataFlag", "Value" => @test_params.params_chan.video_mb_data_flag[0]})
      
    #Setting the video processing back-end
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "screenHeight", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "screenWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    
  end
  
  #Settings for the audio decoder and apbe
  if @test_params.params_chan.audio_codec[0].strip.downcase != 'off'
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment["dut1"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])
    
    #Setting the audio decoder
    if @test_params.params_chan.audio_codec[0].strip.downcase == 'g711'
      @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "codec", "Value" => "g711dec"})
      @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "compandingLaw", "Value" => @test_params.params_chan.speech_companding[0]})
      @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "bitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
    else
      if @test_params.params_chan.audio_codec[0].strip.downcase == 'aac'
        @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "codec", "Value" => "aachedec"})
      else
        @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "codec", "Value" => "mp3dec"})
      end
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "outputPCMWidth", "Value" => @test_params.params_chan.audio_data_width[0]}) 
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "pcmFormat", "Value" => @test_params.params_chan.audio_data_format[0]})
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "dataEndianness", "Value" => @test_params.params_chan.audio_data_endianness[0]})
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "downSampleSbrFlag", "Value" => @test_params.params_chan.audio_downsample_sbr_flag[0]})
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "inbufsize", "Value" => @test_params.params_chan.audio_inbuf_size[0]})
      @equipment['dut1'].set_param({"Class" => "auddec", "Param" => "outbufsize", "Value" => @test_params.params_chan.audio_outbuf_size[0]}) 
    end
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => "1024"})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "format", "Value" => @test_params.params_chan.audio_driver_data_endianness[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "channels", "Value" => @test_params.params_chan.audio_type[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "type", "Value" => @test_params.params_chan.audio_device_mode[0]})
  end
end


def run
    #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("#{(@test_params.params_chan.video_codec[0]+'+'+@test_params.params_chan.audio_codec[0]).sub(/\+*off\+*/,'').upcase} Decode Test Result Form")
    if @test_params.params_chan.video_codec[0].strip.downcase != 'off'
      @test_params.params_chan.video_source.each do |vid_source|
        #======================== Prepare reference files ==========================================================
        puts "Decoding #{vid_source} ....."
        ref_file, local_ref_file = get_ref_file('Video', vid_source)
        if @test_params.params_chan.audio_codec[0].strip.downcase != 'off'
            audio_local_ref_file = ""
            subdir = 'Audio'
            subdir = 'Speech' if @test_params.params_chan.audio_codec[0] == 'g711'
            audio_ref_file,audio_local_ref_file = get_ref_file(subdir, @test_params.params_chan.audio_source[rand(@test_params.params_chan.audio_source.length)])
            file_res_form.add_link(File.basename(audio_local_ref_file)){system("explorer #{audio_local_ref_file.gsub("/","\\")}")}
        end
        # Start decoding function
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"numframes", "Value" => get_number_of_video_frames(vid_source)})
        @equipment['dut1'].video_decoding({"Source" => local_ref_file, "threadId" => @test_params.params_chan.video_codec[0]+'dec'})
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        run_audio_process(audio_local_ref_file) if @test_params.params_chan.audio_codec[0].strip.downcase != 'off'
        @equipment['dut1'].wait_for_threads(240)
      end
    elsif @test_params.params_chan.audio_codec[0].strip.downcase != 'off'
      audio_local_ref_file = ""
        subdir = 'Audio'
        subdir = 'Speech' if @test_params.params_chan.audio_codec[0] == 'g711'
        audio_ref_file,audio_local_ref_file = get_ref_file(subdir, @test_params.params_chan.audio_source[rand(@test_params.params_chan.audio_source.length)])
        file_res_form.add_link(File.basename(audio_local_ref_file)){system("explorer #{audio_local_ref_file.gsub("/","\\")}")}
        run_audio_process(audio_local_ref_file)
      @equipment['dut1'].wait_for_threads(320)
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    if @test_params.params_chan.video_codec[0].strip.downcase != 'off'
      @equipment['dut1'].get_param({"Class" => "viddec", "Param" => ""})
      @equipment['dut1'].get_param({"Class" => "vpbe", "Param" => ""})
    end
    if @test_params.params_chan.audio_codec[0].strip.downcase != 'off'
      @equipment['dut1'].get_param({"Class" => "audio", "Param" => ""})
        if @test_params.params_chan.audio_codec[0].strip.downcase != 'g711'
          @equipment['dut1'].get_param({"Class" => "auddec", "Param" => ""})
        else
          @equipment['dut1'].get_param({"Class" => "sphdec", "Param" => ""})
        end
    end
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)

end

def clean

end



private 

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def run_audio_process(audio_file)
  if @test_params.params_chan.audio_codec[0].strip.downcase == 'g711'
    @equipment['dut1'].speech_decoding({"Source" => audio_file, "threadId" => 'g711dec'})
  else
    thread_id = case @test_params.params_chan.audio_codec[0].strip.downcase
            when /mp\d/ : 'mp3'
            when 'aac' : 'aache'
            else @test_params.params_chan.audio_codec[0]
          end
    @equipment['dut1'].audio_decoding({"Source" => audio_file, "threadId" => thread_id+'dec'})
  end
end

def get_audio_num_frames(audio_time)
  (audio_time.to_f*@test_params.params_chan.audio_sampling_rate[0].to_f/1024).round
end

def get_ref_file(folder, file_name)
  ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER+'/'+folder) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
  FileUtils.cp(ref_file, local_ref_file)
  FileUtils.chmod(0755, local_ref_file)
  [ref_file,local_ref_file]
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round.to_s
end

def get_number_of_video_frames(file)
  /(\d+)frames/.match(file).captures[0]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end
