require '../media_filer_utils'

include MediaFilerUtils

class DmaiVideoEncodeTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by =  ['video_type','video_resolution_and_bit_rate']
	@group_by = ['video_type','video_resolution_and_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  def get_params()
	  
      params = {
        'video_type'			=> ['mpeg2', 'mpeg4', 'h264'],
        'video_input_chroma_format' => ['default', '411p','420p','422i','422p','444p','gray','420sp'],
        'media_location' => ['default','Storage Card'],
        'test_type'  => ['subjective', 'objective'],
        'ti_logo_resolution' => ['0x0'],
        'video_quality_metric' => ['jnd\\=5'],
        'max_num_files'       => [1]
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
  video_res_and_bit_rates.each {|res_br| video_resolutions = video_resolutions | res_br['video_resolution']}
  @video_source_hash = get_source_files_hash("\\w*",video_resolutions,"_",params['video_input_chroma_format'] | ['422i'],"\\w*_\\d{3}frames","yuv")	
	@res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
  
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
    []
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
	     'testcaseID'  	=> "video_encode."+"#{@current_id}",
	     'description' 	=> get_test_description(params),
	     'iter' 		=> '1',
		   'bft' 			=> true,
		   'basic' 		=> true,
		   'ext' 			=> false,
		   'bestFinal' 	=> true,
		   'reg'       	=> true,
		   'auto'			=> true,
		   'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		   'configID' 	=> '../Config/dmai_examples.ini',
		   
       'paramsChan' 	=> {
			
            'command_name'			=> 'video_encode',
            'input_file'			=> get_video_source(params),
            'codec'          => params['video_type'],
            'bit_rate'			=> get_video_bit_rate(params),
		 	      'resolution'		=> get_video_resolution(params),
            'video_input_chroma_format' => params['video_input_chroma_format'],
            'media_location' => params['media_location'],
            'video_quality_metric' => params['video_quality_metric'],
         },
       'paramsEquip' 	=> {},
       'paramsControl'=> {
            'test_type' => params['test_type'],
            'ti_logo_resolution' => params['ti_logo_resolution'],
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
  
  def get_video_source(params)
    resolution = get_video_resolution(params)
    @video_source_hash["\\w*"+resolution+"_"+params['video_input_chroma_format'].sub('default','422i')+"\\w*_\\d{3}frames"]
  end
  
  def get_test_description(params)
      return "video_encode dmai test with Video #{get_test_description_video(params)}"
  end
  
  def get_test_description_video(params)  
    "#{params['video_type']} codec, #{get_video_resolution(params)} resolution, #{get_video_bit_rate(params)} bitrate" 
  end

end