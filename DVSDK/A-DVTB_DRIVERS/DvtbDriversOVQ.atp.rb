require '../media_filer_utils'

include MediaFilerUtils
class DvtbDriversOVQTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@group_by = ['video_source:video_driver']
	@sort_by = ['video_source','video_driver']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    @media_id = 0
	params = {
		'video_driver' => ['vpfe','vpbe','vpfe+vpbe'],
		'audio_driver' => ['on','off'],
		'audio_sampling_rate' => [8000],
		'video_source' => ['football_704x480_420p_150frames_30fps','mobile_704x480_420p_150frames_30fps','sheilds_720x480_420p_252frames_30fps'],
		'video_num_channels' => [1,8],
		'audio_num_channels' => [1,4],
	}
	audio_rates = Array.new
	params['audio_sampling_rate'].each{|sampling_rate| audio_rates << sampling_rate.to_s.gsub("000","KHz")}
	@pcm_audio_source_hash = get_source_files_hash("\\w*_",audio_rates,"\\w*","pcm")
	params
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
	     'testcaseID'     => "dvtb_drivers_ovq.#{@current_id}",
	     'description'    => params['video_driver'].upcase+get_audio_driver(params).upcase+" "+get_video_resolution(params)+" Test.",
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_DRIVERS\dvtb_drivers_ovq.rb',
		 'configID' => '..\Config\dvtb_drivers_ovq.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan' => get_params_chan(params),
		 'paramsEquip' => get_params_equip(params),
		 'paramsControl' => get_params_control(params),
     }
   end
  # END_USR_CFG get_outputs
  private 
  def get_params_chan(params)
	result = Hash.new
	result['video_source'] = params['video_source']
	result['video_region'] = get_video_region(params)
	result['video_height'] = get_video_height(params)
	result['video_width'] = get_video_width(params)
	result['test_type'] = params['video_driver'].downcase+get_audio_driver(params).downcase
	if params['audio_driver'].eql?('on')
		result['audio_source'] = @pcm_audio_source_hash["\\w*_"+params['audio_sampling_rate'].gsub("000","KHz")+"\\w*"] 
		result['audio_sampling_rate'] = params['audio_sampling_rate']		
	end
	result
  end
  
  def get_params_equip(params)
	result = Hash.new
	result
  end
  
  def get_audio_driver(params)
	if params['audio_driver'].eql?('on')
		"_"+params['video_driver'].gsub('v','a')
    else
	   ""
	end
  end
  
  def get_video_resolution(params)
	/(704x480|720x480|704x576|720x576)/.match(params['video_source']).captures[0]
  end
  
  def get_video_region(params)
	case get_video_resolution(params)
	when '704x480','720x480'
		'ntsc'
	else
		'pal'
	end
  end
  
  def get_params_control(params)
	result = Hash.new
	result['video_num_channels'] = params['video_num_channels']
	result['audio_num_channels'] = params['audio_num_channels'] if params['audio_driver'].eql?('on')
	result
  end
  
	def get_video_height(params)
		resolution = get_video_resolution(params)
		resolution.split("x")[1].strip
	end

	def get_video_width(params)
		resolution = get_video_resolution(params)
		resolution.split("x")[0].strip
	end	
	
end