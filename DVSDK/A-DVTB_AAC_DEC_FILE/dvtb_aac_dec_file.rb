#dvtb_aac_dec_file.rb This test script is used to test AAC decode from file. This script will configure the dut decode the .aac files and store the decoded files for analysis.

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Audio'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/AAC_Audio_files/'

def setup
#	@equipment["dut"].set_param({"Class" => "auddec", "Param" => "codec", "Value" => "aacdec"})
	@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxSampleRate", "Value" => "96000"})
	@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxBitrate", "Value" => "768000"})
	@equipment["dut"].set_param({"Class" => "auddec", "Param" => "maxNoOfCh", "Value" => "1"})
end

def run
	files_array = Array.new
	begin
		file_res_form = ResultForm.new("AAC Decode Files Result Form")
		@test_params.params_chan.audio_source.each do |audio_file|
			puts "Decoding #{audio_file} ...."
			ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{audio_file}/}
			raise "File #{audio_file} not found" if ref_file == "" || !ref_file
			File.makedirs(LOCAL_FILES_FOLDER) if !File.exist?(LOCAL_FILES_FOLDER)
			local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
			FileUtils.cp(ref_file, local_ref_file)
			file_format = /\w+_(\w+IS)\w*/i.match(audio_file).captures[0]
			@equipment["dut"].set_param({"Class" => "auddec", "Param" => "outputFormat", "Value" => get_file_format(file_format)})
			@equipment["dut"].audio_decoding({"Source" => local_ref_file, "Target" => local_ref_file.gsub(".aac","_test.pcm")})
			@equipment["dut"].wait_for_threads
			file_res_form.add_link(audio_file) do
				system("explorer #{local_ref_file.gsub(".aac","_test.pcm").gsub("/","\\")}")
			end
			files_array = files_array|[local_ref_file.gsub(".aac","_test.pcm")]
		end
		#@equipment["dut"].wait_for_threads
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