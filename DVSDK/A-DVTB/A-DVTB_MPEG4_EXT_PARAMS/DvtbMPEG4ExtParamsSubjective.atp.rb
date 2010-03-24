require '../media_filer_utils'

include MediaFilerUtils

class DvtbMPEG4ExtParamsSubjectiveTestPlan < TestPlan
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
  @mpeg4_level_resctrictions = {
        'mpeg4_0' => {'sp' => {'res' => '128x96', 'bitrate' => 64000}, 'asp' => {'res' => '176x144', 'bitrate' => 128000}},
        'mpeg4_1' => {'sp' => {'res' => '128x96', 'bitrate' => 64000}, 'asp' => {'res' => '176x144', 'bitrate' => 128000}},
        'mpeg4_2' => {'sp' => {'res' => '176x144', 'bitrate' => 128000}, 'asp' => {'res' => '352x288', 'bitrate' => 384000}},
        'mpeg4_3' => {'sp' => {'res' => '176x144', 'bitrate' => 384000}, 'asp' => {'res' => '352x288', 'bitrate' => 768000}},
        'mpeg4_4' => {'sp' => nil, 'asp' => {'res' => '352x576', 'bitrate' => 3000000}},
        'mpeg4_5' => {'sp' => nil, 'asp' => {'res' => '720x576', 'bitrate' => 8000000}},
        'mpeg4_0b' => {'sp' => {'res' => '176x144', 'bitrate' => 128000}, 'asp' => nil},
   }
   @h263_level_resctrictions = {
      'h263_10' => {'res' => ['176x144','128x96'], 'bitrate' => 64000},
      'h263_20' => {'res' => ['352x288','176x144','128x96'], 'bitrate' => 128000},
      'h263_30' => {'res' => ['352x288','176x144','128x96'], 'bitrate' => 384000},
      'h263_40' => {'res' => ['352x288','176x144','128x96'], 'bitrate' => 2048000},
      'h263_45' => {'res' => ['176x144','128x96'], 'bitrate' => 128000},
   }
  params = {
    
    'video_codec' => ['mpeg4extenc'],
    'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
    'video_rate_control'=> ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
    'video_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'], # 1 -> byte bug-endian stream, 2 -> 16 bit little endian, 3 -> 32 bit little endian. Only 1 is supported in mpeg4sp
    'video_input_chroma_format' => ["420p","422i", "420sp"], # input chroma format
    'video_output_chroma_format' => ["420p", "420sp", "na"], # output chroma format
    'video_input_content_type' => ['progressive', 'interlaced', 'top_field', 'bottom_field'], # 0 -> progressive, 1 -> interlaced. Only 0 is supported in mpeg4sp
    'video_frame_rate' => ['0_to_8',"9_to_16","25_or_30"], # frame rate
    'video_gop' => ["0_to_10","11_to_50","51_to_100","101_to_150","151_to_200","200_to_255"], # intra frame interval
    'video_inter_frame_interval' => [1,2], #max number of B frames calculated as B frames + 1. Only 1 is supported in mpeg4sp
    'video_picture_rotation' => [0,90,180,270], #degrees of picture rotation
    'video_vbv_buffer_size' => [-1, 2], # size of vbv in units of 16384 bits min is 2 units. -1 -> VBV is calculated automatically depending on the resolution; else -> specified number of units will be used
    'video_use_umv' => [0,1], # 0 -> do not use unrestricted motion vector, 1 -> use unrestricted  motion vectors
    'video_encode_mode' => ['svh', 'mpeg4'], # 1 -> mpeg4 mode, 0 -> H.263 mode
    'video_force_frame' => ['na','i','p','b','idr','ii','ip','ib','pi','pp','pb','bi','bp','bb','mbaff_i','mbaff_p','mbaff_b','mbaff_idr'], # Force the current (immediate) frame to be encoded as a specific frame type. IVIDEO_NA_FRAMEFrame type not available. IVIDEO_I_FRAME Intra coded frame. IVIDEO_P_FRAME Forward inter coded frame. IVIDEO_B_FRAME Bi-directional inter coded frame. IVIDEO_IDR_FRAME Intra coded frame that can be used for refreshing video content. IVIDEO_II_FRAME Interlaced frame, both fields are I frames. IVIDEO_IP_FRAME Interlaced frame, first field is an I frame, second field is a P frame. IVIDEO_IB_FRAME Interlaced frame, first field is an I frame, second field is a B frame. IVIDEO_PI_FRAME Interlaced frame, first field is a P frame, second field is a I frame. IVIDEO_PP_FRAME Interlaced frame, both fields are P frames. IVIDEO_PB_FRAME Interlaced frame, first field is a P frame, second field is a B frame. IVIDEO_BI_FRAME Interlaced frame, first field is a B frame, second field is an I frame. IVIDEO_BP_FRAME Interlaced frame, first field is a B frame, second field is a P frame. IVIDEO_BB_FRAME Interlaced frame, both fields are B frames. IVIDEO_MBAFF_I_FRAME Intra coded MBAFF frame. IVIDEO_MBAFF_P_FRAME Forward inter coded MBAFF frame. IVIDEO_MBAFF_B_FRAME Bi-directional inter coded MBAFF frame. IVIDEO_MBAFF_IDR_FRAME Intra coded MBAFF frame that can be used for refreshing video content.  
    'video_mb_data_flag' => [0,1],
    'video_mv_data_enable' => [0,1],
    
    'video_subwindow_resolution' => ['less','equal'],
    'video_intra_dl_vlc_thr'  => [0,4,7],
    'video_intra_thr'       => [192, 300],
    'video_intra_algo'    => ['ii_lq_hp', 'ii_hq_lp'],
    'video_num_mb_rows'    => [-1, 2],
    'video_qp_min_max'=> ['excellent_quality','good_quality','low_quality','good_to_excellent_quality','low_to_good_quality','variable_quality'],
    'video_q_change' => ['mb','picture'],
    'video_q_range' => [2,15,31],
    'video_me_algo'  => ['me_lq_hp', 'me_mq_mp', 'me_hq_mp', 'me_hq_lp'],
    'video_mb_skip_algo'   => ['mb_lq_hp' , 'mb_hq_lp'],
    'video_blk_size'  => ['blk_lq_hp', 'blk_hq_lp'],
    'video_me_range' => [7,31],
    #new
    'video_level' => ['mpeg4_0', 'mpeg4_1', 'mpeg4_2', 'mpeg4_3', 'mpeg4_4', 'mpeg4_5', 'mpeg4_0b', # IMP4VENC_SP_LEVEL_0 MPEG-4 Simple profile level 0 Value = 0. IMP4VENC_SP_LEVEL_0B MPEG-4 Simple profile level 0b Value = 9. IMP4VENC_SP_LEVEL_1 MPEG-4 Simple profile level 1 Value = 1. IMP4VENC_SP_LEVEL_2 MPEG-4 Simple profile level 2 Value = 2. IMP4VENC_SP_LEVEL_3 MPEG-4 Simple profile level 3 Value = 3. IMP4VENC_SP_LEVEL_4A MPEG-4 Simple profile level 4a Value = 4. IMP4VENC_SP_LEVEL_5 MPEG-4 Simple profile level 5 Value = 5
                      'h263_10','h263_20','h263_30','h263_40','h263_45'], # IMP4VENC_H263_LEVEL_10 H263 baseline profile level 10. IMP4VENC_H263_LEVEL_20 H263 baseline profile level 20. IMP4VENC_H263_LEVEL_30 H263 baseline profile level 30. IMP4VENC_H263_LEVEL_40 H263 baseline profile level 40. IMP4VENC_H263_LEVEL_45 H263 baseline profile level 45
    'video_profile' => ['sp','asp'],
    'video_use_vos' => [0,1],
    'video_use_gov' => [0,1],
    'video_use_vol_at_gov' => [0,1],
    'video_use_qpel' => [0,1],
    'video_use_interlace' => [0,1],
    'video_aspect_ratio' => ['1:1','12:11','10:11','16:11','40:33'], # IMP4VENC_AR_SQUARE 1:1 Square See Table 6-14 in MPEG-4 visual standard. IMP4VENC_AR_12_11 12:11 (625 type for 4:3 picture) See Table 6-14 in MPEG-4 visual standard. IMP4VENC_AR_10_11 10:11 (525 type for 4:3 picture) See Table 6-14 in MPEG-4 visual standard. IMP4VENC_AR_16_11 16:11 (625 type stretched for 16:9 picture) See Table 6-14 in MPEG-4 visual standard. IMP4VENC_AR_40_33 40:33 Square (525 type stretched for 16:9 picture) See Table 6-14 in MPEG-4 visual standard.
    'video_pixel_range' => ['16_235','0_255'], # IMP4VENC_PR_16_235 video_range=0, gives a range of Y from 16 to 235, Cb and Cr from 16 to 240. See Section 6.3.2 in MPEG-4 visual standard. IMP4VENC_PR_0_255 video_range=1 gives a range of Y from 0 to 255, Cb and Cr from 0 to 255. See Section 6.3.2 in MPEG-4 visual standard.
    'video_timer_resolution' => [30000,65534], # Timer resolution used for time stamp calculations. No of ticks per second. This should be greater than or equal to maximum frame rate in fps, and the value should be greater than 1 and less than 65535. Default value is 30000.
    'video_reset_imcop_every_frame' => [0,1],
    'video_four_mv_mode' => [0,1],
    'video_packet_size' => [0, 2048], # Insert resync marker (RM) after given specified number of bits. A value of zero implies do not insert packets. Minimum packet size is 1024 bits.
    'video_use_hec' => [0,1],
    'video_use_gob_sync' => [0,-1], # Number of GOB headers to be put in H263 bit stream Range : 0 to No.of MB Rows - 1.
    'video_rc_algo' => ['none','vbr','cbr'],
    'video_max_delay' => [1000, 10000], # Maximum acceptable delay in milliseconds for rate control. This value should be greater than 100 ms. Currently, there is no maximum limit for this parameter. However, the application can use up to 10000 ms. Typical value is 1000 ms
    'video_perceptual_rc' => [0,1], # Flag to switch perceptual rate control Default value is ‘0’.
    'video_insert_end_seq_code' => [0,1], # Flag to insert Sequence end code at the end of frame data. Default value is ‘0’.
    'video_enc_quality' => ['high','std'],
    'video_use_rvlc' => [0,1],
    'video_use_data_pratition' => [0,1],
    'video_air_rate' => [0,-1],
    #End new
    'video_num_channels' => [1],
  }
  
  video_res_and_bit_rates = [
    { 
      'video_bit_rate' => [64000],
      'video_resolution' => ["128x96"],
            },
    {
      'video_resolution' => ["176x120"],
      'video_bit_rate' => [64000,170000,260000,350000,512000],
            },
    { 
      'video_resolution' => ["176x144"],
      'video_bit_rate' => [64000,170000,260000,350000,512000],
            },
    { 
      'video_resolution' => ["320x240"],
      'video_bit_rate' => [128000, 350000,825000,1300000, 2000000],
            },
    { 
      'video_resolution' => ["352x240"],
      'video_bit_rate' => [128000, 350000,825000,1300000, 2000000],
            },
    {   
      'video_resolution' => ["352x288"],
      'video_bit_rate' => [128000, 350000,825000,1300000, 2000000],
            },
    {   
      'video_resolution' => ["640x480"],
      'video_bit_rate' => [512000,1300000,4000000,10000000],
            },
    {   
      'video_resolution' => ["704x480"],
      'video_bit_rate' => [512000,1300000,4000000,10000000],
            },
    {   
      'video_resolution' => ["704x576"],
      'video_bit_rate' => [512000,1300000,4000000,10000000],
            },
    { 
      'video_resolution' => ["720x480"],
      'video_bit_rate' => [512000,1300000,4000000,10000000],
            },
    { 
      'video_resolution' => ["720x576"],
      'video_bit_rate' => [512000,1300000,4000000,10000000],
            },
    {
      'video_resolution' => ['800x600'],
      'video_bit_rate' =>  [1000000,2000000,4000000,7000000,10000000,11000000,12000000,14000000,15000000]  
            },
    {
      'video_resolution' => ['1024x768'],
      'video_bit_rate' =>  [1000000,2000000,4000000,8000000,10000000,11000000,12000000,14000000,15000000]    
            },
    {
      'video_resolution' => ['1280x720'],
      'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000,11000000,12000000,14000000,15000000]    
            },
    {  'video_resolution' => ['1280x960'],
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
     
     svh_mode_res_br = []
     @res_params['video_resolution_and_bit_rate'].each do |bitrate_res|
        svh_mode_res_br << bitrate_res if bitrate_res.match(/(128x96|176x144|352x288|704x576|1408x1152)_\d+/)
     end
     format_constraints = Array.new
     svh_group = '"'+svh_mode_res_br[0]+'"' if svh_mode_res_br[0]
     1.upto(svh_mode_res_br.length-1) do |res_br_idx|
        svh_group += ',"'+svh_mode_res_br[res_br_idx]+'"'
     end
     mpeg4_only = ['video_profile','video_use_vos', 'video_use_gov', 'video_use_vol_at_gov','video_use_qpel','video_use_interlace',
                  'video_four_mv_mode', 'video_packet_size', 'video_use_hec', 'video_use_data_pratition'] & @res_params.keys
     if mpeg4_only.length > 0 
       svh_constr = 'IF [video_encode_mode] = "svh" THEN [' + mpeg4_only[0] + '] = '
       if @res_params[mpeg4_only[0]][0].kind_of?(String)
        svh_constr += '"'+@res_params[mpeg4_only[0]][0]+'"'
       else
        svh_constr += @res_params[mpeg4_only[0]][0].to_s
       end
       mpeg4_only[1..-1].each do |cur_param|
          svh_constr += ' AND [' + cur_param + '] = ' 
          if @res_params[cur_param][0].kind_of?(String)
            svh_constr += '"'+@res_params[cur_param][0]+'"'
          else
            svh_constr += @res_params[cur_param][0].to_s
          end
       end
     end
    if @res_params.has_key?('video_level') && @res_params['video_level'][0].strip.downcase != 'nsup'
      @h263_level_resctrictions.each do |level, res_bitrate|
        res_bitrate_group = ''
        @res_params['video_resolution_and_bit_rate'].each do |res_br|
          resolution, bitrate = res_br.split('_')
          res_bitrate_group += '"' + res_br + '", ' if !res_bitrate['res'].include?(resolution) || bitrate.to_i > res_bitrate['bitrate']
        end
        res_bitrate_group.sub!(/, $/,'')
        format_constraints << 'IF [video_level] = "' + level +'" THEN  [video_resolution_and_bit_rate] NOT IN {' + res_bitrate_group + '};' if res_bitrate_group.strip != ''
      end
    end
    if @res_params.has_key?('video_level') && @res_params['video_level'][0].strip.downcase != 'nsup' && @res_params.has_key?('video_profile') && @res_params['video_profile'][0].strip.downcase != 'nsup'
      @mpeg4_level_resctrictions.each do |level, profile_res_bitrate|
        profile_res_bitrate.each do |prof, res_bitrate|
          res_bitrate_group = ''
          @res_params['video_resolution_and_bit_rate'].each do |res_br|
            resolution, bitrate = res_br.split('_')
            cur_width, cur_height =  resolution.split('x')
            res_bitrate_group += '"' + res_br + '", ' if !res_bitrate || (cur_width.to_i > res_bitrate['res'].split('x')[0].to_i) || (cur_height.to_i > res_bitrate['res'].split('x')[1].to_i) || (bitrate.to_i > res_bitrate['bitrate'])
          end
          rbg = res_bitrate_group.sub(/, $/,'')
          format_constraints << 'IF [video_level] = "' + level +'" AND [video_profile] = "' + prof + '" THEN  [video_resolution_and_bit_rate] NOT IN {' + rbg + '};' if rbg.strip != ''
        end
      end
    end
    format_constraints << svh_constr + ';'
    format_constraints << 'IF [video_encode_mode] = "svh" THEN [video_resolution_and_bit_rate] IN {'+ svh_group +'};' if svh_group.to_s != ''
    format_constraints << 'IF [video_profile] <> "asp" THEN [video_use_qpel] = 0 AND [video_use_interlace] = 0;' if !@res_params['video_use_qpel'] && @res_params['video_use_qpel'].to_s.strip.downcase != 'nsup' 
    format_constraints << 'IF [video_encode_mode] = "svh" THEN [video_subwindow_resolution] IN {"equal", "nsup"} AND [video_picture_rotation] = 0;' if svh_group.to_s != '' && @res_params['video_picture_rotation'] && @res_params['video_picture_rotation'].to_s.strip.downcase != 'nsup' 
    format_constraints << 'IF [video_encode_mode] = "mpeg4" THEN [video_use_gob_sync] = 0;' if @res_params['video_use_gob_sync'] && @res_params['video_use_gob_sync'].to_s.strip.downcase != 'nsup' 
    format_constraints |[
    'IF [video_encode_mode] = "svh" THEN [video_level] IN {"h263_10","h263_20","h263_30","h263_40","h263_45","nsup"};',
    'IF [video_encode_mode] = "mpeg4" THEN [video_level] IN {"mpeg4_0", "mpeg4_1", "mpeg4_2", "mpeg4_3", "mpeg4_4", "mpeg4_5", "mpeg4_0b", "nsup"};',
    ]
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
   
     {
       'testcaseID'     => "dvtb_mpeg4_g711_ext_params.#{@current_id}",
       'description'    => "MPEG4 encode test using extended parameters, a resolution of "+get_video_resolution(params)+", and a bit rate of "+get_video_bit_rate(params), 
       'ext' => false,
     'iter' => '1',
     'bft' => false,
     'basic' => true,
     'ext' => false,
     'bestFinal' => false,
     'script' => 'vatf-scripts/DVSDK/A-DVTB/A-DVTB_MPEG4_EXT_PARAMS/dvtb_mpeg4_ext_params_subjective.rb',
     'configID' => 'Config/dvtb_mpeg4_g711.ini',
     'reg'                       => true,
     'auto'                     => true,
     'paramsChan'     => get_params_chan(params),
     'paramsEquip' => {
      },
     'paramsControl' => get_params_control(params),
     }
   end
   # END_USR_CFG get_outputs
   
   def get_params_chan(params)
    sub_window_height = get_subwindow_height(params)
    sub_window_width = get_subwindow_width(params)
    q_min = get_video_qp_min(params)
    q_max = get_video_qp_max(params)
    result = {}
    result['test_type'] = 'encode'
    params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
    result['video_bit_rate'] = get_video_bit_rate(params)
    result['video_frame_rate'] = get_video_frame_rate(params['video_frame_rate']) if params['video_frame_rate'] && params['video_frame_rate'].strip.downcase != 'nsup'
    result['video_gop'] = get_video_gop(params['video_gop']) if params['video_gop'] && params['video_gop'].strip.downcase != 'nsup'
    result['video_qp_inter'] =  (q_min.to_i + q_max.to_i)/2 if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
    result['video_qp_intra'] =  (q_min.to_i + q_max.to_i)/2 if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
    result['video_height'] =  get_video_height(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
    result['video_width'] =  get_video_width(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
    result['video_vbv_buffer_size'] =  get_vbv_buffer_size(params) if params['video_vbv_buffer_size'] && params['video_vbv_buffer_size'].strip.downcase != 'nsup'
    result['video_use_umv'] =  get_umv_flag(params) if params['video_use_umv'] && params['video_use_umv'].strip.downcase != 'nsup'
    result['video_qp_min'] = q_min if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
    result['video_qp_max'] = q_max if params['video_qp_min_max'] && params['video_qp_min_max'].strip.downcase != 'nsup'
    result['video_subwindow_height'] =  sub_window_height if params['video_subwindow_resolution'] && params['video_subwindow_resolution'].strip.downcase != 'nsup'
    result['video_subwindow_width'] =  sub_window_width if params['video_subwindow_resolution'] && params['video_subwindow_resolution'].strip.downcase != 'nsup'
    result['video_num_mb_rows'] =  get_num_mb_rows(params,sub_window_height) if params['video_num_mb_rows'] && params['video_num_mb_rows'].strip.downcase != 'nsup'
    result['video_source'] = get_video_source(params) 
    result['video_use_gob_sync'] = get_gob_sync(params) if params['video_use_gob_sync'] && params['video_use_gob_sync'].strip.downcase != 'nsup'
    result['video_air_rate'] = get_air_rate(params) if params['video_air_rate'] && params['video_air_rate'].strip.downcase != 'nsup'
    result.delete('video_resolution_and_bit_rate')
    result.delete('video_subwindow_resolution')
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
   
   def get_video_qp_min(params)
    qp_min_max = params['video_qp_min_max']
    if params['video_encode_mode'].strip.downcase == 'svh'
      min_qp = case qp_min_max
        when 'excellent_quality'
           rand(5)+8
        when 'good_quality'
          rand(5)+17
        when 'low_quality'
          rand(5)+24
        when 'good_to_excellent_quality'
          [8, rand(15)].max
        when 'low_to_good_quality'
          rand(6)+20
        when 'variable_quality'
          8
        else
         raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
      end
    else
      min_qp = case qp_min_max
        when 'excellent_quality'
           rand(5)+2
        when 'good_quality'
          rand(5)+11
        when 'low_quality'
          rand(5)+21
        when 'good_to_excellent_quality'
          [2, rand(8)].max
        when 'low_to_good_quality'
          rand(8)+16
        when 'variable_quality'
          2
        else
         raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
      end
    end
    min_qp
   end
   
   def get_video_qp_max(params)
    qp_min_max = params['video_qp_min_max']
    if params['video_encode_mode'].strip.downcase == 'svh'
      max_qp = case qp_min_max
        when 'excellent_quality'
          rand(5)+12
        when 'good_quality'
          rand(5)+21
        when 'low_quality'
          rand(6)+26
        when 'good_to_excellent_quality'
          rand(6)+15
        when 'low_to_good_quality'
          rand(6)+25
        when 'variable_quality'
          31
        else
         raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
      end
    else
      max_qp = case qp_min_max
        when 'excellent_quality'
          rand(6)+6
        when 'good_quality'
          rand(6)+16
        when 'low_quality'
          rand(6)+26
        when 'good_to_excellent_quality'
          rand(8)+8
        when 'low_to_good_quality'
          rand(9)+23
        when 'variable_quality'
          31
        else
         raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
      end
    end
    max_qp
   end
   
   def get_subwindow_height(params)
    case params['video_subwindow_resolution'].strip.downcase
      when 'equal'
        get_video_height(params)
      when 'less'
          [16,rand((get_video_height(params).to_i/16).floor)*16].max
      else params['video_subwindow_resolution'].split('_')[1]
    end
   end
   
   def get_subwindow_width(params)
    case params['video_subwindow_resolution'].strip.downcase
      when 'equal'
        get_video_width(params)
      when 'less'
        [16,rand((get_video_width(params).to_i/16).floor)*16].max
      else params['video_subwindow_resolution'].split('_')[0]
    end
   end
   
   def get_num_mb_rows(params,sub_window_height)
     if params['video_num_mb_rows'].to_i <= 0
       [1,rand((sub_window_height.to_i/16).floor+1)].max
     else params['video_num_mb_rows']
     end
   end
   
   def get_params_control(params)
      result = {
        'video_num_channels' => params['video_num_channels'],
      }
   end
   
   def get_umv_flag(params)
    width = get_video_width(params).to_i
    if width < 192
       0
    else
       params['video_use_umv']
    end 
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
  
  def get_vbv_buffer_size(params)
    if params['video_vbv_buffer_size'].to_i == -1
      case get_video_width(params).to_i
        when 176,128
            10
        when 352,320
            40
        else
          (get_video_width(params).to_i*get_video_height(params).to_i*7.758/16384).floor
      end
    else
      params['video_vbv_buffer_size']
    end
  end
   
  def get_video_qp_inter_intra_max(qp_min_max)
    quality_delta = rand(8)
    case qp_min_max
      when 'excellent_quality'
        quality_delta + 2
      when 'good_quality'
        quality_delta + 9
      when 'low_quality'
        quality_delta + 17
      when 'poor_quality'
        quality_delta + 24
      else
       raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
    end
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
  
  def get_video_resolution(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_bit_rate(params)
    params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_gob_sync(params)
    if params['video_use_gob_sync'].to_i >= 0
      params['video_use_gob_sync']
    else
      (get_video_height(params).to_i/32).floor.to_s
    end
  end
  
  def get_air_rate(params)
    if params['video_air_rate'].to_i >= 0
      params['video_air_rate']
    else
      (get_video_height(params).to_i*get_video_width(params).to_i/512).floor.to_s
    end
  end
end