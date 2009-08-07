require '../media_filer_utils'

include MediaFilerUtils
class DvtbAACEncFileOQTestPlan < TestPlan
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
		'audio_type' => ['mono','stereo', 'dualmono'],
		'audio_sampling_rate' => [8000, 11000, 12000, 16000, 22000, 24000, 32000, 44000, 48000, 88000],
		'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000],
		'test_type' => ["default","use_params"],
		'audio_encoder_preset' => [0,1,2,3],
		'audio_data_endianness' => [1],
		'audio_output_object_type' => ["lc","he","ps"],  #[2,5,29],
		'audio_output_file_format' => ["raw","adif","adts"], #[0,1,2]
		'audio_use_crc' => ["on","off"],
		'audio_use_tns' => ["on","off"],
		'audio_use_pns' => ["on","off"],
		'audio_down_sampling' => ["on","off"],
		'audio_bit_rate_mode' => [0,1,2,3,4,5],
		'audio_anciliary_data_flag' => ["off"],
		'audio_anciliary_data_rate' => [-1],
		'audio_input_format' => ["block","interleaved"], #[0,1]
		'audio_num_lfe_channels' => [0],
		'audio_bits_per_sample' => [16],
		'audio_input_offset' => [1],
		'num_channels' => [1,8]
	}
	file_sampling_rate = Array.new
	params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << sampling_rate/1000}
	@aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*_",params['audio_type'],"\\w*","pcm")
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
          'audio_sampling_rate' => [88000],
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
	 'IF [audio_type] = "stereo" THEN [audio_sampling_rate] NOT IN {88000,24000};', 
	 'IF [audio_type] = "mono" THEN [audio_sampling_rate] <= 48000;',
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_aac_enc_file_oq.#{@current_id}",
	     'description'    => "AAC Codec Encode File Objective Quality Test ,with sampling rate "+params['audio_sampling_rate']+", and audio type "+params['audio_type'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_AAC_ENC_FILE\dvtb_aac_enc_file_oq.rb',
		 'configID' => '..\Config\dvtb_aac_enc_file_oq.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
				'audio_type' => params['audio_type'],
				'audio_source' => get_audio_source(params),
				'audio_sampling_rate' => params['audio_sampling_rate'],
				'audio_bit_rate' => params['audio_bit_rate'],
				'audio_source' => get_audio_source(params),
				'test_type' => params['test_type'],			
				'audio_encoder_preset' => params['audio_encoder_preset'],
				'audio_data_endianness' => params['audio_data_endianness'],
				'audio_output_object_type' => params['audio_output_object_type'],  #[2,5,29],
				'audio_output_file_format' => params['audio_output_file_format'], #[0,1,2]
				'audio_use_crc' => params['audio_use_crc'],
				'audio_use_tns' => params['audio_use_tns'],
				'audio_use_pns' => params['audio_use_pns'],
				'audio_down_sampling' => params['audio_down_sampling'],
				'audio_bit_rate_mode' => params['audio_bit_rate_mode'],
				'audio_anciliary_data_flag' => params['audio_anciliary_data_flag'],
				'audio_anciliary_data_rate' => params['audio_anciliary_data_rate'],
				'audio_input_format' => params['audio_input_format'], #[0,1]
				'audio_num_lfe_channels' => params['audio_num_lfe_channels'],
				'audio_bits_per_sample' => params['audio_bits_per_sample'],
				'audio_input_offset' => params['audio_input_offset'],
	        },
		 
		 'paramsControl' => {
			'num_channels' => params['num_channels'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
  def get_audio_source(params)
	@aac_audio_source_hash["\\w+_"+(params['audio_sampling_rate'].to_i/1000).to_s+"kHz\\w*_"+params['audio_type']+"\\w*"]
  end
end