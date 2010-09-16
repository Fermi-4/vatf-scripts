require File.dirname(__FILE__)+'/../../default_test'

include WinceTestScript
    media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
def setup_connect_equipment
    puts "WinceTestScript::setup_connect_equipment"
	#======================== Equipment Connections ====================================================
	myhash = {"av" => "composite", "ypbpr" =>"component","svideo" => "svideo"}
	
	#@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}}, {@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0}}) #, @equipment["tv0"] => {@test_params.params_chan.video_input[0] => 0}}) 
	@connection_handler.make_video_connection({@equipment[@test_params.params_chan.media_source[0]] => {myhash[@test_params.params_chan.video_input[0]] => 0}}, {@equipment["dut1"] => {myhash[@test_params.params_chan.video_input[0]] => 0} , @equipment["tv0"] => {myhash[@test_params.params_chan.video_input[0]] => 0}}) 
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
	if (@test_params.params_chan.preview[0].to_s == '0')
	 preview_option=''
	else
	preview_option = '/pv'
	end
		output_filename =  @test_params.params_chan.video_input[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.codec[0].to_s+'_'+@test_params.params_chan.media_location[0]+'.asf'
	if (@test_params.params_chan.media_location[0] == "ram")

	#test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+ '/file'+' '+'\temp'+'\\'+@test_params.params_chan.video_input[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.codec[0].to_s+'_'+@test_params.params_chan.media_location[0]+'.asf'
	test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+ '/file'+' '+'\temp'+'\\'+output_filename
	puts "test_command is #{test_command}\n"
	
	elsif (@test_params.params_chan.media_location[0] == "nand")
	test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+'/nand'+' '+'/file'+' '+output_filename
	elsif (@test_params.params_chan.media_location[0] == "sd")
		test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+'/sd'+' '+'/file'+' '+output_filename
	elsif (@test_params.params_chan.media_location[0] == "usb")
		test_command = @test_params.params_chan.cmdline[0]+' '+'/auto'+' '+'/time'+' '+@test_params.params_chan.time[0].to_s+' '+'/venc'+' '+@test_params.params_chan.codec[0].to_s+' '+ '/vin'+' '+@test_params.params_chan.video_input[0].to_s+' '+ '/br'+' '+@test_params.params_chan.bitrate[0].to_s+' '+preview_option+' '+ '/cap'+' '+ @test_params.params_chan.resolution[0].to_s+' '+'/usb'+' '+'/file'+' '+output_filename
	end
	
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
  
# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def run_collect_performance_data
     media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
    dest_dir = @wince_temp_folder
	#dest_dir = dest_dir+'/video_encode'
	  dest_dir = File.join(dest_dir,"video_encode")
    
   if (!File.exist?(dest_dir))
    puts "Saw that video_encode folder does not exist in run_collect_performance_data and calling makedirs now\n"
    #File.makedirs(dest_dir)
        Dir.mkdir(dest_dir)
   end
   if (@test_params.params_chan.preview[0].to_s == '0')
	 preview_option=''
	else
	preview_option = '/pv'
	end
	log_files = get_dir_files({'src_dir'=>'\Temp','dst_dir'=>dest_dir,'binary'=>true} )
    #test_output_files = get_dir_files({'src_dir'=>media_location_hash[@test_params.params_chan.media_location[0]],'dst_dir'=>dest_dir,'binary'=>true} )
    output_filename = @test_params.params_chan.video_input[0].to_s+'_'+@test_params.params_chan.bitrate[0].to_s+'_'+@test_params.params_chan.resolution[0].to_s+'_'+@test_params.params_chan.codec[0].to_s+'_'+@test_params.params_chan.media_location[0]+'.asf'
	test_output_files = get_file({'filename'=>output_filename,'src_dir'=>media_location_hash[@test_params.params_chan.media_location[0]],'dst_dir'=>dest_dir,'binary'=>true})
	
	ser_out = get_serial_output.split(/[\n\r]+/)
	std_out = get_std_output.split(/[\n\r]+/)
	dsp_count = 0
    arm_count = 0
    opm_info = ""
    dsp_load_array = []
    arm_load_array = []
    fps_array = []
    encode_time_array = []
    time_between_frames_array = []
    buffer_copy_time_array = []
    encode_frame_size_array = []
    std_out.each do |current_line|
    if (current_line.scan(/Current Frequencies/).size>0)
     opm_info = current_line.split(/:/)[1]
	 puts "OPM is #{opm_info}\n"
    else
	 opm_info = "exception in do command"
    end	 
  end
  ser_out.each do |current_line|
    if (current_line.scan(/Timm: DSP CPU Load/).size >0)
     dsp_count += 1
    next if dsp_count<2
    current_match = current_line.split(/Timm: DSP CPU Load=/)[1]
    dsp_load_array << current_match.split(/ /)[0].to_f
   end
   
   if (current_line.scan(/Timm: ARM CPU Load/).size >0)
    arm_count += 1
    next if arm_count<2
    current_match = current_line.split(/Timm: ARM CPU Load=/)[1]
    arm_load_array << current_match.split(/ /)[0].to_f
   end
   
   if (current_line.scan(/Encoder: Avg/).size >0)  
    if (current_line.split(/Encoder: Avg./)[1].scan(/fps =/).size>0)   
    temp = current_line.split(/Encoder: Avg./)[1].split(/fps =/)[1]
	else
	temp = current_line.split(/Encoder: Avg./)[1].split(/fps=/)[1]
	end
	puts "temp is #{temp}\n"
	puts "fps_array is #{temp.split(/,/)[0]}\n"
	fps_array << temp.split(/,/)[0].strip.to_f	
	temp = temp.split(/ frames =/)[1]
	time_between_frames_array << temp.split(/,/)[0].sub(/ms/,'').strip.to_f
	if (temp.scan(/encode =/).size>0)
	temp = temp.split(/encode =/)[1]
	else
	temp = temp.split(/encode=/)[1]
	end
	encode_time_array << temp.split(/,/)[0].sub(/ms/,'').strip.to_f
	if (temp.scan(/buffer copy =/).size>0)
	temp = temp.split(/buffer copy =/)[1]
	else
	temp = temp.split(/buffer copy=/)[1]
	end
	buffer_copy_time_array << temp.split(/,/)[0].sub(/ms/,'').strip.to_f
    if (temp.scan(/enc frame size =/).size > 0)	
	encode_frame_size_array << temp.split(/enc frame size =/)[1].strip.to_f	
    else
	encode_frame_size_array << temp.split(/enc frame size=/)[1].strip.to_f
	end
   end
	
  end
 
  fps_mean = get_mean(fps_array)
  time_between_frames_mean = get_mean(time_between_frames_array)  
  encode_time_mean = get_mean(encode_time_array)  
  buffer_copy_time_mean = get_mean(buffer_copy_time_array)  
  encode_frame_size_mean = get_mean(encode_frame_size_array)
  perf_log = nil
  dsp_load_mean = get_mean(dsp_load_array)
  dsp_load_min = dsp_load_array.min
  dsp_load_max = dsp_load_array.max
  arm_load_mean = get_mean(arm_load_array)
  arm_load_min = arm_load_array.min
  arm_load_max = arm_load_array.max 
   perf_log = File.new(File.join(@wince_temp_folder,'perf.log'),'w')
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MEAN "+dsp_load_mean.round(2).to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MIN "+dsp_load_min.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_DSP_LOAD_MAX "+dsp_load_max.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MEAN "+arm_load_mean.round(2).to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MIN "+arm_load_min.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ARM_LOAD_MAX "+arm_load_max.to_s+"%")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_FRAME_RATE "+fps_mean.round(2).to_s+" fps")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_TIME_BETWEEN_FRAMES "+time_between_frames_mean.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ENCODE_TIME "+encode_time_mean.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_BUFFER_COPY_TIME "+buffer_copy_time_mean.round(2).to_s+" ms")
   perf_log.puts(@test_params.params_chan.cmdline[0].gsub(/\.exe$/,'')+"_"+@test_params.params_chan.codec[0].to_s+"_"+@test_params.params_chan.bitrate[0].to_s+"_bps_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+"_ENCODE_FRAME_SIZE "+encode_frame_size_mean.round(2).to_s+" ms")
   @results_html_file.add_paragraph("")
   dest_dir = @wince_temp_folder
   dest_dir = File.join(dest_dir,"video_encode")

   if (!File.exist?(dest_dir))
    puts "Saw that video_encode folder does not exist and calling makedirs now\n"
    Dir.mkdir(dest_dir)
   end
   file_name = File.join(dest_dir,"capturetest_worksheet.txt")
   #xls_file = File.open(File.join(dest_dir,"capturetest_worksheet.txt"),'r')
   if (!File.exist?(file_name))
    puts "file did not exist and hence, creating one\n"
    xls_file = File.new(File.join(dest_dir,"capturetest_worksheet.txt"),'a+')
	#xls_file.puts("Test Time\t\t\tDescription\t\t\tOpm State\t\t\tARM Load\tDSP Load\tFrame Rate\n")
	xls_file.puts("TestTime\tCodec\tBitRate\tResolution\tInputVideo\tOpmState\tARM_Load\tDSP_Load\tFrameRate\tMediaLocation\n")
	xls_file.close
   end
   
   xls_file = File.open(File.join(dest_dir,"capturetest_worksheet.txt"),'a+') 
   time_of_test = (Time.now).strftime("%m_%d_%Y_%H_%M_%S")
    xls_file.puts("#{time_of_test}\t"+@test_params.params_chan.codec[0].to_s+"\t"+@test_params.params_chan.bitrate[0].to_s+"_bps\t"+@test_params.params_chan.resolution[0].to_s+"\t"+@test_params.params_chan.video_input[0].to_s+"\t"+"#{opm_info}"+"\t"+arm_load_mean.round(2).to_s+"\t"+dsp_load_mean.round(2).to_s+"\t"+fps_mean.round(2).to_s+"\t"+@test_params.params_chan.media_location[0].to_s)
	res_table = @results_html_file.add_table([[@test_params.params_chan.cmdline[0]+"video_encode"+" for codec "+@test_params.params_chan.codec[0].to_s+" bitrate (bps) "+@test_params.params_chan.bitrate[0].to_s+"_"+@test_params.params_chan.resolution[0].to_s+"_"+@test_params.params_chan.video_input[0].to_s+"_"+@test_params.params_chan.media_location[0].to_s+" performance",{:bgcolor => "336666", :colspan => "2"},{:color => "white"}]],{:border => "1",:width=>"20%"})
    @results_html_file.add_row_to_table(res_table,["OPM_INFO",opm_info])
    @results_html_file.add_row_to_table(res_table,["DSP_LOAD_MEAN",dsp_load_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["DSP_LOAD_MIN",dsp_load_min.to_s])
	@results_html_file.add_row_to_table(res_table,["DSP_LOAD_MAX",dsp_load_max.to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MEAN",arm_load_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MIN",arm_load_min.to_s])
	@results_html_file.add_row_to_table(res_table,["ARM_LOAD_MAX",arm_load_max.to_s])
	@results_html_file.add_row_to_table(res_table,["FRAME_RATE",fps_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["TIME_BETWEEN_FRAMES",time_between_frames_mean.round(2).to_s])
    @results_html_file.add_row_to_table(res_table,["ENCODE_TIME",encode_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["BUFFER_COPY_TIME",buffer_copy_time_mean.round(2).to_s])
	@results_html_file.add_row_to_table(res_table,["ENCODE_FRAME_SIZE",encode_frame_size_mean.round(2).to_s])
	xls_file.close
	ensure
    perf_log.close if perf_log
	
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
  media_location_hash = {"sd" => '\Storage Card', "nand" =>'\Mounted Volume',"usb" => '\Hard Disk',"ram" => '\Temp'}
  puts "\n WinceCetkPerfScript::clean_delete_log_files"
  @equipment['dut1'].send_cmd("cd \\Temp",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("del \/Q \*\.*",@equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("cd #{media_location_hash[@test_params.params_chan.media_location[0]]}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("del \/Q \*\.asf",@equipment['dut1'].prompt) 
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
