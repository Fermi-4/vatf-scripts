#=============================================================================================================
# Test Script for DvtbPreview.atp.rb test recipe
# History:
#   0.1: [CH, 7/25/7] First Draft
#=============================================================================================================

def setup
  # Set DUT Max number of sockets
  @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
    
  srand = "#{@test_params.params_control.random_seed[0]}"
  video_chan_number = get_chan_number(@test_params.params_control.video_num_channels[0])
  audio_chan_number = get_chan_number(@test_params.params_control.audio_num_channels[0])
  if @test_params.params_chan.respond_to?(:video_driver)
  # Setup VPFE
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "standard",
                                 "Value" => map_standard})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "width",
                                 "Value" => "#{@test_params.params_chan.video_width[0]}"})
                                 
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "height",
                                 "Value" => "#{@test_params.params_chan.video_height[0]}"})                           
    
    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "numframes",
                                 "Value" => (@test_params.params_control.media_time[0].to_i*30).to_s})   

    @equipment["dut"].set_param({"Class" => "vpfe",
                                 "Param" => "chanNumber",
                                 "Value" => video_chan_number.to_s})   
                                 
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
    #                             "Value" => get_xoffset})   
                                 
    #@equipment["dut"].set_param({"Class" => "vpbe",
    #                             "Param" => "yoffset",
    #                             "Value" => get_yoffset}) 
    @equipment["dut"].set_param({"Class" => "vpbe",
                                 "Param" => "chanNumber",
                                 "Value" => "0"})   
    @connection_handler.make_video_connection({@equipment[@test_params.params_chan.video_source[0]] => 0},{@equipment["tv1"] => 0, @equipment["dut"] => video_chan_number}, @test_params.params_chan.video_iface_type[0])
    @connection_handler.make_video_connection({@equipment["dut"] => 0},{@equipment["tv0"] => 0}, @test_params.params_chan.video_iface_type[0])
  end              
  if @test_params.params_chan.respond_to?(:audio_driver)
    # setup Audio
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "samplerate",
                                 "Value" => "44100"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "gain",
                                 "Value" => "100"})
    @equipment["dut"].set_param({"Class" => "audio",
                                 "Param" => "seconds",
                                 "Value" => @test_params.params_control.media_time[0]})
  
	@connection_handler.make_audio_connection({@equipment[@test_params.params_chan.audio_source[0].strip] => 0},{@equipment["tv1"] => 0, @equipment["dut"] => audio_chan_number}, @test_params.params_chan.audio_iface_type[0])
	@connection_handler.make_audio_connection({@equipment["dut"] => 0},{@equipment["tv0"] => 0}, @test_params.params_chan.audio_iface_type[0])
  end
end

def run

  run_again = false
  begin
      @equipment["dut"].video_loopback({}) if @test_params.params_chan.respond_to?(:video_driver)                  
      @equipment["dut"].audio_loopback({}) if @test_params.params_chan.respond_to?(:audio_driver)      
      @equipment["dvd"].go_to_track(3)
      @equipment["dut"].wait_for_threads
      form = ResultForm.new("Subjective Verification")
      form.show_result_form
      run_again = true if form.test_result == FrameworkConstants::Result[:nry]
  end until form.test_result != FrameworkConstants::Result[:nry]
  set_result(form.test_result, form.comment_text)
end

def clean
	
end



private 

def get_chan_number(max_number)
     rand(max_number.to_i)
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
