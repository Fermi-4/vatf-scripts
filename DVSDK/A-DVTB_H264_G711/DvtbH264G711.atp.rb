require '../media_filer_utils'
include MediaFilerUtils

class DvtbH264G711TestPlan < TestPlan
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
    @h264_prof_regex = "_(BP|MP)\\w*"
    @signal_format_max_res = {
      '525' => [720,480],
      '625' => [720,576], 
      '720p50' => [1280,720],
      '720p59' => [1280,720],
      '720p60' => [1280,720],          
    }
    params = {
    'video_frame_rate'      => [5, 10, 15, 'std'],
    'video_bit_rate'        => [64000, 96000, 128000, 192000, 256000, 384000, 512000, 768000, 1000000, 1500000, 2000000, 2500000, 3000000, 4000000,  6000000, 8000000, 10000000, 11000000, 12000000, 14000000, 15000000],
    'video_resolution'      => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480', '800x600', '1024x768', '1280x720', '1280x960'],
    'video_source'              => ['camera', 'dvd', 'media_filer'],
    'video_input_chroma_format' => ['420p', '422i', '420sp'],
    'video_output_chroma_format' => ['420p', '422i', '420sp'],
    'video_input_driver' => ['vpfe+encoder', 'vpfe+resizer+encoder','none'],
    'video_encoder_preset' => ['default', 'high_quality', 'high_speed', 'user_defined'], # default -> XDM_DEFAULT, high_quality -> XDM_HIGH_QUALITY, high_speed -> XDM_HIGH_SPEED, user_defined -> XDM_USER_DEFINED
    'video_rate_control'=> ['cbr','vbr','two_pass','none','user_defined'], # CBR -> IVIDEO_LOW_DELAY, VBR -> IVIDEO_STORAGE, two-pass -> IVIDEO_TWOPASS, 'none' -> IVIDEO_NONE, user_defined -> IVIDEO_USER_DEFINED
    'video_output_driver' => ['decoder+vpbe','none'],
    'video_inter_frame_interval' => [1],
    'video_num_channels'        => [1,4],
    'media_time' => [30],
    'audio_input_driver' => ['apfe+encoder','none'],
    'audio_output_driver' => ['decoder+apbe','none'],
    'audio_companding' => ['ulaw','alaw'],
    'audio_sampling_rate' => [8000],
    'audio_num_channels' => [1],    
    'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
    'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
    'audio_iface_type' => ['rca', 'xlr', 'optical', 'mini35mm',  'mini25mm', 'phoneplug'],
  }
  file_bit_rate = Array.new
  params['video_bit_rate'].each do |bit_rate| 
  if bit_rate/1000 >= 1000
     file_bit_rate << ((bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
     file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
  else
     file_bit_rate << ((bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
  end 
  end
  @video_source_hash = get_source_files_hash("\\w+",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*",params['video_bit_rate'],"bps","264")
  @video_source_hash.merge!(get_source_files_hash("\\w+",params['video_resolution'],@h264_prof_regex,file_bit_rate,"\\w*","264"))
  @ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
  @alaw_audio_source_hash = get_source_files_hash("\\w+","a")
  video_res_and_bit_rates = [
    {'video_resolution' => ["128x96"],
               'video_bit_rate' =>  [64000],  
               },
    {'video_resolution' => ["176x120"],
               'video_bit_rate' =>  [64000,96000,128000,256000]  
               },
    {'video_resolution' => ["176x144"],
               'video_bit_rate' =>  [64000,96000,128000,256000,512000]  
               },
    {'video_resolution' => ["320x240"],
             'video_bit_rate' =>  [256000,512000,768000,1000000,1500000]  
             },
    {'video_resolution' => ["352x240"],
             'video_bit_rate' =>  [64000,96000,128000,256000,384000,512000,768000,1000000,1500000,2000000]  
             },
    {'video_resolution' => ["352x288"],
             'video_bit_rate' =>  [64000,256000,384000,512000,768000,1000000,2000000]  
             },
    {'video_resolution' => ["640x480"],
             'video_bit_rate' =>  [512000,1000000,2000000,4000000]  
             },
    {'video_resolution' => ["704x480"],
             'video_bit_rate' =>  [256000,512000,1000000,2000000,3000000,4000000,8000000,10000000]  
             },
    {'video_resolution' => ["720x480"],
             'video_bit_rate' =>  [128000,256000,384000,512000,1000000,2000000,3000000,4000000,6000000,8000000,10000000]  
             },
    {'video_resolution' => ["720x576"],
             'video_bit_rate' =>  [1000000,2000000,4000000,5000000,10000000]  
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
  ]
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
      'IF [video_input_driver] <> "none" THEN [video_source] <> "media_filer";', 
      'IF [video_input_driver] = "none" THEN [video_source] = "media_filer";',
      'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";',
      'IF [video_output_driver] = "none" THEN [audio_output_driver] = "none";',
      'IF [audio_input_driver] <> "none" AND [video_output_driver] <> "none" THEN [audio_output_driver] <> "none";',
      'IF [audio_output_driver] <> "none" AND [video_input_driver] <> "none" THEN [audio_input_driver] <> "none";',
      'IF [video_input_driver] = "none" THEN [audio_input_driver] = "none";',
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
  'description'    =>"test_type=#{get_test_type(params)}, video_res=#{get_video_resolution(params)}, frame_rate=#{params['video_frame_rate']},bit_rate=#{get_video_bit_rate(params)}",
  
                  
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_h264_g711.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'               => false,
    'script'                     => 'Common\A-DVTB_H264_G711\dvtb_h264_g711.rb',

    # channel parameters
    'paramsChan'                => {
      'video_rate_control'=>params['video_rate_control'],
      'video_encoder_preset' => params['video_encoder_preset'],
      'video_frame_rate'    => get_video_frame_rate(params),
      'video_bit_rate'          => get_video_bit_rate(params),
      'video_height'        => get_video_height(params), 
      'video_width'          => get_video_width(params), 
      'video_input_chroma_format' => params['video_input_chroma_format'],
      'video_output_chroma_format' => params['video_output_chroma_format'],
      'video_inter_frame_interval' => params['video_inter_frame_interval'],
      'video_source'       => get_video_source(params),
      'audio_companding' => params['audio_companding'],
      'audio_codec' => "g711",
      'audio_bit_rate' => 64000,
      'audio_source' => get_audio_source(params),
      'audio_sampling_rate' => params['audio_sampling_rate'],
      'video_signal_format' => params['video_signal_format'],
      'video_iface_type' => params['video_iface_type'],
      'audio_iface_type' => params['audio_iface_type'],
      'test_type' => get_test_type(params)
  },
    'paramsEquip'     => {
    },
    'paramsControl'     => {
          'media_time' => params['media_time'],
          'video_num_channels' => params['video_num_channels'],
          'audio_num_channels' => params['audio_num_channels'],
    },
    'configID'      => '..\Config\dvtb_h264_g711.ini',
 #   'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  def get_test_type(params)
  (params['video_input_driver']+"+"+params['video_output_driver']+"_"+params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"").gsub(/^_/,"").gsub(/_$/,"")
  end
  
  
  private
  def get_video_source(params)
      video_resolution = get_video_resolution(params)
      video_bit_rate = get_video_bit_rate(params)
  if params['video_source'].eql?("media_filer")      
    if video_bit_rate.to_f/1000 >= 1000
       file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(".0Mbps","Mbps")
       file_bit_rate2 = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
       file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps") 
    end 
     video_source = @video_source_hash["\\w+"+video_resolution+"_"+params['video_input_chroma_format']+"\\w*"+video_bit_rate+"bps"]
     video_source += ";" if video_source && @video_source_hash["\\w+"+video_resolution+@h264_prof_regex+file_bit_rate+"\\w*"]
     video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+@h264_prof_regex+file_bit_rate+"\\w*"].to_s
     video_source += ";" if video_source.to_s.strip != '' && file_bit_rate2 && @video_source_hash["\\w+"+video_resolution+@h264_prof_regex+file_bit_rate2+"\\w*"] 
       video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+@h264_prof_regex+file_bit_rate2+"\\w*"].to_s if file_bit_rate2
  else
     video_source = params['video_source']
  end
  video_source
  end
  
  def get_audio_source(params)
  if params['video_source'].eql?('media_filer')
    if params['audio_companding'].eql?("ulaw")
    @ulaw_audio_source_hash["\\w+"]
    elsif params['audio_companding'].eql?("alaw")
    @alaw_audio_source_hash["\\w+"]
    end
  else
    params['video_source']
  end
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
  
  def get_video_frame_rate(params)
    if params['video_frame_rate'].eql?('std')
        case get_video_resolution(params)
            when '176x120', '352x240', '720x480', '704x480', '128x96'
                30
            when '176x144', '352x288', '720x576', '704x576', '128x96'
                25
      else
        if rand() > 0.5
          25
        else
          30
        end
        end
    else
        params['video_frame_rate']
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
  
end
