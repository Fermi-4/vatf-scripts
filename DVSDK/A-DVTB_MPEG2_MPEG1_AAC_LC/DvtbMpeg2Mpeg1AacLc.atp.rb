require '../media_filer_utils'

include MediaFilerUtils

class DvtbMpeg2Mpeg1AacLcTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by = ['video_signal_format']
	@group_by = ['video_signal_format']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    @mpeg2_prof_regex = "_(SP|MPp)\\w*"
	@aac_file_format = "_(RAW|ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
	@signal_format_max_res = {
         '525' => [720,480],
         '625' => [720,576], 
         '720p50' => [1280,720],
         '720p59' => [1280,720],
         '720p60' => [1280,720],          
    }
	common_parameters = {'num_channels' => [1,8],
						 'video_resolution' => ['128x96','176x144','176x120','320x240','352x240','352x288','640x480','704x480','704x576','720x240','720x288','720x480','720x576'],
						 'video_bit_rate' => [10000,64000,96000,128000,192000,200000,256000,350000,384000,500000,512000,600000,768000,786000,800000,1000000,1100000,1500000,1572000,2000000,2500000,2560000,3000000,4000000,4096000,6000000,8000000,10000000],
						 'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
						 'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
						 'audio_iface_type' => ['rca', 'xlr', 'optical', 'mini35mm',  'mini25mm', 'phoneplug'],
						 'audio_type' => ['mono','stereo'],
						 'audio_sampling_rate' => [8000, 11000, 12000, 16000, 22000, 24000, 32000, 44000, 48000, 64000, 88000, 96000],
						 'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
						 'audio_temporal_noise_shaping' => ['y','n'],
						 'audio_perceptual_noise_substituion' => ['y','n']
						}
	file_bit_rate = Array.new
	common_parameters['video_bit_rate'].each do |video_br|
		if video_br.to_f/1000 >= 1000
			file_bit_rate << ((video_br.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
			file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
		else
			file_bit_rate << ((video_br.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	end
	@video_source_hash = get_source_files_hash("\\w+",common_parameters['video_resolution'],"\\w*",@mpeg2_prof_regex,"\\w*",file_bit_rate,"\\w*", "m2v")
	video_res_and_bit_rates = [
	{'video_resolution'=> ['128x96'],
							  'video_bit_rate' => [64000], 
							},
	{'video_resolution'=> ["176x144"],
							  'video_bit_rate' => [10000,64000,96000,128000,200000,512000,800000,1000000],
							},
	{'video_resolution'=> [ "176x120" ],
							  'video_bit_rate' => [64000,96000,128000,256000,800000],
							},
	{'video_resolution'=> ["320x240"],
							  'video_bit_rate' => [64000,192000,256000,512000,768000,1000000,1500000],
							},
	{'video_resolution'=> ["352x240"],
							  'video_bit_rate' => [64000,96000,128000,256000,350000,384000,500000,512000,800000,1000000,1500000],
							},
	{'video_resolution'=> ["352x288"],
							  'video_bit_rate' => [64000,96000,128000,256000,350000,384000,500000,512000,768000,800000,1000000,1500000,2000000,2500000],
							},
	{'video_resolution'=> ["640x480"],
							  'video_bit_rate' => [512000,768000,786000,1000000,2000000,4000000],
							},
	{'video_resolution'=> ["704x480"],
							  'video_bit_rate' => [512000,1572000,800000,1000000,1100000,1500000,1572000,2000000,2560000,4000000,4096000,5000000,6000000,8000000,10000000],
							},
	{'video_resolution'=> ["704x576"],
							  'video_bit_rate' => [512000,800000,1100000,1500000,2000000,4000000,10000000],
							},
	{'video_resolution'=> ["720x240"],
							  'video_bit_rate' => [600000,800000,1000000,1500000],
							},
	{'video_resolution'=> ["720x288"],
							  'video_bit_rate' => [600000,800000,1000000,1500000],
							},
	{'video_resolution'=> ["720x480"],
							  'video_bit_rate' => [128000,256000,512000,384000,1000000,2000000,3000000,4000000,6000000,8000000,10000000],
							},
	{'video_resolution'=> ["720x576"],
							  'video_bit_rate' => [256000,512000,1000000,2000000,2500000,4000000,5000000,6000000,8000000,10000000],
							},
	]
	
	file_sampling_rate = Array.new
	common_parameters['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << sampling_rate/1000}
	file_bit_rate = Array.new
	common_parameters['audio_bit_rate'].each{|bit_rate| file_bit_rate << bit_rate/1000}
	@aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",common_parameters['audio_type'],"_{0,1}",file_bit_rate,"kbps\\w*",@aac_file_format,common_parameters['audio_temporal_noise_shaping'],"TNS\\w*",common_parameters['audio_perceptual_noise_substituion'],"PNS\\w*","aac")
	audio_sampling_rate_and_bit_rate = [
	{
          'audio_sampling_rate' => [8000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [11000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [12000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [16000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [22000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [24000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [32000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [44000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [48000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [64000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [88000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    {
          'audio_sampling_rate' => [96000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
							},
    ]
	
	@res_params = combine_params(common_parameters,video_res_and_bit_rates)
	@res_params = combine_params(@res_params,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
	const_hash = {}
     const_hash.default = []
     @res_params['video_resolution_and_video_bit_rate'].each do |bitrate_res|
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
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [video_resolution_and_video_bit_rate] NOT IN {'+ current_group +'};'
     end
    format_constraints | [
	]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_mpeg2_mpeg1_aac.#{@current_id}",
	     'description'    => "MPEG2+AAC Decoder Test for video resolution = "+get_video_resolution(params)+", video bit rate = "+get_video_bit_rate(params)+', audio_sampling_rate = '+get_audio_sampling_rate(params)+', audio bit rate = '+get_audio_bit_rate(params), 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_MPEG2_MPEG1_AAC_LC\dvtb_mpeg2_mpeg1_aac.rb',
		 'configID' => 'dvtb_mpeg2_mpeg1_aac.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'video_bit_rate' => get_video_bit_rate(params),
				'video_height' => get_video_height(params),
				'video_width' => get_video_width(params),
				'video_source' => get_source_file(params),
				'video_iface_type' => params['video_iface_type'],
			    'video_signal_format' => params['video_signal_format'],
				'audio_iface_type' => params['audio_iface_type'],
				'audio_type' => params['audio_type'],
				'audio_source' => get_audio_source(params),
				'audio_sampling_rate' => get_audio_sampling_rate(params),
				'audio_bit_rate' => get_audio_bit_rate(params),
				'audio_temporal_noise_shaping' => params['audio_temporal_noise_shaping'],
				'audio_perceptual_noise_substituion' => params['audio_perceptual_noise_substituion'],
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
		video_resolution = get_video_resolution(params)
		video_bit_rate = get_video_bit_rate(params)
		if video_bit_rate.to_f/1000 >= 1000
			file_bit_rate = ((video_bit_rate.to_f/1000000).to_s+"Mbps").gsub(/\.0Mbps$/,"Mbps")
			file_bit_rate2 = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(".0kbps","kbps")
		else
			file_bit_rate = ((video_bit_rate.to_f/1000).to_s+"kbps").gsub(/\.0kbps$/,"kbps")
		end
	   video_source = @video_source_hash["\\w+"+video_resolution+"\\w*"+@mpeg2_prof_regex+"\\w*"+file_bit_rate+"\\w*"]
	   video_source += ";" if file_bit_rate2 &&  video_source.to_s.strip != '' && @video_source_hash["\\w+"+video_resolution+"\\w*"+@mpeg2_prof_regex+"\\w*"+file_bit_rate2+"\\w*"] 
	   video_source = video_source.to_s + @video_source_hash["\\w+"+video_resolution+"\\w*"+@mpeg2_prof_regex+"\\w*"+file_bit_rate2+"\\w*"].to_s if file_bit_rate2
	   video_source = 'not found' if video_source.to_s.strip == ''
	   video_source
	end
	
	def get_audio_source(params)
	    audio_source = @aac_audio_source_hash["\\w+_"+(get_audio_sampling_rate(params).to_i/1000).to_s+"kHz\\w*"+params['audio_type']+"_{0,1}"+(get_audio_bit_rate(params).to_i/1000).to_s+"kbps\\w*"+@aac_file_format+params['audio_temporal_noise_shaping']+"TNS\\w*"+params['audio_perceptual_noise_substituion']+"PNS\\w*"]
		audio_source = "not found" if !audio_source
		audio_source
	end
   
   private
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
	  params['video_resolution_and_video_bit_rate'].strip.split("_")[0]
	end

	def get_video_bit_rate(params)
	  params['video_resolution_and_video_bit_rate'].strip.split("_")[1]
	end
	
	def get_audio_bit_rate(params)
	  params['audio_sampling_rate_and_audio_bit_rate'].strip.split("_")[1]
	end
	
	def get_audio_sampling_rate(params)
	  params['audio_sampling_rate_and_audio_bit_rate'].strip.split("_")[0]
	end
   
   def combine_params(dst_hash, array_of_hash=nil, params = ['video_resolution', 'video_bit_rate'])
      result = Array.new
      array_of_hash = [{params[0] => params[0], params[1] => params[1]}] if !array_of_hash
      array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
      array_of_hash.each do |val_hash|
          val_hash[params[0]].each do |param0|
              val_hash[params[1]].each do |param1|
              	result << param0.to_s+"_"+param1.to_s
              end
          end
      end
      dst_hash.delete(params[0])
      dst_hash.delete(params[1])
      dst_hash.merge!({"#{params[0]}_and_#{params[1]}" => result})
      dst_hash
   end
end