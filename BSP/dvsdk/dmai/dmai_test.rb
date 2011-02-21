require File.dirname(__FILE__)+'/../../default_test'

include WinceTestScript
media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
output_file_name = ""

 def run_generate_script
    puts "\n WinceTestScript::run_generate_script"
	  media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    puts "Test Test TEST #{@test_params.params_chan.codec[0].to_s.strip}"    
    case @test_params.params_chan.codec[0].to_s.strip
    when  /h264dec/
	   @output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
    when /mpeg4dec/
	   @output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]    
    when  /aachedec/
     @output_file_name = @test_params.params_chan.input_file[0].to_s + '.pcm'
	   test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
    when  /jpegdec/
     @output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name
    when  /jpegenc/
     @output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'.jpg'
     #test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'--iColorSpace'+' '+@test_params.params_chan.input_colorspace[0]
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'--iColorSpace'+' '+@test_params.params_chan.input_colorspace[0]+' '+'--oColorSpace'+' '+@test_params.params_chan.output_colorspace[0]
     puts "TEST CMD #{test_command}"
    when  /g711dec/
     @output_file_name = @test_params.params_chan.input_file[0].to_s+"_decoded"+'.'+@test_params.params_chan.companding[0].to_s
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+' '+'--compandinglaw '+@test_params.params_chan.companding[0]+' -n'+' '+@test_params.params_chan.num_of_frames[0]
    when  /g711enc/
     @output_file_name = @test_params.params_chan.input_file[0].to_s+"_encoded"+'.'+@test_params.params_chan.companding[0].to_s
     test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+' '+'--compandinglaw '+@test_params.params_chan.companding[0]+' -n'+' '+@test_params.params_chan.num_of_frames[0]
    when  /h264enc/
	   @output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.264'
	   test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-b'+' '+@test_params.params_chan.bitrate[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
     when /mpeg4enc/
	   @output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.m4v'
        #@output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.mpeg4'
	   test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-b'+' '+@test_params.params_chan.bitrate[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
     when /mpeg2enc/
	   @output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.m2v'	
	   test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-b'+' '+@test_params.params_chan.bitrate[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
     when /mpeg2dec/
    @output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
    test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+@output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]    
    end 
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    out_file.puts("do opm ?")
    puts "TEST COMMAND #{test_command}"
    out_file.puts(test_command)
    out_file.close
  end
  def get_destination_folder()
    subfolder = ""
    case @test_params.params_chan.codec[0].to_s.strip
    when /mpeg2dec/
     subfolder = "/common/Multimedia/Video/M2V"
    when /mpeg4dec/
	   subfolder = "/common/Multimedia/Video/MPEG4"
	  when /h264dec/
	   subfolder = "/common/Multimedia/Video/264"
    when /jpegdec/
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("jpg") == 0)
      subfolder = "/common/Multimedia/Image/jpg"
     elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("yuv") == 0)
      subfolder = "/common/Multimedia/Image/yuv"
     elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("mp4") == 0)
      subfolder = "/common/Multimedia/Video/MP4"
     end
    when /jpegenc/
     #if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("uyvy") == 0)
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("yuv") == 0)
	    #subfolder = "/common/Multimedia/Image/UYVY"
      subfolder = "/common/Multimedia/Image/yuv"
	    puts "subfolder is #{subfolder}\n"
      #elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("mpeg4") == 0)
      # subfolder = "/common/Multimedia/Video/MPEG4"
      # puts "subfolder is #{subfolder}\n"
      #elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("264") == 0)
      # subfolder = "/common/Multimedia/Video/264"
      # puts "subfolder is #{subfolder}\n" 
     end 
    when /aachedec/
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("aac") == 0)
	   subfolder = "/common/Multimedia/Audio/AAC"
  	 end
    when /g711dec/
   	 if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("g711") == 0)
  	  subfolder = "/common/Multimedia/Speech/G711"
     end 
    when /g711enc/
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("pcm") == 0)
	    subfolder = "/common/Multimedia/Speech/PCM"
     end
    when /h264enc/
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("yuv") == 0)
	    subfolder = "/common/Multimedia/Video/UYVY"
      puts "subfolder is #{subfolder}\n"
	   elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("mpeg4") == 0)
	    subfolder = "/common/Multimedia/Video/MPEG4"
     elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("264") == 0)
	    subfolder = "/common/Multimedia/Video/264"
     end
     when /mpeg4enc/
     if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("yuv") == 0)
	    subfolder = "/common/Multimedia/Video/UYVY"
      puts "subfolder is #{subfolder}\n"
	   elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("mpeg4") == 0)
	    subfolder = "/common/Multimedia/Video/MPEG4"
     elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("264") == 0)
	    subfolder = "/common/Multimedia/Video/264"
     end
	  end
	  dest_folder = ""
	  dest_folder = SiteInfo::FILE_SERVER + subfolder
    return dest_folder 
  end 
  
  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
	put_file({'filename'=>'test.bat'})
    transfer_server_files(@test_params.params_chan.input_file[0].to_s, get_destination_folder)
  end
  
  def transfer_server_files(test_file, test_file_root)
  puts " SRC #{test_file_root} "
        put_file({'filename' => test_file, 'src_dir' => test_file_root, 'binary' => true})
  end
  
  def run_call_script
    puts "\n DMAI_Test_Script::run_call_script"
	  test_completion_prompt = "End of application"
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call test.bat",test_completion_prompt,180)
	puts "Received test completion prompt\n"
  end
  
#Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output
    puts "\n cetk_test::run_get_script_output"
    @telnet_response = @equipment['dut1'].response
    puts "Response on telnet window is #{@telnet_response}\n"
  end

def run_collect_performance_data
    if  @test_params.params_chan.cmdline[0].to_s.strip.include?("video_decode")
      run_collect_performance_data_video_decode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("video_encode")
      run_collect_performance_data_video_encode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("audio_decode")
      run_collect_performance_data_audio_decode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("image_encode")
      run_collect_performance_data_image_encode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("image_decode")
      run_collect_performance_data_image_decode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("speech_encode")
      run_collect_performance_data_speech_encode
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("speech_decode")
      run_collect_performance_data_speech_decode
	  end	
end
def run_collect_performance_data_video_decode
  media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
  dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_video_decode")
  frame_time = []
	total_time = 0
	resolution = ""
	opm_info = ""
    if (!File.exist?(dest_dir))
    puts "Saw that dmai_video_decode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
	#@output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
	test_output_files = get_file({'filename'=>@output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
	deg_file = dest_dir + '/' + @output_file_name
	ref_file = get_destination_folder  + '/' + @test_params.params_chan.input_file[0].to_s
	video_tester_result = @equipment['video_clarity'].file_to_file_test({'ref_file' => ref_file.gsub(/\//,"\\"), 
                                                                              'test_file' => deg_file,
                                                                              'data_format' => @test_params.params_chan.chroma_format[0],
                                                                              'format' => [@test_params.params_chan.width[0].to_i,@test_params.params_chan.height[0].to_i,30],
                                                                              'video_height' => @test_params.params_chan.height[0],
                                                                              'video_width' => @test_params.params_chan.width[0],
                                                                              'num_frames' => @test_params.params_chan.num_of_frames[0],
                                                                              'frame_rate' => '30',
                                                                              'metric_window' => [0,0,@test_params.params_chan.width[0],@test_params.params_chan.height[0]]})
  
  
  
  
  @telnet_response.each_line {|l|     
	 puts "each line is #{l}\n"
	 if(l.scan(/Current Frequencies/).size>0)
	 opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	  puts "OPM is #{opm_info}\n"
     end	 
	
	 }
   @telnet_response.each_line {|current_line|
      if (current_line.scan(/Decode: /).size>0)
	     frame_time << current_line.split(/: /)[1].split('us')[0].to_f
	 
	  elsif (current_line.scan(/Total: /).size>0)
	    total_time = current_line.split(/: /)[1].split('us')[0]
	
	  elsif (current_line.scan(/to disk/).size>0)
	     resolution = current_line.split('(')[1].split(')')[0]
	
	  end
	 
   }
   
   #y_jnd_scores = @equipment['video_clarity'].get_jnd_scores({'component' => 'y'})
	 frame_time_mean = get_mean(frame_time)
	 frame_time_min = frame_time.min()
	 frame_time_max = frame_time.max()
	 puts "Total Time is #{total_time}\n"
   perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_video_decode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_video_decode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_video_decode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_video_decode.txt"),'a+')
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tFrame Rate\n")
	xls_file.puts("TestTime\tFileName\tResolution\tOpmState\tMean Decode Time/frame(in us)\tMin Decode Time/frame(in us)\tMax Decode Time/frame(in us)\tTotal Decode Time for clip(in us)\tNumber of frames\n")
	xls_file.close
   end
   
  xls_file = File.open(File.join(dest_dir,"dmai_video_decode.txt"),'a+') 
  time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
  xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+resolution.to_s+"\t"+"#{opm_info}"+"\t"+frame_time_mean.round(2).to_s+"\t"+frame_time_min.round(2).to_s+"\t"+frame_time_max.round(2).to_s+"\t"+total_time+"\t"+@test_params.params_chan.num_of_frames[0].to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_video_decode"+"_"+@test_params.params_chan.input_file[0].to_s+"_"+"of size_"+resolution+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
  @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_DECODE_TIME in us",total_time])
	@results_html_file.add_row_to_table(res_table,["MEAN_DECODE_TIME per frame in us",frame_time_mean.round(2).to_s])
	xls_file.close
  y_jnd_scores = []
  chroma_jnd_scores = []
  y_jnd_scores = @equipment['video_clarity'].get_jnd_scores({'component' => 'y'})
  chroma_jnd_scores = @equipment['video_clarity'].get_jnd_scores({'component' => 'chroma'})
  [{'name' => "y_jnd", 'value' => y_jnd_scores, 'units' => "jnd"},{'name' => "chroma_jnd", 'value' => chroma_jnd_scores, 'units' => "jnd"},{'name' => "TOTAL_DECODE_TIME", 'value' => total_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end
  # The function verifies the score returned by video clariy. The return result is complared with pass and fail criteria. 
 def verify_video_clarity_result()
   y_jnd_score_max = @equipment['video_clarity'].get_jnd_score({'component' => 'y','type' => 'max'})
   chroma_jnd_score_max = @equipment['video_clarity'].get_jnd_score({'component' => 'chroma','type' => 'max'})
   if (y_jnd_score_max.to_f < 6.99) or (chroma_jnd_score_max.to_f < 6.99) then 
      result = 1 
    else
      result = 0 
   end
    return result
end
 

 # The function determines test outcome for power  consumption or policy
 def run_determine_test_outcome()
     if  @test_params.params_chan.cmdline[0].to_s.strip.include?("video_decode") or @test_params.params_chan.cmdline[0].to_s.strip.include?("video_encode")
       perf_data  = run_collect_performance_data
       if verify_video_clarity_result() == 1 then
        puts "-----------test passed---------"
        [FrameworkConstants::Result[:pass], "This test pass video quality score.",perf_data]
       else 
        puts "-----------test failed---------"
        [FrameworkConstants::Result[:fail], "This test fail video quality score.",perf_data]
       end
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("audio_decode")
      [FrameworkConstants::Result[:fail], "This test must be verified manaully to pass.",run_collect_performance_data]
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("image_encode")
       [FrameworkConstants::Result[:fail], "This test must be verified manaully to pass.",run_collect_performance_data]
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("image_decode")
     [FrameworkConstants::Result[:fail], "This test must be verified manaully to pass.",run_collect_performance_data]
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("speech_encode")
     [FrameworkConstants::Result[:fail], "This test must be verified manaully to pass.",run_collect_performance_data]
    elsif @test_params.params_chan.cmdline[0].to_s.strip.include?("speech_decode")
     [FrameworkConstants::Result[:fail], "This test must be verified manaully to pass.",run_collect_performance_data]
	  end	
 end



# This function is used to compute the mean value in an array
def get_mean(an_array)
  sum = 0
  puts "Array time #{an_array.length}"
  an_array.each{|element| sum+= element}
  sum/(an_array.length)
  
end

def clean
  super
  clean_delete_log_files
end

# Delete log files (if any) 
def clean_delete_log_files
  media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
  puts "\n WinceCetkPerfScript::clean_delete_log_files"
  @equipment['dut1'].send_cmd("cd #{@test_params.params_chan.test_dir[0]}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("del \/Q \*\.*",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("del #{@test_params.params_chan.input_file[0]}",@equipment['dut1'].prompt) 
  @output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
  @equipment['dut1'].send_cmd("del #{@output_file_name}",@equipment['dut1'].prompt) 
  dest_dir = @wince_temp_folder
   if (!File.exist?(dest_dir))
    puts "Saw that video_encode in clean_delete_log_files folder does not exist and calling makedirs now\n"
	    Dir.mkdir(dest_dir)
   end
	 
  puts "\n dest_dir is #{dest_dir}\n"
  puts "del \/Q #{dest_dir}\\*.tmp"
 system("del \/Q #{dest_dir}\\*.tmp")
end


def run_collect_performance_data_audio_decode
  media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
  dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_audio_decode")
  decode_time = []
	total_time = []
	loader_time = []
	resolution = ""
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_audio_decode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
	output_file_name = @test_params.params_chan.input_file[0].to_s + '.pcm'
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
  @telnet_response.each_line {|l| 
	#puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	}
  @telnet_response.each_line {|current_line|
     if (current_line.scan(/Decode: /).size>0)
	    decode_time << current_line.split(/Decode: /)[1].split('us')[0].to_f
	    loader_time << current_line.split(/Loader: /)[1].split('us')[0].to_f
	 elsif (current_line.scan(/Total: /).size>0)
	    total_time << current_line.split(/: /)[1].split('us')[0].to_f
	
	 end
	 
  }
   #puts "Frame Time Array is #{decode_time}\n"	 
	 decode_time_mean = get_mean(decode_time)
	 decode_time_min = decode_time.min()
	 decode_time_max = decode_time.max()
	 puts "Total Time is #{total_time}\n"
	 total_time_mean = get_mean(total_time)
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	  puts "Loader Time is #{loader_time}\n"
	 loader_time_mean = get_mean(loader_time)
	 loader_time_min = loader_time.min()
	 loader_time_max = loader_time.max()
   perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_audio_decode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_audio_decode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_audio_decode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_audio_decode.txt"),'a+')
	xls_file.puts("TestTime\tFileName\tOpmState\tMean Decode Time(us)\tMin Decode Time(us)\tMax Decode Time(us)\tMean Loader Time(us)\tMin Loader Time(us)\tMax Loader Time(us)\tMean Total Time(us)\tMin Total Time(us)\tMax Total Time(us)\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_audio_decode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+"#{opm_info}"+"\t"+decode_time_mean.round(2).to_s+"\t"+decode_time_min.round(2).to_s+"\t"+decode_time_max.round(2).to_s+"\t"+loader_time_mean.round(2).to_s+"\t"+loader_time_min.round(2).to_s+"\t"+loader_time_max.round(2).to_s+"\t"+total_time_mean.round(2).to_s+"\t"+total_time_min.round(2).to_s+"\t"+total_time_max.round(2).to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_audio_decode"+"_"+@test_params.params_chan.input_file[0].to_s+"_"+"of size_"+resolution+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_DECODE_TIME",total_time_mean])
	xls_file.close
  [{'name' => "Audio_Decode_Total", 'value' => total_time, 'units' => "ms"},{'name' => "Audio_Decode_Time", 'value' => decode_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end

def run_collect_performance_data_image_decode
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_image_decode")
  frame_time = []
	total_time = 0
	resolution = ""
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_image_decode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
	  output_file_name = @test_params.params_chan.input_file[0].to_s + '.yuv'
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
    @telnet_response.each_line {|l| 
	puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	
	}
  @telnet_response.each_line {|current_line|
     if (current_line.scan(/Frame - Decode: /).size>0)
	    frame_time << current_line.split(/: /)[1].split('us')[0].to_f
	 
	 elsif (current_line.scan(/Total: /).size>0)
	    total_time = current_line.split(/: /)[1].split('us')[0]
	
	 elsif (current_line.scan(/to disk/).size>0)
	    resolution = current_line.split('(')[1].split(')')[0]
	
	 end
	 
  }
     puts "Frame Time Array is #{frame_time}\n"	 
	 frame_time_mean = get_mean(frame_time)
	 frame_time_min = frame_time.min()
	 frame_time_max = frame_time.max()
	 puts "Total Time is #{total_time}\n"
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_image_decode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_image_decode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_image_decode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_image_decode.txt"),'a+')
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tFrame Rate\n")
	xls_file.puts("TestTime\tFileName\tResolution\tOpmState\tMean Frame Time(in us)\tTotal Decode Time(in us)\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_image_decode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+resolution.to_s+"\t"+"#{opm_info}"+"\t"+frame_time_mean.round(2).to_s+"\t"+total_time)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_image_decode"+"_"+@test_params.params_chan.input_file[0].to_s+"_"+"of size_"+resolution+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_DECODE_TIME",total_time])
	xls_file.close
[{'name' => "Image_Decode_Total", 'value' => total_time, 'units' => "ms"},{'name' => "Image_Decode_Time", 'value' => frame_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end

def run_collect_performance_data_image_encode
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_image_encode")
    write_time = []
	total_time = []
	encode_time = []
	resolution = ""
	read_time = []
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_image_encode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   if (@test_params.params_chan.codec[0].to_s == "jpegenc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'.jpg'
	end
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
    # @telnet_response.each_line {|l| 
	# puts "each line is #{l}\n"
	# if(l.scan(/Current Frequencies/).size>0)
	# opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 # puts "OPM is #{opm_info}\n"
    # end	 
	
	# }
  @telnet_response.each_line {|current_line|
     if (current_line.scan(/Encode: /).size>0)
	    encode_time << current_line.split(/: /)[1].split('us')[0].to_f
   
	 elsif (current_line.scan(/Total: /).size>0)
	    total_time << current_line.split(/: /)[1].split('us')[0].to_f
	
	 elsif (current_line.scan(/Read time: /).size>0)
	    read_time << current_line.split(/: /)[1].split('us')[0].to_f
		
	 elsif (current_line.scan(/File write time: /).size>0)
	    write_time << current_line.split(/: /)[1].split('us')[0].to_f
	
	 end
	 
  }
     puts "Encode Time Array is #{encode_time}\n"	 
	 encode_time_mean = get_mean(encode_time)
	 #frame_time = frame_time.to_i
	 encode_time_min = encode_time.min()
	 encode_time_max = encode_time.max()
	 puts "Total Time Array is #{total_time}\n"
	 total_time_mean = get_mean(total_time)
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	 # read_time_mean = get_mean(read_time)
	 # read_time_min = read_time.min()
	 # read_time_max = read_time.max()
	 # write_time_mean = get_mean(write_time)
	 # write_time_min = write_time.min()
	 # write_time_max = write_time.max()
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_image_encode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_image_encode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_image_encode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_image_encode.txt"),'a+')
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tFrame Rate\n")
	xls_file.puts("TestTime\tFileName\tResolution\tOpmState\tMean Encode Time\tMean Read Time\tMean Write Time\tMean Total Time\n")
	xls_file.close
  
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_image_encode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
   xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+@test_params.params_chan.resolution[0].to_s+"\t"+"#{opm_info}"+"\t"+encode_time_mean.round(2).to_s+"\t"+total_time_mean.round(2).to_s)
   #xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+@test_params.params_chan.resolution[0].to_s+"\t"+"#{opm_info}"+"\t"+encode_time_mean.round(2).to_s+"\t"+read_time_mean.round(2).to_s+"\t"+write_time_mean.round(2).to_s+"\t"+total_time_mean.round(2).to_s)
	 res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_image_encode"+"_"+@test_params.params_chan.input_file[0].to_s+"_"+"of size_"+@test_params.params_chan.resolution[0].to_s+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_TIME",total_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ENCODE_TIME",encode_time_mean.round(2).to_s])
	#@results_html_file.add_row_to_table(res_table,["READ_TIME",read_time_mean.round(2).to_s])
	#@results_html_file.add_row_to_table(res_table,["WRITE_TIME",write_time_mean.round(2).to_s])
	xls_file.close
    [{'name' => "Image_Encode_Total", 'value' => total_time, 'units' => "ms"},{'name' => "Image_Encode_Time", 'value' => encode_time, 'units' => "ms"},{'name' => "Image_Read_Time", 'value' => read_time, 'units' => "ms"},{'name' => "Image_Write_Time", 'value' => write_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end

def run_collect_performance_data_speech_decode
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_speech_decode")
    loader_time = []
	total_time = []
	decode_time = []
	resolution = ""
	read_time = []
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_speech_decode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   if (@test_params.params_chan.codec[0].to_s == "g711dec")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+"_decoded"+'.'+@test_params.params_chan.companding[0].to_s
	end
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
	
	@telnet_response.each_line {|l| 
	puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	
	}
  @telnet_response.each_line {|current_line|
	 if (current_line.scan(/Decode: /).size>0)
	    decode_time << current_line.split(/Decode: /)[1].split('us')[0].to_f
		loader_time << current_line.split(/Loader: /)[1].split('us')[0].to_f		
		
	 elsif (current_line.scan(/Total: /).size>0)
	    total_time << current_line.split(/Total: /)[1].split('us')[0].to_f
	 end
	 
  }
     puts "Decode Time Array is #{decode_time}\n"	 
	 decode_time_mean = get_mean(decode_time)
	 decode_time_min = decode_time.min()
	 decode_time_max = decode_time.max()
	 puts "Total Time Array is #{total_time}\n"
	 total_time_mean = get_mean(total_time)
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	 loader_time_mean = get_mean(loader_time)
	 loader_time_min = loader_time.min()
	 loader_time_max = loader_time.max()
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_speech_decode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_speech_decode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_speech_decode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_speech_decode.txt"),'a+')
	xls_file.puts("TestTime\tFileName\tOpmState\tMean Decode Time(us)\tMin Decode Time(us)\tMax Decode Time(us)\tMean Loader Time(us)\tMin Loader Time(us)\tMax Loader Time(us)\tMean Total Time(us)\tMin Total Time(us)\tMax Total Time(us)\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_speech_decode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+"#{opm_info}"+"\t"+decode_time_mean.round(2).to_s+"\t"+decode_time_min.round(2).to_s+"\t"+decode_time_max.round(2).to_s+"\t"+loader_time_mean.round(2).to_s+"\t"+loader_time_min.round(2).to_s+"\t"+loader_time_max.round(2).to_s+"\t"+total_time_mean.round(2).to_s+"\t"+total_time_min.round(2).to_s+"\t"+total_time_max.round(2).to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_speech_decode"+"_"+@test_params.params_chan.input_file[0].to_s+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_TIME",total_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["DECODE_TIME",decode_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["LOADER_TIME",loader_time_mean.round(2).to_s])
	xls_file.close
  [{'name' => "Speech_Decode_Total", 'value' => total_time, 'units' => "ms"},{'name' => "Speech_Decode_Time", 'value' => decode_time, 'units' => "ms"},{'name' => "Speech_Loader_Time", 'value' => loader_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end


def run_collect_performance_data_speech_encode
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_speech_encode")
    write_time = []
	total_time = []
	encode_time = []
	resolution = ""
	read_time = []
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_speech_encode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   if (@test_params.params_chan.codec[0].to_s == "g711enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+"_encoded"+'.'+@test_params.params_chan.companding[0].to_s
	end
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
    @telnet_response.each_line {|l| 
	puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	
	}
  @telnet_response.each_line {|current_line|
	 if (current_line.scan(/Read: /).size>0)
	    read_time << current_line.split(/Read: /)[1].split('us')[0].to_f
		encode_time << current_line.split(/Encode: /)[1].split('us')[0].to_f		
		
	 elsif (current_line.scan(/Write: /).size>0)
	    write_time << current_line.split(/Write: /)[1].split('us')[0].to_f
	    total_time << current_line.split(/Total: /)[1].split('us')[0].to_f
	 end
	 
  }
     puts "Encode Time Array is #{encode_time}\n"	 
	 encode_time_mean = get_mean(encode_time)
	 encode_time_min = encode_time.min()
	 encode_time_max = encode_time.max()
	 puts "Total Time Array is #{total_time}\n"
	 total_time_mean = get_mean(total_time)
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	 read_time_mean = get_mean(read_time)
	 read_time_min = read_time.min()
	 read_time_max = read_time.max()
	 write_time_mean = get_mean(write_time)
	 write_time_min = write_time.min()
	 write_time_max = write_time.max()
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_speech_encode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_speech_encode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_speech_encode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_speech_encode.txt"),'a+')
	xls_file.puts("TestTime\tFileName\tOpmState\tMean Encode Time(us)\tMin Encode Time(us)\tMax Encode Time(us)\tMean Read Time(us)\tMin Read Time(us)\tMax Read Time(us)\tMean Write Time(us)\tMin Write Time(us)\tMax Write Time(us)\tMean Total Time(us)\tMin Total Time(us)\tMax Total Time(us)\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_speech_encode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+"#{opm_info}"+"\t"+encode_time_mean.round(2).to_s+"\t"+encode_time_min.round(2).to_s+"\t"+encode_time_max.round(2).to_s+"\t"+read_time_mean.round(2).to_s+"\t"+read_time_min.round(2).to_s+"\t"+read_time_max.round(2).to_s+"\t"+write_time_mean.round(2).to_s+"\t"+write_time_min.round(2).to_s+"\t"+write_time_max.round(2).to_s+"\t"+total_time_mean.round(2).to_s+"\t"+total_time_min.round(2).to_s+"\t"+total_time_max.round(2).to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_speech_encode"+"_"+@test_params.params_chan.input_file[0].to_s+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_TIME",total_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ENCODE_TIME",encode_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["READ_TIME",read_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["WRITE_TIME",write_time_mean.round(2).to_s])
	xls_file.close
  [{'name' => "Speech_Encode_Total", 'value' => total_time, 'units' => "ms"},{'name' => "Speech_Encode_Time", 'value' => encode_time, 'units' => "ms"},{'name' => "Speech_Read_Time", 'value' => read_time, 'units' => "ms"},{'name' => "Speech_Write_Time", 'value' => write_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end


def run_collect_performance_data_video_encode
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	dest_dir = File.join(dest_dir,"dmai_video_encode")
    write_time = []
	total_time = []
	encode_time = []
	resolution = ""
	read_time = []
	opm_info = ""
   if (!File.exist?(dest_dir))
    puts "Saw that dmai_video_encode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   puts "Destination #{dest_dir}"
   puts "out put file name #{@output_file_name}"
  test_output_files = get_file({'filename'=>@output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
	#test_output_files = get_file({'filename'=>@output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
  deg_file = dest_dir + '/' + @output_file_name
	ref_file = get_destination_folder + '/' + @test_params.params_chan.input_file[0].to_s
	video_tester_result = @equipment['video_clarity'].file_to_file_test({'ref_file' => ref_file, 
                                                                              'test_file' => deg_file,
                                                                              'data_format' => @test_params.params_chan.chroma_format[0],
                                                                              'format' => [@test_params.params_chan.width[0].to_i,@test_params.params_chan.height[0].to_i,30],
                                                                              'video_height' => @test_params.params_chan.height[0],
                                                                              'video_width' => @test_params.params_chan.width[0],
                                                                              'num_frames' => @test_params.params_chan.num_of_frames[0],
                                                                              'frame_rate' => '30',
                                                                              'metric_window' => [0,0,@test_params.params_chan.width[0],@test_params.params_chan.height[0]]})
  
  
  
  

  @telnet_response.each_line {|l| 
	puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	
	} 
  @telnet_response.each_line {|current_line|
     if (current_line.scan(/Encode: /).size>0)
	    encode_time << current_line.split(/: /)[1].split('us')[0].to_f
	 
	 elsif (current_line.scan(/Total: /).size>0)
	    total_time << current_line.split(/: /)[1].split('us')[0].to_f
	
	 elsif (current_line.scan(/Read time: /).size>0)
	    read_time << current_line.split(/: /)[1].split('us')[0].to_f
		
	 elsif (current_line.scan(/File write time: /).size>0)
	    write_time << current_line.split(/: /)[1].split('us')[0].to_f
	
	 end
	 
  }
     puts "Encode Time Array is #{encode_time}\n"	 
	 encode_time_mean = get_mean(encode_time)
	 encode_time_min = encode_time.min()
	 encode_time_max = encode_time.max()
	 puts "Total Time Array is #{total_time}\n"
	 total_time_mean = get_mean(total_time)
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	 read_time_mean = get_mean(read_time)
	 read_time_min = read_time.min()
	 read_time_max = read_time.max()
	 write_time_mean = get_mean(write_time)
	 write_time_min = write_time.min()
	 write_time_max = write_time.max()
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"dmai_video_encode")

   if (!File.exist?(dest_dir))
    puts "Saw that dmai_video_encode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"dmai_video_encode.txt")
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"dmai_video_encode.txt"),'a+')
	xls_file.puts("TestTime\tFileName\tResolution\tBitRate\tOpmState\tMean Encode Time\tMean Read Time\tMean Write Time\tMean Total Time\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"dmai_video_encode.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+@test_params.params_chan.resolution[0].to_s+"\t"+@test_params.params_chan.bitrate[0].to_s+"\t"+"#{opm_info}"+"\t"+encode_time_mean.round(2).to_s+"\t"+read_time_mean.round(2).to_s+"\t"+write_time_mean.round(2).to_s+"\t"+total_time_mean.round(2).to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"dmai_video_encode"+"_"+@test_params.params_chan.input_file[0].to_s+"_"+"of size_"+@test_params.params_chan.resolution[0].to_s+"_bitrate_"+@test_params.params_chan.bitrate[0].to_s+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
	@results_html_file.add_row_to_table(res_table,["TOTAL_TIME",total_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ENCODE_TIME",encode_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["READ_TIME",read_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["WRITE_TIME",write_time_mean.round(2).to_s])
	xls_file.close
   y_jnd_scores = []
  chroma_jnd_scores = []
  y_jnd_scores = @equipment['video_clarity'].get_jnd_scores({'component' => 'y'})
  chroma_jnd_scores = @equipment['video_clarity'].get_jnd_scores({'component' => 'chroma'})
  [{'name' => "y_jnd", 'value' => y_jnd_scores, 'units' => "jnd"},{'name' => "chroma_jnd", 'value' => chroma_jnd_scores, 'units' => "jnd"},{'name' => "TOTAL_TIME", 'value' => total_time, 'units' => "ms"},{'name' => "ENCODE_TIME", 'value' => encode_time, 'units' => "ms"},{'name' => "READ_TIME", 'value' => read_time, 'units' => "ms"},{'name' => "WRITE_TIME", 'value' => write_time, 'units' => "ms"}]
	ensure
    perf_log.close if perf_log
	
end
