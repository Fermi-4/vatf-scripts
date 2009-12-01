require '../../TestPlans/Common/A-DVTB_H264/DvtbH264Loopback.atp'
require '../../TestPlans/Common/A-DVTB_G711/DvtbG711Loopback.atp'

class DvtbH264G711DecodeTestPlan < TestPlan
	@@g711_test_plan = DvtbG711LoopbackTestPlan.new
	@@h264_test_plan = DvtbH264LoopbackTestPlan.new
	@@base_params = @@h264_test_plan.get_params().merge(@@g711_test_plan.get_params())
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@group_by = ['video_type', 'video_resolution_and_bit_rate']
	@sort_by =  ['video_type', 'video_resolution_and_bit_rate']
	end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  def get_params()
    @prof_regex     = {'mpeg2' => "_(SP|MPp)\\w*",
                       'mpeg4' => "_(ASP|SP)\\w*",
                       'h264' => "_(BP|MP)\\w*" }
    media_extension = {'mpeg2' => 'm2v',
                       'mpeg4' => 'mpeg4',
                       'h264' => '264' }
    
    params = {
      'operation'       => ['decode'],
      'video_type'			=> ['mpeg2', 'mpeg4', 'h264'],
      'media_location'  => ['default','Storage Card'],
      'ti_logo_resolution' => ['0x0'],
      'video_quality_metric' => ['jnd\\=5'],
      'video_output_chroma_format' => ['411p','420p','422i','422p','444p','gray','420sp'],
      'max_num_files'     => [0],
      'video_num_channels' => [1],
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
      @video_source_hash[vtype] = get_source_files_hash("\\w*",video_resolutions,"\\w*",@prof_regex[vtype],"\\w*",file_bit_rate,"\\w*frames",media_extension[vtype])
    end    
    @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
    #@@g711_test_plan.get_params().merge(@res_params)      
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
     #['{ audio_companding, audio_source, audio_sampling_rate, audio_num_channels } @ 2'] | @@g711_test_plan.get_constraints 
     []
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
   def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_#{params['video_type']}_file_decode.#{@current_id}",
	     'description'    => "#{params['video_type']} Codec Decode Test. Resolution of "+get_video_resolution(params)+" and bit rate of "+get_video_bit_rate(params),
		 'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'DVSDK/A-DVTB_H264_G711_YUV_LOOPBACK/dvtb_h264_g711.rb',
		 'configID' => '../Config/dvtb_h264_g711_loopback.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => get_test_params('paramsChan',params).merge!({
                                                                          'operation' => params['operation'],
                                                                          'video_bit_rate' => get_video_bit_rate(params),
                                                                          'video_output_chroma_format' => params['video_output_chroma_format'],
                                                                          'video_height' => get_video_height(get_video_resolution(params)),
                                                                          'video_width' => get_video_width(get_video_resolution(params)),
                                                                          'video_source' => get_video_source(params),
                                                                          'video_quality_metric' => params['video_quality_metric']}),
		 'paramsEquip'	 => get_test_params('paramsEquip',params),
		 'paramsControl' => get_test_params('paramsControl',params).merge!({
                                                                           'video_num_channels' => params['video_num_channels'],
                                                                           'ti_logo_resolution' => params['ti_logo_resolution'],
                                                                           'codec_class'	  	=> get_codec_class(params['video_type']),
                                                                           'max_num_files'    => params['max_num_files']}),
     }
   end
  # END_USR_CFG get_outputs
  
  private
  
  def get_test_params(type,params)
		result = {}
		# if @@g711_test_plan.get_outputs(params)[type]
			# result.merge!(@@g711_test_plan.get_outputs(params)[type])
		# end
		# if @@h264_test_plan.get_outputs(params)[type]
			# result.merge!(@@h264_test_plan.get_outputs(params)[type])
		# end
		result
	end
  
  def get_codec_class(type)
    type.upcase
  end
  
  def get_video_height(resolution)
		resolution.split("x")[1].strip
  end
   
  def get_video_width(resolution)
    resolution.split("x")[0].strip
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
  
  def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
 
 def get_video_source(params)
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
  
  def get_test_description(params)
      return "video_decode dmai test with Video #{get_test_description_video(params)}"
  end
  
  def get_test_description_video(params)  
    "#{params['video_type']} codec, #{get_video_resolution(params)} resolution, #{get_video_bit_rate(params)} bitrate" 
  end
   	
end