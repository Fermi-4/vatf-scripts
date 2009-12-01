require '../media_filer_utils'
include MediaFilerUtils

class DmaiImageEncodeTestPlan < TestPlan
	attr_reader :picture_source_hash
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
	@group_by = ['picture_resolution']
	@sort_by = ['picture_resolution']
  end
  # END_USR_CFG setup
  

  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	@res_params =  {
	'codec' => ['jpeg'],
  'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '352x288', '720x576', '320x240', '640x480', '704x480','704x576', '1280x720', '1920x1080', '2048x3172'],
	'picture_quality' => [0,25,50,75,100],  #number in the range 0-100, 100=best quality
  'picture_input_chroma_format'  => ['default', '411p','420p','422i','422p','444p','gray','420sp'],
  'picture_output_chroma_format' => ['default', '411p','420p','422i','422p','444p','gray','420sp'],
  'media_location' => ['default','Storage Card'],
  }
	@picture_source_hash = get_source_files_hash("\\w+",@res_params['picture_resolution'],"_",@res_params['picture_input_chroma_format'] | ['422i'],"\\w{0,1}","yuv")
	@picture_source_hash.merge!(get_source_files_hash("\\w+",@res_params['picture_input_chroma_format'] | ['422i'],"_",@res_params['picture_resolution'],"yuv"))	
	@res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    
     format_constraints = Array.new
     
	format_constraints | [   
	'IF [picture_source] <> "media_filer" THEN [picture_input_chroma_format] = "422i";',
  'IF [picture_input_chroma_format] = "default" THEN [picture_output_chroma_format] IN {"default","gray"};',
	'IF [picture_input_chroma_format] = "420p" THEN [picture_output_chroma_format] IN {"420p","gray"};',
	'IF [picture_input_chroma_format] = "422p" THEN [picture_output_chroma_format] IN {"422p","gray"};',
	'IF [picture_input_chroma_format] = "422i" THEN [picture_output_chroma_format] IN {"gray","422i"};',
	'IF [picture_input_chroma_format] = "444p" THEN [picture_output_chroma_format] IN {"444p","gray"};',
	'IF [picture_input_chroma_format] = "411p" THEN [picture_output_chroma_format] IN {"411p","gray"};',
	'IF [picture_input_chroma_format] = "gray" THEN [picture_output_chroma_format] = "gray";',
	#'IF [picture_resolution] IN {"2048x3172"} THEN [picture_source] = "media_filer";',
	#'IF [picture_input_chroma_format] = "411p" AND [picture_source] = "media_filer" THEN [picture_resolution] IN {"192x144","720x480"};',
	#'IF [picture_input_chroma_format] IN {"420p","444p","422p","gray"} AND [picture_source] = "media_filer"  THEN [picture_resolution] NOT IN {"192x144","704x480"};',
	#'IF [picture_resolution] = "640x480" THEN [picture_input_chroma_format] NOT IN {"444p","gray"};',
	#'IF [picture_input_chroma_format] = "422i" AND [picture_source] = "media_filer" THEN [picture_resolution] NOT IN {"704x480", "352x240","640x480","192x144"};',
	
	]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	  'description'		=>"#{params['codec'].upcase} Encoder test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dmai_image_encode.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'                  => false,
    'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		'configID' 	=> '../Config/dmai_examples.ini',

    # channel parameters
    'paramsChan'                 => {
    'command_name'            => 'image_encode',
    'codec'	=> params['codec'],
		'picture_resolution'		  => params['picture_resolution'],
		'input_file'		      => get_picture_source(params),
		'picture_input_chroma_format'  => params['picture_input_chroma_format'],
		'picture_output_chroma_format' => params['picture_output_chroma_format'],
		'picture_quality' => params['picture_quality'],
     'media_location' => params['media_location'],
    },
    
    
    'paramsEquip'     => {
    },
    'paramsControl'     => {
    },
   }
  end
  # END_USR_CFG get_outputs

  def get_picture_source(params)
    result = @picture_source_hash["\\w+"+params['picture_resolution']+"_"+params['picture_input_chroma_format'].sub('default','422i')+"\\w{0,1}"]
		result = result.to_s+";" if result && @picture_source_hash["\\w+"+params['picture_input_chroma_format'].sub('default','422i')+"_"+params['picture_resolution']]
		result = result.to_s+@picture_source_hash["\\w+"+params['picture_input_chroma_format'].sub('default','422i')+"_"+params['picture_resolution']] if @picture_source_hash["\\w+"+params['picture_input_chroma_format'].sub('default','422i')+"_"+params['picture_resolution']]
    result
  end
  
  #def get_chroma_format(params)
   
  
  
end
