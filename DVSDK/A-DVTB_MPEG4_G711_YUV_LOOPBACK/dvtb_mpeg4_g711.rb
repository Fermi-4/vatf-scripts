#=============================================================================================================
# Test Script for DvtbMPEG4Loopback.atp.rb test recipe
# History:
#   0.1: [CH, 7/6/7] First Draft
#   0.2: [AH, 9/20/07]
#=============================================================================================================

NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Video'      
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
    @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i,@test_params.params_control.audio_num_channels[0].to_i)
  # Set engine params
  @equipment["dut"].set_param({"Class" => "engine",
                               "Param" => "name",
                               "Value" => "encdec"})
                               
  @equipment["dut"].set_param({"Class" => "engine",
                               "Param" => "trace",
                               "Value" => "0"})
  # Set encoder params
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "codec",
                               "Value" => "mpeg4enc"})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "maxHeight",
                               "Value" => @test_params.params_chan.video_height[0]})
  
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "maxWidth",
                               "Value" => @test_params.params_chan.video_width[0]})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "inputChromaFormat",
                               "Value" => map_dut_chroma_format(@test_params.params_chan.video_input_chroma_format[0])})                               
  
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "encodingPreset",
                               "Value" => "#{@test_params.params_chan.video_encoder_preset[0]}"}) 
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "rateControlPreset",
                               "Value" => "#{@test_params.params_chan.video_rate_control[0]}"})  
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "inputHeight",
                               "Value" => "#{@test_params.params_chan.video_height[0]}"})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "inputWidth",
                               "Value" => "#{@test_params.params_chan.video_width[0]}"})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "refFrameRate",
                               "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "targetFrameRate",
                               "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "targetBitRate",
                               "Value" => "#{@test_params.params_chan.video_bit_rate[0]}"}) 
  
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "maxBitRate",
                               "Value" => (@test_params.params_chan.video_bit_rate[0].to_i*1.1).round.to_s})							   
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "intraFrameInterval",
                               "Value" => "#{@test_params.params_chan.video_gop[0]}"})  
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "generateHeader",
                               "Value" => "#{@test_params.params_chan.video_gen_header[0]}"})   
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "captureWidth",
                               "Value" => "#{@test_params.params_chan.video_capture_width[0]}"})  
                               
 # @equipment["dut"].set_param({"Class" => "videnc",
 #                              "Param" => "forceIframe",
 #                              "Value" => "#{@test_params.params_chan.video_force_iframe[0]}"})   
                              
  # Set decoder params
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "codec",
                               "Value" => "mpeg4dec"})
                               
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "maxHeight",
                               "Value" => @test_params.params_chan.video_height[0]})
  
    @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "maxWidth",
                               "Value" => @test_params.params_chan.video_width[0]})
                               
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "forceChromaFormat",
                               "Value" => map_dut_chroma_format(@test_params.params_chan.video_input_chroma_format[0])})    
                               
  @equipment["dut"].set_param({"Class" => "viddec",
                               "Param" => "displayWidth",
  #                             "Value" => "#{@test_params.params_chan.video_capture_width[0]}"})        
                               "Value" => "0"}) 
end


def run
  result_comment = " "
  result_type = FrameworkConstants::Result[:pass]
  local_ref_files = Array.new
  @test_params.params_chan.video_source.each do |vid_source|
      #======================== Prepare reference files ==========================================================
      ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{vid_source}/}
      raise "File #{@test_params.params_chan.video_source[0]} not found" if ref_file == "" || !ref_file
      local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
      local_ref_files << local_ref_file
      FileUtils.cp(ref_file, local_ref_file)
	  FileUtils.chmod(0755,local_ref_file)
      File.delete(local_ref_file.gsub(".yuv","_out.yuv")) if File.exists?(local_ref_file.gsub(".yuv","_out.yuv"))
      File.delete(local_ref_file.gsub(".yuv","_out.avi")) if File.exists?(local_ref_file.gsub(".yuv","_out.avi"))
      num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
      @equipment["dut"].set_param({"Class" => "videnc",
                                   "Param" => "numframes",
                                   "Value" => num_frames.to_s}) 
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
  
      # Start encoding-decoding function
      @equipment["dut"].video_encoding_decoding({"Target" => local_ref_file.sub(/\.yuv/, "_out.yuv"), "Source" => local_ref_file})
  end
  @equipment["dut"].wait_for_threads
  local_ref_files.each do |local_ref_file|                      
      #======================== Prepare process file =============================================================
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
      #======================== Call Q-master ====================================================================
      @equipment["video_tester"].file_to_file_test(local_ref_file.gsub('.yuv','.avi'),
                                                   local_ref_file.gsub('.yuv','_out.avi'))
	    @results_html_file.add_paragraph("")										   
	    res_table = @results_html_file.add_table([["Mean Scores #{File.basename(local_ref_file)}",{:bgcolor => "green", :colspan => "2"},{:color => "red"}]],{:border => "1",:width=>"20%"})
	    @results_html_file.add_row_to_table(res_table,["MOS",@equipment["video_tester"].get_mos_score])
	    @results_html_file.add_row_to_table(res_table,["Blockiness",@equipment["video_tester"].get_blocking_score])
	    @results_html_file.add_row_to_table(res_table,["Blurring",@equipment["video_tester"].get_blurring_score])	
	    @results_html_file.add_row_to_table(res_table,["Frames Lost",@equipment["video_tester"].get_frame_lost_count])
	    @results_html_file.add_row_to_table(res_table,["Jerkiness",@equipment["video_tester"].get_jerkiness_score])
	    @results_html_file.add_row_to_table(res_table,["Level",@equipment["video_tester"].get_level_score])
	    @results_html_file.add_row_to_table(res_table,["PSNR",@equipment["video_tester"].get_psnr_score])
      
        #======================== Set Results ======================================================================
      if @equipment["video_tester"].get_mos_score < 3.5
          result_type = FrameworkConstants::Result[:fail]
          result_comment += "#{File.basename(local_ref_file).gsub(".yuv","_out.yuv")} MOS= #{@equipment["video_tester"].get_mos_score}"
          File.cp(local_ref_file.gsub(".yuv","_out.yuv"),local_ref_file.gsub(".yuv","_test_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+"_out.yuv"))
          @results_html_file.add_paragraph(local_ref_file.gsub(".yuv","_test_fail_"+Time.now.to_s.gsub(/[\s:-]/,"_")+"_out.yuv"),nil,nil,"//"+local_ref_file.gsub(".yuv","_test_fail_"+Time.now.to_s.gsub(/[\s\:-]/,"_")+"_out.yuv").gsub("\\","/"))
      end
  end
   set_result(result_type, result_comment)
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

def map_dut_chroma_format(format)
  if format.match(/p/) != nil
    return "1"
  else
    return "4"
  end
end

def map_dut_frame_rate(rate)
  return (rate.to_i * 1000).to_s
end

