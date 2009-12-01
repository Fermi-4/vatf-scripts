#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() #method implemented in DvsdkTestScript module
  @equipment["dut1"].set_param({"Class" => "engine", "Param" => "name", "Value" => "encdec"})
  @equipment["dut1"].set_param({"Class" => "auddec", "Param" => "codec", "Value" => "aacdec"})
  @equipment["dut1"].set_param({"Class" => "auddec", "Param" => "desiredChannelMode", "Value" => @test_params.params_chan.audio_type[0]})
	#@equipment["dut1"].set_param({"Class" => "auddec", "Param" => "maxSampleRate", "Value" => "96000"})
	#@equipment["dut1"].set_param({"Class" => "auddec", "Param" => "maxBitrate", "Value" => "768000"})
	#@equipment["dut1"].set_param({"Class" => "auddec", "Param" => "maxNoOfCh", "Value" => "1"})
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
			#@equipment["dut1"].set_param({"Class" => "auddec", "Param" => "outputFormat", "Value" => get_file_format(file_format)})
			@equipment["dut1"].audio_decoding({"Source" => local_ref_file, "Target" => local_ref_file.gsub(".aac","_test.pcm")})
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

def get_file_format(file_format)
	if file_format.strip.downcase.eql?("yis")
		return 1.to_s
	elsif file_format.strip.downcase.eql?("nis")
		return 0.to_s
	else
		raise "Unsopported file format #{file_format}"
	end
end