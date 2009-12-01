require '../media_filer_utils'

include MediaFilerUtils
class DvtbAACDecFileOQTestPlan < TestPlan
	attr_reader :aac_audio_source_hash
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	params = {
		'audio_type' => ['mono','stereo'],
		'audio_sampling_rate' => [8000, 11000, 12000, 16000, 22000, 24000, 32000, 44000, 48000, 64000, 88000, 96000],
		'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
		'num_channels' => [1,8]
	}
	file_sampling_rate = Array.new
	params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << sampling_rate/1000}
	file_bit_rate = Array.new
	params['audio_bit_rate'].each{|bit_rate| file_bit_rate << bit_rate/1000}
	@aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",params['audio_type'],"_{0,1}",file_bit_rate,"kbps\\w*","aac")
		[params.merge({
          'audio_sampling_rate' => [8000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [11000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [12000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [16000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [22000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [24000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [32000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [44000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [48000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [64000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [88000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
    params.merge({
          'audio_sampling_rate' => [96000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
     }),
     ] 
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
		'IF [audio_type] = "stereo" AND [audio_sampling_rate] = 48000 THEN [audio_bit_rate] NOT IN {16000};',
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_aac_dec_file_oq.#{@current_id}",
	     'description'    => "AAC Codec Decode File Objective Quality Test ,with sampling rate "+params['audio_sampling_rate']+", bitrate "+params['audio_bit_rate']+",and audio type "+params['audio_type'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'DVSDK/A-DVTB_AAC_DEC_FILE/dvtb_aac_dec_file_oq.rb',
		 'configID' => '../Config/dvtb_aac_dec_file_oq.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_type' => params['audio_type'],
				'audio_source' => get_audio_source(params),
				'audio_sampling_rate' => params['audio_sampling_rate'],
				'audio_bit_rate' => params['audio_bit_rate']
	        },
		 
		 'paramsControl' => {
			'num_channels' => params['num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
  def get_audio_source(params)
	@aac_audio_source_hash["\\w+_"+(params['audio_sampling_rate'].to_i/1000).to_s+"kHz\\w*"+params['audio_type']+"_{0,1}"+(params['audio_bit_rate'].to_i/1000).to_s+"kbps\\w*"]
  end
end