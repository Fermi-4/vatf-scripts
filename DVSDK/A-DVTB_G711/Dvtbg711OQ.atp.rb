
class DvtbG711OQTestPlan < TestPlan
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
	params = {
		'audio_input_driver' => ['apfe+encode','none'],
		'audio_output_driver' => ['decode+apbe','none'],
        'audio_num_channels'  => [1,8],
        'audio_source' => ['test1_16bIntel'],
        'audio_companding' 	  => ['ulaw', 'alaw'],
        'audio_sampling_rate' => [8000],
        'audio_media_time'	  => [10], 
	}
	params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
      'IF [audio_input_driver] = "none" THEN [audio_output_driver] <> "none";'
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_g711_oq.#{@current_id}",
	     'description'    => "G711 Codec Objective Quality Test using the codec's default values, with "+params['audio_source']+" as input, and "+params['audio_companding']+" companding.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_G711\dvtb_g711_oq.rb',
		 'configID' => 'dvtb_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_companding' => params['audio_companding'],
				'audio_codec' => "g711",
				'audio_bit_rate' => 64000,
				'audio_source' => params['audio_source'],
				'audio_sampling_rate' => params['audio_sampling_rate'],
				'test_type' => (params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
	        },
		 
		 'paramsControl' => {
			'audio_num_channels' => params['audio_num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
end