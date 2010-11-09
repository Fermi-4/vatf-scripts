require File.dirname(__FILE__)+'/../../default_test'

include WinceTestScript
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
def setup_connect_equipment
    puts "WinceTestScript::setup_connect_equipment"
	#======================== Equipment Connections ====================================================
	#myhash = {"av" => "composite", "ypbpr" =>"component","svideo" => "svideo"}
	
	#@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}}, {@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0}}) #, @equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) 
	#@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}}, {@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0} , @equipment["tv0"] => {myhash[@test_params.params_chan.video_input[0]] => 0}}) 
	#@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}},{@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0}})
	#@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}}, {@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0}, @equipment["tv0"] => {myhash[@test_params.params_chan.video_input[0]] => 0}}) 
    #@connection_handler.make_audio_connection({@equipment[@test_params.params_chan.media_source[0]] => {'mini35mm' => 0}}, {@equipment["dut1"] => {'mini35mm' => 0}, @equipment["tv0"] => {'mini35mm' => 0}})   
    #@connection_handler.make_video_connection({@equipment["dut1"] => {@test_params.params_chan.display_out[0] => 0}},{@equipment['tv1'] => {@test_params.params_chan.display_out[0] => 0}}) 
    #@connection_handler.make_audio_connection({@equipment["dut1"] => {'mini35mm' => 0}},{@equipment['tv1'] => {'mini35mm' => 0}})
  # @connection_handler.make_video_connection({@equipment['ntsc_dvd'] => {@test_params.params_chan.video_input[0] => 0}}, {@equipment["dut1"] => {@test_params.params_chan.video_input[0] => 0}, @equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) 
  
  end
  
 def run_generate_script
    puts "\n WinceTestScript::run_generate_script"
	media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
	if (@test_params.params_chan.codec[0].to_s == "h264enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.264'
	  #output_file_name = @test_params.params_chan.input_file[0].to_s+'.264'
	elsif (@test_params.params_chan.codec[0].to_s == "mpeg4enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.mpeg4'
	  
	elsif (@test_params.params_chan.codec[0].to_s == "mpeg2enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.m2v'
	
	end
	
	test_command = @test_params.params_chan.cmdline[0]+' '+'--benchmark'+' '+'-c'+' '+@test_params.params_chan.codec[0].to_s+' '+'-r'+' '+@test_params.params_chan.resolution[0].to_s+' '+'-b'+' '+@test_params.params_chan.bitrate[0].to_s+' '+'-i'+' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s+' '+ '-o'+' '+@test_params.params_chan.test_dir[0]+'\\'+output_file_name+ ' '+'-n'+' '+@test_params.params_chan.num_of_frames[0]
	puts "test_command is #{test_command}\n"

    FileUtils.mkdir_p @wince_temp_folder
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_chan.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    raw_test_lines.each do |current_line|
	  puts "CURRENT LINE IS #{current_line}"
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end
  
  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
	put_file({'filename'=>'test.bat'})
	if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("uyvy") == 0)
	  subfolder = "/common/Multimedia/Video/UYVY"
	  puts "subfolder is #{subfolder}\n"
	# elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("mpeg4") == 0)
	  # subfolder = "/common/Multimedia/Video/MPEG4"
	  # puts "subfolder is #{subfolder}\n"
	# elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("264") == 0)
	  # subfolder = "/common/Multimedia/Video/264"
	 # puts "subfolder is #{subfolder}\n" 
	end
	puts "subfolder is #{subfolder}\n"
	#dest_folder = SiteInfo::FILE_SERVER.concat(subfolder)
	dest_folder = ""
	dest_folder = SiteInfo::FILE_SERVER + subfolder
	puts "destination folder is #{dest_folder}\n"
    transfer_server_files(@test_params.params_chan.input_file[0].to_s, dest_folder)
	#puts"build_test_libs is #{@test_params.params_chan.input_file[0].to_s} and var_build_test_libs_root is #{SiteInfo::NETWORK_REFERENCE_FILES_FOLDER}+#{subfolder}\n"
  end
  
   
  def transfer_server_files(test_file, test_file_root)
        put_file({'filename' => test_file, 'src_dir' => test_file_root, 'binary' => true})
  end
  
  def run_call_script
    puts "\n DMAI_Test_Script::run_call_script"
	test_completion_prompt = "End of application"
    @equipment['dut1'].send_cmd("cd #{@wince_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("call test.bat",test_completion_prompt,180)
	puts "Received test completion prompt\n"
  end
  
# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  @telnet_response = @equipment['dut1'].response
  puts "Response on telnet window is #{@telnet_response}\n"
end

def run_collect_performance_data
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
   if (@test_params.params_chan.codec[0].to_s == "h264enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.264'
	  
	elsif (@test_params.params_chan.codec[0].to_s == "mpeg4enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s +'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.mpeg4'
	  
	elsif (@test_params.params_chan.codec[0].to_s == "mpeg2enc")
	  output_file_name = @test_params.params_chan.input_file[0].to_s +'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'.m2v'
	
	end
	test_output_files = get_file({'filename'=>output_file_name,'src_dir'=>@test_params.params_chan.test_dir[0],'dst_dir'=>dest_dir,'binary'=>true})
	
	#std_out = get_std_output.split(/[\n\r]+/)
    @telnet_response.each_line {|l| 
	puts "each line is #{l}\n"
	if(l.scan(/Current Frequencies/).size>0)
	opm_info = l.split(/Current Frequencies:/)[1].split(/[\n\r]+/)[0]
	 puts "OPM is #{opm_info}\n"
    end	 
	
	}
	#output_log = @telnet_response
	#puts "Each line is #{current_line}\n"
  #end
  
  #output_log = @telnet_response
 
  @telnet_response.each_line {|current_line|
  
     #if (current_line.scan(/Usage:/).size>0)
	  # [FrameworkConstants::Result[:fail], "Please verify command-line"]
	  # exit
	 
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
	 #frame_time = frame_time.to_i
	 total_time_min = total_time.min()
	 total_time_max = total_time.max()
	 read_time_mean = get_mean(read_time)
	 #frame_time = frame_time.to_i
	 read_time_min = read_time.min()
	 read_time_max = read_time.max()
	 write_time_mean = get_mean(write_time)
	 #frame_time = frame_time.to_i
	 write_time_min = write_time.min()
	 write_time_max = write_time.max()
  perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MEAN "+dsp_load_mean.round(2).to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MIN "+dsp_load_min.to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MAX "+dsp_load_max.to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MEAN "+arm_load_mean.round(2).to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MIN "+arm_load_min.to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MAX "+arm_load_max.to_s+"%")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_FRAME_RATE "+fps_mean.round(2).to_s+" fps")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_TIME_BETWEEN_FRAMES "+time_between_frames_mean.round(2).to_s+" ms")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ENCODE_TIME "+encode_time_mean.round(2).to_s+" ms")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_BUFFER_COPY_TIME "+buffer_copy_time_mean.round(2).to_s+" ms")
   # perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ENCODE_FRAME_SIZE "+encode_frame_size_mean.round(2).to_s+" ms")
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
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tFrame Rate\n")
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
	ensure
    perf_log.close if perf_log
	
end

def run_determine_test_outcome
 # if File.exists?(File.join(@wince_temp_folder,'perf.log'))
 #   [FrameworkConstants::Result[:pass], "This test pass"]
 # else
    [FrameworkConstants::Result[:fail], "Please verify subjectively"]
  end



# This function is used to compute the mean value in an array
def get_mean(an_array)
  sum = 0
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
 # @equipment['dut1'].send_cmd("cd #{media_location_hash[@test_params.params_chan.media_location[0]]}",@equipment['dut1'].prompt)
 # @equipment['dut1'].send_cmd("del \/Q \*\.asf",@equipment['dut1'].prompt) 
 # @equipment['dut1'].send_cmd("del \/Q \*\.asf",@equipment['dut1'].prompt) 
  dest_dir = @wince_temp_folder
  #dest_dir = File.join(@wince_temp_folder,'video_encode')
  #dest_dir = File.join(dest_dir,"video_encode")
  #dest_dir = dest_dir+'\video_encode'
   if (!File.exist?(dest_dir))
    puts "Saw that video_encode in clean_delete_log_files folder does not exist and calling makedirs now\n"
    #File.makedirs(dest_dir)
	    Dir.mkdir(dest_dir)
   end
	 
	 puts "\n dest_dir is #{dest_dir}\n"
 #system("cd dest_dir")
  #system("del \/Q \\dest_dir\\\*\.tmp")
  puts "del \/Q #{dest_dir}\\*.tmp"
 system("del \/Q #{dest_dir}\\*.tmp")
end
