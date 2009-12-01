



include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  boot_dut() # method implemented in DvsdkTestScript module
  
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.picture_num_channels[0].to_i,0)
    
  #Setting the encoders and/or decoders parameters
  
  #Setting the engine type
  @equipment['dut1'].set_param({"Class" => "engine", "Param" => "name", "Value" => 'decode'})
  
  #Setting the picture decodercoder and vpbe
    #Setting the picture encoder
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "codec", "Value" => "jpegdec"})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "maxHeight", "Value" => @test_params.params_chan.picture_height[0]})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "maxWidth", "Value" => @test_params.params_chan.picture_width[0]})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "maxScans", "Value" => @test_params.params_chan.picture_num_scans[0]})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "dataEndianness", "Value" => @test_params.params_chan.picture_data_endianness[0]})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "forceChromaFormat", "Value" => @test_params.params_chan.picture_output_chroma_format[0]})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "displayWidth", "Value" => '0'})
    @equipment['dut1'].set_param({"Class" => "jpegdec", "Param" => "numticks", "Value" => @test_params.params_chan.picture_num_ticks[0]})
    #Making the picture connection
    if @test_params.params_chan.picture_display[0].eql?('on')
      @connection_handler.make_video_connection({@equipment['dut1'] => 0}, {@equipment["tv1"] => 0}, @test_params.params_chan.picture_iface_type[0])
      @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "height", "Value" => @test_params.params_chan.picture_height[0]})
      @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "width", "Value" => @test_params.params_chan.picture_width[0]})
      @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "standard", "Value" => @test_params.params_chan.picture_signal_format[0]})
      @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "format", "Value" => @test_params.params_chan.picture_output_chroma_format[0]})
      @equipment['dut1'].set_param({"Class" => "vpbe", "Param" => "output", "Value" => @test_params.params_chan.picture_iface_type[0]})
    end
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
        if @test_params.params_chan.picture_display[0].eql?('on')
          @equipment['dut1'].set_param({"Class" => "vpfe", "Param" => "chanNumber", "Value" => "0"})
          @equipment['dut1'].image_decoding({"Source" => local_ref_file, "threadId" => 'jpegdec'})
        else
          test_file = local_ref_file.gsub(".jpg","_as_"+@test_params.params_chan.picture_output_chroma_format[0]+"_test.yuv")
          File.delete(test_file) if File.exists?(test_file)
          @equipment['dut1'].image_decoding({"Source" => local_ref_file, "Target" => test_file, "threadId" => 'jpegdec'})
          file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
        end
        @equipment['dut1'].wait_for_threads
      end
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "jpegdec", "Param" => ""})
    @equipment['dut1'].get_param({"Class" => "vpbe", "Param" => ""})
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

def get_keys
  @test_params.target.to_s + @test_params.dsp.to_s + @test_params.micro.to_s + 
  @test_params.platform.to_s + @test_params.os.to_s + @test_params.custom.to_s + 
  @test_params.microType.to_s + @test_params.configID.to_s 
end
