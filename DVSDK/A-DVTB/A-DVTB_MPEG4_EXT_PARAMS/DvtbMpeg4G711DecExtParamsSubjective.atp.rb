require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4G711DecExtParamsSubjectiveTestPlan < TestPlan
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
    @mpeg4_prof_regex = "_(ASP|SP)\\w*"
    params = {
    'video_output_chroma_format' => ['420p', '422i', '420sp'],
    'video_num_channels'        => [1,4],
    'audio_companding' => ['ulaw','alaw'],
    'audio_sampling_rate' => [8000],
    'audio_num_channels' => [1],    
    'video_rotation' => [0,90,180,270], # Rotation (anticlockwise). 0: No Rotation (Default). 90: 90 degrees. 180: 180 degrees. 270: 270 degrees.
    'video_me_range' => [7,31], # Motion Compensation Range. 7: ME7, 31: ME31 (Default)
    'video_use_umv' => [0,1], # UMV support. 0: OFF (Default). 1:ON
    'video_frame_skip_mode' => ['no_skip','skip_p', 'skip_i', 'skip_b', 'skip_ip', 'skip_ib', 'skip_pb', 'skip_ipb', 'skip_idr'],
    'video_frame_order'  => ['display','decode'],
    'video_new_frame_flag' => [0,1],
    'video_mb_data_flag' => [0,1],
    'video_display_delay' => [0,8,16],
    'video_reset_imcop_every_frame' =>[0,1],
    'video_outloop_deblocking' => [0,1],
    'video_outloop_deringing' => [0,1],
    'video_disable_hdvicp_every_frame' => [0,1],
  }
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
    file_bit_rate = []
    video_bitrates.each do |video_br|
      if video_br.to_f/1000 >= 1000
        file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
        file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
      else
        file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
      end
    end
  @video_source_hash = get_source_files_hash("\\w*",video_resolutions,"\\w*",@mpeg4_prof_regex,"\\w*",file_bit_rate,"\\w*frames","mpeg4")   
  @ulaw_audio_source_hash = get_source_files_hash("\\w+","u")
  @alaw_audio_source_hash = get_source_files_hash("\\w+","a")
  @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
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
  'description'    =>"MPEG4 Decoder Extended parameters test with, video_res=#{get_video_resolution(params)},bit_rate=#{get_video_bit_rate(params)}",
  
                  
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg4_g711_dec_ext_params_sub.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'               => false,
    'script'                     => 'vatf-scripts/DVSDK/A-DVTB/A-DVTB_MPEG4_EXT_PARAMS/dvtb_mpeg4_g711_dec_ext_params_subjective.rb',

    # channel parameters
    'paramsChan'                => get_params_chan(params),
    'paramsEquip'     => {
    },
    'paramsControl'     => {
          'video_num_channels' => params['video_num_channels'],
          'audio_num_channels' => params['audio_num_channels'],
    },
    'configID'      => 'Config/dvtb_mpeg4_g711.ini',
 #   'last'            => true,
   }
  end
  # END_USR_CFG get_outputs
  
  
  private
  def get_video_source(params)
    video_resolution = get_video_resolution(params)
    video_br = get_video_bit_rate(params)
    if video_br.to_f/1000 >= 1000
      file_bit_rate = ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
      file_bit_rate2 = ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
    else
      file_bit_rate = ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
    end
    result = ''
    result = @video_source_hash["\\w*"+video_resolution+"\\w*"+@mpeg4_prof_regex+"\\w*"+file_bit_rate2+"\\w*frames"].to_s if file_bit_rate2
    result += ';' if result != ''
    result += @video_source_hash["\\w*"+video_resolution+"\\w*"+@mpeg4_prof_regex+"\\w*"+file_bit_rate+"\\w*frames"].to_s
    result
  end
  
  def get_params_chan(params)
      result = {}
      result['test_type'] = 'decode'
      params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
      
      result['video_bit_rate'] = get_video_bit_rate(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup'
      result['video_height'] = get_video_height(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup' 
      result['video_width'] = get_video_width(params) if params['video_resolution_and_bit_rate'] && params['video_resolution_and_bit_rate'].strip.downcase != 'nsup' 
      result['video_source'] = get_video_source(params)
      result['audio_codec'] = "g711"
      result['audio_bit_rate'] = 64000
      result['audio_source'] = get_audio_source(params)
      
      result.delete('video_num_channels')
      result.delete('audio_num_channels')
      result.delete('video_resolution_and_bit_rate')
      result
   end
  
  def get_audio_source(params)
    if params['audio_companding'].eql?("ulaw")
      @ulaw_audio_source_hash["\\w+"]
    elsif params['audio_companding'].eql?("alaw")
      @alaw_audio_source_hash["\\w+"]
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
