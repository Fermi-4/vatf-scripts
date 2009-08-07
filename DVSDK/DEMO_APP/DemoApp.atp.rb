require '../media_filer_utils'

include MediaFilerUtils

class DemoAppTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 3
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	common_params = {'max_num_channels' => [8],
					 'verbose_console_msgs' => ["on/off","on","off"],
					 'apply_chnnl_1_to_all' => ["on","off"],
					 'analog_output_type' => ["1080i","D1_svideo","D1_composite"],
					 'enable_video' => ["on","off"],
					 'enable_audio' => ["on","off"],
					 'repeat_on_decode' => ["on","off"],
					}
	
	[
     {
         'test_description' => []
     },
	common_params.merge({
		'control_mode' => ["preview"],
	}),
	common_params.merge({
		'control_mode' => ["enc_dec_loopback"],
		'video_codec' => ["h264","mpeg4"],
		'video_frame_rate' => [10,25,30],
		'video_bit_rate_mode' => ["cbr","vbr"],
		'video_bit_rate' => [256000,1000000,2500000,6000000,10000000],
	}),
	common_params.merge({
		'control_mode' => ["dec_from_file"],
	}),
	common_params.merge({
		'control_mode' => ["enc_to_file"],
		'video_codec' => ["h264","mpeg4"],
		'video_frame_rate' => [10,25,30],
		'video_bit_rate_mode' => ["cbr","vbr"],
		'video_bit_rate' => [128000,2000000, 768000, 4000000, 8000000],
		'capture_time' => [30]
	}),
	common_params.merge({
		'control_mode' => ["compare_codecs"]
	}),
	{
        'test_description' => ["Test that the demo application does not crash after clicking stop/play several times with audio and video disabled"],
        'control_mode' => ["preview","enc_dec_loopback","dec_from_file","enc_to_file","none"],
        'enable_video' => ["off"],
        'enable_audio' => ["off"],	
	},
	]	
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
	     'testcaseID'     => "demo_.#{@current_id}",
	     'description'    => get_test_desciprtion(params),
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'This is a manual tc',
		 'configID' => 'This is a manual tc',
		 'reg'                       => true,
		 'auto'                     => false,
		 'paramsChan' => get_params_chan(params),
		 'paramsEquip' => {
		        
		 },
		 'paramsControl' => get_params_control(params),
     }
   end
  # END_USR_CFG get_outputs
  
  def get_params_chan(params)
	fixed_params = {
		'control_mode' => params['control_mode'],
		'verbose_console_msgs' => params['verbose_console_msgs'],
		'apply_chnnl_1_to_all' => params['apply_chnnl_1_to_all'],
		'enable_video' => params['enable_video'],
		'enable_audio' => params['enable_audio'],
		'repeat_on_decode' => params['repeat_on_decode'],
	}
	if params.has_key?('video_codec')
		fixed_params.merge!({
			'video_codec' => params['video_codec'], 
			'video_frame_rate' => params['video_frame_rate'], 
			'video_bit_rate_mode' => params['video_bit_rate_mode'], 
			'video_bit_rate' => params['video_bit_rate'],
		})
	end
	fixed_params
  end
  
  def get_test_description(params)
      if params['test_description']
          params['test_description']
      else
          "Demo #{params['control_mode']} mode test with video #{params['enable_video']} and audio #{params['enable_audio']}".gsub("on","enabled").gsub("off","disabled")
      end
  end
  
  def get_params_control(params)
	fixed_params = {'num_channels' => rand(params['max_num_channels'])}
	fixed_params.merge!({'capture_time' => params['capture_time']}) if params.has_key?('capture_time')
	fixed_params
  end
end