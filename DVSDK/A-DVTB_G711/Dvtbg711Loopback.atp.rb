require '../media_filer_utils'

include MediaFilerUtils
class DvtbG711LoopbackTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	{
		'audio_companding' => ['mulaw','alaw'],
		'audio_sampling_rate' => [8000],
		'audio_source' => get_source_files_hash("\\w+_8KHz\\w*","pcm")["\\w+_8KHz\\w*"].split(";"),
		'audio_num_channels' => [1,8]
	}
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
	     'testcaseID'     => "dvtb_g711_file_loopback.#{@current_id}",
	     'description'    => "G711 Encoder Loopback Test using the encoders default values, with "+params['audio_source']+" as input, and "+params['audio_companding']+" companding.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_G711\dvtb_g711.rb',
		 'configID' => 'dvtb_h264_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_companding' => params['audio_companding'],
				'audio_codec' => "g711",
				'audio_bit_rate' => 64000,
				'audio_source' => params['audio_source'],
				
	        },
		 
		 'paramsControl' => {
			'audio_num_channels' => params['audio_num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
end