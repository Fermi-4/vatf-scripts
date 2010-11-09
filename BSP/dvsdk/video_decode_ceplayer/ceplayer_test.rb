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
	#media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
	#if (@test_params.params_chan.media_location[0] == "ram")
	#test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+ '/file'+' '+'\temp'+'\\'+@test_params.params_chan.video_input[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.codec[0].to_s+'_'+@test_params.params_chan.media_location[0]+'.asf'
	test_command = 'start '+@test_params.params_chan.cmdline[0] +' '+@test_params.params_chan.test_dir[0]+'\\'+@test_params.params_chan.input_file[0].to_s
	puts "test_command is #{test_command}\n"	
	#elsif (@test_params.params_chan.media_location[0] == "nand")
	#test_command = 'start'+' '+@test_params.params_chan.cmdline[0] +' '+'\\Mounted Volume'+'\\'+@test_params.params_chan.input_file[0].to_s
	#elsif (@test_params.params_chan.media_location[0] == "sd")
	 #   test_command = 'start'+' '+@test_params.params_chan.cmdline[0] +' '+'\\Storage Card'+'\\'+@test_params.params_chan.input_file[0].to_s
	#elsif (@test_params.params_chan.media_location[0] == "usb")
     #   test_command = 'start'+' '+@test_params.params_chan.cmdline[0] +' '+'\\Hard Disk'+'\\'+@test_params.params_chan.input_file[0].to_s
	#end
	#puts "test_command is #{test_command}\n"
	
	#cmdline=/auto /time 30000 /venc h264 /vin svideo /br 4000000  /cap 720x480@30 /file \/temp\svideo_4000000_720x480@30_h264.asf
 #{@test_params.params_chan.cmdline[0]} /auto /time #{@test_params.params_chan.time[0].to_s} /venc #{@test_params.params_chan.codec[0].to_s} /vin #{@test_params.params_chan.video_input[0].to_s} /br #{@test_params.params_chan.bitrate[0].to_s} #{@test_params.params_chan.preview[0].to_s == '0' ? '' : '/pv'} /cap #{@test_params.params_chan.resolution[0].to_s} /file \temp\#{@test_params.params_chan.video_input[0].to_s}_#{@test_params.params_chan.bitrate[0].to_s}_#{@test_params.params_chan.resolution[0].to_s}_#{@test_params.params_chan.codec[0].to_s}.asf 
    FileUtils.mkdir_p @wince_temp_folder
    in_file = File.new(File.join(@test_params.view_drive, @test_params.params_chan.shell_script[0]), 'r')
    raw_test_lines = in_file.readlines
    out_file = File.new(File.join(@wince_temp_folder, 'test.bat'),'w')
    raw_test_lines.each do |current_line|
      out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
    end
    in_file.close
    out_file.close
  end
 
 # def run_get_script_output
  # puts "\n cetk_test::run_get_script_output"
  # super("</TESTGROUP>")
# end

  # Transfer the shell script (test.bat) to the DUT and any require libraries
  def run_transfer_script()
    super
	if (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("avi") == 0)
	  subfolder = "/Multimedia/Video/AVI"
	  puts "subfolder is #{subfolder}\n"
	elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1].casecmp("3gp") == 0)
	  subfolder = "/Multimedia/Video/3GPP"
	  puts "subfolder is #{subfolder}\n"
	elsif (@test_params.params_chan.input_file[0].to_s.split('.')[1] .casecmp("mp4") == 0)
	  subfolder = "/Multimedia/Video/MP4"
	 puts "subfolder is #{subfolder}\n" 
	end
	puts "subfolder is #{subfolder}\n"
	#dest_folder = SiteInfo::FILE_SERVER.concat(subfolder)
	dest_folder = ""
	dest_folder = SiteInfo::FILE_SERVER + subfolder
	puts "destination folder is #{dest_folder}\n"
    transfer_server_files(@test_params.params_chan.input_file[0].to_s, dest_folder)
	puts"build_test_libs is #{@test_params.params_chan.input_file[0].to_s} and var_build_test_libs_root is #{SiteInfo::NETWORK_REFERENCE_FILES_FOLDER}+#{subfolder}\n"
  end
  
   
  def transfer_server_files(test_file, test_file_root)
        put_file({'filename' => test_file, 'src_dir' => test_file_root, 'binary' => true})
  end
  
  
    # # Collect output from standard output, standard error and serial port in test.log
  # def run_get_script_output(expect_string=nil)
    # puts "\n WinceTestScript::run_get_script_output"
    # wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
        # check_serial_port
		# puts "OUT of check_serial_port function\n"
		# counter = 0
		# while (counter < wait_time)
		# puts "waiting inside wait_time loop\n"
        # counter += 1
		# end
    # # make sure serial port log wont lost even there is ftp exception
    # begin
      # log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
      # log_file = File.new(log_file_name,'w')
      # get_file({'filename'=>'stderr.log'})
      # get_file({'filename'=>'stdout.log'})
      # #yliu: temp: save differnt test log to different files
      # std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
      # err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
      # std_output = std_file.read
      # std_error  = err_file.read
      # log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
      # log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    # rescue Exception => e
      # log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      # log_file.close
      # add_log_to_html(log_file_name)
      # # force dut reboot on next test case
      # @new_keys = ''
      # raise
    # end
      # log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"</SERIAL_OUTPUT>\n") 
      # log_file.close
      # add_log_to_html(log_file_name)
    # ensure
      # std_file.close if std_file
      # err_file.close if err_file
  # end
# # Collect output from standard output, standard error and serial port in test.log

# def check_serial_port(counter)
    # file_duration = (@test_params.params_chan.input_file[0].to_s.split("duration_")[1].split("_sec")[0]).to_s
    # #file_duration += 10
	# counter = 0
	# puts "Entering while loop in check_serial_port - file duration is #{file_duration}\n"
	# while (counter.to_s < file_duration)
	 # temp = (@serial_port_data.to_s).dup
	 # puts "temp is #{temp}\n"
	 # @serial_port_data = @equipment['dut1'].update_response('serial').to_s.dup
	 # @serial_port_data == temp
	 # puts "Serial port data is #{@serial_port_data}\n"
	 # counter += 1
	 # puts "Counter inside file_duration_counter is #{counter}\n"
	# end
# end

# aparna
# Collect output from standard output, standard error and serial port in test.log
  def run_get_script_output(expect_string=nil)
    puts "\n WinceTestScript from ceplayer_test ::run_get_script_output"
    wait_time = (@test_params.params_control.instance_variable_defined?(:@wait_time) ? @test_params.params_control.wait_time[0] : '10').to_i
    #keep_checking = @equipment['dut1'].target.serial ? true : false     # Do not try to get data from serial port of there is no serial port connection
    #puts "keep_checking is: "+keep_checking.to_s
	file_duration = (@test_params.params_chan.input_file[0].to_s.split("duration_")[1].split("_sec")[0]).to_i
    file_duration_counter = 0
    counter=0  
	playout_started=0
      check_serial_port()
	   start_time_of_test = Time.now
	   while(check_serial_port() && @serial_port_data.scan(/FPS=/).size == 0) 
	    #puts "Serial Data is #{@serial_port_data}\n"
	   end
	   stop_time_before_media_playout = Time.now
	   
	   puts "Time before media_playout is #{stop_time_before_media_playout - start_time_of_test}\n"
	   puts "About to start sleep  #{Time.now}\n"
	   sleep(file_duration)
	   puts "Completed sleep #{Time.now}\n"
	   @serial_port_data = ''
	   check_serial_port()
	  # while ( file_duration_counter < file_duration + 10)
	  #puts "OOOOOOOOOOOOOOOOOutside the first while loop\n"
        #puts "@serial_port_data is: \n"+@serial_port_data+"\nend of @serial_port_data"
        #wait for end of test
		# while(@serial_port_data.scan(/FPS=/).size > 0)
		  # #puts" ALERT1 we are inside the second while()\n"
		  # sleep(5)
		  # check_serial_port()
		    # # puts"ALERT2: Inside check for LPM_open\n"
		    # # startTime = Time.now
			# # puts "ALERT3: file_duration is #{file_duration}\n"
		    # # while (Time.now - startTime < file_duration+20)	
			   # # diff = Time.now - startTime
               # # puts "ALERT4: time now is #{Time.now} and startTime is #{startTime} and difference is #{diff}\n"			
			   # # check_serial_port		
		    # # end
			  # # puts "ALERT4: time now is #{Time.now} and startTime is #{startTime} and difference is #{diff}\n"
		# end
		# puts "OOOOOOOOOOOOOOOOOutside the second while loop\n"
		# check_serial_port()
		# if (playout_started == 1 || @serial_port_data.scan(/LPM_open/).size >0)
		   # puts "playout has started and we are inside the if condition\n"
		   # file_duration_counter += 1
		   # playout_started = 1
        # end
          
        # end
        #if not see expect_string, wait for timeout to prevent infinite loop
        # sleep 1
        # counter += 1
        # if counter >= wait_time
          # puts "\nDEBUG: Finished waiting for data from Serial Port, assumming that App ran to completion."  
          # keep_checking = false
          # break
        # end
      #end
    
    # make sure serial port log wont lost even there is ftp exception
    begin
    
      
	  
	    log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
      log_file = File.new(log_file_name,'w')
	  
	 
	  
      get_file({'filename'=>'stderr.log'})
      get_file({'filename'=>'stdout.log'})
      #yliu: temp: save differnt test log to different files
      std_file = File.new(File.join(@wince_temp_folder,'stdout.log'),'r')
      err_file = File.new(File.join(@wince_temp_folder,'stderr.log'),'r')
      std_output = std_file.read
      std_error  = err_file.read
      log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
     log_file.write("\n<ERR_OUTPUT>\n"+std_error+"</ERR_OUTPUT>\n")
    rescue Exception => e
      # force dut reboot on next test case
      @new_keys = ''
      raise
    end
      log_file.write("\n<SERIAL_OUTPUT>\n"+@serial_port_data.to_s+"\n"+"Time for ceplayer to start playing multimedia=#{stop_time_before_media_playout - start_time_of_test} sec\n"+"</SERIAL_OUTPUT>\n") 
	  log_file.write("Time for ceplayer to start playing multimedia=#{(stop_time_before_media_playout - start_time_of_test)*1000} ms\n")
      log_file.close
      add_log_to_html(log_file_name)
    ensure
      std_file.close if std_file
     err_file.close if err_file
	 puts "BBBBBBBBBBBBBBBBBBBBBBBefore exiting run_get_script_output\n"
  end
  
  def get_serial_output
    #check_serial_port
	puts "got serial output\n"
    @serial_port_data
	puts "got serial output end\n"
  end
# aparna


  def run_collect_performance_data
     media_location_hash = {'\Storage Card'=>"sd", '\Mounted Volume'=>"nand",'\Hard Disk'=>"usb",'\Temp'=>"ram"}
     dest_dir = @wince_temp_folder
	#dest_dir = dest_dir+'/video_encode'
	 dest_dir = File.join(dest_dir,"video_decode")
    
   if (!File.exist?(dest_dir))
    puts "Saw that video_decode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    #File.makedirs(dest_dir)
        Dir.mkdir(dest_dir)
   end
   #log_files = get_dir_files({'src_dir'=>'\Temp','dst_dir'=>dest_dir,'binary'=>true} )
    #test_output_files = get_dir_files({'src_dir'=>media_location_hash[@test_params.params_chan.media_location[0]],'dst_dir'=>dest_dir,'binary'=>true} )
	puts "Calling get_serial_output from run_collect_performance_data\n"
	#ser_out = get_serial_output.split(/[\n\r]+/)
	log_file_name = File.join(@wince_temp_folder, "test_#{@test_id}\.log")
    log_file = File.open(log_file_name,'r')
	ser_out = log_file.read()

	dsp_load_array = []
    arm_load_array = []
    video_fps_array = []
	audio_fps_array = []
    decode_time_array = []
    max_time_between_frames_to_renderer  = []
    buffer_copy_time_array = []
    decode_frame_size_array = []
	#ser_out = @serial_port_data.to_s.split(/[\n\r]+/)
	#puts "Ssssssssserial output is #{ser_out}\n"
	puts "......printing result of first scan\n"
	dsp_load = ser_out.scan(/Timm: DSP CPU Load=\d+/)
	arm_load = ser_out.scan(/Timm: ARM CPU Load=\d+/)
	#puts "VIDEO CODEC is #{@test_params.params_chan.dsp_video_codec[0].to_s}\n"
   # puts "AUDIO CODEC is #{@test_params.params_chan.dsp_audio_codec[0].to_s}\n"
	#video_codec = @test_params.params_chan.dsp_video_codec[0]
	#audio_codec = @test_params.params_chan.dsp_video_codec[0]
	
	video_decoder_FPS_data = ser_out.scan(/#{@test_params.params_chan.dsp_video_codec[0]}: FPS=\d+/i)
	puts "VIDEO parsing result is #{video_decoder_FPS_data}\n"
	if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
	audio_decoder_FPS_data = ser_out.scan(/#{@test_params.params_chan.dsp_audio_codec[0]}: FPS=\d+/i)
	
	puts "AUDIO parsing result is #{audio_decoder_FPS_data}\n"
	end
	frames_to_renderer_time_data = ser_out.scan(/renderer=\d+/)
	system_data = ser_out.scan(/Time for ceplayer to start playing multimedia=\d+\w+/)
	puts "System Data is #{system_data}\n"
	system_data = system_data[0].split(/=/)[1].to_s
	puts "System Data is #{system_data}\n"
	
	dsp_load.each do |dsp_result|
	 dsp_load_array << dsp_result.split(/=/)[1].to_f
	end
	arm_load.each do |arm_result|
	 arm_load_array << arm_result.split(/=/)[1].to_f
	end
    video_decoder_FPS_data.each do |fps_result|	
	 video_fps_array << fps_result.split(/=/)[1].to_f
    end
	
	if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
	audio_decoder_FPS_data.each do |fps_result|	
	 audio_fps_array << fps_result.split(/=/)[1].to_f
    end
	end
	
    frames_to_renderer_time_data.each do |time_result|
     max_time_between_frames_to_renderer << time_result.split(/=/)[1].to_f
	end
	#decoder_h264_data = ser_out.scan(/H264: \w+/)
	#decoder_mpeg4_data = ser_out.scan(/MPEG4: \w+/)
	#decoder_mpeg2_data = ser_out.scan(/MPEG2: \w+/)
	# if (decoder_h264_data.size>0)
	# puts "H264 data is #{decoder_h264_data}\n"
	# elsif (decoder_mpeg4_data.size>0)
	# puts "MPEG4 data is #{decoder_mpeg4_data}\n"
	# elsif (decoder_mpeg2_data.size>0)
	# puts "MPEG2 data is #{decoder_mpeg2_data}\n"
	# end
	#puts "DSP data is #{dsp_load_array.shift}\n"
	#puts "ARM data is #{arm_load_array.shift}\n"
	puts "Video FPS_data is #{video_fps_array}\n"
	if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
	puts "Audio FPS_data is #{audio_fps_array}\n"
	end
	puts "Time_data is #{max_time_between_frames_to_renderer}\n"
	puts "Calling get_std_output from run_collect_performance_data\n"
	std_out = get_std_output.split(/[\n\r]+/)
	dsp_count = 0
    arm_count = 0
	start_flag = 0
	stop_flag = 0
	start_count = 0
	arm_temp_count = 0
    opm_info = ""
    
    std_out.each do |current_line|
    if (current_line.scan(/Current Frequencies/).size>0)
     opm_info = current_line.split(/:/)[1]
	 puts "OPM is #{opm_info}\n"
    else
	 opm_info = "exception in do command"
    end	 
  end
  # ser_out.each do |current_line|
    # puts "Current line from ser_out is #{current_line}\n"
    # if (current_line.scan(/Timm: DSP CPU Load/).size >0)
	 # current_match = current_line.split(/Timm: DSP CPU Load=/)[1]
	   # while (start_flag == 0)
	    # if (current_match.split(/ /)[0].to_f == 0)
	     # start_count += 1
        # elsif(current_match.split(/ /)[0].to_f > 0)
	     # start_flag = 1
	    # end
	   # end
	   # while (start_flag == 1 && stop_flag == 0)
	    # if(current_match.split(/ /)[0].to_f > 0)
          # dsp_load_array << current_match.split(/ /)[0].to_f
	      # dsp_count += 1
	    # else
	      # stop_flag = 1
	      # stop_count = dsp_count
        # end
       # end
	 # # end
   
   # elsif (current_line.scan(/Timm: ARM CPU Load/).size >0)
    # arm_temp_count += 1
    # next if arm_temp_count<start_count
    # current_match = current_line.split(/Timm: ARM CPU Load=/)[1]
	# while (arm_count < stop_count)
	 # arm_count += 1
     # arm_load_array << current_match.split(/ /)[0].to_f
	# end
   # #end
   
   # elsif (current_line.scan(/MPEG2: /).size >0)  
    # if (current_line.split(/MPEG2: /)[1].scan(/FPS=/).size>0)   
    # temp = current_line.split(/MPEG2: /)[1].split(/FPS=/)[1]
	# puts "temp is #{temp}\n"
	# puts "fps_array is #{temp.split(/,/)[0]}\n"
	# fps_array << temp.split(/,/)[0].strip.to_f	
	# temp = temp.split(/=/)[1]
	# time_between_frames_array << temp.sub(/ms/,'').strip.to_f	
   # end
  # # end
  
  # elsif (current_line.scan(/H264: /).size >0)  
    # if (current_line.split(/H264: /)[1].scan(/FPS=/).size>0)   
    # temp = current_line.split(/H264: /)[1].split(/FPS=/)[1]
	# puts "temp is #{temp}\n"
	# puts "fps_array is #{temp.split(/,/)[0]}\n"
	# fps_array << temp.split(/,/)[0].strip.to_f	
	# temp = temp.split(/=/)[1]
	# time_between_frames_array << temp.sub(/ms/,'').strip.to_f	
   # end
  # #end
 
  # elsif (current_line.scan(/MPEG4: /).size >0)  
    # if (current_line.split(/MPEG4: /)[1].scan(/FPS=/).size>0)   
    # temp = current_line.split(/MPEG4: /)[1].split(/FPS=/)[1]
	# puts "temp is #{temp}\n"
	# puts "fps_array is #{temp.split(/,/)[0]}\n"
	# fps_array << temp.split(/,/)[0].strip.to_f	
	# temp = temp.split(/=/)[1]
	# time_between_frames_array << temp.sub(/ms/,'').strip.to_f	
    # end
  # end 
  # end
  
  video_fps_mean = get_mean(video_fps_array)
  video_fps_min = video_fps_array.min
  video_fps_max = video_fps_array.max
  
  if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
  audio_fps_mean = get_mean(audio_fps_array)
  audio_fps_min = audio_fps_array.min
  audio_fps_max = audio_fps_array.max
  end
  
  max_time_between_frames_mean = get_mean(max_time_between_frames_to_renderer)  
  max_time_between_frames_min = max_time_between_frames_to_renderer.min
  max_time_between_frames_max = max_time_between_frames_to_renderer.max
  perf_log = nil
  dsp_load_array.shift
  arm_load_array.shift
  puts "DSP data is #{dsp_load_array}\n"
  puts "ARM data is #{arm_load_array}\n"
  dsp_load_mean = get_mean(dsp_load_array)
  dsp_load_min = dsp_load_array.min
  dsp_load_max = dsp_load_array.max
  arm_load_mean = get_mean(arm_load_array)
  arm_load_min = arm_load_array.min
  arm_load_max = arm_load_array.max 
   perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_DSP_LOAD_MEAN "+dsp_load_mean.round(2).to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_DSP_LOAD_MIN "+dsp_load_min.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_DSP_LOAD_MAX "+dsp_load_max.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_ARM_LOAD_MEAN "+arm_load_mean.round(2).to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_ARM_LOAD_MIN "+arm_load_min.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_ARM_LOAD_MAX "+arm_load_max.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_VIDEO_FRAME_RATE_MEAN "+video_fps_mean.round(2).to_s+" fps")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_VIDEO_FRAME_RATE_MIN "+video_fps_min.round(2).to_s+" fps")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_VIDEO_FRAME_RATE_MAX "+video_fps_max.round(2).to_s+" fps")  
   if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_AUDIO_FRAME_RATE_MEAN "+audio_fps_mean.round(2).to_s+" fps")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_AUDIO_FRAME_RATE_MIN "+audio_fps_min.round(2).to_s+" fps")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_AUDIO_FRAME_RATE_MAX "+audio_fps_max.round(2).to_s+" fps")  
   end
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_MAX_TIME_BETWEEN_FRAMES_MEAN "+max_time_between_frames_mean.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_MAX_TIME_BETWEEN_FRAMES_MIN "+max_time_between_frames_min.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_MAX_TIME_BETWEEN_FRAMES_MAX "+max_time_between_frames_max.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.input_file[0].to_s+"_"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+"_MAX_TIME_BEFORE_MEDIA_PLAYOUT "+system_data.to_s+" ms") 
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"video_decode")

   if (!File.exist?(dest_dir))
    puts "Saw that video_decode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"ceplayer_worksheet.txt")
   #xls_file = File.open(File.join(dest_dir,"ceplayer_worksheet.txt"),'r')
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"ceplayer_worksheet.txt"),'a+')
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tVideo Frame Rate\tAudio Frame Rate\n")
	
	xls_file.puts("TestTime\tFileName\tMediaLocation\tOutputVideo\tOpmState\tARM_Load_Mean\tARM_Load_Min\tARM_Load_Max\tDSP_Load_Mean\tDSP_Load_Min\tDSP_Load_Max\tMean Video FrameRate\tMin Video FrameRate\tMax Video FrameRate\tMean FrameProcessingTime_in ms\tMin FrameProcessingTime_in ms\tMax FrameProcessingTime_in ms\tTimeBeforeMediaPlayout in s\tMean Audio FrameRate(only applicable for AAC)\tMin Audio FrameRate\tMax AudioFrameRate)\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"ceplayer_worksheet.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
   if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
   xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"\t"+@test_params.params_chan.video_output[0].to_s+"\t"+"#{opm_info}"+"\t"+arm_load_mean.round(2).to_s+"\t"+arm_load_min.round(2).to_s+"\t"+arm_load_max.round(2).to_s+"\t"+dsp_load_mean.round(2).to_s+"\t"+dsp_load_min.round(2).to_s+"\t"+dsp_load_max.round(2).to_s+"\t"+video_fps_mean.round(2).to_s+"\t"+video_fps_min.round(2).to_s+"\t"+video_fps_max.round(2).to_s+"\t"+max_time_between_frames_mean.round(2).to_s+"\t"+max_time_between_frames_min.round(2).to_s+"\t"+max_time_between_frames_max.round(2).to_s+"\t"+system_data.to_s+"\t"+audio_fps_mean.round(2).to_s+"\t"+audio_fps_min.round(2).to_s+"\t"+audio_fps_max.round(2).to_s)
   else
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.input_file[0].to_s+"\t"+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"\t"+@test_params.params_chan.video_output[0].to_s+"\t"+"#{opm_info}"+"\t"+arm_load_mean.round(2).to_s+"\t"+arm_load_min.round(2).to_s+"\t"+arm_load_max.round(2).to_s+"\t"+dsp_load_mean.round(2).to_s+"\t"+dsp_load_min.round(2).to_s+"\t"+dsp_load_max.round(2).to_s+"\t"+video_fps_mean.round(2).to_s+"\t"+video_fps_min.round(2).to_s+"\t"+video_fps_max.round(2).to_s+"\t"+max_time_between_frames_mean.round(2).to_s+"\t"+max_time_between_frames_min.round(2).to_s+"\t"+max_time_between_frames_max.round(2).to_s+"\t"+system_data.to_s)
	end
	
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"video_decode"+" for filename "+@test_params.params_chan.input_file[0].to_s+media_location_hash[@test_params.params_chan.test_dir[0]].to_s+"_"+@test_params.params_chan.video_output[0].to_s+"_"+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
    @results_html_file.add_row_to_table(res_table,["DSP_LOAD_MEAN",dsp_load_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["DSP_LOAD_MIN",dsp_load_min.to_s])
	@results_html_file.add_row_to_table(res_table,["DSP_LOAD_MAX",dsp_load_max.to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MEAN",arm_load_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MIN",arm_load_min.to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MAX",arm_load_max.to_s])
	@results_html_file.add_row_to_table(res_table,["VIDEO FRAME_RATE",video_fps_mean.round(2).to_s])
	if (@test_params.params_chan.instance_variable_defined?(:@dsp_audio_codec))
	@results_html_file.add_row_to_table(res_table,["AUDIO FRAME_RATE",audio_fps_mean.round(2).to_s])
	end
	@results_html_file.add_row_to_table(res_table,["TIME_BETWEEN_FRAMES (in ms)",max_time_between_frames_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["SYSTEM_TIME (in s)",system_data.to_s])
	xls_file.close
	ensure
    perf_log.close if perf_log
	puts "BBBBBBBBBBBBBBefore exiting collect_performance data\n"
end

def run_determine_test_outcome
  if File.exists?(File.join(@wince_temp_folder,'perf.log'))
    [FrameworkConstants::Result[:pass], "This test pass"]
  else
    [FrameworkConstants::Result[:pass], "This failed no performance data was collected"]
  end

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
  media_location_hash = {'\Storage Card'=>"sd", '\Mounted Volume'=>"nand",'\Hard Disk'=>"usb",'\Temp'=>"ram"}
  puts "\n WinceCetkPerfScript::clean_delete_log_files"
 # @equipment['dut1'].send_cmd("cd " @test_params.params_chan.test_dir[0],@equipment['dut1'].prompt)
 # @equipment['dut1'].send_cmd("del \/Q \*\.*",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("cd  #{@test_params.params_chan.test_dir[0]}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("del #{@test_params.params_chan.input_file[0]}",@equipment['dut1'].prompt) 
 # @equipment['dut1'].send_cmd("del \/Q \*\.asf",@equipment['dut1'].prompt) 
 # dest_dir = @wince_temp_folder
  #dest_dir = File.join(@wince_temp_folder,'video_encode')
  #dest_dir = File.join(dest_dir,"video_encode")
  #dest_dir = dest_dir+'\video_encode'
 #  if (!File.exist?(dest_dir))
 #   puts "Saw that video_encode in clean_delete_log_files folder does not exist and calling makedirs now\n"
    #File.makedirs(dest_dir)
#	    Dir.mkdir(dest_dir)
 #  end
	 
#	 puts "\n dest_dir is #{dest_dir}\n"
 #system("cd dest_dir")
  #system("del \/Q \\dest_dir\\\*\.tmp")
#  puts "del \/Q #{dest_dir}\\*.tmp"
# system("del \/Q #{dest_dir}\\*.tmp")
end
