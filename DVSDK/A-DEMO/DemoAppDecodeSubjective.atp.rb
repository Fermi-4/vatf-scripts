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
        '1080p50' => [1920,1080],
        '1080p60' => [1920,1080],
        '1080p25' => [1920,1080],
        '1080p30' => [1920,1080],  
	  }
    media_extension = {'mpeg2' => 'm2v',
                       'mpeg4' => 'mpeg4',
                       'h264' => '264' }
    @prof_regex = {'mpeg2' => "_(SP|MPp)\\w*",
                       'mpeg4' => "_(ASP|SP)\\w*",
                       'h264' => "_(BP|MP)\\w*" }
    @aac_file_format = "_(RAW|ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
    params = {
        'enable_osd'				=> ['yes', 'no'],
        'enable_keyboard'		=> ['yes', 'no'],
        'enable_remote'			=> ['yes', 'no'],
        'enable_frameskip'	=> ['yes', 'no'],
        'time'							=> ['20'],
        # Video-Related
        'video_type'					=> ['off',  'mpeg2', 'mpeg4', 'h264'],
        'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
        'display_out'					=> ['composite', 'component', 'svideo'],
        #Speech-Related
        'speech_type' 			=> ['off', 'g711'],
        'speech_companding'	=> ['ulaw', 'alaw'],
        # Audio-Related
        'audio_type' 					=> ['off', 'aac', 'mp3', 'mp2', 'mp1'],		
    }
    
	  audio_sampling_rate_and_bit_rate =	[{
            'audio_sampling_rate' => [8000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [11000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [12000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [16000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [22000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [24000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [32000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [44000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [48000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
      {
            'audio_sampling_rate' => [88000],
            'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
      },
       ]
    
    audio_sampling_rates = []
    audio_bitrates = []
    audio_sampling_rate_and_bit_rate.each do |samp_br| 
      audio_sampling_rates = audio_sampling_rates | samp_br['audio_sampling_rate']
      audio_bitrates = audio_bitrates | samp_br['audio_bit_rate']
    end
    file_bit_rate = []
    audio_bitrates.each do |audio_br|
      if audio_br.to_s.downcase.strip == 'vbr'
        file_bit_rate << 'vbr'
      else
        file_bit_rate << ((audio_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
      end
    end
    @mpx_audio_source_hash = {}
    @aac_audio_source_hash = get_source_files_hash("\\w+_",audio_sampling_rates,"kHz\\w*_",file_bit_rate,"\\w*",@aac_file_format,"aac")
    params['audio_type'].each do |mp_type|
      @mpx_audio_source_hash[mp_type] = get_source_files_hash("\\w+_",audio_sampling_rates,"kHz\\w*_",file_bit_rate,"\\w*",mp_type) if /mp\d/.match(mp_type)
    end
	  combine_sampling_rate_and_bit_rate(params, audio_sampling_rate_and_bit_rate)
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
    
    video_resolutions = []
    video_bitrates = []
    video_res_and_bit_rates.each do |res_br| 
      video_resolutions = video_resolutions | res_br['video_resolution']
      video_bitrates = video_bitrates | res_br['video_bit_rate']
    end
    file_bit_rate = []
    video_bitrates.each do |video_br|
      if video_br.to_f/1000 >= 1000
        file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
        file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
      else
        file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
      end
    end
    @video_source_hash = {}
    params['video_type'].each do |vtype|
      @video_source_hash[vtype] = get_source_files_hash("\\w*",video_resolutions,"\\w*",@prof_regex[vtype],"\\w*",file_bit_rate,"\\w*frames",media_extension[vtype])
    end    
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
		   'script'    =>  'DVSDK/A-DEMO/demo_app_decode_subjective.rb',
		   'configID' 	=> '../Config/demo_app_subjective.ini',
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
    video_br = get_video_bit_rate(params)
    if video_br.to_f/1000 >= 1000
      file_bit_rate = ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
      file_bit_rate2 = ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
      file_bit_rate = ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
    end
    result = ''
    result = @video_source_hash[params['video_type']]["\\w*"+video_resolution+"\\w*"+@prof_regex[params['video_type']]+"\\w*"+file_bit_rate2+"\\w*frames"].to_s if file_bit_rate2
    result += ';' if result != ''
    result += @video_source_hash[params['video_type']]["\\w*"+video_resolution+"\\w*"+@prof_regex[params['video_type']]+"\\w*"+file_bit_rate+"\\w*frames"].to_s
    result
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