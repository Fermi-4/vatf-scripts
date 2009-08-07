
NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
  @equipment['dut1'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  #@equipment['dut1'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut1'].respond_to?(:boot)# call bootscript if required
  
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
    
  #Setting the encoders and/or decoders parameters
  
  #Setting the engine type
  video_engine = case @test_params.params_chan.test_type[0]
  when /vpfe\+encoder\+decode.\+vpbe/ : 'encdec'
  when /vpfe\+encoder/ : 'encode'
  else 'decode'
  end
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => video_engine})
  
  #Setting the video encoder and vpfe
  if @test_params.params_chan.test_type[0].include?("vpfe")
    #Setting the video encoder
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "codec", "Value" => "mpeg4enc"})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxHeight", "Value" => [576,@test_params.params_chan.video_height[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxFrameRate", "Value" => '30000'})
    if @test_params.params_chan.test_type[0].include?("resize")
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
      @equipment['dut1'].set_param({"Class" => "resizer", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    else
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_signal_format[0]})
    end
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "numframes", "Value" => get_video_num_frames})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "input", "Value" => @test_params.params_chan.video_iface_type[0]})
    @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "format", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
  end
  
  #Setting the video decoder and vpbe
  if @test_params.params_chan.test_type[0].include?("vpbe")
    #Making the video connection
    @connection_handler.make_video_connection({@equipment["dut1"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
    #Setting the video decoder
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "codec", "Value" => "mpeg4dec"})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => get_max_bit_rate(@test_params.params_chan.video_bit_rate[0])})    
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => [576,@test_params.params_chan.video_height[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => [720, @test_params.params_chan.video_width[0].to_i].max.to_s})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "forceChromaFormat", "Value" => @test_params.params_chan.video_output_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "displayWidth", "Value" => @test_params.params_chan.video_width[0]})
    
    #Setting vpbe
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "screenHeight", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "screenWidth", "Value" => @test_params.params_chan.video_signal_format[0]})
    @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "format", "Value" => @test_params.params_chan.video_input_chroma_format[0]})
  end
  
  #Setting the audio encoder and apfe
  if @test_params.params_chan.test_type[0].include?("apfe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0]] => 0},{@equipment["dut1"] => 0, @equipment["tv0"] => 0}, @test_params.params_chan.audio_iface_type[0])
    #Setting the audio encoder
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "numframes", "Value" => get_audio_num_frames(@test_params.params_control.media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "seconds", "Value" => @test_params.params_control.media_time[0].to_s})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "codec", "Value" => "g711enc"})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "compandingLaw", "Value" => @test_params.params_chan.audio_companding[0]})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "frameSize", "Value" => "1024"})
    @equipment['dut1'].set_param({"Class" => "sphenc", "Param" => "vadSelection", "Value" => "0"})
    
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio" , "Param" => "seconds", "Value" => @test_params.params_control.media_time[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => "1024"})
  end
  
  #Settings for the audio decoder and apbe
  if @test_params.params_chan.test_type[0].include?("apbe")
    #Making the audio connection
    @connection_handler.make_audio_connection({@equipment["dut1"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])
    #Setting the audio decoder
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "numframes","Value" => get_audio_num_frames(@test_params.params_control.media_time[0]).to_s})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "codec", "Value" => "g711dec"})
    @equipment['dut1'].set_param({"Class" => "sphdec", "Param" => "compandingLaw", "Value" => @test_params.params_chan.audio_companding[0]})
    #Setting ap_e parameters
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
    @equipment['dut1'].set_param({"Class" => "audio", "Param" => "framesize", "Value" => "1024"})
  end
end


def run
    puts "Test Type: "+  @test_params.params_chan.test_type[0]
  first_run = true
  if @test_params.params_chan.test_type[0].include?("vpfe")
    channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
    @connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["dut1"] => channel_number, @equipment['tv0'] => 0}, @test_params.params_chan.video_iface_type[0])
  end
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("MPEG4 G711 #{@test_params.params_chan.test_type[0]} Test Result Form")
    if @test_params.params_chan.test_type[0].include?("vpfe") && @test_params.params_chan.test_type[0].include?("vpbe")
      first_run = start_video(first_run)
      0.upto(channel_number) do |ch_num|
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        if @test_params.params_chan.test_type[0].include?("resize")
            if ch_num == channel_number
            @equipment['dut1'].video_encoding_decoding({'function' => 'videncdecr'}, 'threadId' => 'loopback')
          else
            test_file = @test_params.params_chan.video_source[0]+'_'+@test_params.params_chan.video_width[0]+'x'+@test_params.params_chan.video_height[0]+'_'+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+'fps_channel'+ch_num.to_s+'.mpeg4'
            @equipment['dut1'].video_encoding({"function" => "videncr", "Target" => test_file, "threadId" => 'mpeg4enc'})
          end
        else
          if ch_num == channel_number
            @equipment['dut1'].video_encoding_decoding({'threadId' => 'loopback'})
          else
            test_file = @test_params.params_chan.video_source[0]+'_'+@test_params.params_chan.video_width[0]+'x'+@test_params.params_chan.video_height[0]+'_'+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+'fps_channel'+ch_num.to_s+'.mpeg4'
            @equipment['dut1'].video_encoding("Target" => test_file, "threadId" => 'mpeg4enc')
          end
        end
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")} if test_file
      end
      if @test_params.params_control.audio_num_channels[0].to_i > 0
        audio_ref_file, audio_test_file = run_audio_process(file_res_form) if @test_params.params_control.audio_num_channels[0].to_i > 0
        file_res_form.add_link(File.basename(audio_ref_file)){system("explorer #{audio_ref_file.gsub("/","\\")}")} if audio_ref_file
      end
      @equipment['dut1'].wait_for_threads(@test_params.params_control.media_time[0].to_i*4)
    elsif @test_params.params_chan.test_type[0].include?("vpfe")
      first_run = start_video(first_run)
      0.upto(channel_number) do |ch_num|
        test_file = LOCAL_FILES_FOLDER+"video_"+@test_params.params_chan.video_source[0]+"_"+@test_params.params_chan.video_width[0]+"x"+@test_params.params_chan.video_height[0]+"_"+@test_params.params_chan.video_bit_rate[0].sub(/000$/,"kbps_")+@test_params.params_chan.video_frame_rate[0]+"fps_"+get_video_num_frames+"frames_chan"+ch_num.to_s+"_test.mpeg4"
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
        if @test_params.params_chan.test_type[0].include?("resize")
          @equipment['dut1'].video_encoding({"function" => "videncr", "Target" => test_file, "threadId" => 'mpeg4enc'})
        else
          @equipment['dut1'].video_encoding({"Target" => test_file, "threadId" => 'mpeg4enc'})
        end
      end
      audio_ref_file, audio_test_file = run_audio_process(file_res_form) if @test_params.params_control.audio_num_channels[0].to_i > 0
      @equipment['dut1'].wait_for_threads(@test_params.params_control.media_time[0].to_i*4)
    elsif @test_params.params_chan.test_type[0].include?("vpbe")
      @test_params.params_chan.video_source.each do |vid_source|
        #======================== Prepare reference files ==========================================================
        puts "Decoding #{vid_source} ....."
        ref_file, local_ref_file = get_ref_file('Video', vid_source)
        # Start decoding function
        @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => "0"})
        @equipment['dut1'].set_param({"Class" => "viddec", "Param" =>"numframes", "Value" => get_number_of_video_frames(vid_source)})
        @equipment['dut1'].video_decoding({"Source" => local_ref_file, "threadId" => 'mpeg4dec'})
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        if @test_params.params_control.audio_num_channels[0].to_i > 0
          audio_ref_file, audio_file = run_audio_process(file_res_form)
          file_res_form.add_link(File.basename(audio_ref_file)){system("explorer #{audio_ref_file.gsub("/","\\")}")}
        end
        @equipment['dut1'].wait_for_threads(@test_params.params_control.media_time[0].to_i*4)
      end
    else
      audio_ref_file, audio_test_file = run_audio_process(file_res_form) if @test_params.params_control.audio_num_channels[0].to_i > 0
      @equipment['dut1'].wait_for_threads(@test_params.params_control.media_time[0].to_i*4)
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "vpfe", "Param" => ""})
    @equipment['dut1'].get_param({"Class" => "videnc", "Param" => ""})
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

def run_audio_process(result_form)
  local_ref_file = ""
  if @test_params.params_chan.test_type[0].include?("apfe") && @test_params.params_chan.test_type[0].include?("apbe") 
    @equipment['dut1'].speech_encoding_decoding({'threadId' => 'loopback'})
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

def get_audio_num_frames(audio_time)
  (audio_time.to_f*@test_params.params_chan.audio_sampling_rate[0].to_f/1024).round
end

def get_audio_ext
  if @test_params.params_chan.audio_companding[0].include?("law")
    ".pcm"
  else
    ".aac"
  end
end

def get_ref_file(folder, file_name)
  start_directory = NETWORK_REFERENCE_FILES_FOLDER+'/'+folder
  if file_name.strip.downcase == "from_encoder"
    start_directory = LOCAL_FILES_FOLDER
    file_name = /\w*#{@test_params.params_chan.video_width[0]+'x'+@test_params.params_chan.video_height[0]}_\w*(#{(@test_params.params_chan.video_bit_rate[0].to_i/1000).floor.to_s}\w*bps_|#{@test_params.params_chan.video_bit_rate[0]})\w*\.mpeg4$/i
  end
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}" 
  FileUtils.cp(ref_file, local_ref_file) if file_name.kind_of?(String)
  FileUtils.chmod(0755, local_ref_file)
  [ref_file,local_ref_file]
end

def get_video_num_frames
  (@test_params.params_control.media_time[0].to_f*@test_params.params_chan.video_frame_rate[0].to_f).round.to_s
end

def start_video(first_run)
  if @test_params.params_chan.video_source[0] == "dvd"
    #sleep 60 if first_run
    #@equipment['dvd'].go_to_track(4)  
  end
  false
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def get_max_bit_rate(target_bit_rate)
  (target_bit_rate.to_f*1.1).round.to_s
end
    
def get_number_of_video_frames(file)
  if /(\d+)frames/.match(file)
    /(\d+)frames/.match(file).captures[0]
  else
    '300'
  end
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end

