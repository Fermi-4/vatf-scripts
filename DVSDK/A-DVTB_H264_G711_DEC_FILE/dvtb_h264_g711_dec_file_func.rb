NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Video'  
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
  # Set the maximum number of simultaneous socket that the dut can handle
  @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i+@test_params.params_control.audio_num_channels[0].to_i)
  # Set engine params
  @equipment["dut"].set_param({"Class" => "engine",
                               "Param" => "name",
                               "Value" => "encdec"})
                               
  @equipment["dut"].set_param({"Class" => "engine",
                               "Param" => "trace",
                               "Value" => "0"})
  # Set encoder params
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "codec",
                               "Value" => "h264dec"})
                               
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "maxHeight",
                                "Value" => @test_params.params_chan.video_height[0]})
  
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "maxWidth",
                               "Value" => @test_params.params_chan.video_width[0]})
  
 # @equipment["dut"].set_param({"Class" => "viddec",
 #                              "Param" => "forceChromaFormat",
 #                              "Value" => map_dut_chroma_format(@test_params.params_chan.video_input_chroma_format[0])})                                                              
end


def run
  local_ref_files = Array.new
  @test_params.params_chan.video_source.each do |vid_source|  
      #======================== Prepare reference files ==========================================================
      ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{vid_source}/}
      raise "File #{@test_params.params_chan.video_source[0]} not found" if ref_file == "" || !ref_file
      local_ref_files << LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
      File.delete(local_ref_files.last.gsub(/\.264/, "_test.yuv")) if File.exist?(local_ref_files.last.gsub(/\.264/, "_test.yuv"))
      FileUtils.cp(ref_file, local_ref_files.last)
      num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
	  puts "Decoding file #{vid_source} ......"
      #======================== Process reference file in DUT ====================================================
  
      # Start dut decoding function
      @equipment["dut"].video_decoding({"Source" => local_ref_files.last, "Target" => local_ref_files.last.gsub(/\.264/, "_test.yuv")})	  
  end
  @equipment["dut"].wait_for_threads
  result_comment = " "
  result_type = FrameworkConstants::Result[:pass]
    local_ref_files.each do |ref_file|
	  frame_rate = 30
	  chroma_format = '420'
	  chroma_format = /_(\d{3})[pi]_/.match(ref_file).captures[0] if /_(\d{3})[pi]_/.match(ref_file)
	  frames_rate = /_(\d+)fps/.match(ref_file).captures[0].to_i if /_(\d+)fps/.match(ref_file)
	  num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
	  #Decoding ref_file with q-master
	  @equipment["video_tester"].h264_decode_file(ref_file, ref_file.gsub(/\.264/, "_qmaster_dec_ref.yuv"))
	  ref_file_pixel_format, raw_data_format = get_pixel_and_data_format(ref_file)
	  #Converting dut decoded file to avi
	  yuv_to_bmp_params = {     'inFile'            => ref_file.gsub(/\.264/, "_test.yuv"),
                                'inSamplingFormat'  => "yuv"+chroma_format,
      						    'inComponentOrder'  => raw_data_format,
								'inFieldFormat'     => 'progressive',
								'inPixelFormat'     => ref_file_pixel_format,
								'inHeight'          => "#{@test_params.params_chan.video_height[0]}",
								'inWidth'           => "#{@test_params.params_chan.video_width[0]}",
								'outFile'           => ref_file.gsub(/\.264/, "_test.bmp"),  
								'outSamplingFormat' => 'BMP',
								'outFieldFormat'    => 'progressive',
								'outPixelFormat'    => "planar" }
	  ref_bmp_file = YuvToBmpConverter.new
	  ref_bmp_file.convert(yuv_to_bmp_params)
	  ref_avi_file = BmpToAviConverter.new
	  bmp_to_avi_params = {     'start'             => ref_file.gsub(/\.264/, "_test_0000.bmp"), 
								  'end'               => ref_file.gsub(/\.264/,'_test_'+'0'*(4-(num_frames-1).to_s.length)+(num_frames-1).to_s+'.bmp'), 
								  'frameRate'         => frame_rate.to_s,
								  'output'            => ref_file.gsub(/\.264/,'_test.avi')}
	  ref_avi_file.convert(bmp_to_avi_params)
	  
	  #Converting Q-Master decoded file to avi
	  ref_bmp_file.convert(yuv_to_bmp_params.merge({
													'inFile' => ref_file.gsub(/\.264/, "_qmaster_dec_ref.yuv"),
													'outFile' => ref_file.gsub(/\.264/, "_qmaster_dec_ref.bmp"),
													'inSamplingFormat'  => 'yuv422',
													'inComponentOrder' => 'yuv',
                              						'inPixelFormat'     => 'packed',}))
	  ref_avi_file.convert(bmp_to_avi_params.merge({
								'start' => ref_file.gsub(/\.264/,"_qmaster_dec_ref_0000.bmp"),
								'end' =>ref_file.gsub(/\.264/,'_qmaster_dec_ref_'+'0'*(4-(num_frames-1).to_s.length)+(num_frames-1).to_s+'.bmp'),
								'output' => ref_file.gsub(/\.264/,'_qmaster_dec_ref.avi')}))
      #======================== Call Q-master ====================================================================
      @equipment["video_tester"].file_to_file_test(ref_file.gsub(/\.264/,'_qmaster_dec_ref.avi'),
                                                   ref_file.gsub(/\.264/,'_test.avi'))
        @results_html_file.add_paragraph("")										   
        res_table = @results_html_file.add_table([["#{File.basename(ref_file).gsub(".264","_test.yuv")} Mean Scores",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
        @results_html_file.add_row_to_table(res_table,["MOS",@equipment["video_tester"].get_mos_score])
        @results_html_file.add_row_to_table(res_table,["Blockiness",@equipment["video_tester"].get_blocking_score])
        @results_html_file.add_row_to_table(res_table,["Blurring",@equipment["video_tester"].get_blurring_score])	
        @results_html_file.add_row_to_table(res_table,["Frames Lost",@equipment["video_tester"].get_frame_lost_count])
        @results_html_file.add_row_to_table(res_table,["Jerkiness",@equipment["video_tester"].get_jerkiness_score])
        @results_html_file.add_row_to_table(res_table,["Level",@equipment["video_tester"].get_level_score])
        @results_html_file.add_row_to_table(res_table,["PSNR",@equipment["video_tester"].get_psnr_score])
    
        #======================== Set Results ======================================================================
      if @equipment["video_tester"].get_mos_score < 2
          result_type = FrameworkConstants::Result[:fail]
          result_comment += "#{File.basename(ref_file).gsub(".264","_test.yuv")} MOS= #{@equipment["video_tester"].get_mos_score}"
          File.cp(ref_file.gsub(".264","_test.yuv"),ref_file.gsub(".264","_test_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+".yuv"))
          @results_html_file.add_paragraph(ref_file.gsub(".264","_test_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+".yuv"),nil,nil,"//"+local_ref.gsub(".264","_test_fail_"+Time.now.to_s.gsub(/[\s\:-]/,"_")+".yuv").gsub("\\","/"))
      end
    end

  set_result(result_type, result_comment)
end

def clean
	
end



private

def get_pixel_and_data_format(ref_file)
    if ref_file.match(/_(\d{3})p_/) == nil 
        ref_file_pixel_format = 'packed'
	    raw_data_format = 'uyv'
    else
        ref_file_pixel_format = 'planar'
	    raw_data_format = 'yuv'
    end
    [ref_file_pixel_format,raw_data_format]
end

