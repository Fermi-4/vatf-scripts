require '../media_filer_utils'

include MediaFilerUtils

class DemoAppDecodeSubjectiveTestPlan < TestPlan
	# BEG_USR_CFG setup
  def setup()
	  @order = 2
	  @sort_by =  ['video_type:audio_type:speech_type', 'display_out']
	  @group_by = ['video_type:audio_type:speech_type', 'display_out']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  def get_params()
	  @signal_format_max_res = {
        '525' => [720,480],
        '625' => [720,576], 
        '720p50' => [1280,720],
        '720p59' => [1280,720],
        '720p60' => [1280,720],        
        '1080i50' => [1920,1080],
        '1080i60' => [1920,1080],
	  }
  	@h264_prof_regex = "_(BP|MP)\\w*"
    @mpeg4_prof_regex =  "_(ASP|SP)\\w*"
    @mpeg2_prof_regex =  "_(SP|MP)\\w*"
    @aac_file_format = "_(RAW|ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
    params = {
        'enable_osd'				=> ['yes', 'no'],
        'enable_keyboard'		=> ['yes', 'no'],
        'enable_remote'			=> ['yes', 'no'],
        'enable_frameskip'	=> ['yes', 'no'],
        'time'							=> ['20'],
        # Video-Related
        'video_type'					=> ['off',  'mpeg2', 'mpeg4', 'h264'],
        'video_resolution'		=> ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480', '704x576', '800x600', '1024x768', '1280x720', '1280x960', '1920x1080'],
        'video_bit_rate'	    => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000],
        'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
        'display_out'					=> ['composite', 'component', 'svideo'],
        #Speech-Related
        'speech_type' 			=> ['off', 'g711'],
        'speech_companding'	=> ['ulaw', 'alaw'],
        # Audio-Related
        'audio_type' 					=> ['off', 'aac', 'mp3', 'mp2', 'mp1'],
        'audio_sampling_rate' => [8000, 11000, 12000, 16000, 22000, 24000, 32000, 44000, 48000, 88000],
				'audio_bit_rate' 			=> [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
		
    }
      file_sampling_rate = Array.new
	  params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << sampling_rate/1000}
	  file_bit_rate = Array.new
	  params['audio_bit_rate'].each do |bit_rate| 
		if bit_rate.to_s.strip.downcase != 'vbr'
			file_bit_rate << (bit_rate/1000).to_s+"kbps"
		else
			file_bit_rate << bit_rate
		end
	  end
	  @aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*_",file_bit_rate,"\\w*",@aac_file_format,"aac")
	
      @mpx_audio_source_hash = Hash.new
      params['audio_type'].each do |mp_type|
          @mpx_audio_source_hash[mp_type] = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*_",file_bit_rate,"\\w*",mp_type) if /mp\d/.match(mp_type)
      end
	  audio_sampling_rate_and_bit_rate =	[{
            'audio_sampling_rate' => [8000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [11000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [12000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [16000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [22000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [24000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [32000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [44000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [48000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
      {
            'audio_sampling_rate' => [88000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
      },
       ]
	  combine_sampling_rate_and_bit_rate(params, audio_sampling_rate_and_bit_rate)
	 
	  file_bit_rate = Array.new
    params['video_bit_rate'].each do |bit_rate| 
    if bit_rate/1000 >= 1000
       file_bit_rate << ((bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
       file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
       file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
    end 
    end
    @h264_video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_","\\w*",params['video_bit_rate'],"bps","264")
    @h264_video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],@h264_prof_regex,file_bit_rate,"[\\w\.]*","264"))
    @mpeg4_video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_","\\w*",params['video_bit_rate'],"bps","mpeg4")
    @mpeg4_video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],@mpeg4_prof_regex,file_bit_rate,"[\\w\.]*","mpeg4"))
    @mpeg2_video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_","\\w*",params['video_bit_rate'],"bps","m2v")
    @mpeg2_video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],@mpeg2_prof_regex,file_bit_rate,"[\\w\.]*","m2v"))
    @ulaw_speech_source_hash = get_source_files_hash("\\w+","u")
	@alaw_speech_source_hash = get_source_files_hash("\\w+","a")
		video_res_and_bit_rates = [
    {'video_resolution' => ["128x96"],
           'video_bit_rate' =>  [64000],	
           },
    {'video_resolution' => ["176x144"],
           'video_bit_rate' =>  [64000,96000,128000,256000,512000]	
           },
    {'video_resolution' => ["320x240"],
		       'video_bit_rate' =>  [256000,512000,768000,1000000,1500000]	
	         },
    {'video_resolution' => ["352x240"],
		       'video_bit_rate' =>  [64000,96000,128000,256000,384000,512000,768000,1000000,1500000,2000000]	
	         },
    {'video_resolution' => ["352x288"],
		       'video_bit_rate' =>  [64000,256000,384000,512000,768000,1000000,2000000]	
	         },
    {'video_resolution' => ["640x480"],
		       'video_bit_rate' =>  [512000,1000000,2000000,4000000]	
	         },
    {'video_resolution' => ["704x480"],
		       'video_bit_rate' =>  [256000,512000,1000000,2000000,3000000,4000000,8000000,10000000]	
	         },
    {'video_resolution' => ["720x480"],
		       'video_bit_rate' =>  [128000,256000,384000,512000,1000000,2000000,3000000,4000000,6000000,8000000,10000000]	
	         },
    {'video_resolution' => ["704x576"],
		       'video_bit_rate' =>  [128000,256000,384000,512000,1000000,2000000,3000000,4000000,6000000,8000000,10000000]	
	         },
    {'video_resolution' => ["720x576"],
		       'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000]	
	         },
    {'video_resolution' => ['800x600'],
		       'video_bit_rate' =>  [1000000,2000000,4000000,7000000,10000000,11000000,12000000,14000000,15000000]	
	         },
    {'video_resolution' => ['1024x768'],
		       'video_bit_rate' =>  [1000000,2000000,4000000,8000000,10000000,11000000,12000000,14000000,15000000]		
	         },
    {'video_resolution' => ['1280x720'],
		       'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]		
	         },
    {'video_resolution' => ['1280x960'],
		       'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]		
	         },
    {'video_resolution' => ['1920x1080'],
		       'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]		
	         },
    ]
    @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
     const_hash = {}
     const_hash.default = []
     @res_params['video_resolution_and_bit_rate'].each do |bitrate_res|
         resolution = (bitrate_res.strip.split("_")[0]).split('x')
         @res_params['video_signal_format'].each do |format|
             if @signal_format_max_res[format] && (@signal_format_max_res[format][0] < resolution[0].to_i || @signal_format_max_res[format][1] < resolution[1].to_i)
                 const_hash[format] = const_hash[format]|[bitrate_res]
             end
         end
     end
     format_constraints = Array.new
     const_hash.each do |format,bitrate_res|
         current_group ='"'+bitrate_res[0]+'"'
         1.upto(bitrate_res.length-1){|i| current_group+=', "'+bitrate_res[i]+'"'}
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [video_resolution_and_bit_rate] NOT IN {'+ current_group +'};'
     end
     
      mponly_samp_and_bit_rate = ''
     @res_params['audio_sampling_rate_and_bit_rate'].each do |sampling_br|
         if sampling_br.downcase.include?('vbr')
             mponly_samp_and_bit_rate += ', ' if mponly_samp_and_bit_rate != ''
             mponly_samp_and_bit_rate += '"'+sampling_br+'"'
         end
     end
     format_constraints << 'IF [audio_type] <> "mp3" THEN [audio_sampling_rate_and_bit_rate] NOT IN {' + mponly_samp_and_bit_rate +'};' if mponly_samp_and_bit_rate != '' 
    format_constraints | [
      'IF [video_type] = "off" THEN [video_resolution_and_bit_rate] = "128x96_64000";',
      'IF [speech_type] <> "off" THEN [audio_type] = "off";',
      'IF [display_out] IN {"composite","svideo"} THEN [video_signal_format] IN {"525", "625", "vga"};',
      'IF [display_out] IN {"composite","svideo","component"} THEN [video_signal_format] <> "dummy";'	# Dummy constraint to remove dummy video signal format. The dummy is required for PICT
     ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
     {
	     'testcaseID'  	=> "Decode_.#{@current_id}",
	     'description' 	=> get_test_description(params),
	     'iter' 		=> '1',
		   'bft' 			=> true,
		   'basic' 		=> true,
		   'ext' 			=> false,
		   'bestFinal' 	=> true,
		   'reg'       	=> true,
		   'auto'			=> true,
		   'script'		=> 'Common\A-DEMO\demo_app_decode_subjective.rb',
		   'configID' 	=> '..\Config\demo_app_subjective.ini',
		   'paramsChan' 	=> {
          'time'								=> params['time'],
          'enable_osd'					=> params['enable_osd'],
          'enable_keyboard'			=> params['enable_keyboard'],
          'enable_remote'				=> params['enable_remote'],
          'enable_frameskip'		=> params['enable_frameskip'],
          # Video-Related
          'video_type'					=> params['video_type'],
          'video_source'      	=> get_video_source(params),
          'video_bitrate'				=> get_video_bit_rate(params),
          'video_resolution'		=> get_video_resolution(params),
          'video_signal_format'	=> params['video_signal_format'],
          'display_out'					=> params['display_out'],
          # Audio-Related
          'audio_source' 				=> get_audio_source(params),
          'audio_bit_rate'			=> get_bit_rate(params),
          'audio_sampling_rate'	=> get_sampling_rate(params),
          # Speech-Related
          'speech_source' 			=> get_speech_source(params),
          'speech_companding'		=> params['speech_companding'],
       },
		   'paramsEquip' 	=> {},
		   'paramsControl'=> {},
     }
   end
  # END_USR_CFG get_outputs
  
  private
  def get_video_source(params)
    return 'none' if params['video_type'] == 'off'
    video_resolution = get_video_resolution(params)
    video_bit_rate = get_video_bit_rate(params)
    if video_bit_rate.to_f/1000 >= 1000
      file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
      file_bit_rate2 = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
    	file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
    end 
    video_source_hash = self.instance_variable_get("@#{params['video_type']}_video_source_hash")
    video_prof_regex  = self.instance_variable_get("@#{params['video_type']}_prof_regex")
    video_source = video_source_hash["\\w+"+video_resolution+"_"+"\\w*"+video_bit_rate+"bps"]
    video_source += ";" if video_source && video_source_hash["\\w+"+video_resolution+video_prof_regex+file_bit_rate+"[\\w\.]*"]
    video_source = video_source.to_s + video_source_hash["\\w+"+video_resolution+video_prof_regex+file_bit_rate+"[\\w\.]*"].to_s
    video_source += ";" if video_source.to_s.strip != '' && file_bit_rate2 && video_source_hash["\\w+"+video_resolution+video_prof_regex+file_bit_rate2+"[\\w\.]*"] 
    video_source = video_source.to_s + video_source_hash["\\w+"+video_resolution+video_prof_regex+file_bit_rate2+"[\\w\.]*"].to_s if file_bit_rate2
    video_source
  end
  
  def get_speech_source(params)
    return 'none' if params['speech_type'] == 'off'
	  if params['speech_companding'].eql?("ulaw")
	  	@ulaw_speech_source_hash["\\w+"]
    elsif params['speech_companding'].eql?("alaw")
	  	@alaw_speech_source_hash["\\w+"]
    end
	end
  
  def get_audio_source(params)
    return 'none' if params['audio_type'] == 'off'
    audio_sampling = get_sampling_rate(params).strip
    audio_sampling = (audio_sampling.to_i/1000).to_s
    audio_bit_rate = get_bit_rate(params).strip
    audio_bit_rate = (audio_bit_rate.to_i/1000).to_s+"kbps" if audio_bit_rate.strip.downcase != 'vbr' 
    if params['audio_type'].match(/mp\d/)
    	audio_source = @mpx_audio_source_hash[params['audio_type']]["\\w+_"+audio_sampling+"kHz\\w*_"+audio_bit_rate+"\\w*"]
    else
        audio_source = @aac_audio_source_hash["\\w+_"+audio_sampling+"kHz\\w*_"+audio_bit_rate+"\\w*"+@aac_file_format]
    end
    audio_source
  end
  
  def combine_res_and_bit_rate(dst_hash, array_of_hash=nil)
      result = Array.new
      array_of_hash = [{'video_bit_rate' => dst_hash['video_bit_rate'], 'video_resolution' => dst_hash['video_resolution']}] if !array_of_hash
      array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
      array_of_hash.each do |val_hash|
          val_hash['video_resolution'].each do |video_resolution|
              val_hash['video_bit_rate'].each do |video_bit_rate|
              	result << video_resolution.to_s+"_"+video_bit_rate.to_s
              end
          end
      end
      dst_hash.delete('video_resolution')
      dst_hash.delete('video_bit_rate')
      dst_hash.merge!({'video_resolution_and_bit_rate' => result})
      dst_hash
  end
  
  def combine_sampling_rate_and_bit_rate(dst_hash, array_of_hash=nil)
      result = Array.new
      array_of_hash = [{'audio_bit_rate' => dst_hash['audio_bit_rate'], 'audio_sampling_rate' => dst_hash['audio_sampling_rate']}] if !array_of_hash
      array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
      array_of_hash.each do |val_hash|
          val_hash['audio_sampling_rate'].each do |audio_s_rate|
              val_hash['audio_bit_rate'].each do |audio_bit_rate|
              	result << audio_s_rate.to_s+"_"+audio_bit_rate.to_s
              end
          end
      end
      dst_hash.delete('audio_sampling_rate')
      dst_hash.delete('audio_bit_rate')
      dst_hash.merge!({'audio_sampling_rate_and_bit_rate' => result})
      dst_hash
  end
  
  def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_sampling_rate(params)
		params['audio_sampling_rate_and_bit_rate'].split('_')[0]
  end
  
  def get_bit_rate(params)
		params['audio_sampling_rate_and_bit_rate'].split('_')[1]
  end
  
  def get_test_description(params)
      "Decode demo test with Video #{get_test_description_video(params)} : Speech #{get_test_description_speech(params)} : Audio #{get_test_description_audio(params)}"
  end
  
  def get_test_description_video(params)
      if params['video_type'] == 'off'
          "disabled"
      else
          "#{params['video_type']} codec, #{get_video_resolution(params)} resolution, #{get_video_bit_rate(params)} bitrate"
      end
      
  end
  
  def get_test_description_audio(params)
      if params['audio_type'] == 'off'
          "disabled"
      else
          "#{params['audio_type']} codec, #{get_sampling_rate(params)} samplerate, #{get_bit_rate(params)} bitrate"
      end
      
  end
  
  def get_test_description_speech(params)
      if params['speech_type'] == 'off'
          "disabled"
      else
          "#{params['speech_type']} codec"
      end
  end
  
  
  
end