require '../media_filer_utils'

include MediaFilerUtils
class DvtbAACTestPlan < TestPlan
	attr_reader :aac_audio_source_hash
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@group_by = ['audio_sampling_rate_and_audio_bit_rate']
	@sort_by = ['audio_sampling_rate_and_audio_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
  @aac_file_format = "_(RAW|ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
  
  #This hash table contains the bitrate limits based on sampling rate and bit rate for the aac the format of each entry is sampling_rate => {audio_type => [min bit rate, max bit rate],....}
  @aac_sampling_rates_and_bit_rates = {
    16000 => {'mono' => [8000, 48000], 'stereo' => [8000, 48000]},
    22050 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
    24000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
    32000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
    44100 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
    48000 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
    }
    @aac_sampling_rates_and_bit_rates.default = {'mono' => nil, 'stereo' => nil}
  #Test parameters
	@params = {
		'audio_input_driver' => ['apfe+encoder','none'],
		'audio_output_driver' => ['decoder+apbe','none'],
		'audio_type' => ['mono','stereo'],
		'audio_sampling_rate' => [8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 88200, 96000],
		'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
		'num_channels' => [1,8],
		'media_time' => [20],
	}
	file_sampling_rate = Array.new
	@params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << (sampling_rate/1000).floor}
	file_bit_rate = Array.new
	@params['audio_bit_rate'].each{|bit_rate| file_bit_rate << bit_rate/1000}
	@aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",@params['audio_type'],"_{0,1}",file_bit_rate,"kbps\\w*",@aac_file_format,"aac")
	file_sampling_rate = Array.new
	@params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << sampling_rate/1000}
	@pcm_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*_",@params['audio_type'],"\\w*","pcm")
	audio_sampling_rate_and_bit_rate =	[{
          'audio_sampling_rate' => [8000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
    },
    {
          'audio_sampling_rate' => [11025],
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
          'audio_sampling_rate' => [22050],
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
          'audio_sampling_rate' => [44100],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
    },
    {
          'audio_sampling_rate' => [48000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
    },
    {
          'audio_sampling_rate' => [88200],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
    },
    {
          'audio_sampling_rate' => [96000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
    },
     ]
	 @params = combine_params(@params,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    mode_constraints = []
    constrained_sr_brs = Hash.new{|hash,key| hash[key]=[]} 
    @params['audio_sampling_rate_and_audio_bit_rate'].each do |sr_br|
       sampling_rate = sr_br.split('_')[0].to_i
       bit_rate = sr_br.split('_')[1].to_i
      @params['audio_type'].each do |audio_type|
        if !@aac_sampling_rates_and_bit_rates[sampling_rate][audio_type] || @aac_sampling_rates_and_bit_rates[sampling_rate][audio_type][0] > bit_rate || @aac_sampling_rates_and_bit_rates[sampling_rate][audio_type][1] < bit_rate
              constrained_sr_brs[audio_type] = constrained_sr_brs[audio_type]|[sr_br]  
        end
      end		
    end	
    constrained_sr_brs.each do |aud_type, sr_brs|
      constraint_group = '"'+sr_brs[0].to_s+'"'
      1.upto(sr_brs.length-1) do |i|
        constraint_group += ',"'+sr_brs[i]+'"'
      end
      mode_constraints << 'IF [audio_sampling_rate_and_audio_bit_rate] IN {'+constraint_group+'} THEN [audio_type] <> "'+aud_type+'";' if sr_brs[0]
    end
 	 mode_constraints | [
	 'IF [audio_input_driver] = "none" THEN [audio_output_driver] <> "none";',
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_aac.#{@current_id}",
	     'description'    => "AAC Codec Test type "+(params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"")+",with audio type "+params['audio_type'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_AAC\dvtb_aac.rb',
		 'configID' => '..\Config\dvtb_aac.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_type' => params['audio_type'],
				'audio_source' => get_audio_source(params),
				'audio_sampling_rate' => get_sampling_rate(params),
				'test_type' => (params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
				'audio_bit_rate' => get_bit_rate(params),
				'media_time' => params['media_time'],
	        },
		 
		 'paramsControl' => {
			'num_channels' => params['num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
   def get_audio_source(params)
      if params['audio_input_driver'] != "none"
        file_sampling_rate = get_sampling_rate(params).to_i/1000
      	@pcm_audio_source_hash["\\w+_"+file_sampling_rate.to_s+"kHz\\w*_"+params['audio_type']+"\\w*"]
      else
	  	@aac_audio_source_hash["\\w+_"+(get_sampling_rate(params).to_i/1000).to_s+"kHz\\w*"+params['audio_type']+"_{0,1}"+(get_bit_rate(params).to_i/1000).to_s+"kbps\\w*"+@aac_file_format]
	  end
  end
  
  def get_sampling_rate(params)
	params['audio_sampling_rate_and_audio_bit_rate'].split('_')[0]
  end
  
  def get_bit_rate(params)
	params['audio_sampling_rate_and_audio_bit_rate'].split('_')[1]
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