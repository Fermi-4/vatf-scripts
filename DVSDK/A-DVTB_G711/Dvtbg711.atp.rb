require '../media_filer_utils'

include MediaFilerUtils
class DvtbG711TestPlan < TestPlan
	attr_reader :ulaw_audio_source_hash, :alaw_audio_source_hash
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
		'audio_input_driver' => ['apfe+encoder','none'],
		'audio_output_driver' => ['decoder+apbe','none'],
		'audio_companding' => ['ulaw','alaw'],
		'audio_sampling_rate' => [8000],
		'audio_source' => ['dvd','mic','media_filer'],
		'audio_num_channels' => [1]
	}
	@ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
	@alaw_audio_source_hash = get_source_files_hash("\\w+","a")
	params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
	 'IF [audio_input_driver] = "none" THEN [audio_output_driver] <> "none";',
	 'IF [audio_input_driver] = "none" THEN [audio_source] = "media_filer";',
     'IF [audio_input_driver] <> "none" THEN [audio_source] <> "media_filer";'
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_g711.#{@current_id}",
	     'description'    => "G711 Encoder Test using the encoders default values, with "+params['audio_source']+" as input, and "+params['audio_companding']+" companding.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_G711\dvtb_g711.rb',
		 'configID' => 'dvtb_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_companding' => params['audio_companding'],
				'audio_codec' => "g711",
				'audio_bit_rate' => 64000,
				'audio_source' => get_audio_source(params),
				'audio_sampling_rate' => params['audio_sampling_rate'],
				'test_type' => (params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
	        },
		 
		 'paramsControl' => {
			'audio_num_channels' => params['audio_num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
  def get_audio_source(params)
	if params['audio_source'].eql?('media_filer')
	  if params['audio_companding'].eql?("ulaw")
		@ulaw_audio_source_hash["\\w+"]
	  elsif params['audio_companding'].eql?("alaw")
		@alaw_audio_source_hash["\\w+"]
	  end
	else
	  params['audio_source']
	end
  end
end