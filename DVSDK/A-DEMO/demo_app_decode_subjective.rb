require File.dirname(__FILE__)+'/../default_dvsdk_test_module'

include DvsdkTestScript

def setup
    @equipment['dut1'].set_api('demo')
    #boot_dut() # method implemented in DvsdkTestScript module
end

def run
	video_tester_result = 0
	test_comment = ''
	#======================== Equipment Connections ====================================================
	@connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment['tv1'] => {@test_params.params_chan.display_out[0] => 0}})
  @connection_handler.make_audio_connection({@equipment["dut1"] => {'mini35mm' => 0},{@equipment['tv1'] => {'mini35mm' => 0}})
  #======================== Start Decode Demo ====================================================
  if !@test_params.params_chan.instance_variable_defined?('@video_source') or @test_params.params_chan.video_source[0] == nil
    set_result(FrameworkConstants::Result[:np], "Video File not available in repository")
    return
  end 
  begin
	  file_res_form = ResultForm.new("Subjective DVSDK Decode Demo Test Result Form")
	  #======================== Prepare reference files ==========================================================	
	  num_aud_files = @test_params.params_chan.audio_source[0] == 'none' ? 0 : @test_params.params_chan.audio_source.length
	  num_sph_files = @test_params.params_chan.speech_source[0] == 'none' ? 0 : @test_params.params_chan.speech_source.length
	  num_vid_files = @test_params.params_chan.video_source[0] == 'none' ? 0 : @test_params.params_chan.video_source.length
	  max_num_files = num_vid_files
	  max_num_files = [num_sph_files, num_aud_files].max if num_vid_files <= 0
	  max_num_files.times{ |index|
		  dec_params = num_aud_files > 0 ? prepare_aud_files(index, file_res_form) : {'audio_file' => nil}
		  dec_params.merge!(num_sph_files > 0 ? prepare_sph_files(index, file_res_form) : {'speech_file' => nil})
		  dec_params.merge!(num_vid_files > 0 ? prepare_vid_files(index, file_res_form) : {'video_file' => nil})
		  dec_params.merge!(get_decode_params())
	    @equipment['dut1'].decode(dec_params)
	    @equipment['dut1'].wait_for_threads(dec_params['time'].to_i + 120)
	  }
		file_res_form.show_result_form		
	end until file_res_form.test_result != FrameworkConstants::Result[:nry]
	set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
end

private
def prepare_aud_files(index, res_form = nil)
  file_index = [index, @test_params.params_chan.audio_source.length-1].min
  audio_file = @test_params.params_chan.audio_source[file_index]
  puts "Decoding Audio file: #{audio_file} ....."
  local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Audio/Decoder', audio_file)
  res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")} if res_form
  {'audio_file'	 => local_ref_file}
end

def prepare_sph_files(index, res_form = nil)
  file_index = [index, @test_params.params_chan.speech_source.length-1].min
  speech_file = @test_params.params_chan.speech_source[file_index]
  puts "Decoding Speech file: #{speech_file} ....."
  local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Speech/Decoder', speech_file)
  res_form.add_link(File.basename(local_ref_file).gsub(/\.g711/,'.pcm')){system("explorer #{local_ref_file.gsub("/","\\").gsub(/\.g711/,'.pcm')}")} if res_form
  File.rename(local_ref_file, local_ref_file.gsub(/\.[u|a]$/,'.g711'))
  {'speech_file' => local_ref_file.gsub(/\.[u|a]$/,'.g711')}
end

def prepare_vid_files(index, res_form = nil)
  file_index = [index, @test_params.params_chan.video_source.length-1].min
  video_file = @test_params.params_chan.video_source[file_index]
  puts "Decoding Video file: #{video_file} ....."
  local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER+'Video/Decoder', video_file)
  res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}  if res_form
  {'video_file'	 => local_ref_file}
end

# def get_ref_file(start_directory, file_name)
	# ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
	# raise "File #{file_name} not found" if ref_file == "" || !ref_file
	# local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	# FileUtils.cp(ref_file, local_ref_file)
	# local_ref_file
#end

def get_ref_file(start_directory, file_name)
  if file_name.strip.downcase == "from_encoder"
    start_directory = SiteInfo::LOCAL_FILES_FOLDER
    file_name = /^#{@test_params.params_chan.video_resolution[0]}_#{@test_params.params_chan.video_bitrate[0]}_\d+frames\.#{@test_params.params_chan.video_type[0].gsub(/h264/,"264")}$/i
  end 
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}" 
  FileUtils.cp(ref_file, local_ref_file) if file_name.kind_of?(String)
  local_ref_file
end


def get_decode_params()
    h={
        'display_out'				=> @test_params.params_chan.display_out[0],
        'enable_keyboard'		=> @test_params.params_chan.enable_keyboard[0],
        'enable_osd'				=> @test_params.params_chan.enable_osd[0],
        'enable_remote'			=> @test_params.params_chan.enable_remote[0],
        'enable_frameskip'	=> @test_params.params_chan.enable_frameskip[0],
        'time'							=> @test_params.params_chan.time[0],
        'video_signal_format'	=> @test_params.params_chan.video_signal_format[0],
    }
    h
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end







