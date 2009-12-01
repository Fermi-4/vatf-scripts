require '../media_filer_utils'
include MediaFilerUtils

class DmaiImageDecodeTestPlan < TestPlan
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
    'picture_resolution'		  => ['88x72','176x120', '176x144','192x144','352x240', '720x480', '176x144', '352x288', '720x576', '320x240', '640x480','704x576', '1280x720', '2048x3172'],
    'picture_output_chroma_format' => ['default', '411p','420p','422i','422p','444p','gray','420sp'], #Only these output formats have been confirmed to be supported
    'codec' => ['jpeg'],
    'media_location' => ['default','Storage Card'],
		}
	@picture_source_hash = get_source_files_hash("\\w+",@res_params['picture_resolution'],"\\w*\.{0,1}","jpg")	
	@res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [
		]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"#{params['codec'].upcase} Decoder test, picture_res=#{params['picture_resolution']}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dmai_image_decode.#{@current_id}",
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
    'command_name'      => 'image_decode',
		'picture_resolution'		  => params['picture_resolution'],
		'picture_output_chroma_format' => params['picture_output_chroma_format'],
		'input_file'		      => get_picture_source(params),
		'codec'	=> params['codec'],
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
		@picture_source_hash["\\w+"+params['picture_resolution']+"\\w*\.{0,1}"]
  end
  
end
