require File.dirname(__FILE__)+'/../default_dvsdk_test_module'

include DvsdkTestScript

def setup
    @equipment['dut1'].set_api('demo')
   # boot_dut() # method implemented in DvsdkTestScript module
   @equipment['dut1'].connect({'type'=>'telnet'})
end

def run
	video_tester_result = 0
	test_comment = ''
	#======================== Equipment Connections ====================================================
	@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.video_input[0] => 0}, @equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) 
    @connection_handler.make_audio_connection({@equipment[@test_params.params_chan.media_source[0]] => {'mini35mm' => 0}}, {@equipment["dut1"] => {'mini35mm' => 0}, @equipment["tv0"] => {'mini35mm' => 0}})   
    @connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment['tv1'] => {@test_params.params_chan.display_out[0] => 0}}) 
    @connection_handler.make_audio_connection({@equipment["dut1"] => {'mini35mm' => 0}},{@equipment['tv1'] => {'mini35mm' => 0}})
    
    #======================== Start Demo Test ====================================================
    begin
		file_res_form = ResultForm.new("Subjective DVSDK Demo #{@test_params.params_chan.command_name[0]} Test Result Form")
		if @test_params.params_chan.command_name[0].include?("encode") && @test_params.params_chan.command_name[0].include?("decode")
			start_video()
			enc_dec_params = get_encode_decode_params()
        	@equipment['dut1'].encode_decode(enc_dec_params)
        	@equipment['dut1'].wait_for_threads(enc_dec_params['time'].to_i + 120)
    	elsif @test_params.params_chan.command_name[0].include?("encode")
			start_video()
			enc_params = get_encode_params()
			test_files = [enc_params['audio_file'], enc_params['speech_file'], enc_params['video_file']]
			test_files.each {|media_file|
                File.delete(media_file.gsub("/","\\").gsub(/\.g711/,'.pcm')) if media_file && File.exists?(media_file.gsub("/","\\").gsub(/\.g711/,'.pcm'))
            }
        	@equipment['dut1'].encode(enc_params)
        	@equipment['dut1'].wait_for_threads(enc_params['time'].to_i + 120)
        	test_files.each {|media_file|
                next if (media_file == nil or enc_params['passthrough'] == 'yes')
                File.rename(media_file,media_file.sub(/\.g711$/,'.pcm') )
                file_res_form.add_link(File.basename(media_file).gsub(/\.g711/,'.pcm')){system("explorer #{media_file.gsub("/","\\").gsub(/\.g711/,'.pcm')}")} 
            }
    	else
            raise "Unkown Demo command #{@test_params.params_chan.command_name[0]}"
        end
        #10.times {puts "sleeping"; sleep 1}
		file_res_form.show_result_form		
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
	set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
end

private
def start_video()
	if @test_params.params_chan.media_source[0].include? "dvd"
		#sleep 60 if first_run
		#@equipment['dvd'].go_to_track(2)	
	end
	false
end

def get_width
    @test_params.params_chan.video_resolution[0].split('x')[0].to_i
end

def get_height
    @test_params.params_chan.video_resolution[0].split('x')[1].to_i
end

def get_encode_decode_params()
    h={
        'audio_bitrate'			=> @test_params.params_chan.audio_bitrate[0],
        'audio_file'			=> SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.audio_file[0],
        'audio_input'			=> @test_params.params_chan.audio_input[0],
        'audio_samplerate'		=> @test_params.params_chan.audio_samplerate[0],
        'disable_deinterlace'	=> @test_params.params_chan.disable_deinterlace[0],
        'display_out'			=> @test_params.params_chan.display_out[0],
        'enable_keyboard'		=> @test_params.params_chan.enable_keyboard[0],
        'enable_osd'			=> @test_params.params_chan.enable_osd[0],
        'enable_remote'			=> @test_params.params_chan.enable_remote[0],
        'passthrough'			=> @test_params.params_chan.passthrough[0],
        'speech_file' 			=> SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.speech_file[0],
        'time'					=> @test_params.params_chan.time[0],
        'video_bitrate' 		=> @test_params.params_chan.video_bitrate[0],
        'video_file' 			=> SiteInfo::LOCAL_FILES_FOLDER+@test_params.params_chan.video_resolution[0]+'_'+@test_params.params_chan.video_bitrate[0]+'_'+(@test_params.params_chan.time[0].to_i*30).to_s+'frames.'+@test_params.params_chan.video_type[0].gsub(/h264$/i,'264'),
        'video_input'			=> @test_params.params_chan.video_input[0],
        'video_resolution' 		=> @test_params.params_chan.video_resolution[0],
        'video_signal_format'	=> @test_params.params_chan.video_signal_format[0],
    }
    h.merge!({'audio_file' => nil}) if @test_params.params_chan.audio_file[0] == 'none'
    h.merge!({'speech_file' => nil}) if @test_params.params_chan.speech_file[0] == 'none'
    h.merge!({'video_file' => nil}) if @test_params.params_chan.video_type[0] == 'off'
    h
end

def get_encode_params()
    get_encode_decode_params
end

def get_frame_rate
    case @test_params.params_chan.video_signal_format[0]
    when '625','1080p25','1080p50': '25'
    else 30
    end
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end




