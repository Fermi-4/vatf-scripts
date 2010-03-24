



# include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  # boot_dut() # method implemented in DvsdkTestScript module
  @equipment['dut1'].connect({'type'=>'telnet'})
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.picture_num_channels[0].to_i,0)
    
  #Setting the encoders and/or decoders parameters
  
  #Setting the engine type
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'decode'})
  
  #Setting the picture decodercoder and vpbe
  #Setting the picture encoder
  @equipment['dut1'].set_param({"Class" => "jpegextdec", "Param" => "codec", "Value" => "jpegdec"})
  set_codec_param("maxHeight", (@test_params.params_chan.picture_height[0].to_i/16).ceil * 16)
  set_codec_param("maxWidth", (@test_params.params_chan.picture_width[0].to_i/32).ceil * 32)
  set_codec_param("maxScans", "picture_num_scans")
  set_codec_param("dataEndianness", "picture_data_endianness")
  set_codec_param("forceChromaFormat", "picture_output_chroma_format")
  set_codec_param("displayWidth", 0)
  set_codec_param("numticks", "picture_num_ticks")
  set_codec_param("progressiveDecFlag", "picture_progressive_dec_flag")
  set_codec_param("progDisplay", "picture_prog_display")
  set_codec_param("dynParamsDisableEOI", "picture_disable_eoi")
  set_codec_param("dynParamsResizeOption", "picture_output_scale_factor")
  set_codec_param("dynParamsSubRegUpLeftX", "picture_subregion_upper_leftx")
  set_codec_param("dynParamsSubRegUpLeftY", "picture_subregion_upper_lefty")
  set_codec_param("dynParamsSubRegDownRightX", "picture_subregion_down_rightx")
  set_codec_param("dynParamssubRegDownRightY", "picture_subregion_down_righty")
  set_codec_param("x_length", "picture_subregion_x_length")
  set_codec_param("y_length", "picture_subregion_y_length")
  set_codec_param("dynParamsRotation", "picture_rotation")
  set_codec_param("RGB_Format", "picture_rgb_format")
  set_codec_param("numMCU_row", "picture_num_mcu_row")
  set_codec_param("alpha_rgb", "picture_alpha_rgb")
  set_codec_param("outImgRes", "picture_out_img_res")
    
end


def run
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("JPEG Decoder Test Result Form")
    @test_params.params_chan.picture_source.each do |pic_source|
      #======================== Prepare reference files ==========================================================
      get_ref_file(pic_source).each do |current_files|
        ref_file, local_ref_file = current_files
        puts "Decoding #{File.basename(local_ref_file)} ....."
        file_res_form.add_link(File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
        # Start decoding function
        test_file = local_ref_file.gsub(".jpg","_as_"+@test_params.params_chan.picture_output_chroma_format[0]+"_"+@test_params.params_chan.picture_subregion_upper_leftx[0]+
                                              @test_params.params_chan.picture_subregion_upper_leftx[0]+@test_params.params_chan.picture_subregion_down_rightx[0]+@test_params.params_chan.picture_subregion_down_righty[0]+"_subregion_resize_val"+@test_params.params_chan.picture_output_scale_factor[0]+"_test.yuv")
        File.delete(test_file) if File.exists?(test_file)
        @equipment['dut1'].jpegext_decoding({"Source" => local_ref_file, "Target" => test_file, "threadId" => 'jpegdec'})
        file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        @equipment['dut1'].wait_for_threads
      end
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "jpegextdec", "Param" => ""})
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)

end

def clean

end



private 

def get_ref_file(file_name)
  case file_name.strip.downcase
    when 'from_encoder'
      jpeg_files = []
      Dir.new(SiteInfo::LOCAL_FILES_FOLDER).each { |f| jpeg_files << [SiteInfo::LOCAL_FILES_FOLDER+f, SiteInfo::LOCAL_FILES_FOLDER+f]  if f =~ /#{@test_params.params_chan.picture_width[0]+'x'+@test_params.params_chan.picture_height[0]}.*\.jpg$/i}
      raise "File #{file_name} not found" if jpeg_files.length == 0
      jpeg_files
    when 'from_web'
      jpeg_files = []
      Dir.new(SiteInfo::LOCAL_FILES_FOLDER+'JPEG_Files').each { |f| jpeg_files << [SiteInfo::LOCAL_FILES_FOLDER+'JPEG_Files/'+f, SiteInfo::LOCAL_FILES_FOLDER+'JPEG_Files/'+f]  if f =~ /#{@test_params.params_chan.picture_width[0]+'x'+@test_params.params_chan.picture_height[0]}.*\.jpg$/i}
      raise "File #{file_name} not found" if jpeg_files.length == 0
      jpeg_files
    else
      ref_file = Find.file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{file_name}/}
      raise "File #{file_name} not found" if ref_file == "" || !ref_file
      local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
      FileUtils.cp(ref_file, local_ref_file)
      [[ref_file,local_ref_file]]
  end
end

def set_codec_param(param_name, param_value)
  if param_value.kind_of?(String)
    @equipment['dut1'].set_param({"Class" => "jpegextdec", "Param" => param_name, "Value" => @test_params.params_chan.instance_variable_get('@'+param_value)[0]}) if @test_params.params_chan.instance_variable_defined?('@'+param_value)
  else
    @equipment['dut1'].set_param({"Class" => "jpegextdec", "Param" => param_name, "Value" => param_value.to_s})
  end
end
