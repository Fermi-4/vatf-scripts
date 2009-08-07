require '../media_filer_utils'
include MediaFilerUtils

class DvtbMjpegTestPlan < TestPlan
	attr_reader :picture_source_hash
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
   params =  {
       
    'video_resolution'  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '352x288', '720x576', '320x240', '640x480', '704x480','704x576', '1280x720', '2048x3172'], 
    'video_input_resolution' => ['less','equal'],
    'video_data_endianness' => [1,2,3],
    'video_picture_num_scans' => [0,1,3,10],
    'video_input_chroma_format'  => ['411p','420p','422i','422p','444p','gray'],
    'video_output_chroma_format' => ['default', '411p','420p', '422i', '422p', '444p', 'gray'],
	'video_picture_rotation' => [0,90,180,270],
    'video_source' => ['camera', 'dvd', 'media_filer'],
    'video_picture_num_access_units' => ['default', 'all'],
    'video_region' => ['ntsc', 'pal'],	
    'video_num_channels'	=> [1],
	'video_input_driver' => ['vpfe+encode' , 'vpfe+resizer+encode', 'encode','none'],
	'video_output_driver' => ['decode+vpbe', 'decode', 'none'],
	'video_frame_rate' => [5,10,15,30],
    'video_picture_quality' => [25,50,75,100],  #number in the range 0-100, 100=best quality
	}
    
	@picture_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*\\d+frame\\w*","yuv")
	@picture_source_hash.merge!(get_source_files_hash("\\w+",params['video_input_chroma_format'],"_",params['video_resolution'],"\\w*\\d+frame\\w*","yuv"))	
	@picture_source_hash2 = get_source_files_hash("\\w+",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*\\d+frame\\w*","jpg")	

	
	params
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  #
 
  def get_constraints()
    [   
	'IF [video_source] <> "media_filer" THEN [video_input_chroma_format] = "422p";',
	'IF [video_input_chroma_format] = "420p" THEN [video_output_chroma_format] IN {"420p","gray"};',
	'IF [video_input_chroma_format] = "422p" THEN [video_output_chroma_format] IN {"422p","gray"};',
	'IF [video_input_chroma_format] = "422i" THEN [video_output_chroma_format] IN {"422p","420p","gray"};',
	'IF [video_input_chroma_format] = "444p" THEN [video_output_chroma_format] IN {"444p","gray"};',
	'IF [video_input_chroma_format] = "411p" THEN [video_output_chroma_format] IN {"411p","gray"};',
	'IF [video_input_chroma_format] = "gray" THEN [video_output_chroma_format] = "gray";',
	'IF [video_resolution] IN {"2048x3172"} THEN [video_source] = "media_filer";',
	'IF [video_input_chroma_format] = "411p" AND [video_source] = "media_filer" THEN [video_resolution] IN {"192x144","720x480"};',
	'IF [video_input_chroma_format] IN {"420p","444p","422p","gray"} AND [video_source] = "media_filer"  THEN [video_resolution] NOT IN {"192x144","704x480"};',
	'IF [video_resolution] = "640x480" THEN [video_input_chroma_format] NOT IN {"444p","gray"};',
	'IF [video_input_chroma_format] = "422i" AND [video_source] = "media_filer" THEN [video_resolution] NOT IN {"704x480", "352x240","640x480","192x144"};',
	'IF [video_source] = "camera" AND [video_region] = "ntsc" THEN [video_resolution] NOT IN {"704x576","1280x720", "2048x3172"};',
	'IF [video_source] = "camera" AND [video_region] = "pal" THEN [video_resolution] NOT IN {"1280x720", "2048x3172"};',
	'IF [video_input_chroma_format] = "444p" THEN [video_resolution] NOT IN {"192x144","640x480","704x480"};',
	'IF [video_input_chroma_format] = "gray" THEN [video_resolution] NOT IN {"640x480","704x480","192x144"};',
	'IF [video_input_chroma_format] = "411p" THEN [video_resolution] NOT IN {"1280x720","320x240","640x480","704x480","704x576","352x240","720x576","352x288"};',
	'IF [video_input_chroma_format] = "420p" THEN [video_resolution] NOT IN {"320x240","640x480","704x480","192x144"};',
	'IF [video_input_chroma_format] = "422p" THEN [video_resolution] NOT IN {"192x144","704x480"};',
	'IF [video_input_driver] IN {"vpfe+encode","vpfe+resizer+encode"} THEN [video_output_driver] <> "decode";',
	'IF [video_input_driver] IN {"vpfe+encode","vpfe+resizer+encode"} THEN [video_source] IN {"camera", "dvd", "video_tester"};',
	'IF [video_input_driver] = "encode" THEN [video_output_driver] <> "decode+vpbe";',
	'IF [video_input_driver] IN {"encode","none"} THEN [video_source] = "media_filer";',
	'IF [video_input_driver] = "vpfe+resizer+encode" THEN [video_input_resolution] = "less";',
	'IF [video_input_driver] <> "vpfe+resizer+encode" THEN [video_input_resolution] = "equal";',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"MJPEG "+get_test_type(params)+" test, video resolution = #{params['video_resolution']}", 
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mjpeg.#{@current_id}", 
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => false,
    'bestFinal'                  => false,
    'script'                     => 'Common\A-DVTB_MJPEG\dvtb_mjpeg.rb',

    # channel parameters
    'paramsChan'                 => {
		'video_width'		  => get_video_width(params),
		'video_height'	  => get_video_height(params),
		'video_input_height' => get_video_input_height(params),
		'video_input_width' => get_video_input_width(params),
		'video_source'		      => get_video_source(params),
		'video_picture_num_scans' => params['video_picture_num_scans'],
		'video_data_endianness' => params['video_data_endianness'],
		'video_input_chroma_format'  => params['video_input_chroma_format'],
		'video_output_chroma_format' => params['video_output_chroma_format'],
		'video_picture_num_access_units' => get_num_access_units(params),
		'video_picture_quality' => params['video_picture_quality'],
		'video_region'				    => params['video_region'],
		'video_picture_rotation' => params['video_picture_rotation'],
		'video_frame_rate' => params['video_frame_rate'],
		'test_type' => get_test_type(params),
    },
        
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'video_num_channels'				=> params['video_num_channels'],
    },
    'configID'      => '..\Config\dvtb_mjpeg.ini', # HN this will need to be changed I think
#    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  def get_video_source(params)
    result = params['video_source']
    if !params['video_input_driver'].include?('vpfe') && !params['video_input_driver'].eql?('none')
		result = @picture_source_hash["\\w+"+params['video_resolution']+"_"+params['video_input_chroma_format']+"\\w*\\d+frame\\w*"]
		result = result.to_s+";" if result && @picture_source_hash["\\w+"+params['video_input_chroma_format']+"_"+params['video_resolution']]
		result = result.to_s+@picture_source_hash["\\w+"+params['video_input_chroma_format']+"_"+params['video_resolution']+"\\w*\\d+frame\\w*"]if @picture_source_hash["\\w+"+params['video_input_chroma_format']+"_"+params['video_resolution']+"\\w*\\d+frame\\w*"]  
	elsif params['video_input_driver'].eql?('none')
		result = @picture_source_hash2["\\w+"+params['video_resolution']+"_"+params['video_input_chroma_format']+"\\w*\\d+frame\\w*"]
    end
	result
  end
  
  private
  def get_video_height(params)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(params['video_resolution'])
		res[2]
  end
  
  def get_video_width(params)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(params['video_resolution'])
		res[1]
  end
  
  def get_video_input_height(params)
	height = get_video_height(params).to_i
	
	if params['video_input_resolution'].eql?('less')
	    height/2
	elsif params['video_input_resolution'].eql?('equal')
	    height
	else
	   raise 'Unsupported picture_input_resolution value '+params['video_input_resolution']
	end
	
  end
  
  def get_video_input_width(params)
    width = get_video_width(params).to_i
	
	if params['video_input_resolution'].eql?('less')
	    width/2
	elsif params['video_input_resolution'].eql?('equal')
	    width
	else
	   raise 'Unsupported picture_input_resolution value '+params['video_input_resolution']
	end
	
  end
  
  def get_num_access_units(params)
	if params['video_picture_num_access_units'].strip.downcase.eql?('default')
		0
	elsif params['video_picture_num_access_units'].strip.downcase.eql?('all')
		(get_video_height(params).to_i*get_video_width(params).to_i/16).ceil
	else
		params['video_picture_num_access_units'].strip.downcase.to_i
	end
  end
  
  def get_test_type(params)
	(params['video_input_driver']+"+"+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"").gsub(/^_/,"").gsub(/_$/,"")
  end
      
end
