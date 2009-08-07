#=============================================================================================================
# Test Script for DvtbPreview.atp.rb test recipe
# History:
#   0.1: [CH, 7/25/7] First Draft
#   0.2: [AH, 9/26/07]
#=============================================================================================================

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/'      # TODO: Make sure this is the right place
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
  #Setting the interface used for this test and checking if a reboot is needed
  @equipment['dut1'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  @equipment['dut1'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut1'].respond_to?(:boot)# call bootscript if required
  
  # Set DUT Max number of sockets
  @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
  srand = @test_params.params_control.random_seed[0].to_i
  
  if @test_params.params_chan.video_driver[0].include?("vpfe")
  # Setup VPFE
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "standard",
                                 "Value" => @test_params.params_chan.video_signal_format[0]})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "width",
                                 "Value" => @test_params.params_chan.video_width[0]})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "height",
                                 "Value" => @test_params.params_chan.video_height[0]})                             
								 
	@equipment['dut'].set_param({"Class" => "vpfe",
                                 "Param" => "numframes",
                                 "Value" => get_num_frames})
								 
	if @test_params.params_chan.video_driver[0].include?("resizer")
		@equipment['dut'].set_param({"Class" => "resizer", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
		@equipment['dut'].set_param({"Class" => "resizer", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => get_video_signal_height(@test_params.params_chan.video_signal_format[0]).to_s})
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => get_video_signal_width(@test_params.params_chan.video_signal_format[0]).to_s})
	else
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "height", "Value" => @test_params.params_chan.video_height[0]})
		@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "width", "Value" => @test_params.params_chan.video_width[0]})
	end	
	@connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
	@test_params.params_control.video_num_channels[0].to_i.times do |input_idx|
		@connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["dut"] => input_idx}, @test_params.params_chan.video_iface_type[0])
	end
  end
  
  if @test_params.params_chan.video_driver[0].include?("vpbe")
	# Setup VPBE                              
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "standard",
                                 "Value" => @test_params.params_chan.video_signal_format[0]})
								 
	#@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "vencmode",
    #                            "Value" => map_standard})
                                 
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "width",
                                 "Value" => @test_params.params_chan.video_width[0]})
                                 
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "height",
                                 "Value" => @test_params.params_chan.video_height[0]})                                       
    
    #@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "xoffset",
    #                             "Value" => get_xoffset})   
                                 
    #@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "yoffset",
    #                             "Value" => get_yoffset})  
    
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "chanNumber",
                                 "Value" => "0"})   
	
	@connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.video_iface_type[0])
  end
              
  
  @equipment["dut"].set_param({"Class" => "audio",
                               "Param" => "samplerate",
                               "Value" => @test_params.params_chan.audio_sampling_rate[0]})
							   
  if @test_params.params_chan.audio_driver[0].include?("apfe")
    # setup apfe
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "mode",
                                 "Value" => "1"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "gain",
                                 "Value" => "100"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "seconds",
                                 "Value" => @test_params.params_control.media_time[0]})
								 
	@connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0]] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])
    @test_params.params_control.audio_num_channels[0].to_i.times do |input_idx| 
      @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0]] => 0},{@equipment["dut"] => input_idx}, @test_params.params_chan.audio_iface_type[0])
    end
  end
  
  if @test_params.params_chan.audio_driver[0].include?("apbe")
  #setup apbe
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "mode",
                                 "Value" => "0"})
	@equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "gain",
                                 "Value" => "100"})
	@connection_handler.make_audio_connection({@equipment["dut"] => 0},{@equipment["tv1"] => 0}, @test_params.params_chan.audio_iface_type[0])
  end
end

def run
  run_again = false
  begin
	media_files = {'video_files' => Array.new, 'audio_files' => Array.new}
	if @test_params.params_chan.video_source[0] == "dvd"
#		sleep 60 if !run_again
		@equipment["dvd"].go_to_track(3)  
	end
	if @test_params.params_chan.video_driver[0].include?("vpfe")
		0.upto(rand(@test_params.params_control.video_num_channels[0].to_i-1)) do |chan_number|
			media_files['video_files'] <<  LOCAL_FILES_FOLDER+@test_params.params_chan.video_driver[0]+"_"+@test_params.params_chan.video_width[0]+"x"+@test_params.params_chan.video_height[0]+"_"+@test_params.params_chan.video_output_chroma_format[0]+"_"+@test_params.params_chan.video_source[0]+"_"+@test_params.params_chan.video_signal_format[0]+"_channel"+chan_number.to_s+"_video_drivers_test.yuv"
			media_files['audio_files'] << process_audio(chan_number) if @test_params.params_control.audio_num_channels[0].to_i > 0
			@equipment['dut'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => chan_number.to_s})
			if @test_params.params_chan.video_driver[0].include?("resizer")
			    @equipment['dut'].video_capture({"function" => "vpfer", "Target" => media_files['video_files'].last})
			else
				@equipment['dut'].video_capture({"Target" => media_files['video_files'].last})
			end
		end
	elsif @test_params.params_chan.video_driver[0].include?("vpbe")
		@test_params.params_chan.video_source.each do |vid_source|
			#======================== Prepare reference files ==========================================================
			media_files['audio_files'] << process_audio(0) if @test_params.params_control.audio_num_channels[0].to_i > 0
			media_files['video_files'] << get_ref_file(vid_source)
			@equipment['dut'].video_play({"Source" => media_files['video_files'].last})
		end
	end     
	@equipment["dut"].wait_for_threads
	form = ResultForm.new("Subjective Driver Verification")
    media_files['video_files'].each do |video_file|
        form.add_link(File.basename(video_file)) do
	        system("explorer #{video_file.gsub("/","\\")}")
        end
    end
    media_files['audio_files'].each do |audio_file|
	    form.add_link(File.basename(audio_file)) do
		    system("explorer #{audio_file.gsub("/","\\")}")
	    end
    end
	form.show_result_form
	run_again = true if form.test_result == FrameworkConstants::Result[:nry]
  end until form.test_result != FrameworkConstants::Result[:nry]
  set_result(form.test_result, form.comment_text)
end

def clean

end



private 

def get_num_frames
	(@test_params.params_chan.video_frame_rate[0].to_i*@test_params.params_control.media_time[0].to_i).to_s
end

def process_audio(channel_number)
	if channel_number < @test_params.params_control.audio_num_channels[0].to_i  
		if @test_params.params_chan.audio_driver[0].include?("apfe")
			audio_file =  LOCAL_FILES_FOLDER+"apfe_"+@test_params.params_chan.audio_sampling_rate[0]+"Hz_"+@test_params.params_chan.audio_source[0]+"_"+@test_params.params_chan.video_signal_format[0]+"_channel"+channel_number.to_s+"_audio_driver_test.pcm"
			@equipment['dut'].audio_capture({"Target" => audio_file})
		elsif @test_params.params_chan.audio_driver[0].include?("apbe")
			ref_file_base_name = @test_params.params_chan.audio_source[rand(@test_params.params_chan.audio_source.length)]
			audio_file = get_ref_file(ref_file_base_name)
			sampling_rate = /\w+_(\d+)Khz_\w+/i.match(audio_file).captures[0]
			@equipment['dut'].set_param({"Class" => "audio" ,"Param" => "framesize", "Value" => get_frame_size(sampling_rate).to_s})
			@equipment['dut'].audio_play({"Source" => audio_file})
		end
	end
	audio_file
end

def get_ref_file(file_name)
	File.makedir(LOCAL_FILES_FOLDER) if !File.exists?(LOCAL_FILES_FOLDER)
	ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{file_name}/}
	raise "File #{file_name} not found" if ref_file == "" || !ref_file
	local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	FileUtils.cp(ref_file, local_ref_file)
	local_ref_file
end

def get_frame_size(sampling_rate)
	case sampling_rate.to_i
		when 8
			4096
		when 44.1
			32000
		else
			32000
	end
end

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

def get_xoffset
	((get_video_signal_width(@test_params.params_chan.video_signal_format[0])-@test_params.params_chan.video_width[0].to_i)/2).floor.to_s
end

def get_yoffset
	((get_video_signal_height(@test_params.params_chan.video_signal_format[0])-@test_params.params_chan.video_height[0].to_i)/2).floor.to_s
end

def get_video_signal_width(format)
	case format
		when /525/
			720
		when /625/
			720
		when /720.+/
			1280
		when /1080.+/
			1920
		else
			params['format'].scan(/\d+/)[0].to_i*16/9
	end
end
    
def get_video_signal_height(format)
	case format
		when /525/
			480
		when /625/
			576
		when /720.+/
			720
		when /1080.+/
			1080
		else
			params['format'].scan(/\d+/)[0].to_i
	end
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end

