#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

# include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() #method implemented in DvsdkTestScript module
  @equipment['dut1'].connect({'type'=>'telnet'})
  set_codec_param("codec", "audio_codec")
  set_codec_param("outputPCMWidth","audio_output_pcm_width")
  set_codec_param("pcmFormat","audio_pcm_format")
  set_codec_param("dataEndianness","audio_data_endianness")
  set_codec_param("desiredChannelMode","audio_type")
  set_codec_param("downSampleSbrFlag","audio_downsample_sbr_flag")
  set_codec_param("sixChannelMode","audio_six_channel_mode")
  set_codec_param("enablePS","audio_enable_ps")
  set_codec_param("ulSamplingRateIdx","audio_sampling_rate")
  set_codec_param("nProfile","audio_profile")
  set_codec_param("bRawFormat","audio_raw_format")
  set_codec_param("pseudoSurroundEnableFlag","audio_pseudo_surround_enable_flag")
  set_codec_param("enableARIBDownmix","audio_enable_arib_downmix")
  set_codec_param("inbufsize","audio_inbufsize")
  set_codec_param("outbufsize","audio_outbufsize")
end

def run
	files_array = Array.new
	begin
		file_res_form = ResultForm.new("AAC Decode Files Result Form")
    max_num_files = @test_params.params_control.max_num_files[0].to_i 
    file_counter = 0 
		@test_params.params_chan.audio_source.each do |audio_file|
      break if (file_counter == max_num_files and max_num_files > 0)
			puts "Decoding #{audio_file} ...."
      ref_file = Find.file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{audio_file}/}
			raise "File #{audio_file} not found" if ref_file == "" || !ref_file
			File.makedirs(SiteInfo::LOCAL_FILES_FOLDER) if !File.exist?(SiteInfo::LOCAL_FILES_FOLDER)
			local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
			FileUtils.cp(ref_file, local_ref_file)
      file_res_form.add_link(audio_file) do
				system("explorer #{local_ref_file.gsub("/","\\")}")
			end
			file_format = /\w+_(\w+IS)\w*/i.match(audio_file).captures[0]
			@equipment["dut1"].aacext_decoding({"Source" => local_ref_file, "Target" => local_ref_file.gsub(".aac","_test.pcm")})
			@equipment["dut1"].wait_for_threads
			file_res_form.add_link(audio_file.gsub(".aac","_test.pcm")) do
				system("explorer #{local_ref_file.gsub(".aac","_test.pcm").gsub("/","\\")}")
			end
			files_array = files_array|[local_ref_file.gsub(".aac","_test.pcm")]
      file_counter += 1
		end
		#@equipment["dut1"].wait_for_threads
		file_res_form.show_result_form
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
		
	if file_res_form.test_result == FrameworkConstants::Result[:fail]
		@results_html_file.add_paragraph("Decoded File links:")
		files_array.each do |decoded_file| 
			@results_html_file.add_paragraph("")
			@results_html_file.add_paragraph(decoded_file,nil,nil,"//"+decoded_file)
		end
	end
	
	#======================== Set Results ======================================================================
	set_result(file_res_form.test_result, file_res_form.comment_text)
end

def clean
	
end

def set_codec_param(param_name, param_value)
  if param_value.kind_of?(String)
    @equipment['dut1'].set_param({"Class" => "aacextdec", "Param" => param_name, "Value" => @test_params.params_chan.instance_variable_get('@'+param_value)[0]}) if @test_params.params_chan.instance_variable_defined?('@'+param_value)
  else
    @equipment['dut1'].set_param({"Class" => "aacextdec", "Param" => param_name, "Value" => param_value.to_s})
  end
end