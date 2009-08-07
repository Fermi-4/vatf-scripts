require '../media_filer_utils'
include MediaFilerUtils

class DvtbH264OVQTestPlan < TestPlan
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
	@group_by = ['video_input_driver:video_output_driver']
	@sort_by = ['video_input_driver:video_output_driver']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	params = { 
		'video_input_driver'  => ['vpfe+encode','none'],
		'video_output_driver'  => ['decode+vpbe','none'],
		'video_rate_control'=> [1,2,3,4,5], # 1 -> CBR, 2 -> VBR, 3 -> two-pass, 5 -> user defined 
		'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined
        'video_bit_rate'	  => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000],
        'video_resolution'		  => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480', '800x600', '1024x768', '1280x720', '1280x960', '1920x1080'],
	    'video_frame_rate'		  => [5, 10, 15, 'std'],
		'video_num_channels'  => [1,8],
		'video_input_chroma_format' => ['420p', '422i'],
		'video_output_chroma_format' => ['420p', '422i'],
		'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
		'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
		'video_source_chroma_format' => ['411p','420p','422i','422p','444p'],
		'video_quality_metric' => ['jnd\=5','mos\=3.5'],
        'setup_delay' 	  => [32],
	}
	file_bit_rate = Array.new
	params['video_bit_rate'].each do |bit_rate| 
		if bit_rate/1000 >= 1000
		   file_bit_rate << ((bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
		else
		   file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
		end 
	end
	@video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*",params['video_bit_rate'],"bps","264")
	@video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],"_(BP|MP)\\w*",file_bit_rate,"\\w*","264"))
	@video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],"_",params['video_source_chroma_format'],"\\w*\\d{3}frames","yuv"))
	video_res_and_bit_rates = [
     {'video_resolution' => ["128x96"],
						     'video_bit_rate' =>  [64000],	
					       },
     {'video_resolution' => ["176x120"],
						     'video_bit_rate' =>  [64000,96000,128000,256000]	
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
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [
     'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";'
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"Objective Video Quality #{(params['video_input_driver']+'+'+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"")} test, for #{get_video_resolution(params)} resolution picture at #{get_video_bit_rate(params)} bps",
    	'iter'                       => '1',
        'testcaseID'                 => "dvtb_h264_ovq.#{@current_id}",
        'bft'                        => false,
        'basic'                      => false,
        'ext'                        => true,
        'reg'                        => false,
        'auto'                       => true,
        'bestFinal'                  => false,
        'script'                     => 'Common\A-DVTB_H264\dvtb_h264_ovq.rb',

        # channel parameters
    'paramsChan'                => {
		    'test_type'              	=> (params['video_input_driver']+'+'+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
	        'video_frame_rate'		=> get_video_frame_rate(params),
	        'video_bit_rate'          	=> get_video_bit_rate(params),
			'video_rate_control'=>params['video_rate_control'],
			'video_encoder_preset' => params['video_encoder_preset'],
		    'video_height'			=> get_video_height(get_video_resolution(params)), 
		    'video_width'			=> get_video_width(get_video_resolution(params)), 
		    'video_input_chroma_format' => params['video_input_chroma_format'],
			'video_output_chroma_format' => params['video_output_chroma_format'],
		    'video_source'           	=> get_video_source(params),
			'video_iface_type' => params['video_iface_type'],
			'video_signal_format' => params['video_signal_format'],
			'video_source_chroma_format' => params['video_source_chroma_format'],
			'video_quality_metric' => params['video_quality_metric'],
    },
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'video_num_channels' => params['video_num_channels'],
		'setup_delay' 	     => params['setup_delay'], 
     },
    'configID'      => '..\Config\dvtb_h264_ovq.ini',
   }
  end
  # END_USR_CFG get_outputs

  private
  def get_video_height(resolution)
	pat = /(\d+)[x|X](\d+)/i
	res = pat.match(resolution)
	res[2]
  end
  
  def get_video_width(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[1]
  end
  
  def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_video_source(params)
	video_resolution = get_video_resolution(params)
	video_bit_rate = get_video_bit_rate(params)	
    if params['video_input_driver'] == 'none'
		if video_bit_rate.to_f/1000 >= 1000
		   file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
		else
		   file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
		end 
		video_source = @video_source_hash["\\w+"+video_resolution+"_"+params['video_input_chroma_format']+"\\w*"+video_bit_rate+"bps"]
		video_source += ";" if video_source && @video_source_hash["\\w+"+video_resolution+"_(BP|MP)\\w*"+file_bit_rate+"\\w*"]
		video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+"_(BP|MP)\\w*"+file_bit_rate+"\\w*"].to_s
	else
		video_source = @video_source_hash["\\w+"+video_resolution+"_"+params['video_source_chroma_format']+"\\w*\\d{3}frames"].to_s
	end
	video_source = 'not found' if video_source.strip == ''
	video_source
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
  
  def get_video_frame_rate(params)
    if params['video_frame_rate'].eql?('std')
      	case get_video_resolution(params)
      	    when '176x120', '352x240', '720x480', '704x480', 
                30
      	    when '176x144', '352x288', '720x576', '704x576',
                25
			else
				if rand() > 0.5
					25
				else
					30
				end
        end
    else
        params['video_frame_rate']
    end   	
  end
  
end
