

class DvtbH264LevelsTestPlan < TestPlan
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
		'video_level' => [1,'1b',1.1,1.2,1.3,2,2.1,2.2],
		'num_channels' => [8]
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
	     'testcaseID'     => "dvtb_h264_video_level.#{@current_id}",
	     'description'    => "H.264 Encoder video Level "+params['video_level']+" Test.", 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_H264_LEVELS\dvtb_h264_levels.rb',
		 'configID' => 'dvtb_h264_g711.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' => get_bit_rate(params['video_level']),
				'video_frame_rate' => get_frame_rate(params['video_level']),
				'video_gop' => get_gop(params['video_level']),
				'video_encoder_preset' => 3,
				'video_gen_header' => 0,
				'video_capture_width' => 0,
				'video_force_iframe' => 0,
				'video_rate_control' => 5,
				'video_input_chroma_format' => "420p",
				'video_height' => get_video_height(params['video_level']),
				'video_width' => get_video_width(params['video_level']),
				'video_source' => get_source_file(params['video_level']),
				'video_rc_algo' => 0,
				'video_qp_min' => 10,
				'video_qp_max' => 40,
				'video_qp_inter' => 25,
				'video_qp_intra' => 25,
				'video_lf_disable_idc' => 0,
				'video_filter_offset_a' => 0,
				'video_filter_offset_b' => 0,
				'video_max_mb_per_slice' => 0,
				'video_max_bytes_per_slice' => get_bytes_per_slice(params['video_level']),
				'video_slice_refresh_row_start_num' => 0,
				'video_slice_refresh_row_num' => 0,
				'video_constr_intra_pred_enabled' => 0,
				'video_air_mb_period' => 0,
				'video_quarter_pel_disable' => 1,
				'video_pic_order_cnt' => 0,
				'video_log2_maxF_num_minus4' => 4,
				'video_chroma_qp_index_offset' => 0,
				'video_search_range' => 64,
				'video_level' => get_video_level(params['video_level']),
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
   def get_bytes_per_slice(level) 
	if level == 2
	 1500
	else
	 1300
	end
   end
   
   def get_video_level(level)
	case level.to_s.strip
	when '1'
		10
	when '1b'
		9
	when '1.1'
		11
	when '1.2'
		12
	when '1.3'
		13
	when '2'
		20
	when '2.1'
		21
	when '2.2'
		22
	else
		raise "Level "+level.to_s+" not supported"
	end
   end
   
   def get_source_file(level)
	case level.to_s.strip
	when '1'
		'miss_am_128x96_420p_150frames.yuv'
	when '1b'
		'grasses_176x144_420p_250frames.yuv'
	when '1.1'
		'cablenews_320x240_420p_511frames.yuv'
	when '1.2'
		'shrek_3_352x240_420p_264frames.yuv'
	when '1.3'
		'philips_night_352x288_420p_600frames.yuv'
	when '2'
		'fish_352x288_420p_300frames.yuv'
	when '2.1'
		'tt_352x288_420p_300frames.yuv'
	when '2.2'
		'mummy_4_720x576_420p_323frames.yuv'
	else
		raise "Level "+level.to_s+" not supported"
	end
   end
   
   def get_video_height(level)
	case level.to_s.strip
	when '1'
		96
	when '1b'
		144
	when '1.1','1.2'
		240
	when '1.3','2','2.1'
		288
	when '2.2'
		576
	else
		raise "Level "+level.to_s+" not supported"
	end
   end
   
   def get_video_width(level)
	case level.to_s.strip
	when '1'
		128
	when '1b'
		176
	when '1.1'
		320
	when '1.2','1.3','2','2.1'
		352
	when '2.2'
		720
	else
		raise "Level "+level.to_s+" not supported"
	end
   end	
   
   def get_frame_rate(level)
	case level.to_s.strip
	when '1'
		30
	when '1b'
		0
	when '1.1','1.2'
		15
	when '1.3','2','2.1','2.2'
		30
	else
		raise "Level "+level.to_s+" not supported"
	end
   end	
   
   def get_gop(level)
	case level.to_s.strip
	when '1','1b','1.2'
		15
	when '1.1'
		10
	when '1.3','2','2.1'
		30
	when '2.2'
		12.5
	else
		raise "Level "+level.to_s+" not supported"
	end
   end

   def get_bit_rate(level)
	case level.to_s.strip
	when '1'
		64000
	when '1b'
		128000
	when '1.1'
		192000
	when '1.2'
		384000
	when '1.3'
		768000
	when '2.1','2'
		2000000
	when '2.2'
		4000000
	else
		raise "Level "+level.to_s+" not supported"
	end
   end
end