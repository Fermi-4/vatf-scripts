

OPERA_WAIT_TIME				   = 30000

   
def setup
  @equipment['dut1'].set_api('dmai')
  if @test_params.params_chan.command_name[0].include?("video_display") 
    @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment['tv1'] => {@test_params.params_chan.display_out[0] => 0}}) if @equipment.include?('tv1')
  elsif @test_params.params_chan.command_name[0].strip.downcase == "video_loopback" || @test_params.params_chan.command_name[0].strip.downcase == "video_loopback_copy"
    @equipment['video_tester'].set_output_format({'format' => @test_params.params_chan.video_signal_format[0]})
    @connection_handler.make_video_connection({@equipment["video_tester"] => {"sdi" => 0}}, {@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {"sdi" => 0}})
    @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {"sdi" => 0}}, {@equipment["video_tester"] => {"sdi" => 0}})	
    @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.video_input[0] => 0}}) 
    @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) if @equipment.include?('tv0')
    @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] =>0}}, {@equipment['tv1'] => {@test_params.params_chan.display_out[0] =>0}}) if @equipment.include?('tv1')
    sleep 3
  end
end

def run
  test_result = FrameworkConstants::Result[:nry]
  test_comment = ''
  audio_input_handle, audio_output_handle = nil
  begin
    file_res_form = nil
    file_res_form = ScrollableResultForm.new("DMAI Test Result Form") if !@test_params.params_control.respond_to?(:test_type) || @test_params.params_control.test_type[0].strip == 'subjective'
    if @test_params.params_chan.command_name[0].include?("video_encode")
      run_dmai_test("Video/Encoder", file_res_form) do |media_file|
        enc_params = get_video_encode_params(media_file)
        @equipment['dut1'].video_encode(enc_params)
        if @test_params.params_control.test_type[0].strip != 'subjective'
          #======================== Call Objective quality equipment ====================================================================
          out_file = enc_params['output_file']
          if @test_params.params_chan.codec[0].strip.downcase.include?('mpeg4')
            out_file = enc_params['output_file'].sub(/\..+$/,'_'+@test_params.params_chan.video_input_chroma_format[0]+'_rawconv.yuv') 
            get_raw_video_file(enc_params['output_file'],out_file, @test_params.params_chan.video_input_chroma_format[0]) 
          end
          video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => enc_params['input_file'], 
                                                                              'test_file' => out_file,
                                                                              'data_format' => @test_params.params_chan.video_input_chroma_format[0],
                                                                              'format' => get_video_tester_format,
                                                                              'video_height' => get_height(@test_params.params_chan.resolution[0]),
                                                                              'video_width' => get_width(@test_params.params_chan.resolution[0]),
                                                                              'num_frames' => enc_params['num_of_frames'].to_i,
                                                                              'frame_rate' => '30',
                                                                              'metric_window' => get_metric_window})
          if video_tester_result
            test_res, test_cmnt = get_video_results(enc_params['output_file'])
            test_comment += test_cmnt
            test_result = test_res if test_result != FrameworkConstants::Result[:fail]
          else
            test_result = FrameworkConstants::Result[:fail]
            test_comment += 'Video scores could not be calculated for ' + media_file
          end
        end
        enc_params
      end
    elsif @test_params.params_chan.command_name[0].include?("audio_encode")
      run_dmai_test("Audio/Encoder", file_res_form) do |media_file|
        aud_params = get_audio_encode_params(media_file)
        @equipment['dut1'].audio_encode(aud_params)
        aud_params
      end
    elsif @test_params.params_chan.command_name[0].include?("image_encode")
      run_dmai_test("Image/Encoder", file_res_form) do |media_file|
        img_params = get_image_encode_params(media_file)
        @equipment['dut1'].image_encode(img_params)
        img_params
      end
    elsif @test_params.params_chan.command_name[0].include?("video_decode")
      run_dmai_test("Video/Decoder", file_res_form) do |media_file|
        dec_params = get_video_decode_params(media_file)
        @equipment['dut1'].video_decode(dec_params)
        if @test_params.params_control.test_type[0].strip != 'subjective'
          #======================== Call Objective quality equipment ====================================================================
          in_file = dec_params['input_file']
          if @test_params.params_chan.codec[0].strip.downcase.include?('mpeg4')
            in_file = dec_params['input_file'].sub(/\..+$/,'_'+@test_params.params_chan.video_output_chroma_format[0]+'_rawconv.yuv') 
            get_raw_video_file(dec_params['input_file'],in_file, @test_params.params_chan.video_output_chroma_format[0]) 
          end
          video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => in_file, 
                                                                              'test_file' => dec_params['output_file'],
                                                                              'data_format' => @test_params.params_chan.video_output_chroma_format[0],
                                                                              'format' => get_video_tester_format,
                                                                              'video_height' => get_height(@test_params.params_chan.resolution[0]),
                                                                              'video_width' => get_width(@test_params.params_chan.resolution[0]),
                                                                              'num_frames' => dec_params['num_of_frames'].to_i,
                                                                              'frame_rate' => '30',
                                                                              'metric_window' => get_metric_window})
          if video_tester_result
            test_res, test_cmnt = get_video_results(dec_params['output_file'])
            test_comment += test_cmnt
            test_result = test_res if test_result != FrameworkConstants::Result[:fail]
          else
            test_comment += 'Video scores could not be calculated for ' + media_file
          end
        end
        dec_params
      end
    elsif @test_params.params_chan.command_name[0].include?("audio_decode")
      run_dmai_test("Audio/Decoder", file_res_form) do |media_file|
        auddec_params = get_audio_decode_params(media_file)
        if @test_params.params_chan.output_type[0].strip.downcase == 'file'
          @equipment['dut1'].audio_decode(auddec_params)
        else
          make_audio_output_connections
          auddec_params['output_file'] = nil
          @equipment['dut1'].audio_decode1(auddec_params)
        end
        auddec_params
      end  
    elsif @test_params.params_chan.command_name[0].include?("image_decode")
      run_dmai_test("Image/Decoder", file_res_form) do |media_file|
        img_dec_params = get_image_decode_params(media_file)
        @equipment['dut1'].image_decode(img_dec_params)
        img_dec_params
      end
    elsif @test_params.params_chan.command_name[0].include?("speech_decode")
      run_dmai_test(["Speech/Decoder"], file_res_form) do |media_file|
        sph_dec_params = get_speech_decode_params(media_file)
        if @test_params.params_chan.output_type[0].strip.downcase == 'file'
          @equipment['dut1'].speech_decode(sph_dec_params)
        else
          make_audio_output_connections
          sleep 1
          sph_dec_params['output_file'] = nil
          audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process() 
          @equipment['dut1'].speech_decode1(sph_dec_params)
          bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle)
        end
        if @test_params.params_control.test_type[0].strip != 'subjective'
          local_ref_file = get_ref_file('Speech/Encoder', @test_params.params_chan.input_file[0].sub(/\..*$/,".pcm"))
          test_res, test_cmnt = get_speech_results(local_ref_file, sph_dec_params['output_file'])
          test_comment += test_cmnt
          test_result = test_res if test_result != FrameworkConstants::Result[:fail]
        end
        sph_dec_params
      end
    elsif @test_params.params_chan.command_name[0].include?("speech_encode")
      run_dmai_test(["Speech/Encoder","Audio/Encoder"], file_res_form) do |media_file|
        sph_enc_params = get_speech_encode_params(media_file)
        if @test_params.params_chan.input_type[0].strip.downcase == 'file'
          @equipment['dut1'].speech_encode(sph_enc_params)
        else
          make_audio_input_connections()
          sleep 1
          sph_enc_params['input_file'] = nil
          sph_enc_params['num_of_frames'] = (File.size(media_file)/200).ceil 
          @equipment['dut1'].speech_encode1(sph_enc_params)
          audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process()
          @equipment['dut1'].wait_for_threads(sph_enc_params['timeout'].to_i)
          bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle)
        end
        if @test_params.params_control.test_type[0].strip != 'subjective'
          local_ref_file = get_ref_file('Speech/Decoder', @test_params.params_chan.input_file[0].sub(/\..*$/,"."+@test_params.params_chan.speech_companding[0].gsub(/-*law/,'')))
          test_res, test_cmnt = get_speech_results(local_ref_file, sph_enc_params['output_file'])
          test_comment += test_cmnt
          test_result = test_res if test_result != FrameworkConstants::Result[:fail]
        end
        sph_enc_params
      end
    elsif @test_params.params_chan.command_name[0].include?("video_display")
        vid_dis_params = get_video_display_params
        @equipment['dut1'].video_display(vid_dis_params)
    elsif @test_params.params_chan.command_name[0].include?("video_loopback_blend")
        make_subjective_connections
        vid_loop_blend_params = get_video_loopback_blend_params
        @equipment['dut1'].video_loopback_blend(vid_loop_blend_params)
    elsif @test_params.params_chan.command_name[0].include?("video_loopback_convert")
        make_subjective_connections
        vid_loop_convert_params = get_video_loopback_convert_params
        @equipment['dut1'].video_loopback_convert(vid_loop_convert_params)
    elsif @test_params.params_chan.command_name[0].include?("video_loopback_resize")
        make_subjective_connections
        vid_loop_res_params = get_video_loopback_resize_params
        @equipment['dut1'].video_loopback_resize(vid_loop_res_params)
    elsif @test_params.params_chan.command_name[0].include?("video_loopback_copy")
      run_dmai_test("Video/Encoder", file_res_form) do |media_file|
        vid_loopback_cp_params = get_video_loopback_copy_params(media_file)
        @equipment['dut1'].video_loopback_copy(vid_loopback_cp_params)
        if @test_params.params_control.test_type[0].strip == 'subjective'
          @equipment['video_tester'].play_video_out({'src_clip' => media_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                                                     'format' => @test_params.params_chan.video_signal_format[0],'video_height' => get_height(@test_params.params_chan.resolution[0]), 
                                                     'video_width' => get_width(@test_params.params_chan.resolution[0]), 'num_frames' => get_video_num_frames(media_file), 'frame_rate' => get_frame_rate})
        else
          vid_enc_dec_params = {'ref_clip' => media_file, 'test_clip' => media_file.sub(/\..*$/,'_test.avi'), 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                          'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => get_height(@test_params.params_chan.resolution[0]),
                          'video_width' =>get_width(@test_params.params_chan.resolution[0]), 'num_frames' => get_video_num_frames(media_file), 'frame_rate' => get_frame_rate,
                          'metric_window' => get_metric_window
          }
          @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] =>0}},{@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}})  
          video_tester_result = @equipment['video_tester'].video_out_to_video_in_test(vid_enc_dec_params){
             @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}})
             sleep 1
          }
          if video_tester_result
            test_res, test_cmnt = get_video_results(media_file)
            test_comment += test_cmnt
            test_result = test_res if test_result != FrameworkConstants::Result[:fail]
          else
            test_comment += 'Video scores could not be calculated for ' + media_file
            test_result = FrameworkConstants::Result[:fail]
          end
        end
        @equipment['dut1'].wait_for_threads(vid_loopback_cp_params['timeout'].to_i)
        vid_loopback_cp_params
      end
    elsif @test_params.params_chan.command_name[0].include?("video_loopback")
      run_dmai_test("Video/Encoder", file_res_form) do |media_file|
        vid_loopback_params = get_video_loopback_params(media_file)
        @equipment['dut1'].video_loopback(vid_loopback_params)
        vid_loopback_params
      end
    end
    file_res_form.show_result_form	if 	file_res_form
  end until !file_res_form || file_res_form.test_result != FrameworkConstants::Result[:nry]
  
  if file_res_form
    test_result = file_res_form.test_result
    test_comment = file_res_form.comment_text
  end
  rescue Exception => e
    test_comment += e.to_s
		stop_audio_process(audio_input_handle, audio_output_handle) if audio_input_handle || audio_output_handle
    raise 
	ensure
    set_result(test_result,test_comment)
end

def clean
end



private

def get_video_loopback_blend_params
  {
    'display_output' => @test_params.params_chan.display_out[0],
    'in_place' => @test_params.params_chan.in_place[0],
    'output_position' => @test_params.params_chan.output_position[0],
    'resolution'      => @test_params.params_chan.resolution[0],
    'input_position' => @test_params.params_chan.input_position[0],
    'num_of_frames' => @test_params.params_control.display_time[0].to_i*30,
    'bitmap_position' => @test_params.params_chan.bitmap_position[0],
    'bitmap_resolution' => @test_params.params_chan.bitmap_resolution[0],
    'timeout' => @test_params.params_control.display_time[0].to_i*5
  }
end

def get_video_loopback_resize_params
  {
    'display_standard' => @test_params.params_chan.video_signal_format[0], 
    'display_output' => @test_params.params_chan.display_out[0],
    'capture_ualloc' => @test_params.params_chan.capture_ualloc[0],
    'display_ualloc' => @test_params.params_chan.display_ualloc[0],
    'output_position' => @test_params.params_chan.output_position[0],
    'output_resolution' => @test_params.params_chan.output_resolution[0],
    'input_position' => @test_params.params_chan.input_position[0],
    'input_resolution' => @test_params.params_chan.input_resolution[0],
    'crop' => @test_params.params_chan.crop[0],
    'num_of_frames' => @test_params.params_control.display_time[0].to_i*30,
    'timeout' => @test_params.params_control.display_time[0].to_i*3
  }
end

def get_video_loopback_convert_params
  {
    'display_output' => @test_params.params_chan.display_out[0],
    'capture_ualloc' => @test_params.params_chan.capture_ualloc[0],
    'display_ualloc' => @test_params.params_chan.display_ualloc[0],
    'output_position' => @test_params.params_chan.output_position[0],
    'input_position' => @test_params.params_chan.input_position[0],
    'resolution' => @test_params.params_chan.resolution[0],
    'num_of_frames' => @test_params.params_control.display_time[0].to_i*30,
    'input_accel' => @test_params.params_chan.input_accel[0],
    'output_accel' => @test_params.params_chan.output_accel[0],
    'timeout' => @test_params.params_control.display_time[0].to_i*8
  }
end


def run_audio_process()
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
	if @test_params.params_chan.command_name[0].include?("encode") && @test_params.params_chan.command_name[0].include?("decode")
		local_ref_file = get_ref_file('Speech/Encoder/',@test_params.params_chan.input_file[0])
		test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.input_file[0]+"_test.pcm"
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
		@equipment['audio_player'].play_wave_audio(audio_output_handle, local_ref_file)
  elsif @test_params.params_chan.command_name[0].include?("encode")  
		test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.input_file[0]+"_test"+get_audio_ext()
		pcm_local_ref_file = get_ref_file('Speech/Encoder/', @test_params.params_chan.input_file[0])
		ref_file, local_ref_file = get_ref_file('Speech/Decoder/', @test_params.params_chan.input_file[0].gsub(/\..*$/,'.')+get_audio_ext)
		@equipment['audio_player'].play_wave_audio(audio_output_handle, pcm_local_ref_file)
	elsif @test_params.params_chan.command_name[0].include?("decode")
	  test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.input_file[0].gsub(/\..*$/,"_test.pcm")
		local_ref_file = get_ref_file('Speech/Encoder/', @test_params.params_chan.input_file[0].gsub(/\..*$/,".pcm"))
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
	end
	[local_ref_file,test_file,audio_input_handle, audio_output_handle]
  rescue Exception => e
    stop_audio_process(audio_input_handle, audio_output_handle) if audio_input_handle || audio_output_handle
end

def stop_audio_process(audio_input_handle, audio_output_handle)
   while audio_output_handle && !@equipment['audio_player'].wave_audio_play_done(audio_output_handle)
		sleep(1)
   end
   sleep(1)
   bytes_recorded = nil
   bytes_recorded = @equipment['audio_player'].stop_wave_audio_record(audio_input_handle) if audio_input_handle && @test_params.params_chan.command_name[0].include?("decode")
   @equipment['audio_player'].stop_wave_audio_play(audio_output_handle) if audio_output_handle && @test_params.params_chan.command_name[0].include?("encode")
   @equipment['audio_player'].close_wave_in_device(audio_input_handle) if audio_input_handle
   @equipment['audio_player'].close_wave_out_device(audio_output_handle) if audio_output_handle
   [bytes_recorded, nil, nil]   
end

def run_dmai_test(ref_dir, file_res_form)
  max_num_files = @test_params.params_chan.input_file.length - 1
  max_num_files = [max_num_files, @test_params.params_control.max_num_files[0].to_i - 1].min if @test_params.params_control.instance_variables.include?('@max_num_files')
  @test_params.params_chan.input_file[0..max_num_files].each do |input_file|
    puts "Processing #{input_file}"
    media_files = get_ref_file(ref_dir,input_file)
    media_files = [media_files] if media_files.kind_of?(String)
    media_files.each do |media_file|    
      media_params = yield media_file
      if file_res_form
        file_res_form.add_link(File.basename(input_file)) do
          system("explorer #{media_file.gsub("/","\\")}")
        end
        if media_params['output_file']
          file_res_form.add_link(File.basename(media_params['output_file'])) do
            system("explorer #{media_params['output_file'].gsub("/","\\")}")
          end
        end
      end
    end
  end
end

def get_audio_ext
  @test_params.params_chan.speech_companding[0].gsub(/law/,'')
end

def make_subjective_connections()
  @connection_handler.make_video_connection({@test_params.params_chan.video_source[0] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.video_input[0] => 0}})
  @connection_handler.make_video_connection({@test_params.params_chan.video_source[0] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) if @equipment.include?('tv0')
  @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] =>0}}, {@equipment['tv1'] => {@test_params.params_chan.display_out[0] =>0}}) if @equipment.include?('tv1')
  puts "Processing #{@test_params.params_chan.video_source[0]} signal"
end

def make_audio_input_connections()
  @connection_handler.make_audio_connection({@equipment['audio_player'] => {@test_params.params_chan.input_type[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.input_type[0] => 0}})
  @connection_handler.make_audio_connection({@equipment['audio_player'] => {@test_params.params_chan.input_type[0] => 0}}, {@equipment["tv0"] => {@test_params.params_chan.input_type[0] => 0}}) if @equipment.include?('tv0')
end

def make_audio_output_connections()
  @connection_handler.make_audio_connection({@equipment["dut1"] => {@test_params.params_chan.output_type[0] => 0}}, {@equipment['audio_player'] => {@test_params.params_chan.output_type[0] => 0}}) if @equipment['audio_player']
  @connection_handler.make_audio_connection({@equipment["dut1"] => {@test_params.params_chan.output_type[0] => 0}}, {@equipment["tv1"] => {@test_params.params_chan.output_type[0] => 0}}) if @equipment.include?('tv1')
end

def get_video_encode_params(vid_source)
        if @test_params.params_chan.codec[0] == "h264" 
          extension = "264" 
        elsif @test_params.params_chan.codec[0] == "mpeg2"
          extension = "m2v"
        elsif @test_params.params_chan.codec[0] == "mpeg4" 
          extension = "mpeg4"        
        end
        
    {
      'input_file'			=> vid_source,
      'codec'           => @test_params.params_chan.codec[0],
      'num_of_frames'   => get_video_num_frames(vid_source),
      'output_file'		  => vid_source.sub(/\.yuv$/,"_#{@test_params.params_chan.bit_rate[0]}bps_encode_test.#{extension}"),
      'resolution'      => @test_params.params_chan.resolution[0],
      'bit_rate'		 	  => @test_params.params_chan.bit_rate[0],
      'media_location'  => @test_params.params_chan.media_location[0],
      'timeout'         => get_video_num_frames(vid_source)*2
    }
end

def get_audio_encode_params(aud_source)
  {
    'input_file' 			=> aud_source,
    'codec'           => @test_params.params_chan.codec[0],
    'num_of_frames'   => get_audio_num_frames(aud_source),
    'output_file'		  => @test_params.params_chan.output_file[0],
    'bit_rate'		 	  => @test_params.params_chan.bit_rate[0],
    'media_location'  => @test_params.params_chan.media_location[0],
    'timeout'         => File.size(aud_source)/10 + 10
  }
end

def get_image_encode_params(img_source)

  {
    'input_file'			=> img_source,
    'codec'           => @test_params.params_chan.codec[0],
    'output_file'     => img_source.sub(/\.yuv$/,"_#{@test_params.params_chan.picture_output_chroma_format[0]}_#{@test_params.params_chan.picture_quality[0]}qlty.#{@test_params.params_chan.codec[0]}"),
    'output_color_space' => @test_params.params_chan.picture_output_chroma_format[0],
    'input_color_space' => @test_params.params_chan.picture_input_chroma_format[0],
    'image_resolution'		=> @test_params.params_chan.picture_resolution[0],
    'image_qvalue'			=> @test_params.params_chan.picture_quality[0], 
    'media_location'  => @test_params.params_chan.media_location[0],        
  }

end

def get_video_decode_params(vid_source)
  {
      'input_file'			=> vid_source,
      'codec'           => @test_params.params_chan.codec[0],
      'num_of_frames'   => get_video_num_frames(vid_source),
      'output_file'		  => vid_source.sub(/\.\w+$/,"_decode_test.yuv"),
      'media_location'  => @test_params.params_chan.media_location[0],
      'timeout'         => get_video_num_frames(vid_source)*get_vid_timeout_mult(@test_params.params_chan.resolution[0]),
      'resolution'      => @test_params.params_chan.resolution[0]
  }
end

def get_audio_decode_params(aud_source)
  {
      'input_file' 			=> aud_source,
      'codec'           => @test_params.params_chan.audio_codec[0],
      'num_of_frames'   => get_audio_num_frames(aud_source),
      'output_file'		  => aud_source.sub(/\.\w+$/,"_decode_test.pcm"),
      'bit_rate'		 	  => @test_params.params_chan.audio_bit_rate[0],
      'media_location'  => @test_params.params_chan.media_location[0],
      'timeout'         => File.size(aud_source)/10 + 10
  }
end

def get_speech_decode_params(speech_source)
  {
      'input_file' 			=> speech_source,
      'codec'           => @test_params.params_chan.audio_codec[0],
      'num_of_frames'   => File.size(speech_source)*2,
      'output_file'		  => speech_source.sub(/\.\w+$/,"_decode_test.pcm"),
      'companding'		 	  => @test_params.params_chan.speech_companding[0],
      'start_frame'  => @test_params.params_chan.start_frame[0],
      'timeout'         => File.size(speech_source)/10 + 10,
      #'output_type' => @test_params.params_chan.output_type[0] 
  }
end

def get_speech_encode_params(speech_source)
  {
      'input_file' 			=> speech_source,
      'codec'           => @test_params.params_chan.audio_codec[0],
      'num_of_frames'   => get_audio_num_frames(speech_source,2),
      'output_file'		  => speech_source.sub(/\.\w+$/,"_encode_test_#{@test_params.params_chan.speech_companding[0]}.pcm"),
      'companding'		 	  => @test_params.params_chan.speech_companding[0],
      'start_frame'  => @test_params.params_chan.start_frame[0],
      'timeout'         => File.size(speech_source)/10 + 10
  }
end

def get_image_decode_params(img_source)
  {
      'input_file'  => img_source,
      'codec'           => @test_params.params_chan.codec[0],
      'output_file'     => img_source.sub(/\.\w+$/,"_decode_test.yuv"),
      'output_color_space' => @test_params.params_chan.picture_output_chroma_format[0],
      'image_resolution'		=> @test_params.params_chan.picture_resolution[0],     
      'media_location'  => @test_params.params_chan.media_location[0],        
  }
end

def get_video_display_params
  {
      'standard'  => @test_params.params_chan.video_signal_format[0],
      'output'    => @test_params.params_chan.display_out[0],
      'timeout'   => @test_params.params_chan.display_time[0].to_i + 10,
      'num_of_frames'     => @test_params.params_chan.display_time[0].to_i*30,      
  }
end

def get_video_loopback_copy_params(vid_source)
  params = {
    'resolution' => @test_params.params_chan.resolution[0],
    'display_output' => @test_params.params_chan.display_out[0],
    'num_of_frames' => @test_params.params_control.test_type[0].strip.downcase == 'subjective' ? get_video_num_frames(vid_source)*2 : get_video_num_frames(vid_source)*12, 
    'display_standard' => @test_params.params_chan.display_standard[0], 
    'display_device' => @test_params.params_chan.display_device[0],
    'use_accelerator' => @test_params.params_chan.use_accelerator[0],
    'output_position' => @test_params.params_chan.output_position[0],
    'input_position' => @test_params.params_chan.input_position[0],
    'enable_smooth' => @test_params.params_chan.enable_smooth[0],
    'crop' => @test_params.params_chan.crop[0],
    'timeout'         => get_video_num_frames(vid_source)*11
  }
end

def get_video_loopback_params(vid_source)
  params = {
    'resolution' => @test_params.params_chan.resolution[0],
    'display_output' => @test_params.params_chan.display_out[0],
    'num_of_frames' => @test_params.params_control.test_type[0].strip.downcase == 'subjective' ? get_video_num_frames(vid_source)*2 : get_video_num_frames(vid_source)*12,
    'timeout'         => get_video_num_frames(vid_source)*11
  }
end

def get_vid_timeout_mult(resolution)
  vid_timeouts = Hash.new(5).merge({'240' => 5, '480' => 12, '576' => 14, '720' => 30, '1080' => 70})
  vid_timeouts[get_height(resolution)]
end

def get_height(resolution)
  /\d+x(\d+)/.match(resolution).captures[0]
end

def get_width(resolution)
  /(\d+)x\d+/.match(resolution).captures[0]
end

def get_video_num_frames(vid_source)
    file_num_frames = /(\d+)frames/.match(vid_source).captures[0].to_i
    file_num_frames
end

def get_audio_num_frames(aud_source, framesize=2048)
  file_size = File.size(aud_source)
  sampling_rate = @test_params.params_chan.audio_sampling_rate[0].to_i
  seconds = file_size.to_f/sampling_rate*2
  audio_channels = 1
  audio_channels = 2 if /Stereo/i.match(aud_source)
  [(@test_params.params_chan.audio_bit_rate[0].to_i*audio_channels*seconds/framesize*8).to_i,100].max
end


def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end

def get_local_file_regex(type)
  case type
  when /video/i
    /.*#{@test_params.params_chan.resolution[0]}.*_#{@test_params.params_chan.bit_rate[0]}bps.*_encode_test\.#{@test_params.params_chan.codec[0].gsub(/h264/,"264")}$/i
  when /audio/i
    // # Todo
  when /speech/i
    // # Todo
  else
    /#{@test_params.params_chan.picture_resolution[0]}.*\.jpe{0,1}g$/i
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
    ref_file = Find.files(start_directory) { |f| File.basename(f) =~ /#{filename_regex}/}
  when 'from_web'
    start_directory = SiteInfo::LOCAL_FILES_FOLDER+'JPEG_Files'
    filename_regex = get_local_file_regex(strt_directory)
    ref_file = Find.files(start_directory) { |f| File.basename(f) =~ /#{filename_regex}/}
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

def get_video_tester_format
    [get_width(@test_params.params_chan.resolution[0]).to_i,get_height(@test_params.params_chan.resolution[0]).to_i, 30]
end

def get_metric_window
    ti_logo_height = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[1].to_i
    ti_logo_width = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[0].to_i
	    
    metric_window_width = get_width(@test_params.params_chan.resolution[0]).to_i
    metric_window_height = get_height(@test_params.params_chan.resolution[0]).to_i
    
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

def get_video_results(video_file)
  test_done_result = FrameworkConstants::Result[:pass]
  @results_html_file.add_paragraph("")
    test_comment = " "  
  res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
  
  pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
    
  @results_html_file.add_row_to_table(res_table, [["#{@test_params.params_chan.respond_to?(:codec) ? @test_params.params_chan.codec[0] : 'Video'} Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
  if pass_fail_criteria[0] == 'jnd'
    max_consecutive_failures = 0
    y_jnd_scores = @equipment['video_tester'].get_jnd_scores({'component' => 'y'})
    chroma_jnd_scores = @equipment['video_tester'].get_jnd_scores({'component' => 'chroma'})
    consecutive_failures = 0
    fail_criteria = pass_fail_criteria[1].to_f
    max_failed = false
    consec_fail_criteria = 6
    consec_fail_frames = []
    start_of_failures = -1
    y_jnd_scores.each_index do |frame_num|
      if y_jnd_scores[frame_num] >  fail_criteria + 1 || chroma_jnd_scores[frame_num] > fail_criteria + 1
        max_failed = true
        break
      end
      if y_jnd_scores[frame_num] > fail_criteria || chroma_jnd_scores[frame_num] > fail_criteria
        start_of_failures = frame_num if consecutive_failures < 1
        consecutive_failures += 1
      else
        consec_fail_frames << [start_of_failures, consecutive_failures] if consecutive_failures > consec_fail_criteria
        consecutive_failures = 0
      end
      max_consecutive_failures = consecutive_failures if  consecutive_failures > max_consecutive_failures
    end
    if max_failed || max_consecutive_failures > consec_fail_criteria || @equipment["video_tester"].get_jnd_score({'component' => 'y'}) > fail_criteria || @equipment["video_tester"].get_jnd_score({'component' => 'chroma'}) > fail_criteria
      test_done_result = FrameworkConstants::Result[:fail]
    end
    @results_html_file.add_row_to_table(res_table,["AVG_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y'})])
    @results_html_file.add_row_to_table(res_table,["MIN_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'min'})])
    @results_html_file.add_row_to_table(res_table,["MAX_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'max'})])
    @results_html_file.add_row_to_table(res_table,["AVG_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma'})])
    @results_html_file.add_row_to_table(res_table,["MIN_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'min'})])
    @results_html_file.add_row_to_table(res_table,["MAX_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'max'})])
    @results_html_file.add_row_to_table(res_table,["AVG_DMOS_Y",@equipment["video_tester"].get_dmos_score({'component' => 'y'})])
    @results_html_file.add_row_to_table(res_table,["MIN_DMOS_Y",@equipment["video_tester"].get_dmos_score({'component' => 'y', 'type' => 'min'})])
    @results_html_file.add_row_to_table(res_table,["MAX_DMOS_Y",@equipment["video_tester"].get_dmos_score({'component' => 'y', 'type' => 'max'})])
    @results_html_file.add_row_to_table(res_table,["AVG_DMOS_Chroma",@equipment["video_tester"].get_dmos_score({'component' => 'chroma'})])
    @results_html_file.add_row_to_table(res_table,["MIN_DMOS_Chroma",@equipment["video_tester"].get_dmos_score({'component' => 'chroma', 'type' => 'min'})])
    @results_html_file.add_row_to_table(res_table,["MAX_DMOS_Chroma",@equipment["video_tester"].get_dmos_score({'component' => 'chroma', 'type' => 'max'})])
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
    consec_fail_frames.each{|consec_f_info| test_comment+=" Starting at #{consec_f_info[0]}, #{consec_f_info[1]} frames."}
    file_ext = File.extname(video_file)
    failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+file_ext)
    File.copy(video_file, failed_file_name)
    @results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
  end
  
  [test_done_result, test_comment]
end
  
  
def get_speech_results(audio_ref_file,audio_test_file)
  test_done_result = FrameworkConstants::Result[:pass]
  @results_html_file.add_paragraph("")
  test_comment = " "  

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
  
  if pesq_mos < @test_params.params_chan.speech_quality_metric[0].to_f 
    test_done_result = FrameworkConstants::Result[:fail]
    test_comment = test_comment.to_s+" Test failed for file "+File.basename(audio_ref_file)
    audio_test_file_ext = /\..*$/.match(audio_test_file)[0]
    audio_test_file_copy = audio_test_file.gsub(audio_test_file_ext,"_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+audio_test_file_ext)
    File.cp(audio_test_file,audio_test_file_copy)
          @results_html_file.add_paragraph(File.basename(audio_test_file_copy),nil,nil,"//"+audio_test_file_copy.gsub("\\","/"))
  end
  res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
  @results_html_file.add_row_to_table(res_table, [["#{@test_params.params_chan.audio_codec[0]} Scores #{File.basename(audio_ref_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
  @results_html_file.add_row_to_table(res_table,["MOS",pesq_mos])
  @results_html_file.add_row_to_table(res_table,["LQ_MOS",pesq_lq_mos])
  @results_html_file.add_row_to_table(res_table,["MOS2",pesq_mos2])
  @results_html_file.add_row_to_table(res_table,["Speech",pesq_speech])
  @results_html_file.add_row_to_table(res_table,["Noise",pesq_noise])
  @results_html_file.add_row_to_table(res_table,["Attenuation",pesq_att])
  @results_html_file.add_row_to_table(res_table,["Min_delay",pesq_min_del])
  @results_html_file.add_row_to_table(res_table,["Nom_delay",pesq_nom_del])
  @results_html_file.add_row_to_table(res_table,["Max_delay",pesq_max_del])


  [test_done_result, test_comment]
end

def map_recorded_audio_format
    if @test_params.params_chan.command_name[0].include?("decode")
        companding = "linear"
    else
        companding = @test_params.params_chan.speech_companding[0]
    end  
    if  companding == "ulaw" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
      OperaLib::SampleFormat.new(0)
    elsif companding == "alaw" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
      OperaLib::SampleFormat.new(1)
    elsif companding == "ulaw" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
      OperaLib::SampleFormat.new(2)
    elsif companding == "alaw" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
      OperaLib::SampleFormat.new(3)
  elsif companding == "linear" && @test_params.params_chan.audio_sampling_rate[0] == "8000"
    OperaLib::SampleFormat.new(4)
  elsif companding == "linear" && @test_params.params_chan.audio_sampling_rate[0] == "16000"
    OperaLib::SampleFormat.new(5)
  else
      raise "Unsupported #{@test_params.params_chan.codec[0]} recorded audio format companding = "+@test_params.params_chan.audio_companding[0]+" sampling rate = "+@test_params.params_chan.audio_sampling_rate[0]
  end
end

def get_frame_rate
    case @test_params.params_chan.video_signal_format[0]
    when '625','1080p25','1080p50': '25'
    else 30
    end
end

def get_raw_video_file(mpeg4_src_file, raw_video_dst_file, format)
    file_converter = Mpeg4ToYuvConverter.new
    file_converter.convert({'Source' => mpeg4_src_file, 'Target' => raw_video_dst_file, 'data_format' => format})
end
