require '../media_filer_utils'

include MediaFilerUtils

class DvtbMPEG4ExtParamsTestPlan < TestPlan
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
  @signal_format_max_res = {
         '525' => [720,480],
         '625' => [720,576], 
         '720p50' => [1280,720],
         '720p59' => [1280,720],
         '720p60' => [1280,720],          
    }
  common_params = {
  
    'video_input_driver' => ['vpfe+encoder','encoder','none'], #type of front end operation
    'video_output_driver' => ['decoder+vpbe','decoder','none'], # type of backend operation
    'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
    'video_rate_control'=> ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
    'video_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'], # 1 -> byte bug-endian stream, 2 -> 16 bit little endian, 3 -> 32 bit little endian. Only 1 is supported in mpeg4sp
    'video_input_chroma_format' => ["420p","422i", "420sp"], # input chroma format
    'video_output_chroma_format' => ["420p", "420sp"], # output chroma format
    'video_input_content_type' => ['progressive', 'interlaced', 'top_field', 'bottom_field'], # 0 -> progressive, 1 -> interlaced. Only 0 is supported in mpeg4sp
    'video_resolution' => ["128x96", "176x120","176x144","320x240","352x240","352x288","640x480","704x480","704x576","720x480","720x576", "800x600", "1024x768", "1280x720", "1280x960"],
    'video_bit_rate' => [64000,128000,170000,260000,350000,512000,825000,1300000,2000000,4000000,10000000,11000000, 12000000, 14000000, 15000000],
    'video_frame_rate' => ['0_to_8',"9_to_16","25_or_30"], # frame rate
    'video_gop' => ["0_to_10","11_to_50","51_to_100","101_to_150","151_to_200","200_to_255"], # intra frame interval
    'video_inter_frame_interval' => [1,2], #max number of B frames calculated as B frames + 1. Only 1 is supported in mpeg4sp
    'video_picture_rotation' => [0,90,180,270], #degrees of picture rotation
    'video_vbv_buffer_size' => [-1, 2], # size of vbv in units of 16384 bits min is 2 units. -1 -> VBV is calculated automatically depending on the resolution; else -> specified number of units will be used
    'video_use_umv' => [0,1], # 0 -> do not use unrestricted motion vector, 1 -> use unrestricted  motion vectors
    'video_encode_mode' => ['svh', 'mpeg4'], # 1 -> mpeg4 mode, 0 -> H.263 mode
    'video_source' => ['dvd','camera','media_filer'],
    'video_force_iframe' => [0,1],
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
    
    'media_time' => [15], # time in sec to perform the video processing operation.
    'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
    'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
    'video_quality_metric' => ['jnd\=5','mos\=3.5'],
    'video_num_channels' => [1],
  }
  @video_source_hash = get_source_files_hash("\\w*",common_params['video_resolution'],"_\\w*_{0,1}",common_params['video_source_chroma_format'],"\\w*\\d{3}frames","yuv")
  
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
  @res_params = combine_res_and_bit_rate(common_params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params
  
  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     const_hash = {}
     const_hash.default = []
     svh_mode_res_br = []
     @res_params['video_resolution_and_bit_rate'].each do |bitrate_res|
         resolution = (bitrate_res.strip.split("_")[0]).split('x')
         @res_params['video_signal_format'].each do |format|
             if @signal_format_max_res[format] && (@signal_format_max_res[format][0] < resolution[0].to_i || @signal_format_max_res[format][1] < resolution[1].to_i)
                 const_hash[format] = const_hash[format]|[bitrate_res]
             end
         end
         svh_mode_res_br << bitrate_res if bitrate_res.match(/(128x96|176x144|352x288|704x576|1408x1152)_\d+/)
     end
     format_constraints = Array.new
     const_hash.each do |format,bitrate_res|
         current_group ='"'+bitrate_res[0]+'"'
         1.upto(bitrate_res.length-1){|i| current_group+=', "'+bitrate_res[i]+'"'}
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [video_resolution_and_bit_rate] NOT IN {'+ current_group +'};'
     end
     svh_group = '"'+svh_mode_res_br[0]+'"' if svh_mode_res_br[0]
     1.upto(svh_mode_res_br.length-1) do |res_br_idx|
        svh_group += ',"'+svh_mode_res_br[res_br_idx]+'"'
     end
    format_constraints << 'IF [video_encode_mode] = "svh" THEN [video_subwindow_resolution] = "equal" AND [video_picture_rotation] = 0 AND [video_resolution_and_bit_rate] IN {'+ svh_group +'};' if svh_group.to_s != ''
    format_constraints |[
    'IF [video_input_driver] IN {"vpfe+encoder","vpfe+resizer+encoder"} THEN [video_output_driver] <> "decoder";',
    'IF [video_input_driver] = "encoder" THEN [video_output_driver] <> "decoder+vpbe";',
    'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";', 
    'IF [video_iface_type] IN {"composite","svideo","scart"} THEN [video_signal_format] IN {"525","625"};',
    'IF [video_iface_type] IN {"vga","hdmi","dvi","sdi"} THEN [video_signal_format] IN {"1080i50", "1080i59", "1080i60", "720p50", "720p59", "720p60", "1080p23", "1080p24", "1080p25", "1080p29", "1080p30", "1080p50", "1080p59", "1080p60"};',
   ]
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
   sub_window_height = get_subwindow_height(params)
   sub_window_width = get_subwindow_width(params)
   q_min = get_video_qp_min(params['video_qp_min_max'])
   q_max = get_video_qp_max(params['video_qp_min_max'])
     {
       'testcaseID'     => "dvtb_mpeg4_g711_ext_params.#{@current_id}",
       'description'    => "MPEG4 "+get_test_type(params)+" using extended parameters, a resolution of "+get_video_resolution(params)+", and a bit rate of "+get_video_bit_rate(params), 
       'ext' => false,
     'iter' => '1',
     'bft' => false,
     'basic' => true,
     'ext' => false,
     'bestFinal' => false,
     'script' => 'Common\A-DVTB_MPEG4_G711_EXT_PARAMS\dvtb_mpeg4_g711_ext_params.rb',
     'configID' => '..\Config\dvtb_mpeg4_g711_ext_params.ini',
     'reg'                       => true,
     'auto'                     => true,
     'paramsChan'     => {
        'video_bit_rate' => get_video_bit_rate(params),
        'video_frame_rate'=> get_video_frame_rate(params['video_frame_rate']),
        'video_gop'=> get_video_gop(params['video_gop']),
        'video_rate_control'=>params['video_rate_control'],
        'video_encoder_preset' => params['video_encoder_preset'],
        'video_qp_inter' => (q_min.to_i + q_max.to_i)/2,
        'video_qp_intra' => (q_min.to_i + q_max.to_i)/2,
        'video_height' => get_video_height(params),
        'video_width' => get_video_width(params),
        'video_data_endianness' => params['video_data_endianness'],
        'video_input_chroma_format' => params['video_input_chroma_format'],
        'video_output_chroma_format' => params['video_output_chroma_format'],
        'video_input_content_type' => params['video_input_content_type'],
        'video_inter_frame_interval' => params['video_inter_frame_interval'],
        'video_source' => get_source_file(params),
        'test_type' => get_test_type(params),        
        'video_vbv_buffer_size' => get_vbv_buffer_size(params),
        'video_encode_mode' => params['video_encode_mode'],
        'video_use_umv' => get_umv_flag(params),
        'video_picture_rotation' => params['video_picture_rotation'],
        'video_iface_type' => params['video_iface_type'],
        'video_signal_format' => params['video_signal_format'],
        'video_force_iframe' => params['video_force_iframe'],
        'video_picture_rotation' => params['video_picture_rotation'],
        'video_mv_data_enable' => params['video_mv_data_enable'],
        
        'video_qp_min'    => q_min,
        'video_qp_max'    => q_max,
        'video_subwindow_height' => sub_window_height,
        'video_subwindow_width' => sub_window_width,
        'video_intra_dl_vlc_thr' => params['video_intra_dl_vlc_thr'],
        'video_intra_thr'   => params['video_intra_thr'],
        'video_intra_algo'  => params['video_intra_algo'],
        'video_num_mb_rows' => get_num_mb_rows(params,sub_window_height),
        'video_q_change' => params['video_q_change'],
        'video_q_range'  => params['video_q_range'],
        'video_me_algo'  => params['video_me_algo'],
        'video_mb_skip_algo' => params['video_mb_skip_algo'],
        'video_blk_size' => params['video_blk_size'],
        'video_me_range' => params['video_me_range'],
        'video_mb_data_flag' => params['video_mb_data_flag'],
          },
     'paramsEquip' => {
      },
     'paramsControl' => get_params_control(params),
     }
   end
   # END_USR_CFG get_outputs
   
   def get_video_qp_min(qp_min_max)
  #qp_min_max.split('/')[0].strip
  case qp_min_max
    when 'excellent_quality'
      min_qp = rand(5)+2
    when 'good_quality'
      min_qp = rand(5)+11
    when 'low_quality'
      min_qp = rand(5)+21
    when 'good_to_excellent_quality'
      min_qp = [2, rand(8)].max
    when 'low_to_good_quality'
      min_qp = rand(8)+16
    when 'variable_quality'
      min_qp = 2
    else
     raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
  end
  min_qp
   end
   
   def get_video_qp_max(qp_min_max)
  #qp_min_max.split('/')[1].strip
  case qp_min_max
    when 'excellent_quality'
      max_qp = rand(6)+6
    when 'good_quality'
      max_qp = rand(6)+16
    when 'low_quality'
      max_qp = rand(6)+26
    when 'good_to_excellent_quality'
      max_qp = rand(8)+8
    when 'low_to_good_quality'
      max_qp = rand(9)+23
    when 'variable_quality'
      max_qp = 31
    else
     raise 'Video_qp_min_max type'+qp_min_max.to_s+' not supported'
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
   
   def get_test_type(params)
    (params['video_input_driver']+'+'+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"").gsub(/^_/,"").gsub(/_$/,"")
   end
   
   def get_source_file(params)
    if params['video_source'] == 'media_filer'
      video_source = @video_source_hash["\\w*"+video_resolution+"_\\w*_{0,1}"+params['video_input_chroma_format']+"\\w*\\d{3}frames"].to_s
    else
      video_source = params['video_source']
    end
    video_source = 'not found' if video_source.strip == ''
    video_source
   end
   
   def get_params_control(params)
      result = {
        'video_num_channels' => params['video_num_channels'],
        'media_time' => params['media_time'],
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
  
end