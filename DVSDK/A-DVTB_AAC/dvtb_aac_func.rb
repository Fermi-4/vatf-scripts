#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Audio'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/AAC_Audio_files/'

def setup
	#Setting max number of dut supported sockets
	@equipment["dut"].set_max_number_of_sockets(0,@test_params.params_control.num_channels[0].to_i)
	
	#Setting audio driver
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "mode", "Value" => get_audio_driver_mode})
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "framesize", "Value" => get_frame_size.to_s}) 
	
	if @test_params.params_chan.test_type[0].include?("apfe")
		#Setting audio encoder
		@equipment["dut"].set_param({"Class" => "audenc", "Param" => "sampleRate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
		@equipment["dut"].set_param({"Class" => "audenc", "Param" => "bitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
		@equipment["dut"].set_param({"Class" => "audenc", "Param" => "numChannels", "Value" => map_audio_type(@test_params.params_chan.audio_type[0])})	
	end
	
	#Setting audio decoder
	if @test_params.params_chan.test_type[0].include?("apbe")
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxSampleRate", "Value" => "96000"})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxBitrate", "Value" => "768000"})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxNoOfCh", "Value" => map_audio_type("stereo")})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "dataEndianness", "Value" => "2"})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "outputFormat", "Value" => "1"})
	end
	
	#Making audio connections
	@connection_handler.make_audio_connection(@equipment[@test_params.params_chan.audio_source[0].strip],{@equipment["dut"] => 1}) if @test_params.params_chan.test_type[0].include?("apfe")
	@connection_handler.make_audio_connection(@equipment["dut"], {@equipment["output_device"] => 1}) if @test_params.params_chan.test_type[0].include?("apbe")
end

def run
	begin
		file_res_form = ResultForm.new("AAC Codec #{@test_params.params_chan.test_type[0]} Test Result Form")
		if !@test_params.params_chan.test_type[0].include?("apfe")
			@test_params.params_chan.audio_source.each do |audio_file|
				ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{audio_file}/}
				raise "File #{audio_file} not found" if ref_file == "" || !ref_file
				File.makedirs(LOCAL_FILES_FOLDER) if !File.exist?(LOCAL_FILES_FOLDER)
				local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
				FileUtils.cp(ref_file, local_ref_file)
				puts "Playing File #{audio_file} ...."
				@equipment["dut"].audio_decoding({"Source" => local_ref_file})
				@equipment["dut"].wait_for_threads
			end
		elsif !@test_params.params_chan.test_type[0].include?("apbe")
			if @test_params.params_chan.audio_source[0] == "dvd"
				sleep 60
				@equipment["dvd"].go_to_track(4)
			end
			@equipment["dut"].set_param({"Class" => "audenc", "Param" => "seconds", "Value" => @test_params.params_chan.media_time[0]})
			puts "Capturing Audio in file #{LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]}_#{@test_params.params_chan.audio_sampling_rate[0].gsub("000","kHz")}_#{@test_params.params_chan.audio_bit_rate[0].gsub("000","kbps")}_AAC_ENC_DEF_VAL.aac"
			@equipment["dut"].audio_encoding({"Target" => "#{LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]}_#{@test_params.params_chan.audio_sampling_rate[0].gsub("000","kHz")}_#{@test_params.params_chan.audio_bit_rate[0].gsub("000","kbps")}_AAC_ENC_DEF_VAL.aac"})
			@equipment["dut"].wait_for_threads
			file_res_form.add_link(audio_file) do
				system("explorer #{test_file.gsub("/","\\")}")
			end
			files_array = files_array|[test_file]
		else
			@equipment["dut"].audio_encoding_decoding 
			@equipment["dut"].wait_for_threads
		end
		file_res_form.show_result_form
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
	
	if file_res_form.test_result == FrameworkConstants::Result[:fail] && !@test_params.params_chan.test_type[0].include?("apbe")
		@results_html_file.add_paragraph("Captured File link:")
		files_array.each do |encoded_file| 
			@results_html_file.add_paragraph("")
			@results_html_file.add_paragraph(encoded_file,nil,nil,"//"+encoded_file)
		end
	end
	
	#======================== Set Results ======================================================================
	set_result(file_res_form.test_result, file_res_form.comment_text)
end

def clean
	
end

private
def map_audio_type(audio_type)
	if audio_type.strip.downcase.eql?("mono") 
		return 0.to_s
	elsif audio_type.strip.downcase.eql?("stereo") || audio_type.strip.downcase.eql?("dualmono")
		return 1.to_s
	else
		raise "Unsopported audio type #{audio_type}"
	end
end

def get_frame_size
	#@test_params.params_chan.audio_sampling_rate[0].to_i*@test_params.params_chan.audio_bit_rate[0].to_i*14/1000
	32000
end

def get_audio_driver_mode
	if !@test_params.params_chan.test_type[0].include?("apbe")
		1.to_s
	else
		0.to_s
	end
end