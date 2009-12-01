



include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  boot_dut() # method implemented in DvsdkTestScript module
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.picture_num_channels[0].to_i,0)
    
	#Setting the encoders and/or decoders parameters
	
	#Setting the engine type
	@equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'encode'})
	
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "codec", "Value" => "jpegenc"})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "maxHeight", "Value" => @test_params.params_chan.picture_height[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "maxWidth", "Value" => @test_params.params_chan.picture_width[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "maxScans", "Value" => @test_params.params_chan.picture_num_scans[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "dataEndianness", "Value" => @test_params.params_chan.picture_data_endianness[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "forceChromaFormat", "Value" => @test_params.params_chan.picture_output_chroma_format[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.picture_input_chroma_format[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "inputHeight", "Value" => @test_params.params_chan.picture_input_height[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "inputWidth", "Value" => @test_params.params_chan.picture_input_width[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "captureWidth", "Value" => @test_params.params_chan.picture_signal_format[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "captureHeight", "Value" => @test_params.params_chan.picture_height[0]}) #Commented out because dvtb doe not support this parameter
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "generateHeader", "Value" => '0'})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "qValue", "Value" => @test_params.params_chan.picture_quality[0]})
	@equipment['dut1'].set_param({"Class" => "jpegenc", "Param" => "numAU", "Value" => @test_params.params_chan.picture_num_access_units[0]})
	
	#Setting image capture input drivers
	@equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "numframes", "Value" => '300'})
	@equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.picture_width[0]})
	@equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.picture_height[0]})
	@equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "standard", "Value" => @test_params.params_chan.picture_signal_format[0]})
  @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "input", "Value" => @test_params.params_chan.picture_iface_type[0]})
  @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "format", "Value" => @test_params.params_chan.picture_input_chroma_format[0]})
end


def run
	first_run = true
	if @test_params.params_chan.picture_source[0].eql?("dvd") || @test_params.params_chan.picture_source[0].eql?("camera")
		channel_number = get_chan_number(@test_params.params_control.picture_num_channels[0].to_i)
		@connection_handler.make_video_connection({@equipment[@test_params.params_chan.picture_source[0]] => 0},{@equipment["dut1"] => channel_number, @equipment['tv0'] => 0}, @test_params.params_chan.picture_iface_type[0])
	end
	#======================== Processing Media ====================================================
	begin
		file_res_form = ResultForm.new("JPEG Encoder Test Result Form")
		if @test_params.params_chan.picture_source[0].eql?("dvd") || @test_params.params_chan.picture_source[0].eql?("camera")
			first_run = start_picture(first_run)
			0.upto(channel_number) do |ch_num|
				test_file = SiteInfo::LOCAL_FILES_FOLDER+"picture_"+@test_params.params_chan.picture_source[0]+"_at_"+@test_params.params_chan.picture_quality[0]+"qual_"+@test_params.params_chan.picture_input_width[0]+"x"+@test_params.params_chan.picture_input_height[0]+"_"+@test_params.params_chan.picture_output_chroma_format[0]+"_"+ch_num.to_s+"_test.jpg"
				file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
				@equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => ch_num.to_s})
				@equipment['dut1'].image_encoding({"function" => "jpegenc","Target" => test_file, "threadId" => 'jpegenc'})
			end	
			@equipment['dut1'].wait_for_threads
		else
			@test_params.params_chan.picture_source.each do |source_file|
				puts "Encoding #{source_file} ........."
				test_file = SiteInfo::LOCAL_FILES_FOLDER+source_file.gsub(".yuv","_at_"+@test_params.params_chan.picture_quality[0]+"qual_"+@test_params.params_chan.picture_input_width[0]+"x"+@test_params.params_chan.picture_input_height[0]+"_"+@test_params.params_chan.picture_output_chroma_format[0]+"_test.jpg")
				File.delete(test_file) if File.exists?(test_file)
				ref_file,local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER,source_file)
				file_res_form.add_link('ref_'+File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
				@equipment['dut1'].image_encoding({"function" => "jpegenc", "Source" => local_ref_file, "Target" => test_file, "threadId" => 'jpegenc'})
				file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
				@equipment['dut1'].wait_for_threads
			end
		end
		file_res_form.show_result_form		
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
	if file_res_form.test_result == FrameworkConstants::Result[:fail]
		@equipment['dut1'].get_param({"Class" => "vpfe", "Param" => ""})
		@equipment['dut1'].get_param({"Class" => "jpegenc", "Param" => ""})
	end
	set_result(file_res_form.test_result,file_res_form.comment_text)

end

def clean

end



private 
def map_dut_chroma_format(format)
  case(format.strip.downcase)
      when 'default'
		0
	  when '420p'
		1
	  when '422p'
		2
	  when '422i'
	    4
	  when '444p'
		5
	  when '411p'
		6
      when 'gray'
		7
	  else
	    raise "Unknown chroma format "+format.to_s
  end
end

def get_ref_file(start_directory, file_name)
	ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
	raise "File #{file_name} not found" if ref_file == "" || !ref_file
	local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	FileUtils.cp(ref_file, local_ref_file)
	[ref_file,local_ref_file]
end

def start_picture(first_run)
	if @test_params.params_chan.picture_source[0] == "dvd"
		#sleep 60 if first_run                                                        #Commented out to speed test execution, user must be aware that the dvd must be playing a movie when the test is started.
		#@equipment['dvd'].go_to_track(4)   	# TODO: Remove comment. Commenting out due to pal dvd limitation
		#@equipment['dvd'].pause
	end
	false
end

def get_chan_number(num_chan)
	rand(num_chan)
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end
