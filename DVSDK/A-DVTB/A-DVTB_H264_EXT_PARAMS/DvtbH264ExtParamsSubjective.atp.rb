require '../media_filer_utils'

include MediaFilerUtils

class DvtbH264ExtParamsSubjectiveTestPlan < TestPlan
  attr_reader :video_source_hash
  # BEG_USR_CFG setup
  # General setup:
  def setup()
  @order = 2
  @group_by = ['video_resolution_and_bit_rate']
  @sort_by = ['video_resolution_and_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
  srand = 4321
  @level_max_res_mb = {
         99 => [1],
         396 => [11,12,13,20], 
         792 => [21],
         1620 => [22,30],
         3600 => [31],
         5120 => [32],
         8192 => [40,41],
         8704 => [42],
         22080 => [50],
         36864 => [51],        
	  }
  params = {
    'video_codec' => ['h264extenc', 'h264fhdextenc'],
    'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
    'video_rate_control'=> ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
    'video_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
    'video_inter_frame_interval' => [1,2], #max number of B frames
    'video_input_chroma_format' => ["420p","422i","420sp", "na"], # input chroma format
    'video_input_content_type' => ['progressive', 'interlaced', 'top_field', 'bottom_field'],
    'video_output_chroma_format' => ["420p","422i", "420sp", "na"], # output chroma format
    'video_frame_rate' => ['0_to_8',"9_to_16","25_or_30"], # frame rate
    'video_gop' => ["0_to_10","11_to_50","51_to_100","101_to_150","151_to_200","200_to_255"], # intra frame interval
    'video_profile' => ['baseline', 'main', 'extended', 'high', 'high_10', 'high_10_intra', 'high_422', 'high_422_intra', 'high_444_pred', 'high_444_intra', 'cavlc_444_intra'], #High 10 Intra, High 4:2:2 Intra, and High 4:4:4 Intra require that constraint_set_flag=1  
    'video_level' => [10, 11, 12, 13, 20, 21, 22, 30, 31, 32, 40, 41, 42, 50, 51], # Encoder level id = level x 10. i.e level 3 is defined as video_level = 30, except for level 1b for which video_level = 11 with constraint_set3_flag = 1
    'video_entropy_coding' => ['cavlc','cabac'],
    'video_qp_min_max'=> ['excellent_quality','good_quality','low_quality','good_to_excellent_quality','low_to_good_quality','variable_quality'],
    'video_rc_algo' => ['dces_tm5', 'plr', 'cbr', 'vbr', 'fixed_qp'],  # Only valid when video_rate_control is set to user_defined
    'video_lf_disable_idc' => [0,1,2], # 0 -> filter all edges, 1 -> disable edge filtering, 2-> disable filtering of slice edges
    'video_air_mb_period' => [0], # intra macroblock period
    'video_transform_8x8_i_frame_flag' => [0,1], # Flag for 8x8 Transform for I frame. 0 – Disable. 1 – Enable. Default value = 1.
    'video_transform_8x8_p_frame_flag' => [0,1], # Flag for 8x8 Transform for P frame. 0 – Disable. 1 – Enable. Default value = 0.
    'video_aspect_ratio' => ['1:1','4:3','16:9'], # x:y aspect ratio.The values for x and y value should be greater than 0 and co-prime with respect to each other. Default value = '1:1'
    'video_pixel_range' => [0,1], # The range for the luma and chroma pixel values. 0 – Restricted Range. 1 – Full Range (0-255). Default value = 1
    'video_time_scale' => [150], # Time resolution value for Picture Timing Information. This should be greater than or equal to frame rate in fps. Default value = 150.
    'video_num_units_ticks' => [1], # Units of Time Resolution constituting the single Tick. Default value = 1.
    'video_enable_vui_params' => [0,1], # Flag for Enable VUI Parameters. 0 – Disable VUI Parameters. 1 – Enable VUI Parameters. Default value = 0.
    'video_reset_hdivc_every_frame' => [0,1], # Flag to reset HDVICP at the start of every frame being encoded. This is useful for multi-channel and multi-format encoding. 1 – ON. 0 – OFF. Default value = 1
    'video_disable_hdivc_every_frame' => [0,1], # Flag to disable HDVICP at the start of every frame being encoded. This is useful for power saving. 1 – ON. 0 – OFF. Default value = 0.
    'video_me_algo' => ['normal_full', 'low_power', 'hybrid'], # The type of Motion Estimation Search Algorithm. 0 – Normal Search. 1 – Low Power Search with vertical GMV. Default value = 0. This feature is only present when encoder preset is XDM_HIGH_QUALITY or encQuality =1.
    'video_use_umv' => [0,1], # Flag to enable the use of Unrestricted motion vectors. 0 – Disable. 1 – Enable. Default value = 0. This feature is only present when encoder preset is XDM_HIGH_QUALITY or encQuality =1
    'video_sequence_scaling_flag' => ['disable', 'auto', 'low', 'moderate', 'high'], # Flag for use of Sequence Scaling Matrix. 0 – Disable. 1 – Auto. 2 – Low. 3 – Moderate. 4 – High. Default value = 1.
    'video_enc_quality' => [0,1], # Flag for High and low quality encoding. 1 – High Quality, full feature. 0 – Standard Quality, high speed. Default value = 0
    'video_max_delay' => [2000], # Maximum acceptable delay in milliseconds for rate control. This value should be greater than 100ms. Currently, there is a maximum limit for this parameter but application can use up to 10000 ms. Typical value is 1000 ms. By default, this is set to 2000 ms at the time of encoder object creation.
    'video_me_multipart' => [0,1], # Flag to enable multiple partitions of macro-blocks. 0 – Single partition. 1 – Multiple partitions. Maximum of 8x8 partitions coded. Default value = 0. This feature is only present when encoder preset is XDM_HIGH_QUALITY or encQuality =1 
    'video_enable_buf_sei' => [0,1], # Flag for enabling Buffering Period SEI message. 0 – Disable. 1 – Enable. Default value = 0
    'video_enable_pic_timing_sei' => [0,1], # Flag for enabling Picture Timing SEI message. 0 – Disable. 1 – Enable. This parameter is disabled if EnableBufSEI is disabled. Default value = 0
    'video_intra_thresh_qf' => [0,1,2,3,4,5], # Quality factor for intra thresholding process. The encoder does the intra-prediction estimation process selectively for MBs in P-frame based on the threshold derived using the quality factor. Valid values : 0 – 5. 0 – Intra prediction estimation is avoided for most of the MBs in the P-frame. 5 – Intra prediction estimation is done for all MBs in the P-frame. Default value = 5. This feature is only present when encoder preset is XDM_HIGH_QUALITY or encQuality =1 
    'video_perceptual_rc' => [0,1], # Flag for enabling Perceptual QP modulation of MBs. 0 – Disable. 1 – Enable. Default value = 1. PRC is disable automatically for maxDelay<100 and rcAlgo = CBR
    'video_idr_frame_interval' => [0, 300], # Interval between two consecutive IDR frames. 0: first frame will be IDR coded. Default value = 0. Generally idrFrameInterval will be larger than intraFrameInterval. For example, idrFrameInterval = 300 and intraFrameInterval = 30. This means that at every 30th frame, there will be an I frame. But at every 300th frame, an IDR frame will be placed instead of I frame. IDR frame is used for syncronization. 
    'video_filter_offset_a' => ['first_index_group','second_index_group','third_index_group'],
    'video_filter_offset_b' => ['first_index_group','second_index_group','third_index_group'],
    'video_chroma_qp_index_offset' => ['worse_than_qpy','similar_to_qpy','better_than_qpy'], # chroma quantization relative to luma quantization
    'video_sec_chroma_qp_index_offset' => ['worse_than_qpy','similar_to_qpy','better_than_qpy'], # High profile only secondary chroma quantization relative to luma quantization
    
    #new
    'video_slice_coding_preset'   => ['default', 'user_defined', 'existing', 'max'], # IH264_SLICECODING_DEFAULT 0: Default slice coding params. IH264_SLICECODING_USERDEFINED 1: User defined slice coding params. IH264_SLICECODING_EXISTING 2: Keep the slice coding params as existing. IH264_SLICECODING_MAX 3:
    'video_slice_mode'          => ['none', 'mbunit', 'bytes', 'offset', 'default' , 'max'], # IH264_SLICEMODE_NONE 0: No multiple slices, Default setting. IH264_SLICEMODE_MBUNIT 1: Slices are controlled based on the number of macro blocks. IH264_SLICEMODE_BYTES 2: Slices are controlled based on number of bytes. IH264_SLICEMODE_OFFSET 3: Slices are controlled based on user defined offset in unit of rows. IH264_SLICEMODE_DEFAULT Default slice coding mode single slice. IH264_SLICEMODE_MAX Reserved for future use
    'video_sequence_scaling_factor' => ['auto', 1, 2 , 4 ], #0: AUTO (Codec internally chooses scalingFactor depending on input resolution). 1: Value of ScalingFactor is 1. 2: Value of ScalingFactor is 2. 4: Value of ScalingFactor is 4. Default auto
    'video_top_field_first_flag' => [0,1], #Flag to indicate when the application should display the top field first
    'video_mb_data_flag' => [0,1], #Flag to indicate that the algorithm should use MB data supplied in additional buffer within inBufs.
    'video_mv_sad_out_flag'    => [0,1], #This flag enables dumping of MV and SAD value of the encoded stream. If the flag is enabled, XDM_GETBUFINFO call will request for one extra buffer to dump the MV and SAD.
    'video_disable_mv_dcost_factor' => ['nsup'], #Reserved
    
    'video_chroma_conversion' => ['line','avg'], # 422 to 420 Chroma conversion mode select. 0: Line drop. 1: Average. Default::0
    'video_stream_format'  => ['byte','nalu'], # Controls the type of stream, byte stream format or NALU format
    'video_pic_aff_flag' => ['nsup'], # Reserved
    'video_adaptive_mbs' => ['nsup'], # Reserved
    'video_transform_4x4_i_frame_flag' => ['disable', 'i_picture', 'p_picture', 'ip_picture'], # 0: Disable 4x4 modes. 1: Enable 4x4 intra modes in I-picture. 2: Enable 4x4 intra modes in P-picture. 3: Enable 4x4 intra modes in both I and P Pictures. Default: Disable 4x4 modes
    'video_me_1080i_mode' => ['nsup'], # Reserved
    'video_mv_data_flag' => [0,1], # Reserved
    'video_interlace_ref_mode' => ['one_field', 'same_parity', 'most_recent', 'adaptive'], # 0: One field default. 1: Predictions from the same parity field. 2: Most recently coded reference. 3: Adaptive reference field. Default: 0
    'video_transform_8x8_disable_flag' => [0,1], # Reserved 
    'video_force_frame' => ['na','i','p','b','idr','ii','ip','ib','pi','pp','pb','bi','bp','bb','mbaff_i','mbaff_p','mbaff_b','mbaff_idr'], # Force the current (immediate) frame to be encoded as a specific frame type. IVIDEO_NA_FRAMEFrame type not available. IVIDEO_I_FRAME Intra coded frame. IVIDEO_P_FRAME Forward inter coded frame. IVIDEO_B_FRAME Bi-directional inter coded frame. IVIDEO_IDR_FRAME Intra coded frame that can be used for refreshing video content. IVIDEO_II_FRAME Interlaced frame, both fields are I frames. IVIDEO_IP_FRAME Interlaced frame, first field is an I frame, second field is a P frame. IVIDEO_IB_FRAME Interlaced frame, first field is an I frame, second field is a B frame. IVIDEO_PI_FRAME Interlaced frame, first field is a P frame, second field is a I frame. IVIDEO_PP_FRAME Interlaced frame, both fields are P frames. IVIDEO_PB_FRAME Interlaced frame, first field is a P frame, second field is a B frame. IVIDEO_BI_FRAME Interlaced frame, first field is a B frame, second field is an I frame. IVIDEO_BP_FRAME Interlaced frame, first field is a B frame, second field is a P frame. IVIDEO_BB_FRAME Interlaced frame, both fields are B frames. IVIDEO_MBAFF_I_FRAME Intra coded MBAFF frame. IVIDEO_MBAFF_P_FRAME Forward inter coded MBAFF frame. IVIDEO_MBAFF_B_FRAME Bi-directional inter coded MBAFF frame. IVIDEO_MBAFF_IDR_FRAME Intra coded MBAFF frame that can be used for refreshing video content.  
    'video_enable_arm926_tcm' => [0,1], # Flag for enabling/disabling usage of ARM926 TCM: 1 – Uses ARM926 TCM. 0 – Does not use ARM926 TCM. Default value = 0
   # end new
    
    'video_constr_intra_pred_enabled' => [0,1], # 0 -> inter pixel not used for intra macro block prediction, 1 -> inter pixels used for intra macro block prediction
    'video_quarter_pel_disable' => [0,1], # 1 -> true, 0 ->false
    'video_pic_order_cnt' => [0, 1, 2], # only 0 and 2 are supported
    'video_log2_maxf_num_minus4' => [0,1,2,3,4,5,6,7,8,9,10,12], #max num of frames in the bitstream
    'video_search_range' => ['auto', 64,256,512], #  auto -> calculate mv search range automatically; Integer -> pel search around macro block equal number
    'video_num_channels' => [1],
    
    }
  
  video_res_and_bit_rates = [{ 'video_bit_rate' => [64000],
              'video_resolution' => ['128x96'],
            },
   {'video_resolution' => ["176x120"],
              'video_bit_rate' => [64000,128000,192000,256000,512000],
            },
   { 'video_resolution' => ["176x144"],
              'video_bit_rate' => [64000,128000,192000,256000,512000],
            },
   { 'video_resolution' => ["320x240"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
   { 'video_resolution' => ["352x240"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
   { 'video_resolution' => ["352x288"],
              'video_bit_rate' => [128000, 256000,768000,1000000, 2000000],
            },
  { 'video_resolution' => ["640x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["704x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["704x576"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["720x480"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  { 'video_resolution' => ["720x576"],
              'video_bit_rate' => [512000,1000000,4000000,10000000],
            },
  {'video_resolution' => ['800x600'],
             'video_bit_rate' =>  [1000000,2000000,4000000,7000000,10000000,11000000,12000000,14000000,15000000]  
             },
  {'video_resolution' => ['1024x768'],
             'video_bit_rate' =>  [1000000,2000000,4000000,8000000,10000000,11000000,12000000,14000000,15000000]    
             },
  {'video_resolution' => ['1280x720'],
             'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]    
             },
  {'video_resolution' => ['1280x960'],
             'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]    
             },
  {'video_resolution' => ['1920x1080'],
             'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]    
             },
  ]
  
  video_resolutions = []
  video_bitrates = []
  video_res_and_bit_rates.each do |res_br| 
    video_resolutions = video_resolutions | res_br['video_resolution']
    video_bitrates = video_bitrates | res_br['video_bit_rate']
  end
  @yuv_video_source_hash = get_source_files_hash("\\w+",video_resolutions,"_",params['video_input_chroma_format'],"\\w*_\\d{2,3}frames","yuv")  
	
  @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    const_hash = {}
     const_hash.default = []
     @res_params['video_resolution_and_bit_rate'].each do |bitrate_res|
        resolution = (bitrate_res.strip.split("_")[0]).split('x')
        res_in_mb = resolution[0].to_i*resolution[1].to_i/256
        @level_max_res_mb.each do |max_size_mb, levels|
          if res_in_mb > max_size_mb
            const_hash[bitrate_res] = const_hash[bitrate_res]|(levels)
          end
        end
     end
     format_constraints = Array.new
     const_hash.each do |bitrate_res,levels|
         current_group =levels[0].to_s
         1.upto(levels.length-1){|i| current_group+=', '+levels[i].to_s}
         format_constraints << 'IF [video_resolution_and_bit_rate] = "'+ bitrate_res + '" THEN [video_level] NOT IN {'+ current_group +'};'
     end
    qp_constraint = @res_params['video_sec_chroma_qp_index_offset'][0]

    format_constraints | [
      'IF [video_profile] IN {"baseline", "main", "extended", "cavlc_444_intra"} THEN [video_sec_chroma_qp_index_offset] = "'+qp_constraint+'";',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
   
     {
        'testcaseID'     => "dvtb_h264_ext_params.#{@current_id}",
        'description'    => "H.264 Encode Test using the codec extended parameters with a resolution of "+get_video_resolution(params)+", and a bit rate of "+get_video_bit_rate(params), 
        'ext' => false,
        'iter' => '1',
        'bft' => false,
        'basic' => true,
        'ext' => false,
        'bestFinal' => false,
        'script' => 'vatf-scripts/DVSDK/A-DVTB/A-DVTB_H264_EXT_PARAMS/dvtb_h264_ext_params_subjective.rb',
        'configID' => 'Config/dvtb_h264_g711.ini',
        'reg'                       => true,
        'auto'                     => true,
        'paramsChan'     => get_params_chan(params),
        'paramsEquip' => {
        },
        'paramsControl' => get_params_control(params),
     }
   end
  # END_USR_CFG get_outputs
   private
   
   def get_params_chan(params)
      qp_min = get_video_qp_min(params['video_qp_min_max'])
      qp_max = get_video_qp_max(params['video_qp_min_max'])
      refresh_row = get_video_slice_refresh_row_start(get_video_resolution(params))
      max_mb_per_slice = get_max_mb_per_slice(params)
      result = {}
      result['test_type'] = 'encode'
      params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
      result['video_bit_rate'] = get_video_bit_rate(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_frame_rate'] = get_video_frame_rate(params['video_frame_rate'])  if params['video_frame_rate'] && params['video_frame_rate'].strip.downcase != 'nsup'
      result['video_gop'] = get_video_gop(params['video_gop'])  if params['video_gop'] && params['video_gop'].strip.downcase != 'nsup'
      result['video_qp_min'] =  qp_min  if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
      result['video_qp_max'] =  qp_max  if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
      result['video_qp_inter'] = get_qp_inter_intra(qp_min,qp_max) if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
      result['video_qp_intra'] = get_qp_inter_intra(qp_min,qp_max) if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
      result['video_filter_offset_a'] = get_filter_offset(params['video_filter_offset_a']) if params['video_filter_offset_a'] && params['video_filter_offset_a'].strip.downcase != 'nsup'
      result['video_filter_offset_b'] = get_filter_offset(params['video_filter_offset_b']) if params['video_filter_offset_b'] && params['video_filter_offset_b'].strip.downcase != 'nsup'
      result['video_max_mb_per_slice'] = max_mb_per_slice if params['video_profile'] && params['video_profile'].strip.downcase != 'nsup'
      result['video_num_rows_per_slice'] =  (max_mb_per_slice.to_f*16/get_video_width(params).to_f).floor if result['video_max_mb_per_slice']
      result['video_max_bytes_per_slice'] = max_mb_per_slice*384 if result['video_max_mb_per_slice'] 
      result['video_slice_refresh_row_start_num'] = refresh_row if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_slice_refresh_num'] = get_video_slice_refresh_row_num(get_video_resolution(params), refresh_row) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_chroma_qp_index_offset'] = get_chroma_qp_index_offset(params['video_chroma_qp_index_offset']) if params['video_chroma_qp_index_offset'] && params['video_chroma_qp_index_offset'].strip.downcase != 'nsup'
      result['video_sec_chroma_qp_index_offset'] = get_chroma_qp_index_offset(params['video_sec_chroma_qp_index_offset']) if params['video_sec_chroma_qp_index_offset'] && params['video_sec_chroma_qp_index_offset'].strip.downcase != 'nsup'
      result['video_search_range'] = get_mv_search_range(params) if params['video_search_range'] && params['video_search_range'].strip.downcase != 'nsup'
      result['video_height'] = get_video_height(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_width'] = get_video_width(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_aspect_ratio_x'] = get_x_aspect(params['video_aspect_ratio']) if params['video_aspect_ratio'] && params['video_aspect_ratio'].strip.downcase != 'nsup' # The value should be greater than 0 and co-prime with AspectRatioY. Default value = 1
      result['video_aspect_ratio_y'] = get_y_aspect(params['video_aspect_ratio']) if params['video_aspect_ratio'] && params['video_aspect_ratio'].strip.downcase != 'nsup' # The value should be greater than 0 and co-prime with AspectRatioX. Default value = 1.
      result['video_source'] = get_video_source(params)
      
      result.delete('video_resolution_and_bit_rate')
      result.delete('video_qp_min_max')
      result.delete('video_aspect_ratio')
      result
   end
   
   def get_params_control(params)
    result = {
      'video_num_channels' => params['video_num_channels'],
    }
   end
  
   def get_video_source(params)
    video_resolution = get_video_resolution(params) 
    @yuv_video_source_hash["\\w+"+video_resolution+"_"+params['video_input_chroma_format']+"\\w*_\\d{2,3}frames"].to_s
   end
  
   def get_video_qp_min(qp_min_max)
    #qp_min_max.split('/')[0].strip
    case qp_min_max
      when 'excellent_quality'
        min_qp = rand(9)+1
      when 'good_quality'
        min_qp = rand(9)+18
      when 'low_quality'
        min_qp = rand(8)+36
      when 'good_to_excellent_quality'
        min_qp = rand(18)
      when 'low_to_good_quality'
        min_qp = rand(18)+18
      when 'variable_quality'
        min_qp = 5
      else
       raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
    end
    min_qp
   end
   
   def get_video_qp_max(qp_min_max)
    #qp_min_max.split('/')[1].strip
    case qp_min_max
      when 'excellent_quality'
        max_qp = rand(9)+9
      when 'good_quality'
        max_qp = rand(9)+27
      when 'low_quality'
        max_qp = rand(9)+43
      when 'good_to_excellent_quality'
        max_qp = rand(18)+18
      when 'low_to_good_quality'
        max_qp = rand(16)+36
      when 'variable_quality'
        max_qp = 51
      else
       raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
    end
    max_qp
   end
   
   def get_filter_offset(index_group)
    case index_group
      when 'first_index_group'
        offset = (rand(4)+3)*-1
      when 'second_index_group'
        offset = (2-1*rand(5))
      when 'third_index_group'
        offset = (rand(4)+3)
      else
      raise 'filter index group type'+index_group.to_s+' not supported'
    end
    offset
   end
   
   def get_qp_inter_intra(qp_min,qp_max)
    ((qp_min+qp_max)/2).round
   end
   
   def get_chroma_qp_index_offset(qp_index_offset)
    case qp_index_offset
      when 'worse_than_qpy'
        offset = 5+rand(8)
      when 'similar_to_qpy'
        offset = rand(9) - 4
      when 'better_than_qpy'
        offset = -1*(5+rand(8))
      else
      raise 'filter index group type'+index_group.to_s+' not supported'
    end
    offset
   end
   
   def get_max_mb_per_slice(params)
    frame_width,frame_height = /(\d+)x(\d+)/.match(get_video_resolution(params)).captures
    [(frame_width.to_i*frame_height.to_i/2048).ceil, rand((frame_width.to_i/16).floor*(frame_height.to_i/16).floor+1)].max
    case params['video_profile'].to_i
      when 44, 77, 100, 110, 122, 244
        get_max_mb_per_frame_for_level(params)
      else
        [(frame_width.to_i*frame_height.to_i/2048).ceil, rand((frame_width.to_i/16).floor*(frame_height.to_i/16).floor+1)].max
    end
   end
   
   def get_max_mb_per_frame_for_level(params)
      case params['video_level'].to_i
        when 9,10
          99
        when 11,12,13,20
          396
        when 21
          792
        when 22,30
          1620
        when 31
          3600
        when 32
          5120
        when 40,41
          8192
        when 42
          8704
        when 50
          22080
        when 51
          36864
        else
          raise 'Level '+params['video_level']+ ' is not defined in the standard'
      end
   end
   
   def get_video_slice_refresh_row_start(resolution)
    frame_width,frame_height = /(\d+)x(\d+)/.match(resolution).captures
    rand((frame_height.to_i/16).floor+1)
   end
   
   def get_video_slice_refresh_row_num(resolution,row_start_num)
    frame_width,frame_height = /(\d+)x(\d+)/.match(resolution).captures
    frame_rows = (frame_height.to_i/16).floor
    rand(frame_rows-row_start_num+2)
   end
   
   def get_video_frame_rate(fps_range)
     if fps_range.eql?('25_or_30')
      if rand >= 0.5
        30
      else
        25
      end
     else
      fps_limits = fps_range.split('_to_')
      offset = fps_limits[0].strip.to_i
      interval_length = fps_limits[1].strip.to_i-offset+1
      [1,offset+rand(interval_length)].max
     end
   end
   
   def get_video_gop(gop_range)
     gop_limits = gop_range.split('_to_')
     offset = gop_limits[0].strip.to_i
     interval_length = gop_limits[1].strip.to_i-offset+1
     offset+rand(interval_length)
   end
   
  def get_video_height(params)
    pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
    res[2]
  end
  
  def get_video_width(params)
    pat = /(\d+)x(\d+)/i
    res = pat.match(get_video_resolution(params))
    res[1]
  end
  
  def get_mv_search_range(params)
    if params['video_search_range'].downcase.include?('auto')
      case params['video_level'].to_i
        when 9,10
          rand(128)-64
        when 11,12,13,20
          rand(256)-128
        when 21,22,30
          rand(512)-256
        when 31,32,40,41,42,50,51
          rand(1024)-512
        else
          raise 'Level '+params['video_level']+ ' is not defined in the standard'
      end
    else
      params['video_search_range']
    end
  end
  
  def get_video_resolution(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_bit_rate(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_x_aspect(ratio)
    ratio.split(':')[0].strip
  end
  
  def get_y_aspect(ratio)
    ratio.split(':')[1].strip
  end
  
  def combine_res_and_bit_rate(dst_hash, array_of_hash=nil)
    result = Array.new
    array_of_hash = [{'video_bit_rate' => dst_hash['video_bit_rate'], 'video_resolution' => dst_hash['video_resolution']}] if !array_of_hash
    array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
    array_of_hash.each do |val_hash|
      val_hash['video_resolution'].each do |video_resolution|
        val_hash['video_bit_rate'].each do |video_bit_rate|
          result << video_resolution.to_s+"_"+video_bit_rate.to_s
        end
      end
    end
    dst_hash.delete('video_resolution')
    dst_hash.delete('video_bit_rate')
    dst_hash.merge!({'video_resolution_and_bit_rate' => result})
    dst_hash
  end
  
end