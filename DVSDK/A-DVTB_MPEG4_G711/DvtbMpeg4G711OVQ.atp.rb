require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4G711OVQTestPlan < TestPlan

  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
    #@auto_gen = ['inputs']
  @group_by = ['video_input_driver:video_output_driver','video_resolution_and_bit_rate', 'video_rate_control']
  @sort_by = ['video_input_driver:video_output_driver','video_resolution_and_bit_rate', 'video_rate_control']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
  @signal_format_max_res = {
         '525' => [720,480],
         '625' => [720,576], 
         '720p50' => [1280,720],
         '720p59' => [1280,720],
         '720p60' => [1280,720],          
    }
    @mpeg4_prof_regex =  "_(ASP|SP)\\w*"
  common_params = {
            'video_input_driver'  => ['vpfe+encoder', 'none'],
            'video_output_driver'  => ['decoder+vpbe', 'none'], 
            'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
            'video_rate_control'=> ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
            'video_bit_rate'    => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000, 11000000, 12000000, 14000000, 15000000],
            'video_resolution'      => ['128x96', '176x120', '176x144', '320x240', '352x240', '352x288', '640x480', '704x288', '704x480', '704x576', '720x480', '720x576', '800x600', '1024x768', '1280x720', '1280x960'],
            'video_frame_rate'      => [5, 10, 15, 'std'],
            'video_num_channels' => [1,8],
            'video_input_chroma_format' => ['420p', '422i', '420sp'],
            'video_output_chroma_format' => ['420p', '422i', '420sp'],
            'video_picture_rotation' => [0,90,180,270], #degrees of picture rotation
            'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
            'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
            'video_source_chroma_format' => ['411p','420p','422i','422p','444p','420sp'],
            'video_quality_metric' => ['jnd\=5','mos\=3.5'],
            'audio_input_driver' => ['apfe+encoder','none'],
            'audio_output_driver' => ['decoder+apbe','none'],
            'video_inter_frame_interval' => [1],
            'video_rec_delay' => [2],
            'audio_num_channels'  => [1,8],
            'audio_source' => ['test1_16bIntel'],
            'audio_companding'     => ['ulaw', 'alaw'],
            'audio_iface_type' => ['rca', 'xlr', 'optical', 'mini35mm',  'mini25mm', 'phoneplug'],
            'audio_sampling_rate' => [8000],
            'setup_delay'     => [32],
            'audio_media_time' => [32],
            'ti_logo_resolution' => ['0x0']
          }
          
  @video_source_hash = get_source_files_hash("\\w*",common_params['video_resolution'],"_\\w*_{0,1}",common_params['video_source_chroma_format'],"\\w*\\d{3}frames","yuv")
  file_bit_rate = Array.new
  common_params['video_bit_rate'].each do |bit_rate| 
    if bit_rate/1000 >= 1000
       file_bit_rate << ((bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
       file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
      file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
    end
  end
  @video_source_hash = @video_source_hash.merge!(get_source_files_hash("\\w+",common_params['video_resolution'],"_",common_params['video_output_chroma_format'],"\\w*",common_params['video_bit_rate'],"bps","mpeg4"))
  @video_source_hash = @video_source_hash.merge!(get_source_files_hash("\\w+",common_params['video_resolution'],@mpeg4_prof_regex,file_bit_rate,"\\w*","mpeg4"))
  
  video_res_and_bit_rates = [
    {
      'video_resolution' => ['128x96'],
      'video_bit_rate'  => [64000],
            },
    {
      'video_resolution' => ['176x120'],
      'video_bit_rate'  => [128000,256000,64000,800000,96000],
            },
    {
      'video_resolution' => ['176x144'],
      'video_bit_rate'  => [2000000,64000,800000,96000,256000,1000000],
            },
    {
      'video_resolution' => ['320x240'],
      'video_bit_rate'  => [256000,512000,768000,1000000],
            },
    {
      'video_resolution' => ['352x240'],
      'video_bit_rate'  => [128000,64000,512000,1000000,500000,350000,800000,256000,1500000,96000],
            },
    {
      'video_resolution' => ['352x288'],
      'video_bit_rate'  => [1000000,2000000,512000,64000,128000,256000,1500000,350000,500000,800000,96000],
            },
    {
      'video_resolution' => ['640x480'],
      'video_bit_rate'  => [4000000,2000000,512000,1000000,786000],
            },
    {
      'video_resolution' => ['704x480'],
      'video_bit_rate'  => [128000,1000000,512000,2000000,1100000,1500000],
            },
    {
      'video_resolution' => ['704x576'],
      'video_bit_rate'  => [128000,1000000,512000,2000000,1100000,1500000],
            },
    {
      'video_resolution' => ['720x480'],
      'video_bit_rate'  => [6000000,128000,384000,800000,2000000,4000000,256000,512000,1000000,10000000],
            },
    {
      'video_resolution' => ['720x576'],
      'video_bit_rate'  => [256000,4000000,1000000,8000000,2000000,800000,512000,6000000,10000000],
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
     @res_params['video_resolution_and_bit_rate'].each do |bitrate_res|
         resolution = (bitrate_res.strip.split("_")[0]).split('x')
         @res_params['video_signal_format'].each do |format|
             if @signal_format_max_res[format] && (@signal_format_max_res[format][0] < resolution[0].to_i || @signal_format_max_res[format][1] < resolution[1].to_i)
                 const_hash[format] = const_hash[format]|[bitrate_res]
             end
         end
     end
     format_constraints = Array.new
     const_hash.each do |format,bitrate_res|
         current_group ='"'+bitrate_res[0]+'"'
         1.upto(bitrate_res.length-1){|i| current_group+=', "'+bitrate_res[i]+'"'}
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [video_resolution_and_bit_rate] NOT IN {'+ current_group +'};'
     end
    format_constraints | [
     'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";',
     'IF [video_output_driver] = "none" THEN [audio_output_driver] = "none";',
     'IF [video_input_driver] = "none"  THEN [audio_input_driver] = "none";',
     'IF [audio_input_driver] <> "none" AND [video_output_driver] <> "none" THEN [audio_output_driver] <> "none";',  
     'IF [audio_output_driver] <> "none" AND [video_input_driver] <> "none" THEN [audio_input_driver] <> "none";',  
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
    {
  'description'    => get_test_description(params),
      'iter'                       => '1',
        'testcaseID'                 => "dvtb_mpeg4_g711_ovq.#{@current_id}",
        'bft'                        => false,
        'basic'                      => false,
        'ext'                        => true,
        'reg'                        => false,
        'auto'                       => true,
        'bestFinal'                  => false,
        'script'                     => 'Common\A-DVTB_MPEG4_G711\dvtb_mpeg4_g711_ovq.rb',

        # channel parameters
      'paramsChan'                => {
            'test_type'                => get_test_type(params),
            'video_codec'                => 'mpeg4',
            'video_encoder_preset'  => params['video_encoder_preset'],
            'video_frame_rate'    => get_video_frame_rate(params),
            'video_bit_rate'            => get_video_bit_rate(params),
            'video_rate_control'=>params['video_rate_control'],
            'video_encoder_preset' => params['video_encoder_preset'],
            'video_height'      => get_video_height(get_video_resolution(params)), 
            'video_width'      => get_video_width(get_video_resolution(params)), 
            'video_input_chroma_format' => params['video_input_chroma_format'],
            'video_output_chroma_format' => params['video_output_chroma_format'],
            'video_source'             => get_video_source(params),
            'video_iface_type' => params['video_iface_type'],
            'video_signal_format' => params['video_signal_format'],
            'video_source_chroma_format' => params['video_source_chroma_format'],
            'video_inter_frame_interval' => params['video_inter_frame_interval'],
            'video_quality_metric' => params['video_quality_metric'],
            'audio_companding' => params['audio_companding'],
            'audio_bit_rate' => 64000,
            'audio_source' => params['audio_source'],
            'audio_sampling_rate' => params['audio_sampling_rate'],
            'audio_iface_type' => params['audio_iface_type'],
        },
    'paramsEquip'     => {
    },
    'paramsControl'     => {
            'video_num_channels' => params['video_num_channels'],
            'audio_num_channels' => params['audio_num_channels'],
            'setup_delay'        => params['setup_delay'], 
            'audio_media_time'   => params['audio_media_time'],
            'ti_logo_resolution' => params['ti_logo_resolution'],
            'video_rec_delay' => params['video_rec_delay']
     },
    'configID'      => '..\Config\dvtb_mpeg4_g711_ovq.ini',
 #   'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  private
    
  def get_test_type(params)
      (params['video_input_driver']+'+'+params['video_output_driver']+"_"+params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"").gsub(/^_/,"").gsub(/_$/,"")
  end
  
  def get_test_description(params)
    description = "Objective Quality Test MPEG4 and G711 " + get_test_type(params) + " test, "
      description += "video_res=#{get_video_resolution(params)}, bit_rate=#{get_video_bit_rate(params)}, frame_rate=#{params['video_frame_rate']}" 
      description += ", audio_companding=#{params['audio_companding']}" if description.include?("apfe") || description.include?("apbe")
      description
  end
  
  def get_video_height(resolution)
  pat = /(\d+)[x|X](\d+)/i
  res = pat.match(resolution)
  res[2]
  end
  
  def get_video_width(resolution)
    pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
    res[1]
  end
  
  def get_video_resolution(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  end
  
  def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  end
  
  def get_video_source(params)
  video_resolution = get_video_resolution(params)
  video_bit_rate = get_video_bit_rate(params)  
    if params['video_input_driver'] == 'none'
    if video_bit_rate.to_f/1000 >= 1000
      file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
      file_bit_rate2 = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
      file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
    end 
      video_source = @video_source_hash["\\w+"+video_resolution+"_"+params['video_output_chroma_format']+"\\w*"+video_bit_rate+"bps"]
      video_source += ";" if video_source && @video_source_hash["\\w+"+video_resolution+@mpeg4_prof_regex+file_bit_rate+"\\w*"]
      video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+@mpeg4_prof_regex+file_bit_rate+"\\w*"].to_s
      video_source += ";" if video_source.to_s.strip != '' && file_bit_rate2 && @video_source_hash["\\w+"+video_resolution+@mpeg4_prof_regex+file_bit_rate2+"\\w*"] 
        video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+@mpeg4_prof_regex+file_bit_rate2+"\\w*"].to_s if file_bit_rate2 
  else
    video_source = @video_source_hash["\\w*"+video_resolution+"_\\w*_{0,1}"+params['video_source_chroma_format']+"\\w*\\d{3}frames"].to_s
  end
  video_source = 'not found' if video_source.strip == ''
  video_source
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
  
  def get_video_frame_rate(params)
    if params['video_frame_rate'].eql?('std')
        case get_video_resolution(params)
            when '176x120', '352x240', '720x480', '704x480' 
                30
            when '176x144', '352x288', '720x576', '704x576'
                25
      else
        rate = 30
        if rand() > 0.5
          rate = 25
        end
        rate
        end
    else
        params['video_frame_rate']
    end     
  end
  
end
