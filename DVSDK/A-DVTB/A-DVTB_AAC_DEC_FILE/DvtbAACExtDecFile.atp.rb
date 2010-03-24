require '../media_filer_utils'

include MediaFilerUtils
class DvtbAACExtDecFileTestPlan < TestPlan
	attr_reader :aac_audio_source_hash
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
  @sort_by = ['audio_type', 'audio_sampling_rate_and_audio_bit_rate']
	@group_by = ['audio_type', 'audio_sampling_rate_and_audio_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    @aac_file_format = "_(ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
    common_parameters = {
      'audio_codec' => ['aachedec'],
      'audio_output_pcm_width' => [16,24],
      'audio_pcm_format' => ["block","interleaved"],
      'audio_data_endianness' => ['byte','le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
      'audio_type' => ['mono','stereo', '3.0'] | ['dualmono', '2.1','3.1','2.2','3.2','2.3','3.3','3.4'] | ['5.0', '5.1', '7.1'],
      'audio_downsample_sbr_flag' => [0,1],
      'audio_six_channel_mode' => [0,1],
      'audio_enable_ps' => [0,1],
      'audio_profile' => ['main', 'lc', 'ssr', 'ltp'], # Decoder profile required for raw input data format: 0 - MAIN. 1 - LC. 2 - SSR. 3 - LTP
      'audio_raw_format' => [0,1],
      'audio_pseudo_surround_enable_flag' => [0,1],
      'audio_enable_arib_downmix' => [0,1],
      'audio_inbufsize' => ['nsup'],
      'audio_outbufsize' => ['nsup'],
      'num_channels' => [1,8],
      'max_num_files' => [0]      
    }
    
    audio_sampling_rate_and_bit_rate = [
      {
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
            'audio_sampling_rate' => [64000],
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
    audio_sampling_rates = []
    audio_bit_rates = []
    audio_sampling_rate_and_bit_rate.each do |audio_param_hash|
      audio_sampling_rates = audio_sampling_rates | audio_param_hash['audio_sampling_rate']
      audio_bit_rates = audio_bit_rates | audio_param_hash['audio_bit_rate']
    end
    file_sampling_rate = Array.new
    audio_sampling_rates.each{|sampling_rate| file_sampling_rate << (sampling_rate/1000).floor.to_i}
    file_bit_rate = Array.new
    audio_bit_rates.each {|bit_rate| file_bit_rate << (bit_rate/1000).to_s+"kbps"}
    @aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",common_parameters['audio_type'],"\\w*_",file_bit_rate,"\\w*",@aac_file_format,"\\w+","aac")
    @raw_aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",common_parameters['audio_type'],"\\w*_",file_bit_rate,"\\w*_RAW\\w+","aac") if common_parameters.has_key?('audio_raw_format') && common_parameters['audio_raw_format'][0].to_s.strip.downcase != 'nsup'
    @res_params = combine_params(common_parameters,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    res = []
    
		res << 'IF [audio_raw_format] = 0 THEN [audio_profile] IN {"' + @res_params['audio_profile'][0].to_s + '","nsup"};' if @res_params['audio_profile']
	  res
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_aac_ext_dec_file.#{@current_id}",
	     'description'    => "AAC Ext Decode File Test ,with sampling rate "+get_audio_sampling_rate(params)+", bitrate "+get_audio_bit_rate(params)+",and audio type "+params['audio_type'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'vatf-scripts/DVSDK/A-DVTB/A-DVTB_AAC_DEC_FILE/dvtb_aac_ext_dec_file.rb',
		 'configID' => 'Config/dvtb_aac_dec_file.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => get_params_chan(params),
		 'paramsControl' => {
			'num_channels' => params['num_channels'],
      'max_num_files' => params['max_num_files']
			},
     }
   end
  # END_USR_CFG get_outputs
   	
  def get_params_chan(params)
      result = {}
      result['test_type'] = 'decode'
      params.each {|k,v| result[k] = v if v.strip.downcase != 'nsup'}
      result['audio_source'] = get_audio_source(params)
      result['audio_sampling_rate'] = get_audio_sampling_rate(params)
      result['audio_bit_rate'] = get_audio_bit_rate(params)     
      result.delete('num_channels')
      result.delete('max_num_files')
      result.delete('audio_sampling_rate_and_audio_bit_rate')
      result
   end
  
  def get_audio_source(params)
		file_sampling_rate = (get_audio_sampling_rate(params).to_i/1000).floor.to_i.to_s
		file_bit_rate = get_audio_bit_rate(params)
		file_bit_rate = (file_bit_rate.to_i/1000).to_s+"kbps" if file_bit_rate.strip.downcase != 'vbr'
    audio_source = ''
		if params['audio_raw_format'] && params['audio_raw_format'].to_s.strip.downcase != 'nsup' && params['audio_raw_format'] == '1'
      audio_source = @raw_aac_audio_source_hash["\\w+_"+file_sampling_rate+"kHz\\w*"+params['audio_type']+"\\w*_"+file_bit_rate+"\\w*_RAW\\w+"]
    else  
      audio_source = @aac_audio_source_hash["\\w+_"+file_sampling_rate+"kHz\\w*"+params['audio_type']+"\\w*_"+file_bit_rate+"\\w*"+@aac_file_format+"\\w+"]
    end
    audio_source = "not found" if audio_source.to_s.strip == ''
		audio_source
	end
  
  def combine_params(dst_hash, array_of_hash=nil, params = ['audio_sampling_rate','audio_bit_rate'])
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
  
  def get_audio_bit_rate(params)
	  params['audio_sampling_rate_and_audio_bit_rate'].strip.split("_")[1]
	end
	
	def get_audio_sampling_rate(params)
	  params['audio_sampling_rate_and_audio_bit_rate'].strip.split("_")[0]
	end
  
end