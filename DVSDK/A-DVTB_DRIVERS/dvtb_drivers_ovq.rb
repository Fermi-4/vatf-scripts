NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'
OPERA_WAIT_TIME				   = 30000

def setup
    #Setting up the maximum number of sockets that the client can support
    num_of_vid_sockets = @test_params.params_control.video_num_channels[0].to_i
	num_of_aud_sockets = 0
    num_of_aud_sockets =  @test_params.params_control.audio_num_channels[0].to_i if @test_params.params_control.respond_to?(:audio_num_channels)
    @equipment['dut'].set_max_number_of_sockets(num_of_vid_sockets,num_of_aud_sockets)
    
  if @test_params.params_chan.test_type[0].include?("vpfe")
  # Setup VPFE
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "standard",
                                 "Value" => map_standard})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "width",
                                 "Value" => @test_params.params_chan.video_width[0]})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "height",
                                 "Value" => @test_params.params_chan.video_height[0]})                             
								 
	@equipment['dut'].set_param({"Class" => "vpfe",
                                 "Param" => "numframes",
                                 "Value" => get_num_frames})

	@connection_handler.make_video_connection({@equipment["video_tester"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
	@test_params.params_control.video_num_channels[0].to_i.times do |input_idx|
		@connection_handler.make_video_connection({@equipment["video_tester"] => 0},{@equipment["dut"] => input_idx}, @test_params.params_chan.video_iface_type[0])
	end
  end
  
  if @test_params.params_chan.test_type[0].include?("vpbe")
	# Setup VPBE                              
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "standard",
                                 "Value" => map_standard})
                                 
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "width",
                                 "Value" => "#{@test_params.params_chan.video_width[0]}"})
                                 
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "height",
                                 "Value" => "#{@test_params.params_chan.video_height[0]}"})                           
    
    #@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "xoffset",
    #                             "Value" => "0"})   
                                 
    #@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "yoffset",
    #                             "Value" => "0"}) 
    
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "chanNumber",
                                 "Value" => "0"})   
	
	@connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
  end
              
  if @test_params.params_chan.test_type[0].include?("apfe")
    # setup apfe
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "mode",
                                 "Value" => "1"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "samplerate",
                                 "Value" => "44100"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "gain",
                                 "Value" => "100"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "seconds",
                                 "Value" => @test_params.params_control.media_time[0]})
								 
    @connection_handler.make_audio_connection({@equipment["audio_player"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])
    @test_params.params_control.audio_num_channels[0].to_i.times do |input_idx| 
      @connection_handler.make_audio_connection({@equipment["audio_player"] => 0},{@equipment["dut"] => input_idx}, @test_params.params_chan.audio_iface_type[0])
    end
  end
  
  if @test_params.params_chan.test_type[0].include?("apbe")
  #setup apbe
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "mode",
                                 "Value" => "0"})
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "gain",
                                 "Value" => "100"})
	@connection_handler.make_audio_connection({@equipment["dut"] => 0},{@equipment["tv1"] => 0})
  end
end

def run
    video_tester_result = 0
	video_channel_number = get_chan_number(@test_params.params_control.video_num_channels[0].to_i)
	@connection_handler.make_video_connection({@equipment["video_tester"] => 0}, {@equipment["dut"] => video_channel_number, @equipment["tv0"] => 0},@test_params.params_chan.video_iface_type[0]) if @test_params.params_chan.test_type[0].include?("vpfe")
    audio_channel_number = get_chan_number(@test_params.params_control.audio_num_channels[0].to_i) 
	@connection_handler.make_audio_connection({@equipment["audio_player"] => 0},{@equipment["dut"] => audio_channel_number, @equipment["tv0"] => 0}, @test_params.params_chan.audio_iface_type[0]) if @test_params.params_chan.test_type[0].include?("apfe")  
	#======================== Processing Media ====================================================
    audio_ref_file = audio_test_file = audio_input_handle = audio_output_handle = nil   
    test_done_result = FrameworkConstants::Result[:nry] 
    test_comment = ''
    if @test_params.params_chan.test_type[0].include?("vpfe") && @test_params.params_chan.test_type[0].include?("vpbe")
        ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
		test_file = local_ref_file.gsub(".yuv","_test.avi")
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => get_video_num_frames(vid_source)})
		puts "Video Loopback for #{vid_source} ....."
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
		@equipment['dut'].video_loopback
		vid_enc_dec_params = {'ref_clip' => local_ref_file, 'test_clip' => test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
							  'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => @test_params.params_chan.video_height[0],
							  'video_width' =>@test_params.params_chan.video_width[0], 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => @test_params.params_chan.video_frame_rate[0],
							  'metric_window' => metric_window
		}
		@connection_handler.make_video_connection({@equipment["video_tester"] => 0},{@equipment["video_tester"] =>0},@test_params.params_chan.video_iface_type[0])  
		video_tester_result = @equipment['video_tester'].video_out_to_video_in_test(vid_enc_dec_params){
			 @connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["video_tester"] => 0},@test_params.params_chan.video_iface_type[0])
			 sleep 1
			 audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0
		 }
		bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0
		@equipment['dut'].wait_for_threads
    elsif @test_params.params_chan.test_type[0].include?("vpfe")
		ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
		test_file = local_ref_file.gsub(/\d+frames/,(get_te_video_num_frames(vid_source)*2).to_s+"frames")
		vid_enc_params = {'ref_clip' => local_ref_file, 'test_file' =>  test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
						  'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => @test_params.params_chan.video_height[0],
						  'video_width' =>@test_params.params_chan.video_width[0], 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => @test_params.params_chan.video_frame_rate[0],
						  'metric_window' => metric_window, 'test_file_data_format' => @test_params.params_chan.video_output_chroma_format[0]
		}
		@connection_handler.make_video_connection({@equipment["video_tester"] => 0},{@equipment["video_tester"] =>0},@test_params.params_chan.video_iface_type[0])
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => (get_te_video_num_frames(vid_source)*2).to_s})
		puts "Capturing #{vid_source} ....."
		video_tester_result = @equipment['video_tester'].video_out_to_file_test(vid_enc_params){
			0.upto(video_channel_number) do |ch_num|
				@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
				@equipment['dut'].video_capture({"Target" => local_ref_file.gsub(/\d+frames/,(get_te_video_num_frames(vid_source)*2).to_s+"frames")})
			end
			audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0
			@equipment['dut'].wait_for_threads
		bytes_rec, audio_input_handle, audio_output_handle = stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0
		}
	elsif @test_params.params_chan.test_type[0].include?("vpbe")
		#======================== Prepare reference files ==========================================================
		ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
		test_file = local_ref_file.sub(/\.\w*$/,'_test.avi')
		vid_dec_params = {'ref_clip' => local_ref_file, 'test_clip' =>  test_file, 'data_format' => @test_params.params_chan.video_source_chroma_format[0],
						  'format' => @test_params.params_chan.video_signal_format[0], 'video_height' => @test_params.params_chan.video_height[0],
						  'video_width' =>@test_params.params_chan.video_width[0], 'num_frames' => get_te_video_num_frames(vid_source), 'frame_rate' => @test_params.params_chan.video_frame_rate[0],
						  'metric_window' => metric_window							
		}
		@connection_handler.make_video_connection({@equipment["video_tester"] => 0},{@equipment["video_tester"] => 0, @equipment['tv0'] => 0},@test_params.params_chan.video_iface_type[0])
		puts "Playing #{vid_source} ....."
		video_tester_result = @equipment['video_tester'].file_to_video_in_test(vid_dec_params){
			@equipment['dut'].video_play({"Source" => LOCAL_FILES_FOLDER+vid_source})
			@connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["video_tester"] => 0},@test_params.params_chan.video_iface_type[0])
			audio_ref_file, audio_test_file, audio_input_handle, audio_output_handle = run_audio_process(audio_channel_number) if @test_params.params_control.audio_num_channels[0].to_i > 0	
		}
		@equipment['dut'].wait_for_threads
	end     
	if  !video_tester_result
		    @results_html_file.add_paragraph("")
     	    test_done_result = FrameworkConstants::Result[:fail]
     	    test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{vid_source}\n"   
		else  	
    		video_done_result, video_done_comment = get_results(audio_ref_file, audio_test_file, test_file)
    		test_comment += video_done_comment+"\n"
    		test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
    	end
    end
	rescue Exception => e
		test_comment += e.to_s
		stop_audio_process(audio_input_handle, audio_output_handle) if @test_params.params_control.audio_num_channels[0].to_i > 0 && (audio_input_handle || audio_output_handle)
    	@equipment['dut'].wait_for_threads
	ensure
        set_result(test_done_result,test_comment)
end

def clean

end



private 

def map_standard
    #These values may change depending on the ptaform
    case @test_params.params_chan.video_signal_format[0].downcase
        when '525'
            0.to_s
			#1.to_s
        when '625'
            1.to_s
			#5.to_s
        else
            raise 'video region '+@test_params.params_chan.video_signal_format[0]+' not supported'
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
		@equipment['dut'].audio_loopback	# Multiple Audio Channel are not supported yet
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
		@equipment['audio_player'].play_wave_audio(audio_output_handle, local_ref_file)
    elsif @test_params.params_chan.test_type[0].include?("apfe")  
		test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test"+get_audio_ext()
		pcm_ref_file, pcm_local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
		ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
		@equipment['dut'].audio_capture({"Target" => test_file})	# Multiple Audio Channel are not supported yet
		@equipment['audio_player'].play_wave_audio(audio_output_handle, pcm_local_ref_file)
	elsif @test_params.params_chan.test_type[0].include?("apbe")
	    test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_test.pcm"
		companded_ref_file, companded_local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder/', @test_params.params_chan.audio_source[0]+get_audio_ext)
		ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Speech/Encoder/', @test_params.params_chan.audio_source[0]+".pcm")
		@equipment['audio_player'].record_wave_audio(audio_input_handle, test_file)
		@equipment['dut'].audio_play({"Source" => companded_local_ref_file})
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

def get_audio_ext
	if @test_params.params_chan.audio_companding[0].include?("ulaw")
		".u"
	else
		".a"
	end
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

def get_ref_file(start_directory, file_name)
	ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
	raise "File #{file_name} not found" if ref_file == "" || !ref_file
	local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	FileUtils.cp(ref_file, local_ref_file)
	[ref_file,local_ref_file]
end

def get_frame_size(sampling_rate)
	# case sampling_rate.to_i
		# when 8
			# 4096
		# when 44.1
			# 32000
		# else
			# raise "Unknown frame size for sampling rate "+samplng_rate
	# end
	1024
end

def get_chan_number(num_chan)
	rand(num_chan)
end

def get_results(audio_ref_file,audio_test_file, video_file)
	test_done_result = FrameworkConstants::Result[:pass]
	@results_html_file.add_paragraph("")
    test_comment = " "	
	res_table = @results_html_file.add_table([["#{@test_params.params_chan.test_type[0]} Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	
	if @test_params.params_chan.test_type[0].include?("vpfe") || @test_params.params_chan.test_type[0].include?("vpbe")
		pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
		
		@results_html_file.add_row_to_table(res_table, [["Video Driver Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
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
		@results_html_file.add_row_to_table(res_table, [["Audio Driver Scores #{File.basename(audio_ref_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
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
    if @test_params.params_chan.test_type[0].include?("apbe")
        companding = "linear"
    else
        companding = @test_params.params_chan.audio_companding[0]
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
	    raise "Unsupported G711 recorded audio format companding = "+@test_params.params_chan.audio_companding[0]+" sampling rate = "+@test_params.params_chan.audio_sampling_rate[0]
	end
end



