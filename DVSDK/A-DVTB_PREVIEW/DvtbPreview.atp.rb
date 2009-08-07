require '../media_filer_utils'

include MediaFilerUtils

class DvtbPreviewTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 3
	@group_by = ['video_resolution']
	@sort_by = ['video_resolution']
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
	@res_params = {
		'video_driver' => ['on','off'],
		'audio_driver' => ['on','off'],
		'video_resolution' => ['352x288','720x576','720x480','352x240', '1280x720', '1920x1080'],
		'video_motion' => ['none','slow','fast'],
		'video_source' => ['dvd','camera'],
		'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60'],
		'audio_iface_type' => ['rca', 'xlr', 'optical', 'mini35mm',  'mini25mm', 'phoneplug'],
		'video_iface_type' => ['vga', 'component', 'composite', 'svideo', 'hdmi', 'dvi', 'sdi', 'scart'],
		'video_num_channels' => [8],
		'audio_num_channels' => [4],
		'random_seed' => [10],
		'media_time' => [30],
	}
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     const_hash = {}
     const_hash.default = []
     @res_params['video_resolution'].each do |res|
	     resolution = res.split(/x/i)
         @signal_format_max_res.each do |format,max_res|
             if max_res[0] < resolution[0].to_i || max_res[1] < resolution[1].to_i
                 const_hash[format] = const_hash[format]|[res]
             end
         end
     end
     format_constraints = Array.new
     const_hash.each do |format,res|
         current_group ='"'+res[0]+'"'
         1.upto(res.length-1){|i| current_group+=', "'+res[i]+'"'}
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [video_resolution] NOT IN {'+ current_group +'};'
     end
    format_constraints | [
	 'IF [video_driver] = "off" THEN [audio_driver] = "on";',
     ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_preview.#{@current_id}",
	     'description'    => get_description(params),
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_PREVIEW\DvtbPreview.rb',
		 'configID' => '..\Config\DvtbPreview.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan' => get_params_chan(params),
		 'paramsEquip' => get_params_equip(params),
		 'paramsControl' => {
				'video_num_channels' => params['video_num_channels'],
				'audio_num_channels' => params['audio_num_channels'],
				'random_seed' => params['random_seed'],
				'media_time' => params['media_time'],
      },
     }
   end
  # END_USR_CFG get_outputs
  private 
  def get_params_chan(params)
	result = Hash.new
	if params['video_driver'].include?("on")
		if params['video_driver'].include?("on+resizer")
			result['video_driver'] = "vpfe+resizer+vpbe" 
		else
			result['video_driver'] = "vpfe+vpbe"
		end
		result['video_source'] = params['video_source']				
		result['video_frame_rate'] = get_frame_rate(params['video_signal_format'])
		result['video_iface_type'] = params['video_iface_type']
		result['video_height'] = get_video_height(params['video_resolution'])
		result['video_width'] = get_video_width(params['video_resolution'])
		result['video_signal_format'] = params['video_signal_format']
		result['video_motion'] = params['video_motion']
	end
	if params['audio_driver'].eql?("on")
		result['audio_driver'] = "apfe+apbe"
		result['audio_source'] = params['video_source']
		result['audio_iface_type'] = params['audio_iface_type']
	end
	result
  end
  
  def get_params_equip(params)
	result = Hash.new
	result
  end
  
  def get_frame_rate(signal_format)
    case signal_format.strip.downcase
		when '625'
			25
	    when '525'
			30
		else
			signal_format.strip.split(/\D/)[1].to_i
	end
  end
  
	def get_video_height(resolution)
		resolution.split("x")[1].strip
	end
  
  def get_video_width(resolution)
		resolution.split("x")[0].strip
	end	
	
  def get_description(params)
	test_description = ""
	if params['video_driver'].include?("on")
		test_description+="VPFE+"
		test_description+="RESIZER+" if params['video_driver'].include?('resizer')
		test_description+="VPBE "+params['video_signal_format'].downcase
	end
	if params['audio_driver'].include?("on")
		test_description+=" APFE+APBE "
	end
	test_description+=" Test: using "
	if params['video_driver'].include?("on")
		test_description+=params['video_motion']+" motion content from "+params['video_source']
	end 
	if params['video_driver'].include?("on") && params ['audio_driver'].include?("on")
	  test_description+=" and "
	end
	if params ['audio_driver'].include?("on")
	  test_description+=" audio from "+params['video_source']
	end
	test_description								
  end

end
