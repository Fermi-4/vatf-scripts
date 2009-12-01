require File.dirname(__FILE__)+'/../default_dvsdk_test_module'

OPERA_WAIT_TIME				   = 30000

include DvsdkTestScript

def setup
    @equipment['dut1'].set_api('demo')
    #boot_dut() # method implemented in DvsdkTestScript module
end

def run
  video_tester_result = 0
  test_comment = ''
  @connection_handler.make_video_connection({@equipment["video_tester"] => {'sdi' => 0}}, {@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {'sdi' => 0}})
  @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {'sdi' => 0}}, {@equipment["video_tester"] => {'sdi' => 0}})	
  @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.video_input[0] => 0}}) 
  @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) if @equipment.include?('tv0')
  @connection_handler.make_audio_connection({@equipment["audio_player"] => {'mini35mm' => 0}},{@equipment["dut1"] => {'mini35mm' => 0}})   
  @connection_handler.make_audio_connection({@equipment["audio_player"] => {'mini35mm' => 0}}, {@equipment["tv0"] => {'mini35mm' => 0}}) if @equipment.include?('tv0')
  @connection_handler.make_audio_connection({@equipment["dut1"] => {'mini35mm' => 0}},{@equipment["audio_player"] => {'mini35mm' => 0}})
  @connection_handler.make_audio_connection({@equipment["dut1"] => {'mini35mm' => 0}}, {@equipment['tv1'] => {'mini35mm' => 0}}) if @equipment.include?('tv1')
  @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment['tv1'] => {@test_params.params_chan.display_out[0] => 0}}) if @equipment.include?('tv1')
  #======================== Processing Media ====================================================
  audio_ref_file = audio_test_file = audio_input_handle = audio_output_handle = nil   
  test_done_result = FrameworkConstants::Result[:nry] 
  max_num_files = @test_params.params_chan.video_source.length - 1
  max_num_files = [max_num_files, @test_params.params_control.max_num_files[0].to_i - 1].min if @test_params.params_control.instance_variables.include?('@max_num_files')
  @test_params.params_chan.video_source[0..max_num_files].each do |vid_source|
		audio_ref_file = audio_test_file = audio_input_handle = audio_output_handle = nil   
		metric_window = get_metric_window
		if @test_params.params_chan.command_name[0].include?("encode") && @test_params.params_chan.command_name[0].include?("decode")
      local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      test_file = local_ref_file.gsub(".yuv","_test.avi")
      puts "Encoding+Decoding #{vid_source} ....."
      enc_dec_params = get_encode_decode_params(vid_source)
      @equipment['dut1'].encode_decode(enc_dec_params)
      vid_enc_dec_params = {'ref_clip' => local_ref_file, 'test_clip' => test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                  'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => get_height,
                  'video_width' =>get_width, 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => get_frame_rate,
                  'metric_window' => metric_window
      }
      
      @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}})  
      video_tester_result = @equipment['video_tester'].video_out_to_video_in_test(vid_enc_dec_params){
        @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}})
        sleep 2 
        audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process() if @test_params.params_chan.speech_file[0] != 'none'
      }
      bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_chan.speech_file[0] != 'none'
      @equipment['dut1'].wait_for_threads(enc_dec_params['time'].to_i+50)
    elsif @test_params.params_chan.command_name[0].include?("encode")
      local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      @connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}},{@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.video_input[0] => 0}})  
      puts "Encoding #{vid_source} ....."
      enc_params = get_encode_params(vid_source)
      test_file = enc_params['video_file']
      raw_video_test_file = test_file.sub(/\..+$/,'_'+@test_params.params_chan.video_source_chroma_format[0]+'_rawconv.yuv')
      test_file_video_tester = enc_params['video_file']=~/\.mpeg4$/ ? raw_video_test_file : test_file
      vid_enc_params = {'ref_clip' => local_ref_file, 'test_file' =>  test_file_video_tester, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
                'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => get_height,
                'video_width' =>get_width, 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => get_frame_rate,
                'metric_window' => metric_window, 'test_file_data_format' => '422i'
      }
      video_tester_result = @equipment['video_tester'].video_out_to_file_test(vid_enc_params){
        sleep 1
        @equipment['dut1'].encode(enc_params)
        sleep 2
        audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process() if @test_params.params_chan.speech_file[0] != 'none'
        @equipment['dut1'].wait_for_threads(enc_params['time'].to_i + 50)
        bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_chan.speech_file[0] != 'none'
        audio_test_file = enc_params['speech_file']
        get_raw_video_file(test_file,raw_video_test_file, '422i') if enc_params['video_file']=~/\.mpeg4$/
      }	      
    elsif @test_params.params_chan.command_name[0].include?("decode")
			#======================== Prepare reference files ==========================================================	
			local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder', vid_source)
			test_file = local_ref_file.sub(/\.\w*$/,'_test.avi')
			companded_local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
			File.copy(companded_local_ref_file, SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+".g711")
			companded_local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+".g711"
      dec_params = get_decode_params(local_ref_file, companded_local_ref_file)
			if dec_params['video_file']=~/\.mpeg4$/
			    raw_video_ref_file = local_ref_file.sub(/\..+$/,'_'+@test_params.params_chan.video_source_chroma_format[0]+'_rawconv.yuv') 
			    get_raw_video_file(local_ref_file, raw_video_ref_file, @test_params.params_chan.video_source_chroma_format[0])
			end
			ref_file_video_tester = dec_params['video_file']=~/\.mpeg4$/ ? raw_video_ref_file : local_ref_file
			vid_dec_params = {'ref_clip' => ref_file_video_tester, 'test_clip' =>  test_file, 'format' => @test_params.params_chan.video_signal_format[0],
							  'num_frames' => get_te_video_num_frames(vid_source.sub(/from_.*/, File.basename(local_ref_file))), 'metric_window' => metric_window, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
							   'video_height' => get_height, 'video_width' =>get_width, 'frame_rate' => get_frame_rate, 'rec_delay' => @test_params.params_control.video_rec_delay[0].to_f						
			}
			@connection_handler.make_video_connection({@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment["#{@test_params.params_chan.display_out[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}})
			puts "Decoding #{vid_source} ....."
			video_tester_result = @equipment['video_tester'].file_to_video_in_test(vid_dec_params){
				@equipment['dut1'].decode(dec_params)
				@connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment["#{@test_params.params_chan.video_input[0]}_converter"] => {@test_params.params_chan.display_out[0] => 0}})
            	audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process() if @test_params.params_chan.speech_file[0] != 'none'
            }
            @equipment['dut1'].wait_for_threads(vid_dec_params['time'].to_i + 50)
            bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_chan.speech_file[0] != 'none'
    end
    if  !video_tester_result
      @results_html_file.add_paragraph("")
      test_done_result = FrameworkConstants::Result[:fail]
      test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{vid_source}\n"   
		else  	
      video_done_result, video_done_comment = get_results(audio_ref_file, audio_test_file, test_file, vid_source)
      test_comment += video_done_comment+"\n" if video_done_comment.strip != ''
      test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
    end
  end
	rescue Exception => e
    test_comment += e.to_s
		stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_chan.speech_file[0] != 'none' && (audio_input_handle || audio_output_handle)
    @equipment['dut1'].wait_for_threads
    raise 
	ensure
    set_result(test_done_result,test_comment)    
end

def clean
end

private
def get_metric_window
    ti_logo_height = @test_params.params_chan.ti_logo_resolution[0].downcase.split('x')[1].to_i
    ti_logo_width = @test_params.params_chan.ti_logo_resolution[0].downcase.split('x')[0].to_i
	
    video_signal_height = @equipment['video_tester'].get_video_signal_height({'format' => @test_params.params_chan.video_signal_format[0]})
    video_signal_width = @equipment['video_tester'].get_video_signal_width({'format' => @test_params.params_chan.video_signal_format[0]})
    
    x_offset = [0,((video_signal_width - get_width)/2).ceil].max
    y_offset = [0,((video_signal_height - get_height)/2).ceil].max
    metric_window_width = get_width
    metric_window_height = get_height
    if rand < 0.5
    	metric_window_width -= ti_logo_width
    else
        metric_window_height -= ti_logo_height
        y_offset+=ti_logo_height
    end
    [x_offset, y_offset, metric_window_width, metric_window_height] 
end

def get_width
    @test_params.params_chan.video_resolution[0].split('x')[0].to_i
end

def get_height
    @test_params.params_chan.video_resolution[0].split('x')[1].to_i
end

# def get_ref_file(start_directory, file_name)
	# ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
	# raise "File #{file_name} not found" if ref_file == "" || !ref_file
	# local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	# FileUtils.cp(ref_file, local_ref_file)
	# [ref_file,local_ref_file]
# end

def get_local_file_regex(type)
  case type
    when /video/i
      /^#{@test_params.params_chan.video_resolution[0]}_#{@test_params.params_chan.video_bitrate[0]}_\d+frames\.#{@test_params.params_chan.video_type[0].gsub(/h264/,'264')}$/i
    when /audio/i
      // # Todo
    when /speech/i
      // # Todo
    else
      /#{@test_params.params_chan.picture_resolution[0]}.*\.jpg$/i
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

def get_encode_decode_params(vid_source)
    {
        'video_resolution' 		=> @test_params.params_chan.video_resolution[0],
        'video_bitrate' 		=> @test_params.params_chan.video_bitrate[0],
        'video_signal_format'	=> @test_params.params_chan.video_signal_format[0],
        'display_out'			=> @test_params.params_chan.display_out[0],
        'time'					=> (get_video_time(vid_source)*3).to_s,
        'disable_deinterlace'	=> @test_params.params_chan.disable_deinterlace[0],
        'passthrough'			=> @test_params.params_chan.passthrough[0],
        'enable_osd'			=> @test_params.params_chan.enable_osd[0],
        'video_input'			=> @test_params.params_chan.video_input[0],
    }
end

def get_encode_params(vid_source)
    h={
        'speech_file' 			=> SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.speech_file[0],
        'video_file'			=> SiteInfo::LOCAL_FILES_FOLDER+get_test_video_file_name(get_video_time(vid_source)-4),
        'video_resolution'		=> @test_params.params_chan.video_resolution[0],
        'video_bitrate'		 	=> @test_params.params_chan.video_bitrate[0],
        'video_signal_format'	=> @test_params.params_chan.video_signal_format[0],
        'display_out'			=> @test_params.params_chan.display_out[0],
        'time'					=> get_video_time(vid_source).to_s,
        'audio_input'			=> @test_params.params_chan.audio_input[0],
        'disable_deinterlace'	=> @test_params.params_chan.disable_deinterlace[0],
        'enable_osd'			=> @test_params.params_chan.enable_osd[0],
        'video_input'			=> @test_params.params_chan.video_input[0],
    }
    h.merge!({'speech_file' => nil}) if @test_params.params_chan.speech_file[0] == 'none'
    h
end

def get_test_video_file_name(time)
  @test_params.params_chan.video_resolution[0]+'_'+@test_params.params_chan.video_bitrate[0]+'_'+(time.to_i*30).to_s+'frames'+get_video_extension(@test_params.params_chan.video_type[0])
end

def get_video_extension(video_type)
  case video_type.strip.downcase
    when 'h264': return '.264'
    when 'mpeg4': return '.mpeg4'
    when 'mpeg2': return '.m2v'
    else video_type
  end
end

def get_decode_params(vid_source, speech_source)
    h={
        'speech_file' 			=> speech_source,
        'video_file'			=> vid_source,
        'video_signal_format'	=> @test_params.params_chan.video_signal_format[0],
        'display_out'			=> @test_params.params_chan.display_out[0],
        'time'					=> get_video_time(vid_source).to_s,
        'enable_osd'			=> @test_params.params_chan.enable_osd[0],
    }
    h.merge!({'speech_file' => nil}) if @test_params.params_chan.speech_file[0] == 'none'
    h
end

def get_video_time(vid_source)
    file_num_frames = /(\d+)frames/.match(vid_source).captures[0].to_i
    (file_num_frames*0.1).ceil
end

def get_te_video_num_frames(vid_source)
    file_num_frames = /(\d+)frames/.match(vid_source).captures[0].to_i
    file_num_frames
end

def get_frame_rate
    case @test_params.params_chan.video_signal_format[0]
    when '625','1080p25','1080p50': '25'
    else 30
    end
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
		local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/',@test_params.params_chan.audio_source[0]+".pcm")
		test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test.pcm"
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
		@equipment['audio_player'].play_wave_audio(audio_output_handle, local_ref_file)
    elsif @test_params.params_chan.command_name[0].include?("encode")  
		test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test"+get_audio_ext()
		pcm_local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
		ref_file, local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
		@equipment['audio_player'].play_wave_audio(audio_output_handle, pcm_local_ref_file)
	elsif @test_params.params_chan.command_name[0].include?("decode")
	    test_file = SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test.pcm"
		local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
	end
	[local_ref_file,test_file,audio_input_handle, audio_output_handle]
end

def stop_audio_process(audio_input_handle, audio_output_handle)
   while !@equipment['audio_player'].wave_audio_play_done(audio_output_handle)
		sleep(1)
   end
   sleep(1)
   bytes_recorded = nil
   bytes_recorded = @equipment['audio_player'].stop_wave_audio_record(audio_input_handle) if @test_params.params_chan.command_name[0].include?("decode")
   @equipment['audio_player'].stop_wave_audio_play(audio_output_handle) if @test_params.params_chan.command_name[0].include?("encode")
   @equipment['audio_player'].close_wave_in_device(audio_input_handle)
   @equipment['audio_player'].close_wave_out_device(audio_output_handle)
   [bytes_recorded, nil, nil]   
end

def get_results(audio_ref_file,audio_test_file, video_file, vid_source)
	test_done_result = FrameworkConstants::Result[:pass]
	@results_html_file.add_paragraph("")
    test_comment = " "	
	res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	
	if @test_params.params_chan.command_name[0].include?("encode") || @test_params.params_chan.command_name[0].include?("decode")
		pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
		@results_html_file.add_row_to_table(res_table, [["h264 Scores #{File.basename(vid_source)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
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
			if @equipment['video_tester'].get_mos_score < pass_fail_criteria[1].to_f #|| @equipment['video_tester'].get_jerkiness_score < 3.5 || @equipment['video_tester'].get_level_score > 2 ||	@equipment['video_tester'].get_blocking_score < 3.5 || @equipment['video_tester'].get_blurring_score < 3.5 || @equipment['video_tester'].get_frame_lost_count > 0 || @equipment['video_tester'].get_psnr_score < 28
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
			test_comment = "Test failed for file "+File.basename(vid_source)+"."
			file_extension = File.extname(video_file)
			failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+file_extension)
      if File.exists?(video_file)
        File.copy(video_file, failed_file_name) 
        @results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
      end
		end
	end
	
	if @test_params.params_chan.speech_file[0] != 'none'
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
		
		if pesq_mos < 1.0 
			test_done_result = FrameworkConstants::Result[:fail]
			test_comment = test_comment.to_s+" Test failed for file "+File.basename(audio_test_file)
			audio_test_file_ext = /\..*$/.match(audio_test_file)[0]
			audio_test_file_copy = audio_test_file.gsub(audio_test_file_ext,"_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+audio_test_file_ext)
			File.cp(audio_test_file,audio_test_file_copy)
            @results_html_file.add_paragraph(File.basename(audio_test_file_copy),nil,nil,"//"+audio_test_file_copy.gsub("\\","/"))
		end
		@results_html_file.add_row_to_table(res_table, [["G711 Scores #{File.basename(audio_test_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
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

def get_audio_ext
		".a"
end

def get_raw_video_file(mpeg4_src_file, raw_video_dst_file, format)
    file_converter = Mpeg4ToYuvConverter.new
    file_converter.convert({'Source' => mpeg4_src_file, 'Target' => raw_video_dst_file, 'data_format' => format})
end

def map_recorded_audio_format
    if @test_params.params_chan.command_name[0].include?("decode")
        companding = "linear"
    else
        companding = "alaw"
    end	
    if  companding == "ulaw"
	    OperaLib::SampleFormat.new(0)
    elsif companding == "alaw"
	    OperaLib::SampleFormat.new(1)
    elsif companding == "linear"
		OperaLib::SampleFormat.new(4)
	else
	    raise "Unsupported G711 recorded audio format companding = "+@test_params.params_chan.audio_companding[0]+" sampling rate = "+@test_params.params_chan.audio_sampling_rate[0]
	end
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end

