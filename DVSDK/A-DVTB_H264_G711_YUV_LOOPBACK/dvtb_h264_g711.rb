#=============================================================================================================
# Test Script for DvtbH264Loopback.atp.rb test recipe
# History:
#   0.1: [CH, 7/6/7] First Draft
#   0.2: [AH, 9/20/07]
#=============================================================================================================

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SystemTest_refs/VISA/Video'      
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

class H264Params
    attr_reader :codec_name, :enc_codec_name, :enc_thread_name, :dec_codec_name, :dec_thread_name
    def initialize
        @codec_name 		= 'H264'
        @enc_codec_name 	= 'h264enc'
        @enc_thread_name 	= 'h264enc'
        @dec_codec_name 	= 'h264dec'
        @dec_thread_name 	= 'h264dec'
    end
end

class MPEG4Params
    attr_reader :codec_name, :enc_codec_name, :enc_thread_name, :dec_codec_name, :dec_thread_name
    def initialize
        @codec_name 		= 'MPEG4'
        @enc_codec_name 	= 'mpeg4enc'
        @enc_thread_name 	= 'mpeg4enc'
        @dec_codec_name 	= 'mpeg4dec'
        @dec_thread_name 	= 'mpeg4dec'
    end
end

def setup
  @equipment['dut1'].set_interface('dvtb')
  dst_folder = "\\\\#{@equipment['server1'].telnet_ip}\\#{@equipment['server1'].samba_root_path.sub(/(\\|\/)$/,'')}\\#{@tester.downcase}\\#{@test_params.target}\\#{@test_params.platform}"
  boot_params = {'tester' => @tester, 'platform' => @test_params.platform.to_s, 'image_path' => @test_params.image_path['kernel'], 'server' => @equipment['server1'], 'tftp_ip' => @equipment['server1'].telnet_ip,  'samba_path' => dst_folder, 'apc' => @equipment['apc'], 'target' => @test_params.target.to_s}
  boot_params['bootargs'] = @test_params.params_chan.bootargs[0] if @test_params.params_chan.instance_variable_defined?(:@bootargs)
  @new_keys = (@test_params.params_chan.instance_variable_defined?(:@bootargs))? (get_keys + @test_params.params_chan.bootargs[0]) : (get_keys) 
  @equipment['dut1'].boot(boot_params) if @old_keys != @new_keys && @equipment['dut1'].respond_to?(:boot)# call bootscript if required
    
    codec_class = @test_params.params_control.codec_class[0]+"Params"
    codec_object = Object.const_get(codec_class).new
    
    @equipment["dut1"].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i, 0)
  # Set engine params
  @equipment["dut1"].set_param({"Class" => "engine", "Param" => "name", "Value" => "encdec"})
  @equipment["dut1"].set_param({"Class" => "engine", "Param" => "trace","Value" => "0"})
  
  # Set encoder params
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "codec", "Value" => codec_object.enc_codec_name})
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxHeight", "Value" => @test_params.params_chan.video_height[0]})
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxWidth", "Value" => @test_params.params_chan.video_width[0]})
  @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxFrameRate", "Value" => '30000'})
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]}) 
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "reconChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})  
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "encodingPreset", "Value" => @test_params.params_chan.video_encoder_preset[0]}) 
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "rateControlPreset", "Value" => @test_params.params_chan.video_rate_control[0]})  
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputHeight", "Value" => @test_params.params_chan.video_height[0]})
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "inputWidth", "Value" => @test_params.params_chan.video_width[0]})
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "refFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "targetFrameRate", "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "targetBitRate", "Value" => @test_params.params_chan.video_bit_rate[0]}) 
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "maxBitRate", "Value" => (@test_params.params_chan.video_bit_rate[0].to_i*1.1).round.to_s})							   
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "intraFrameInterval", "Value" => @test_params.params_chan.video_gop[0]})  
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "generateHeader", "Value" => @test_params.params_chan.video_gen_header[0]})   
  @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "captureWidth", "Value" => @test_params.params_chan.video_width[0]})  
  @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "maxInterFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
  @equipment['dut1'].set_param({"Class" => "videnc", "Param" => "interFrameInterval", "Value" => @test_params.params_chan.video_inter_frame_interval[0]})
 # @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "forceIframe", "Value" => "#{@test_params.params_chan.video_force_iframe[0]}"})   
                              
  # Set decoder params
  @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "codec", "Value" => codec_object.dec_codec_name})
  @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxBitRate", "Value" => (@test_params.params_chan.video_bit_rate[0].to_i*1.1).round.to_s}) 
  @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "maxFrameRate", "Value" => '30000'})
  @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxHeight", "Value" => @test_params.params_chan.video_height[0]})
  @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "maxWidth", "Value" => @test_params.params_chan.video_width[0]})
  @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "forceChromaFormat", "Value" => @test_params.params_chan.video_input_chroma_format[0]})    
  @equipment['dut1'].set_param({"Class" => "viddec", "Param" => "displayWidth", "Value" => @test_params.params_chan.video_width[0]})
end


def run
  result_comment = " "
  result_type = FrameworkConstants::Result[:pass]
  local_ref_files = Array.new
  num_frames = test_done_result = nil
  test_comment = ''
  codec_class = @test_params.params_control.codec_class[0]+"Params"
  codec_object = Object.const_get(codec_class).new
      
  @test_params.params_chan.video_source.each do |vid_source|
      #======================== Prepare reference files ==========================================================
      ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{vid_source}/}
      raise "File #{@test_params.params_chan.video_source[0]} not found" if ref_file == "" || !ref_file
      local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
      local_ref_files << local_ref_file
      FileUtils.cp(ref_file, local_ref_file)
	  FileUtils.chmod(0755,local_ref_file)
      File.delete(local_ref_file.gsub(".yuv","_out.yuv")) if File.exists?(local_ref_file.gsub(".yuv","_out.yuv"))
      #File.delete(local_ref_file.gsub(".yuv","_out.avi")) if File.exists?(local_ref_file.gsub(".yuv","_out.avi"))
      num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
      @equipment["dut1"].set_param({"Class" => "videnc", "Param" => "numframes", "Value" => num_frames.to_s}) 
      @equipment["dut1"].set_param({"Class" => "viddec", "Param" => "numframes", "Value" => num_frames.to_s}) 
=begin
      ref_file_pixel_format, raw_data_format = get_pixel_and_data_format
      ref_bmp_file = YuvToBmpConverter.new
      ref_bmp_file.convert( {       'inFile'            => local_ref_file,
                                  'inSamplingFormat'  => "yuv"+"#{@test_params.params_chan.video_input_chroma_format[0]}".gsub(/[pi]/, ""),
                                  'inComponentOrder'  => raw_data_format,
                                  'inFieldFormat'     => 'progressive',
                                  'inPixelFormat'     => "#{ref_file_pixel_format}",
                                  'inHeight'          => "#{@test_params.params_chan.video_height[0]}",
                                  'inWidth'           => "#{@test_params.params_chan.video_width[0]}",
                                  'outFile'           => local_ref_file.gsub('.yuv','.bmp'),                              
                                  'outSamplingFormat' => 'BMP',
                                  'outFieldFormat'    => 'progressive',
                                  'outPixelFormat'    => "#{ref_file_pixel_format}" } )
      ref_avi_file = BmpToAviConverter.new
      ref_avi_file.convert( {       'start'             => local_ref_file.gsub('.yuv','_0000.bmp'), 
                                  'end'               => local_ref_file.gsub('.yuv','_'+'0'*(4-(num_frames-1).to_s.length)+(num_frames-1).to_s+'.bmp'), 
                                  'frameRate'         => "#{@test_params.params_chan.video_frame_rate[0]}",
                                  'output'            => local_ref_file.gsub('.yuv','.avi')} )
  
      #======================== Process reference file in DUT ====================================================
=end  
      # Start encoding-decoding function
      @equipment["dut1"].video_encoding_decoding({"Target" => local_ref_file.sub(/\.yuv/, "_out.yuv"), "Source" => local_ref_file, "threadIdEnc" => codec_object.enc_thread_name, "threadIdDec" => codec_object.dec_thread_name})
      @equipment["dut1"].wait_for_threads
  end
  local_ref_files.each do |local_ref_file|                      
      #======================== Prepare process file =============================================================
      metric_window = get_metric_window
      #ref_file, local_ref_file = get_ref_file(NETWORK_REFERENCE_FILES_FOLDER+'Video/Encoder', vid_source)
      test_file = local_ref_file.sub(/\.yuv/, "_out.yuv")
=begin      
      ref_file_pixel_format, raw_data_format = get_pixel_and_data_format
      num_frames = /_(\d+)frames/.match(local_ref_file).captures[0].to_i
      ref_bmp_file = YuvToBmpConverter.new
      ref_bmp_file.convert( {       'inFile'            => local_ref_file.sub(/\.yuv/, "_out.yuv"),
                                  'inSamplingFormat'  => "yuv"+"#{@test_params.params_chan.video_input_chroma_format[0]}".gsub(/[pi]/, ""),
                                  'inComponentOrder'  => raw_data_format,
                                  'inFieldFormat'     => 'progressive',
                                  'inPixelFormat'     => "#{ref_file_pixel_format}", 
                                  'inHeight'          => "#{@test_params.params_chan.video_height[0]}",
                                  'inWidth'           => "#{@test_params.params_chan.video_width[0]}",
                                  'outFile'           => local_ref_file.sub(/\.yuv/, "_out.bmp"),
                                  'outSamplingFormat' => 'BMP',
                                  'outFieldFormat'    => 'interlaced',
                                  'outPixelFormat'    => "#{ref_file_pixel_format}" } )
      ref_avi_file = BmpToAviConverter.new
      ref_avi_file.convert( {       'start'             => local_ref_file.sub(/\.yuv/, '_out_0000.bmp'), 
                                  'end'               => local_ref_file.sub(/\.yuv/,'_out_'+'0'*(4-(num_frames-1).to_s.length)+(num_frames-1).to_s+'.bmp'), 
                                  'frameRate'         => "#{@test_params.params_chan.video_frame_rate[0]}",
                                  'output'            => local_ref_file.sub(/\.yuv/, '_out.avi')} )
=end 
      #======================== Call Objective quality equipment ====================================================================
      video_tester_result = @equipment['video_tester'].file_to_file_test({'ref_file' => local_ref_file, 
                                                                         'test_file' => test_file,
                                                                         'data_format' => @test_params.params_chan.video_input_chroma_format[0],
                                                                         'format' => get_video_tester_format,
                                                                         'video_height' => @test_params.params_chan.video_height[0],
                                                                         'video_width' =>@test_params.params_chan.video_width[0],
                                                                         'num_frames' => num_frames,
                                                                         'frame_rate' => @test_params.params_chan.video_frame_rate[0],
                                                                         'metric_window' => metric_window})
      if  !video_tester_result
        @results_html_file.add_paragraph("")
        test_done_result = FrameworkConstants::Result[:fail]
        test_comment += "Objective Video Quality could not be calculated. Video_Tester returned #{video_tester_result} for #{local_ref_file}\n"   
      else  	
    		video_done_result, video_done_comment = get_results(test_file)
    		test_comment += video_done_comment+"\n" if video_done_comment.strip.to_s == ''
    		test_done_result = video_done_result if test_done_result !=	 FrameworkConstants::Result[:fail]
      end
   end
   set_result(test_done_result, test_comment)
end

def clean

end



private 

def get_pixel_and_data_format
    if @test_params.params_chan.video_input_chroma_format[0].match(/p/) == nil 
        ref_file_pixel_format = 'packed'
	    raw_data_format = 'uyv'
    else
        ref_file_pixel_format = 'planar'
	    raw_data_format = 'yuv'
    end
    [ref_file_pixel_format,raw_data_format]
end

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

def get_video_tester_format
    [@test_params.params_chan.video_width[0].to_i,@test_params.params_chan.video_height[0].to_i, @test_params.params_chan.video_frame_rate[0].to_i]
end


def get_metric_window
    ti_logo_height = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[1].to_i
    ti_logo_width = @test_params.params_control.ti_logo_resolution[0].downcase.split('x')[0].to_i
	
    #video_signal_height = @equipment['video_tester'].get_video_signal_height({'format' => @test_params.params_chan.video_signal_format[0]})
    #video_signal_width = @equipment['video_tester'].get_video_signal_width({'format' => @test_params.params_chan.video_signal_format[0]})
    
    metric_window_width = @test_params.params_chan.video_width[0].to_i
    metric_window_height = @test_params.params_chan.video_height[0].to_i
    
    x_offset = [0,((metric_window_width - metric_window_width)/2).ceil].max
    y_offset = [0,((metric_window_height - metric_window_height)/2).ceil].max
    
    if rand < 0.5
    	metric_window_width -= ti_logo_width
    else
        metric_window_height -= ti_logo_height
        y_offset+=ti_logo_height
    end
    [x_offset, y_offset, metric_window_width, metric_window_height] 
end

def get_ref_file(start_directory, file_name)
	ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
	raise "File #{file_name} not found" if ref_file == "" || !ref_file
	local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
	FileUtils.cp(ref_file, local_ref_file)
	[ref_file,local_ref_file]
end

def get_results(video_file)
    codec_class = @test_params.params_control.codec_class[0]+"Params"
    codec_object = Object.const_get(codec_class).new
	test_done_result = FrameworkConstants::Result[:pass]
	@results_html_file.add_paragraph("")
    test_comment = " "	
	res_table = @results_html_file.add_table([["Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	
	pass_fail_criteria = @test_params.params_chan.video_quality_metric[0].strip.downcase.split(/\/*=/)
	
	@results_html_file.add_row_to_table(res_table, [["#{codec_object.codec_name} Scores #{File.basename(video_file)}",{:bgcolor => "add8e6", :colspan => "2"},{:color => "blue"}]])
	if pass_fail_criteria[0] == 'jnd'
		if @equipment['video_tester'].get_jnd_scores({'component' => 'y'}).max > pass_fail_criteria[1].to_f || @equipment['video_tester'].get_jnd_scores({'component' => 'chroma'}).max > pass_fail_criteria[1].to_f
			test_done_result = FrameworkConstants::Result[:fail]
		end
		@results_html_file.add_row_to_table(res_table,["AVG_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y'})])
		@results_html_file.add_row_to_table(res_table,["MIN_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_JND_Y",@equipment["video_tester"].get_jnd_score({'component' => 'y', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma'})])
		@results_html_file.add_row_to_table(res_table,["MIN_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_JND_Chroma",@equipment["video_tester"].get_jnd_score({'component' => 'chroma', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Y",@equipment["video_tester"].get_psnr_score({'component' => 'y', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cb",@equipment["video_tester"].get_psnr_score({'component' => 'cb', 'type' => 'max'})])
		@results_html_file.add_row_to_table(res_table,["AVG_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr'})])
		@results_html_file.add_row_to_table(res_table,["MIN_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'min'})])
		@results_html_file.add_row_to_table(res_table,["MAX_PSNR_Cr",@equipment["video_tester"].get_psnr_score({'component' => 'cr', 'type' => 'max'})])
	end
	
	if test_done_result == FrameworkConstants::Result[:fail]
		test_comment = "Test failed for file "+File.basename(video_file)+"."
		file_ext = File.extname(video_file)
		failed_file_name = video_file.sub(/\..*$/,'_failed_'+Time.now.to_s.gsub(/[\s\-:]+/,'_')+file_ext)
		File.copy(video_file, failed_file_name)
		@results_html_file.add_paragraph(File.basename(failed_file_name),nil,nil,"//"+failed_file_name.gsub("\\","/"))
	end
	[test_done_result, test_comment]
end

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end