NETWORK_REFERENCE_FILES_FOLDER = '//gtpegasus/SysTest_refs/VISA/Video'  
LOCAL_FILES_FOLDER             = 'C:/Video_tools/'

def setup
  # Set the maximum number of simultaneous socket that the dut can handle
  @equipment['dut'].set_max_number_of_sockets(@test_params.params_control.video_num_channels[0].to_i)
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
                               "Param" => "rateControlPreset",
                               "Value" => @test_params.params_chan.video_rate_control[0]})  
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "inputHeight",
                               "Value" => @test_params.params_chan.video_height[0]})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "inputWidth",
                               "Value" => @test_params.params_chan.video_width[0]})
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "refFrameRate",
                               "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "targetFrameRate",
                               "Value" => map_dut_frame_rate(@test_params.params_chan.video_frame_rate[0])}) 
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "targetBitRate",
                               "Value" => @test_params.params_chan.video_bit_rate[0]})   
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "intraFrameInterval",
                               "Value" => @test_params.params_chan.video_gop[0]})  
                               
#  @equipment["dut"].set_param({"Class" => "videnc",
#                               "Param" => "generateHeader",
#                               "Value" => "#{@test_params.params_chan.video_gen_header[0]}"})   
                               
  @equipment["dut"].set_param({"Class" => "videnc",
                               "Param" => "captureWidth",
                               "Value" => "0"})  
                               
 # @equipment["dut"].set_param({"Class" => "videnc",
 #                              "Param" => "forceIframe",
 #                              "Value" => "#{@test_params.params_chan.video_force_iframe[0]}"})   
                              
end


def run
  begin
	  file_res_form = ResultForm.new("MPEG4 G711 Encode File Test Result Form")
      @test_params.params_chan.video_source.each do |vid_source|  
          #======================== Prepare reference files ==========================================================
          ref_file = Find.file(NETWORK_REFERENCE_FILES_FOLDER) { |f| File.basename(f) =~ /#{vid_source}/}
          raise "File #{@test_params.params_chan.video_source[0]} not found" if ref_file == "" || !ref_file
          local_ref_file = LOCAL_FILES_FOLDER+"#{File.basename(ref_file)}"
		  puts "Encoding #{local_ref_file} at time #{Time.now.to_s} .............."
          test_file = local_ref_file.gsub(/\.yuv/, "_test.mpeg4")
          File.delete(test_file) if File.exist?(test_file)
          FileUtils.cp(ref_file, local_ref_file)
          num_frames = /_(\d+)frames/.match(ref_file).captures[0].to_i
          @equipment["dut"].set_param({"Class" => "videnc",
                                       "Param" => "numframes",
                                       "Value" => num_frames.to_s}) 
          # Start encoding-decoding function
          @equipment["dut"].video_encoding({"Source" => local_ref_file, "Target" => test_file})
          file_res_form.add_link(File.basename(test_file)){system("explorer #{test_file.gsub("/","\\")}")}  
      end
      @equipment["dut"].wait_for_threads
	  file_res_form.show_result_form
  end until file_res_form.test_result != FrameworkConstants::Result[:nry]
  set_result(file_res_form.test_result,file_res_form.comment_text)
end

def clean
	
end



private

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

