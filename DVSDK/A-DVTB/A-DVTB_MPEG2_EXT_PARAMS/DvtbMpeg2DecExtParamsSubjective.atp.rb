require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg2DecExtParamsSubjectiveTestPlan < TestPlan
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
    @mpeg2_prof_regex = "_(SP|MPp{0,1})\\w*"
    params = {
    'video_codec' => ['mpeg2extdec'],
    'video_output_chroma_format' => ['420p', '422i', '420sp'],
    'video_num_channels'        => [1,4],  
    'video_data_endianness' => ['byte', 'le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
    'video_display_delay' => [0,8,16], # Display delay before which the decoder starts to output frames for display. Default value: 16 (when base class is used). Valid range: [0, 16]
    'video_frame_skip_mode' => ['no_skip','skip_p', 'skip_i', 'skip_b', 'skip_ip', 'skip_ib', 'skip_pb', 'skip_ipb', 'skip_idr'],
    'video_frame_order'  => ['display','decode'],
    'video_new_frame_flag' => [0,1],
    'video_mb_data_flag' => [0,1],
    'video_deblocking' => ['none', 'deblocking', 'deblocking+deringing'], # 0 - No De-Blocking. 1 – De-Blocking. 2 – De-Blocking + Deringing. Default value = 0
    'video_bottom_fld_ddr_ppt' => [0,1],
    'video_mb_error_reporting' => [0,1],
    'video_error_conceal' => [0,1],
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
  @video_source_hash = get_source_files_hash("\\w*",video_resolutions,"\\w*",@mpeg2_prof_regex,"\\w*",file_bit_rate,"\\w*frames","m2v")   
  @res_params = combine_res_and_bit_rate(params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    res = []
    res << 'IF [video_mb_error_reporting] <> 1 THEN [video_error_conceal] = 0;' if @res_params['video_mb_error_reporting'] && @res_params['video_error_conceal'] && @res_params['video_mb_error_reporting'][0].to_s.strip.downcase != 'nsup' && @res_params['video_error_conceal'][0].to_s.strip.downcase != 'nsup'
    res
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
  'description'    =>"MPEG2 Decoder Extended parameters test with, video_res=#{get_video_resolution(params)},bit_rate=#{get_video_bit_rate(params)}",
  
                  
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg2_dec_ext_params_sub.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => true,
    'bestFinal'               => false,
    'script'                     => 'vatf-scripts/DVSDK/A-DVTB/A-DVTB_MPEG2_EXT_PARAMS/dvtb_mpeg2_dec_ext_params_subjective.rb',

    # channel parameters
    'paramsChan'                => get_params_chan(params),
    'paramsEquip'     => {
    },
    'paramsControl'     => {
          'video_num_channels' => params['video_num_channels'],
    },
    'configID'      => 'Config/dvtb_mpeg2_g711.ini',
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
    result = @video_source_hash["\\w*"+video_resolution+"\\w*"+@mpeg2_prof_regex+"\\w*"+file_bit_rate2+"\\w*frames"].to_s if file_bit_rate2
    result += ';' if result != ''
    result += @video_source_hash["\\w*"+video_resolution+"\\w*"+@mpeg2_prof_regex+"\\w*"+file_bit_rate+"\\w*frames"].to_s
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
            
      result.delete('video_num_channels')
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
