

class DvtbH264MotionVectorTestPlan < TestPlan
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
		'video_bit_rate' => [2000000],
		'video_frame_rate'=>[30],
		'video_gop'=>[0,15,30],
		'video_rate_control'=>[5],
		'video_input_chroma_format'=>['420p','422i'],
		'video_resolution' => ['512x512', '720x576', '720x480'],
		'video_source' => ['zeroMV512x512_420p_10frames.yuv','src1_720x576_422i_40frames.yuv','shieldsMvData_720x480_420p_4frames.yuv'],
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
		 'IF [video_resolution] = "512x512" THEN [video_source] = "zeroMV512x512_420p_10frames.yuv" AND [video_input_chroma_format]="420p" AND [video_gop] = 0;',
		 'IF [video_resolution] = "720x576" THEN [video_source] = "src1_720x576_422i_40frames.yuv" AND [video_input_chroma_format]="422i" AND [video_gop] = 15;',
		 'IF [video_resolution] = "720x480" THEN [video_source] = "shieldsMvData_720x480_420p_4frames.yuv" AND [video_input_chroma_format]="422i" AND [video_gop] = 30;',
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_h264_motion_vector_loopback.#{@current_id}",
	     'description'    => "H.264 Encoder Motion Vector Loopback Test using the encoders default values, a resolution of "+params['video_resolution']+", a bit rate of "+params['video_bit_rate']+", and "+get_source_file(params)+" as reference file.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_H264_MOTION_VECTOR\dvtb_H264_motion_vector.rb',
		 'configID' => 'dvtb_h264_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' => params['video_bit_rate'],
				'video_frame_rate' => params['video_frame_rate'],
				'video_gop' => params ['video_gop'],
				'video_encoder_preset' => 3,
				'video_gen_header' => 0,
				'video_capture_width' => 0,
				'video_force_iframe' => 0,
				'video_rate_control' => params['video_rate_control'],
				'video_input_chroma_format' => params['video_input_chroma_format'],
				'video_height' => get_video_height(params['video_resolution']),
				'video_width' => get_video_width(params['video_resolution']),
				'video_source' => get_source_file(params),
	        },
		 'paramsEquip' => {
			},
		 'paramsControl' => {
			'num_channels' => params['num_channels']	
			},
     }
   end
  # END_USR_CFG get_outputs
   def get_source_file(params)
	params['video_source']
   end
   
   private
   def get_video_height(resolution)
		resolution.split("x")[1].strip
   end
   
   def get_video_width(resolution)
		resolution.split("x")[0].strip
   end	
end