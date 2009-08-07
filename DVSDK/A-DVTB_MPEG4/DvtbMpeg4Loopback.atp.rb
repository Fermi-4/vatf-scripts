require 'find'
require '../media_filer_utils'

include MediaFilerUtils

class DvtbMpeg4LoopbackTestPlan < TestPlan
  attr_reader :video_source_hash
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 3
	@sort_by = ['video_resolution','video_bit_rate','video_frame_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	params = {
		'video_bit_rate' => [128000, 512000, 768000 , 1000000, 2000000, 3000000, 4000000],
		'video_frame_rate'=>[25,30],
		'video_gop'=>[0,15,30],
		'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined
		'video_rate_control'=>[1,2,5],
		'video_input_chroma_format'=>['420p','422i'],
		'video_resolution' => ['176x144', '352x240', '352x288', '704x480', '704x576', '720x480', '720x576'],
		'video_num_channels' => [1,8]
	}
	@video_source_hash = get_source_files_hash("\\w*",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*frames","yuv")	
	params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
		 'IF [video_resolution] = "176x144" THEN [video_bit_rate]=128000;',
		 'IF [video_resolution] = "352x240" THEN [video_bit_rate] >= 512000 AND [video_bit_rate] <= 1000000;',
		 'IF [video_resolution] = "352x288" THEN [video_bit_rate] = 768000;',
		 'IF [video_resolution] = "704x480" THEN [video_bit_rate] IN {1000000, 2000000, 4000000};',
		 'IF [video_resolution] = "704x576" THEN [video_bit_rate] IN {2000000,4000000};',
		 'IF [video_resolution] = "720x480" THEN [video_bit_rate] >= 1000000 AND [video_bit_rate] <= 4000000;',
		 'IF [video_resolution] = "720x576" THEN [video_bit_rate] IN {2000000,4000000};',	
		 'IF [video_input_chroma_format] = "422i" THEN [video_resolution] NOT IN {"704x576","704x480","176x144"};'
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_mpeg4_loopback.#{@current_id}",
	     'description'    => "MPEG4 Encoder Loopback Test using the encoders default values, a resolution of "+params['video_resolution']+",and a bit rate of "+params['video_bit_rate'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_MPEG4\dvtb_mpeg4_loopback.rb',
		 'configID' => 'dvtb_mpeg4_loopback.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' => params['video_bit_rate'],
				'video_frame_rate' => params['video_frame_rate'],
				'video_gop' => params ['video_gop'],
				'video_encoder_preset' => params['video_encoder_preset'],
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
			'video_num_channels' => params['video_num_channels']	
			},
     }
   end
  # END_USR_CFG get_outputs
   def get_source_file(params)
	@video_source_hash["\\w*"+params['video_resolution']+"_"+params['video_input_chroma_format']+"\\w*frames"]
   end
   
   private
   def get_video_height(resolution)
		resolution.split("x")[1].strip
   end
   
   def get_video_width(resolution)
		resolution.split("x")[0].strip
   end

end
