#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Audio'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/AAC_Audio_files/'

def setup
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsSampleRate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsBitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsOutFileFormat", "Value" => map_out_file_format(@test_params.params_chan.audio_output_file_format[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsBitRate", "Value" => @test_params.params_chan.audio_bit_rate[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsSampleRate", "Value" => @test_params.params_chan.audio_sampling_rate[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsOutObjectType", "Value" => map_out_object_type(@test_params.params_chan.audio_output_object_type[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsOutObjectType", "Value" => map_out_object_type(@test_params.params_chan.audio_output_object_type[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsOutFileFormat", "Value" => map_out_file_format(@test_params.params_chan.audio_output_file_format[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "nbInChannels", "Value" => map_audio_type(@test_params.params_chan.audio_type[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "numChannels", "Value" => map_audio_type(@test_params.params_chan.audio_type[0])})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsDualMono", "Value" => set_flag(@test_params.params_chan.audio_type[0],"dualmono")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsDualMono", "Value" => set_flag(@test_params.params_chan.audio_type[0],"dualmono")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsUseCRC", "Value" => set_flag(@test_params.params_chan.audio_use_crc[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsUseTns", "Value" => set_flag(@test_params.params_chan.audio_use_tns[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "paramsUsePns", "Value" => set_flag(@test_params.params_chan.audio_use_pns[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsUseCRC", "Value" => set_flag(@test_params.params_chan.audio_use_crc[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsUseTns", "Value" => set_flag(@test_params.params_chan.audio_use_tns[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "dynparamsUsePns", "Value" => set_flag(@test_params.params_chan.audio_use_pns[0],"on")})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "numLFEChannels", "Value" => @test_params.params_chan.audio_num_lfe_channels[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "bitRateMode", "Value" => @test_params.params_chan.audio_bit_rate_mode[0]})
	@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.audio_encoder_preset[0]})
	#@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "inputFormat", "Value" => map_input_format(@test_params.params_chan.audio_input_format[0])})
	#@equipment["dut"].set_param({"Class" => "aaclc1dot1enc", "Param" => "inputBitsPerSample", "Value" => "32"})
end

def run
	files_array = Array.new
	begin
		file_res_form = ResultForm.new("AAC Encode Files Result Form")
		@test_params.params_chan.audio_source.each do |audio_file|
			puts "Encoding #{audio_file} ...."
			ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{audio_file}/}
			raise "File #{audio_file} not found" if ref_file == "" || !ref_file
			File.makedirs(LOCAL_FILES_FOLDER) if !File.exist?(LOCAL_FILES_FOLDER)
			local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
			test_file = get_test_file_name(local_ref_file)
			FileUtils.cp(ref_file, local_ref_file)
			@equipment["dut"].audio_encoding({"Source" => local_ref_file, "Target" => test_file, "Encoder" => "aaclc1dot1enc"})
			@equipment["dut"].wait_for_threads
			file_res_form.add_link(audio_file) do
				system("explorer #{test_file.gsub("/","\\")}")
			end
			files_array = files_array|[test_file]
		end
		#@equipment["dut"].wait_for_threads
		file_res_form.show_result_form
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
	
	if file_res_form.test_result == FrameworkConstants::Result[:fail]
		@results_html_file.add_paragraph("Decoded File links:")
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

def map_out_file_format(file_format)
	if file_format.strip.downcase.eql?("adts")
		return 2.to_s
	elsif file_format.strip.downcase.eql?("adif")
		return 1.to_s
	elsif file_format.strip.downcase.eql?("raw")
		return 0.to_s
	else
		raise "Unsopported file format #{file_format}"
	end
end

def map_out_object_type(out_type)
	if out_type.strip.downcase.eql?("lc")
		return 2.to_s
	elsif out_type.strip.downcase.eql?("he")
		return 5.to_s
	elsif out_type.strip.downcase.eql?("ps")
		return 29.to_s
	else
		raise "Unsopported object type #{out_type}"
	end
end

def map_audio_type(audio_type)
	if audio_type.strip.downcase.eql?("mono") 
		return 0.to_s
	elsif audio_type.strip.downcase.eql?("stereo") || audio_type.strip.downcase.eql?("dualmono")
		return 1.to_s
	else
		raise "Unsopported audio type #{audio_type}"
	end
end

def set_flag(audio_type, true_string)
	if audio_type.strip.downcase.eql?(true_string) 
		1.to_s
	else
		0.to_s
	end
end

def get_test_file_name(source_file_name)
	source_file_name.gsub(".pcm","_"+@test_params.params_chan.audio_bit_rate[0].gsub("000","kbps")+"_"+@test_params.params_chan.audio_output_file_format[0].upcase+"_xIS_"+map_on_off(@test_params.params_chan.audio_use_tns[0])+"TNS_"+map_on_off(@test_params.params_chan.audio_use_pns[0])+"PNS_xMS_"+"test.aac")
end

def map_on_off(on_off)
	on_off.strip.downcase.gsub("on","y").gsub("off","n")
end

def get_bits_per_sample(audio_type)
	if audio_type.strip.downcase.eql?("mono") 
		return 0.to_s
	elsif audio_type.strip.downcase.eql?("stereo") || audio_type.strip.downcase.eql?("dualmono")
		return 1.to_s
	else
		raise "Unsopported audio type #{audio_type}"
	end
end

def map_input_format(in_format)
	if in_format.strip.downcase.eql?("block") 
		return 0.to_s
	elsif in_format.strip.downcase.eql?("interleaved") 
		return 1.to_s
	else
		raise "Unsopported audio type #{in_format}"
	end
end

