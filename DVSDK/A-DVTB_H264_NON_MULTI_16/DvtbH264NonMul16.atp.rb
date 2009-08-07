

class DvtbH264NonMul16TestPlan < TestPlan
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
		'video_params' => ['170x120/128000/15/shrek_9_170x140_420p_264frames.yuv',
						   '300x200/512000/25/shrek_8_300x200_420p_264frames.yuv',
						   '714x418/2000000/30/shrek_10_714x418_420p_312frames.yuv'],						  
		'num_channels' => [1,8]
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
	vid_params = params['video_params'].split("/")
     {
	     'testcaseID'     => "dvtb_h264_non_mul16.#{@current_id}",
	     'description'    => "H.264 Non Multiple of 16 resolution Test using the encoders default values, a resolution of "+vid_params[0]+", a bit rate of "+vid_params[1].to_s+", and "+vid_params[3].to_s+" as reference file.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_H264_NON_MULTI_16\dvtb_H264_non_multi_16.rb',
		 'configID' => 'dvtb_h264_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' => vid_params[1],
				'video_frame_rate' => vid_params[2],
				'video_gop' => 30,
				'video_encoder_preset' => 3,
				'video_gen_header' => 0,
				'video_capture_width' => 0,
				'video_force_iframe' => 0,
				'video_rate_control' => 5,
				'video_input_chroma_format' => '420p',
				'video_height' => get_video_height(vid_params[0]),
				'video_width' => get_video_width(vid_params[0]),
				'video_source' => vid_params[3],
	        },
		 'paramsEquip' => {
			},
		 'paramsControl' => {
			'num_channels' => params['num_channels']
			},
     }
   end
  # END_USR_CFG get_outputs
   
   private
   def get_video_height(resolution)
		resolution.split("x")[1].strip
   end
   
   def get_video_width(resolution)
		resolution.split("x")[0].strip
   end	
end