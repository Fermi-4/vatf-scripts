require '../media_filer_utils'

include MediaFilerUtils

class DvtbVidG711LoopbackTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	#@order = 2
	@group_by = ['operation', 'video_rate_control', 'video_resolution_and_bit_rate']
	@sort_by = ['operation', 'video_rate_control', 'video_resolution_and_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
  params = {
    'operation'=>['encode', 'encode+decode'],
    'video_frame_rate' => [25,30],
    'video_gop' => [0,15,30],
    'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
    'video_rate_control' => ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
    'video_input_chroma_format' => ['420p','422i', '420sp'],
    'video_inter_frame_interval' => [1],
    'video_num_channels' => [1,8],
    'video_quality_metric' => ['jnd\=5'],
    'ti_logo_resolution' => ['0x0'],
    'codec_class'		  => ['h264', 'mpeg4', 'mpeg2'],
    'max_num_files'    => [1],
  }
  video_res_and_bit_rates = [{ 'video_bit_rate' => [64000],
              'video_resolution' => ['128x96'],
            },
   {'video_resolution' => ["176x120"],
              'video_bit_rate' => [64000,128000,192000,256000,512000],
            },
   { 'video_resolution' => ["176x144"],
              'video_bit_rate' => [64000,128000,192000,256000,512000],
            },
   { 'video_resolution' => ["320x240"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
   { 'video_resolution' => ["352x240"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
   { 'video_resolution' => ["352x288"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
  { 'video_resolution' => ["640x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["704x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["704x576"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["720x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["720x576"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
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
  @yuv_video_source_hash = get_source_files_hash("\\w+",video_resolutions,"_",params['video_input_chroma_format'],"\\w*_\\d{2,3}frames","yuv")  
	
  @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [] 
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_#{params['codec_class']}_file_loopback.#{@current_id}",
	     'description'    => "#{params['codec_class']} Codec Loopback Test using the encoders default values, a resolution of "+get_video_resolution(params)+", a bit rate of "+get_video_bit_rate(params)+", and yuv source files.",
		 'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'vatf-scripts/DVSDK/A-DVTB/A-DVTB_VIDEO_YUV_LOOPBACK/dvtb_video_g711.rb',
		 'configID' => 'Config/dvtb_video_g711_loopback.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => get_params_chan(params),
		 'paramsEquip'	 => {},
		 'paramsControl' => {
                         'ti_logo_resolution' => params['ti_logo_resolution'],
                         'codec_class'	  	=> params['codec_class'],
                         'max_num_files'    => params['max_num_files']},
     }
   end
  # END_USR_CFG get_outputs
  
  private
  def get_video_source(params)
    video_resolution = get_video_resolution(params) 
    @yuv_video_source_hash["\\w+"+video_resolution+"_"+params['video_input_chroma_format']+"\\w*_\\d{2,3}frames"].to_s
  end
  
  def get_params_chan(params)
      result = {}
      params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
      result['video_bit_rate'] = get_video_bit_rate(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_height'] = get_video_height(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_width'] = get_video_width(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_source'] = get_video_source(params)
      
      result.delete('video_resolution_and_bit_rate')
      result.delete('ti_logo_resolution')
      result.delete('codec_class')
      result.delete('max_num_files')
      result
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
  
  def get_video_height(params)
    pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
    res[2]
  end
  
  def get_video_width(params)
    pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
    res[1]
  end
  
  def get_video_resolution(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_bit_rate(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
   	
end