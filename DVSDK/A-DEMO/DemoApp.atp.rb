require '../media_filer_utils'

include MediaFilerUtils

class DemoAppTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by = ['command_name', 'video_type','video_resolution_and_bit_rate']
	@group_by = ['command_name', 'video_type','video_resolution_and_bit_rate']
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
	  @prof_regex = {'mpeg2' => "_(SP|MPp)\\w*",
                   'mpeg4' => "_(ASP|SP)\\w*",
                   'h264' => "_(BP|MP)\\w*" }
    media_extension = {'mpeg2' => 'm2v',
                       'mpeg4' => 'mpeg4',
                       'h264' => '264' }
      params = {
          'command_name'		=> ['encode', 'decode', 'encodedecode'],
          'speech_type' 		=> ['off', 'g711'],
          #'audio_type' 			=> ['off', 'acc'],
          'video_type'			=> ['off', 'mpeg2', 'mpeg4', 'h264'],
          'video_input'			=> ['component', 'composite', 'svideo'],
          'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
          'display_out'			=> ['composite', 'component', 'svideo'],
          'audio_input'			=> ['line_in', 'mic'],
          #'audio_bitrate'		=> [64000, 128000],
          #'audio_samplerate'	=> [48000],
          'disable_deinterlace'	=> ['yes', 'no'],
          'enable_osd'			=> ['yes', 'no'],
          'passthrough'			=> ['yes', 'no'],
          'audio_source' 		=> ['test1_16bIntel'],
          'video_source_chroma_format' => ['411p','420p','422i','422p','444p'],
          'ti_logo_resolution' 	=> ['0x0'],
          'video_quality_metric'=> ['jnd\=5','mos\=3.5'],
          'video_rec_delay'     => [2],
          'max_num_files'       => [1],
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
    next if vtype.downcase == 'off'
    @video_source_hash[vtype] = get_source_files_hash("\\w*",video_resolutions,"\\w*",@prof_regex[vtype],"\\w*",file_bit_rate,"\\w*_\\d{3}frames",media_extension[vtype])
  end
  @yuv_video_source_hash = get_source_files_hash("\\w+",video_resolutions,"_",params['video_source_chroma_format'],"\\w*_\\d{3}frames","yuv")  
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
     format_constraints << 'IF [video_type] = "off" THEN [video_resolution_and_bit_rate] = "'+ @res_params['video_resolution_and_bit_rate'][0] + '";'
     format_constraints | [
      'IF [display_out] IN {"composite","svideo"} THEN [video_signal_format] IN {"525", "625", "vga"};',
      'IF [display_out] IN {"composite","svideo","component"} THEN [video_signal_format] <> "dummy";',	# Dummy constraint to remove dummy video signal format. The dummy is required for PICT
      'IF [command_name] IN {"encode","decode"} THEN [passthrough] = "no";',
      'IF [video_type] = "mpeg2" THEN [command_name] = "decode";' #Remove this constraint if mpeg2 encoder is supported
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
		 'script'    =>  'DVSDK/A-DEMO/demo_app.rb',
		 'configID' 	=> '../Config/demo_app.ini',
		 'paramsChan' 	=> {
			'command_name'			=> params['command_name'],
            'speech_file' 			=> get_speech_filename(params),
            #'audio_file' 			=> get_audio_filename(params),
            'video_bitrate'			=> get_video_bit_rate(params),
            'video_resolution'		=> get_video_resolution(params),
            'video_signal_format'	=> params['video_signal_format'],
            'display_out'			=> params['display_out'],
            'audio_input'			=> params['audio_input'],
            'disable_deinterlace'	=> params['disable_deinterlace'],
            'enable_osd'			=> params['enable_osd'],
            'passthrough'			=> params['passthrough'],
            'video_input'			=> params['video_input'],
            'video_type'      => params['video_type'],
            'audio_source'			=> params['audio_source'],
            'video_source'          => get_video_source(params),
            'video_source_chroma_format' => params['video_source_chroma_format'],
            'ti_logo_resolution' 	=> params['ti_logo_resolution'],
            'video_quality_metric' 	=> params['video_quality_metric'],
         },
		 'paramsEquip' 	=> {},
		 'paramsControl'=> {
        'video_rec_delay' => params['video_rec_delay'],
        'max_num_files' => params['max_num_files']
      },
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
  
  def get_speech_filename(params)
      if params['speech_type'] == 'off' 
          return 'none'
      else
          return 'test'+get_speech_extension(params)
      end
  end
  
  def get_speech_extension(params)
      case params['speech_type']
          when 'g711': return '.g711'
          else raise "Unknown speech_type #{params['speech_type']}"
          end
  end
  
  def get_test_description(params)
      "#{params['command_name']} demo test with video #{get_test_description_video(params)} : audio #{get_test_description_audio(params)}"
  end
  
  def get_test_description_video(params)
      if params['video_type'] == 'off'
          "disabled"
      else
          "#{params['video_type']} codec, #{get_video_resolution(params)} resolution, #{get_video_bit_rate(params)} bitrate"
      end
      
  end
  
  def get_test_description_audio(params)
      if params['speech_type'] == 'off'
          "disabled"
      else
          "#{params['speech_type']} codec"
      end
  end
  
  def get_video_source(params)
    return 'none' if params['video_type'] == 'off'
    video_resolution = get_video_resolution(params) 
    if !params['command_name'].include?('encode')
      video_br = get_video_bit_rate(params)
      if video_br.to_f/1000 >= 1000
        file_bit_rate = ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
        file_bit_rate2 = ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
      else
        file_bit_rate = ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
      end
      video_source = ''
      video_source = @video_source_hash[params['video_type']]["\\w*"+video_resolution+"\\w*"+@prof_regex[params['video_type']]+"\\w*"+file_bit_rate2+"\\w*_\\d{3}frames"].to_s if file_bit_rate2
      video_source += ';' if video_source != ''
      video_source += @video_source_hash[params['video_type']]["\\w*"+video_resolution+"\\w*"+@prof_regex[params['video_type']]+"\\w*"+file_bit_rate+"\\w*_\\d{3}frames"].to_s
    else
      video_source = @yuv_video_source_hash["\\w+"+video_resolution+"_"+params['video_source_chroma_format']+"\\w*_\\d{3}frames"].to_s
    end
    video_source = 'not found' if video_source.to_s.strip == ''
    video_source
  end
  
end