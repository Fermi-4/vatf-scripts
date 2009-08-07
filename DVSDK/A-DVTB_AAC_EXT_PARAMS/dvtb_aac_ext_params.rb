#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Audio'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/AAC_Audio_files/'

def setup
  @equipment['dut'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  @equipment['dut'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut'].respond_to?(:boot)# call bootscript if required

	#Setting max number of dut supported sockets
	@equipment["dut"].set_max_number_of_sockets(0,@test_params.params_control.audio_num_channels[0].to_i)
	
	#Setting audio driver
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "mode", "Value" => get_audio_driver_mode})
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "samplerate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
	@equipment["dut"].set_param({"Class" => "audio", "Param" => "framesize", "Value" => get_frame_size.to_s}) 
	
	if @test_params.params_chan.test_type[0].include?("apfe") || @test_params.params_chan.test_type[0].include?("encode")
		#Setting audio encoder
		@equipment["dut"].set_param({"Class" => "engine", "Param" => "name", "Value" => "encode" })
		
		#Base parameters
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "codec", "Value" => "aacenc" })		
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "sampleRate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "bitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "channelMode", "Value" => @test_params.params_chan.audio_type[0]})	
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dataEndianness", "Value" => @test_params.params_chan.audio_data_endianness[0]})	
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "encMode", "Value" => @test_params.params_chan.audio_encoder_mode[0]})	
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "inputFormat", "Value" => @test_params.params_chan.audio_input_format[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "inputBitsPerSample", "Value" => @test_params.params_chan.audio_type[0]})		
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "maxBitrate", "Value" => get_max_bit_rate})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dualMonoMode", "Value" => @test_params.params_chan.audio_dual_mono_mode[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "crcFlag", "Value" => @test_params.params_chan.audio_crc_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "ancFlag", "Value" => @test_params.params_chan.audio_anc_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "lfeFlag", "Value" => @test_params.params_chan.audio_lfe_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "seconds", "Value" => @test_params.params_control.media_time[0]})
		
		#Extended Parameters
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "outObjectType", "Value" => @test_params.params_chan.audio_output_object_type[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "outFileFormat", "Value" => @test_params.params_chan.audio_output_file_format[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "useTns", "Value" => @test_params.params_chan.audio_use_tns[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "usePns", "Value" => @test_params.params_chan.audio_use_pns[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "downMixFlag", "Value" => @test_params.params_chan.audio_down_mix_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "bitRateMode", "Value" => @test_params.params_chan.audio_bit_rate_mode[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "ancRate", "Value" => @test_params.params_chan.audio_anc_rate[0]})
		
		#Dynamic Base Parameters
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsSampleRate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsBitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsChannelMode", "Value" => @test_params.params_chan.audio_type[0]})	
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsLfeFlag", "Value" => @test_params.params_chan.audio_lfe_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsDualMonoMode", "Value" => @test_params.params_chan.audio_dual_mono_mode[0]})		
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsInputBitsPerSample", "Value" => @test_params.params_chan.audio_type[0]})		
		
		#Dynamic Extended Parameters
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsOutObjectType", "Value" => @test_params.params_chan.audio_output_object_type[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsOutFileFormat", "Value" => @test_params.params_chan.audio_output_file_format[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsUseCRC", "Value" => @test_params.params_chan.audio_crc_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsUseTns", "Value" => @test_params.params_chan.audio_use_tns[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsUsePns", "Value" => @test_params.params_chan.audio_use_pns[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsDownMixFlag", "Value" => @test_params.params_chan.audio_down_mix_flag[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsBitRateMode", "Value" => @test_params.params_chan.audio_bit_rate_mode[0]})
		@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "dynParamsAncRate", "Value" => @test_params.params_chan.audio_anc_rate[0]})
	end
	
	#Setting audio decoder
	if @test_params.params_chan.test_type[0].include?("apbe")
#		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxSampleRate", "Value" => (@test_params.params_chan.audio_sampling_rate[0].to_i*1.1).round.to_s})
#		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxBitrate", "Value" => (@test_params.params_chan.audio_bit_rate[0].to_i*1.1).round.to_s})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxNoOfCh", "Value" => '2'})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "dataEndianness", "Value" => "2"})
		@equipment["dut"].set_param({"Class" => "auddec", "Param" => "outputFormat", "Value" => "1"})
	end
	
	#Making audio connections
	@connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0].strip] => 0},{@equipment["dut"] => 0}, 'mini35mm') if @test_params.params_chan.test_type[0].include?("apfe")
	@connection_handler.make_audio_connection({@equipment["dut"] => 0}, {@equipment["output_device"] => 0}, 'mini35mm') if @test_params.params_chan.test_type[0].include?("apbe")
end

def run
	begin
	    files_array =  []
		file_res_form = ResultForm.new("AAC Codec #{@test_params.params_chan.test_type[0]} Test Result Form")
		if !@test_params.params_chan.test_type[0].include?("apfe") && !@test_params.params_chan.test_type[0].include?("encode")
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
		elsif !@test_params.params_chan.test_type[0].include?("apbe") && !@test_params.params_chan.test_type[0].include?("decode") && @test_params.params_chan.test_type[0].include?("apfe")
			if @test_params.params_chan.audio_source[0] == "dvd"
#				sleep 60 Commented out because user will start dvd player before running tests
#				@equipment["dvd"].go_to_track(4)
			end
			@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "seconds", "Value" => @test_params.params_control.media_time[0]})
			test_file = LOCAL_FILES_FOLDER+@test_params.params_chan.audio_source[0]+"_"+(@test_params.params_chan.audio_sampling_rate[0].to_i/1000).floor.to_s+"KHz_"+@test_params.params_chan.audio_bit_rate[0].sub(/000$/,"kbps")+"_"+@test_params.params_chan.audio_output_file_format[0].upcase+"_xIS_"+map_on_off(@test_params.params_chan.audio_use_tns[0])+"TNS_"+map_on_off(@test_params.params_chan.audio_use_pns[0])+"PNS_xMS_"+"test.aac"
			puts "Capturing Audio in file " + test_file +" ..."
			@equipment["dut"].aacext_encoding({"Target" => test_file, "threadIdEnc" => 'aacheenc'})
			@equipment["dut"].wait_for_threads
			file_res_form.add_link(File.basename(test_file)) do
				system("explorer #{test_file.gsub("/","\\")}")
			end
			files_array = files_array|[test_file]
		elsif !@test_params.params_chan.test_type[0].include?("decode")
			@test_params.params_chan.audio_source.each do |audio_file|
				ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{audio_file}/}
				raise "File #{audio_file} not found" if ref_file == "" || !ref_file
				File.makedirs(LOCAL_FILES_FOLDER) if !File.exist?(LOCAL_FILES_FOLDER)
				local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
				FileUtils.cp(ref_file, local_ref_file)
				puts "Encoding File #{audio_file} ...."
				@equipment["dut"].set_param({"Class" => "aacextenc", "Param" => "seconds", "Value" => @test_params.params_control.media_time[0]})
				test_file = LOCAL_FILES_FOLDER+File.basename(local_ref_file).gsub(".pcm","")+"_"+@test_params.params_chan.audio_bit_rate[0].gsub("000","kbps")+"_"+@test_params.params_chan.audio_output_file_format[0].upcase+"_xIS_"+map_on_off(@test_params.params_chan.audio_use_tns[0])+"TNS_"+map_on_off(@test_params.params_chan.audio_use_pns[0])+"PNS_xMS_"+"test.aac"
				@equipment["dut"].aacext_encoding({"Target" => test_file, "Source" => local_ref_file, "threadIdEnc" => 'aacheenc'})
				file_res_form.add_link(File.basename(test_file)) do
					system("explorer #{test_file.gsub("/","\\")}")
				end
				files_array = files_array|[test_file]
			end
			@equipment["dut"].wait_for_threads
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

def map_on_off(on_off)
	on_off.strip.downcase.gsub("1","y").gsub("0","n")
end

def get_max_bit_rate
	[576000,(@test_params.params_chan.audio_bit_rate[0].to_i*1.1).round].min.to_s
end

def get_max_sampling_rate
	[96000,(@test_params.params_chan.audio_sampling_rate[0].to_i*1.1).round].min.to_s
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end