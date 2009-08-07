require '../media_filer_utils'

include MediaFilerUtils

class DemoAppEncodeSubjectiveTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by =  ['video_input:display_out', 'command_name', 'video_type','video_resolution_and_bit_rate']
	@group_by = ['video_input:display_out', 'command_name', 'video_type','video_resolution_and_bit_rate']
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
      params = {
          'command_name'		=> ['encode', 'encodedecode', 'multi_encode'],
          'media_source'		=> ['camera', 'dvd'],
          'disable_deinterlace'	=> ['yes', 'no'],
          'enable_osd'			=> ['yes', 'no'],
          'enable_keyboard'		=> ['yes', 'no'],
          'enable_remote'		=> ['yes', 'no'],
          'passthrough'			=> ['yes', 'no'],
          'time'				=> ['20'],
          # Video-Related
          'video_type'			=> ['off',  'mpeg2', 'mpeg4', 'h264'],
          'video_input'			=> ['composite', 'svideo', 'component'],
          'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
          'display_out'			=> ['composite', 'component', 'svideo'],
          # Image-Related
          'image_type' 			=> ['off', 'jpeg'],
          'image_resolution'	=> ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480', '704x576', '800x600', '1024x768', '1280x720', '1280x960', '1920x1080'],
          'image_qvalue'	   	=> [25,50,75,100],
	      # Speech-Related
          'speech_type' 		=> ['off', 'g711'],
          # Audio-Related
          'audio_type' 			=> ['off', 'aac'],
          'audio_input'			=> ['line_in', 'mic'],
          'audio_bitrate'		=> [64000, 128000],
          'audio_samplerate'	=> [48000],
      }
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
     format_constraints << 'IF [video_type] = "off" THEN [video_resolution_and_bit_rate] = "' + @res_params['video_resolution_and_bit_rate'][0] + '";' 
     format_constraints << 'IF [image_type] = "off" THEN [image_resolution] = "' + @res_params['image_resolution'][0] + '";'
     format_constraints << 'IF [image_type] = "off" THEN [image_qvalue] = ' + @res_params['image_qvalue'][0].to_s + ';'
     format_constraints << 'IF [audio_type] = "off" THEN [audio_bitrate] = ' + @res_params['audio_bitrate'][0].to_s + ';'
     format_constraints | [
      'IF [speech_type] <> "off" THEN [audio_type] = "off";',
      'IF [display_out] IN {"composite","s-video"} THEN [video_signal_format] IN {"525", "625", "vga"};',
      'IF [command_name] IN {"encode","decode"} THEN [passthrough] = "no";',
      'IF [display_out] IN {"composite","s-video","component"} THEN [video_signal_format] <> "dummy";'	# Dummy constraint to remove dummy video signal format. The dummy is required for PICT
     ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
     {
	     'testcaseID'  	=> "#{params['command_name']}_.#{@current_id}",
	     'description' 	=> get_test_description(params),
	     'iter' 		=> '1',
		 'bft' 			=> true,
		 'basic' 		=> true,
		 'ext' 			=> false,
		 'bestFinal' 	=> true,
		 'reg'       	=> true,
		 'auto'			=> true,
		 'script'		=> 'Common\A-DEMO\demo_app_encode_subjective.rb',
		 'configID' 	=> '..\Config\demo_app_subjective.ini',
		 'paramsChan' 	=> {
			'command_name'			=> params['command_name'],
			'media_source'			=> params['media_source'],
			'time'					=> params['time'],
            'disable_deinterlace'	=> params['disable_deinterlace'],
            'enable_osd'			=> params['enable_osd'],
            'enable_keyboard'		=> params['enable_keyboard'],
            'enable_remote'			=> params['enable_remote'],
            'passthrough'			=> params['passthrough'],
            # Video-Related
			'video_file'			=> get_video_filename(params),
            'video_bitrate'			=> get_video_bit_rate(params),
		 	'video_resolution'		=> get_video_resolution(params),
            'video_signal_format'	=> params['video_signal_format'],
            'display_out'			=> params['display_out'],
            'video_input'			=> params['video_input'],
            # Image-Related
			'image_file'			=> get_image_filename(params),
            'image_resolution'		=> params['image_resolution'],
            'image_qvalue'			=> params['image_qvalue'],
            # Audio-Related
			'audio_file' 			=> get_audio_filename(params),
            'audio_input'			=> params['audio_input'],
            'audio_bitrate'			=> params['audio_bitrate'],
            'audio_samplerate'		=> params['audio_samplerate'],
            # Speech-Related
			'speech_file' 			=> get_speech_filename(params),
            
         },
		 'paramsEquip' 	=> {},
		 'paramsControl'=> {},
     }
   end
  # END_USR_CFG get_outputs
  
  private
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
  
  def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_filename(params)
      if params['video_type'] == 'off' 
          return 'none'
      else
          return params['video_resolution_and_bit_rate']+get_video_extension(params)
      end
  end
  
  def get_audio_filename(params)
      if params['audio_type'] == 'off' 
          return 'none'
      else
          return params['audio_samplerate']+'_'+params['audio_bitrate']+get_audio_extension(params)
      end
  end
  
  def get_image_filename(params)
      if params['image_type'] == 'off' 
          return 'none'
      else
          return 'image_files'
      end
  end
  
  def get_speech_filename(params)
      if params['speech_type'] == 'off' 
          return 'none'
      else
          return 'test'+get_speech_extension(params)
      end
  end
  
  def get_video_extension(params)
      case params['video_type']
          when 'h264': return '.264'
          when 'mpeg4': return '.mpeg4'
          when 'mpeg2': return '.m2v'
          else raise "Unknown video_type #{params['video_type']}"
          end
  end
  
  def get_audio_extension(params)
      case params['audio_type']
          when /.*aac.*/ : return '.aac'
          else raise "Unknown audio_type #{params['audio_type']}"
          end
  end
  
  def get_speech_extension(params)
      case params['speech_type']
          when 'g711': return '.g711'
          else raise "Unknown speech_type #{params['speech_type']}"
          end
  end
  
  def get_test_description(params)
      "#{params['command_name']} demo test with Video #{get_test_description_video(params)} : Image #{get_test_description_image(params)} : Speech #{get_test_description_speech(params)} : Audio #{get_test_description_audio(params)}"
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
          "#{params['audio_type']} codec, #{params['audio_samplerate']} samplerate, #{params['audio_bitrate']} bitrate"
      end
      
  end
  
  def get_test_description_image(params)
      if params['image_type'] == 'off'
          "disabled"
      else
          "#{params['image_type']} codec, #{params['image_resolution']} resolution, #{params['image_qvalue']} qvalue"
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