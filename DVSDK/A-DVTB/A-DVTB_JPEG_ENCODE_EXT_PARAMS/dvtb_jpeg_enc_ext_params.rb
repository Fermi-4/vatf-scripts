



#include DvsdkTestScript

def setup
  @equipment['dut1'].set_api('dvtb')
  #boot_dut() # method implemented in DvsdkTestScript module
  @equipment['dut1'].connect({'type'=>'telnet'})  
  # Set DUT Max number of sockets
  @equipment['dut1'].set_max_number_of_sockets(@test_params.params_control.picture_num_channels[0].to_i,0)
    
  #Setting the encoders and/or decoders parameters
  
  #Setting the engine type
  set_codec_param("name", "encode")
  
  set_codec_param("codec", "jpegenc")
  set_codec_param("maxHeight", "picture_height")
  set_codec_param("maxWidth", "picture_width")
  set_codec_param("maxScans", "picture_num_scans")
  set_codec_param("dataEndianness", "picture_data_endianness")
  set_codec_param("forceChromaFormat", "picture_output_chroma_format")
  set_codec_param("inputChromaFormat", "picture_input_chroma_format")
  set_codec_param("inputHeight", "picture_input_height")
  set_codec_param("inputWidth", "picture_input_width")
  set_codec_param("captureWidth", "picture_width")
  set_codec_param("captureHeight", "picture_height")
  set_codec_param("generateHeader", 0)
  set_codec_param("qValue", "picture_quality")
  set_codec_param("numAU", "picture_num_access_units")
  set_codec_param("dynParamsRstInterval", "picture_reset_interval")
  set_codec_param("dynParamsDisableEOI", "picture_disable_eoi")
  set_codec_param("dynParamsRotation", "picture_rotation")
  set_codec_param("dri_interval", "picture_reset_interval")
end


def run
  #======================== Processing Media ====================================================
  begin
    file_res_form = ResultForm.new("JPEG Encoder Test Result Form")
    @test_params.params_chan.picture_source.each do |source_file|
      puts "Encoding #{source_file} ........."
      test_file = SiteInfo::LOCAL_FILES_FOLDER+source_file.gsub(".yuv","_at_"+@test_params.params_chan.picture_quality[0]+"qual_"+@test_params.params_chan.picture_input_width[0]+"x"+@test_params.params_chan.picture_input_height[0]+"_"+@test_params.params_chan.picture_output_chroma_format[0]+"_test.jpg")
      File.delete(test_file) if File.exists?(test_file)
      ref_file,local_ref_file = get_ref_file(SiteInfo::NETWORK_REFERENCE_FILES_FOLDER,source_file)
      file_res_form.add_link('ref_'+File.basename(local_ref_file)){system("explorer #{local_ref_file.gsub("/","\\")}")}
      @equipment['dut1'].jpegext_encoding({"Source" => local_ref_file, "Target" => test_file, "threadId" => 'jpegenc'})
      file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}
      @equipment['dut1'].wait_for_threads
    end
    file_res_form.show_result_form    
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  if file_res_form.test_result == FrameworkConstants::Result[:fail]
    @equipment['dut1'].get_param({"Class" => "jpegextenc", "Param" => ""})
  end
  set_result(file_res_form.test_result,file_res_form.comment_text)

end

def clean

end



private 
def get_ref_file(start_directory, file_name)
  ref_file = Find.file(start_directory) { |f| File.basename(f) =~ /#{file_name}/}
  raise "File #{file_name} not found" if ref_file == "" || !ref_file
  local_ref_file = SiteInfo::LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
  FileUtils.cp(ref_file, local_ref_file)
  [ref_file,local_ref_file]
end

def get_chan_number(num_chan)
  rand(num_chan)
end

def set_codec_param(param_name, param_value)
  if param_value.kind_of?(String)
    @equipment['dut1'].set_param({"Class" => "jpegextenc", "Param" => param_name, "Value" => @test_params.params_chan.instance_variable_get('@'+param_value)[0]}) if @test_params.params_chan.instance_variable_defined?('@'+param_value)
  else
    @equipment['dut1'].set_param({"Class" => "jpegextenc", "Param" => param_name, "Value" => param_value.to_s})
  end
end
