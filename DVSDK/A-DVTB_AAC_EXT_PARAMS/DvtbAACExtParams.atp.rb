require '../media_filer_utils'

include MediaFilerUtils
class DvtbAACExtParamsTestPlan < TestPlan
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
    @aac_enc_mode_sampling_rates_and_bit_rates = {
        'lc' => {
            8000 => {'mono' => [8000, 48000], 'stereo' => [16000, 96000]},
            11025 => {'mono' => nil, 'stereo' => nil},
            16000 => {'mono' => [8000, 96000], 'stereo' => [16000,192000]},
            22050 => {'mono' => [8000, 132300], 'stereo' => [16000, 264600]},
            24000 => {'mono' => nil, 'stereo' => nil},
            32000 => {'mono' => [8000, 192000], 'stereo' => [16000, 384000]},
            44100 => {'mono' => [8000, 264600], 'stereo' => [16000, 529200]},
            48000 => {'mono' => [8000, 288000], 'stereo' => [16000, 576000]},
            96000 => {'mono' => [16000, 288000], 'stereo' => [20000, 576000]},
        },
        'ps' => {
            8000 => {'mono' => nil, 'stereo' => nil},
            11025 => {'mono' => nil, 'stereo' => nil},
            16000 => {'mono' => [8000, 48000], 'stereo' => [8000, 48000]},
            22050 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            24000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            32000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            44100 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
            48000 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
            96000 => {'mono' => nil, 'stereo' => nil},
        },
        'heaac' =>{
            8000 => {'mono' => nil, 'stereo' => nil},
            11025 => {'mono' => nil, 'stereo' => nil},
            16000 => {'mono' => [8000, 48000], 'stereo' => [8000, 48000]},
            22050 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            24000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            32000 => {'mono' => [8000, 64000], 'stereo' => [8000, 64000]},
            44100 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
            48000 => {'mono' => [12000, 64000], 'stereo' => [12000, 64000]},
            96000 => {'mono' => nil, 'stereo' => nil},
        }, 
    }
    
	params = {
		'audio_input_driver' => ['apfe+encoder','encoder'],
		'audio_output_driver' => ['decoder+apbe','none','decoder'],
		'audio_type' => ['mono','stereo', '3.0'] | ['dualmono', '2.1','3.1','2.2','3.2','2.3','3.3','3.4'] | ['5.0', '5.1', '7.1'], #['5.0', '5.1', '7.1'] only in 0.9 xdm codecs; ['dualmono', '2.1','3.1','2.2','3.2','2.3','3.3','3.4'] only on 1.0 or later codecs
		'audio_sampling_rate' => [8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 64000, 88200, 96000],
		'audio_source' => ['dvd','camera','media_filer'],
		'audio_bit_rate' => [8000, 16000, 20000, 32000, 42000, 48000, 64000, 84000, 96000, 116000, 128000, 160000, 168000, 192000, 224000, 232000, 236000, 288000, 320000, 576000],
		'audio_data_endianness' => ['byte','le_16', 'le_32', 'le_64', 'be_16', 'be_32', 'be_64'],
		'audio_encoder_mode' => ['cbr','vbr'],
		'audio_input_format' => ["block","interleaved"],
		'audio_dual_mono_mode'	=> ['left', 'right','left_right', 'mix'],
		'audio_crc_flag' => [0,1],
		'audio_output_object_type' => ["lc","heaac","ps"],  #[2,5,29],
		'audio_output_file_format' => ["raw","adif","adts"], #[0,1,2]
		'audio_use_tns' => [0,1],
		'audio_use_pns' => [0,1],
		'audio_down_mix_flag' => [0,1],
		'audio_bit_rate_mode' => ['vbr1', 'vbr2', 'vbr3', 'vbr4', 'vbr5'],
		'audio_anc_rate' => [-1],
		'audio_num_lfe_channels' => [0],
		'audio_num_channels' => [1,8],
		'media_time' => [20]
	}
	file_sampling_rate = Array.new
	params['audio_sampling_rate'].each{|sampling_rate| file_sampling_rate << (sampling_rate/1000).floor}
	@pcm_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"[KkHhz]{3}\\w*_",params['audio_type'],"\\w*","pcm")
	audio_sampling_rate_and_bit_rate = [
	{
          'audio_sampling_rate' => [8000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [11025],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [12000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [16000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [22050],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [24000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [32000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [44100],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [48000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [64000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [88200],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    {
          'audio_sampling_rate' => [96000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000, 96000, 128000, 160000, 192000, 224000, 236000, 288000, 'vbr'],
							},
    ]
    @res_params = combine_params(params,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     mode_constraints = []
     constrained_sr_brs = Hash.new{|hash,key| hash[key]=Hash.new([])} 
     @res_params['audio_output_object_type'].each do |type|
         @res_params['audio_sampling_rate_and_audio_bit_rate'].each do |sr_br|
             sampling_rate = sr_br.split('_')[0].to_i
             bit_rate = sr_br.split('_')[1].to_i
             @res_params['audio_type'].each do |audio_type|
             	if !@aac_enc_mode_sampling_rates_and_bit_rates[type][sampling_rate][audio_type] || @aac_enc_mode_sampling_rates_and_bit_rates[type][sampling_rate][audio_type][0] > bit_rate || @aac_enc_mode_sampling_rates_and_bit_rates[type][sampling_rate][audio_type][1] < bit_rate
                    constrained_sr_brs[type][audio_type] = constrained_sr_brs[type][audio_type]|[sr_br]  
             	end
            end		
        end	
 	 end

 	 constrained_sr_brs.each do |type, val|
         val.each do |aud_type, sr_brs|
             constraint_group = '"'+sr_brs[0].to_s+'"'
             1.upto(sr_brs.length-1) do |i|
                constraint_group += ',"'+sr_brs[i]+'"'
             end
             mode_constraints << 'IF [audio_sampling_rate_and_audio_bit_rate] IN {'+constraint_group+'} AND [audio_output_object_type] = "'+type+'" THEN [audio_type] <> "'+aud_type+'";' if sr_brs[0]
         end
     end
 	 mode_constraints | [
	 'IF [audio_input_driver] IN {"encoder"} THEN [audio_source] = "media_filer";',
     'IF [audio_input_driver] = "apfe+encoder" THEN [audio_source] <> "media_filer";',
	]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_aac_ext_params.#{@current_id}",
	     'description'    => "AAC Codec Test type "+(params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,"")+",with audio source "+params['audio_source']+" as input, and audio type "+params['audio_type'], 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script' => 'Common\A-DVTB_AAC_EXT_PARAMS\dvtb_aac_ext_params.rb',
		 'configID' => '..\Config\dvtb_aac_ext_params.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
			    'test_type' => (params['audio_input_driver']+"+"+params['audio_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
				'audio_type' => params['audio_type'],
				'audio_sampling_rate' => get_audio_sampling_rate(params),
				'audio_source' => get_audio_source(params),
				'audio_bit_rate' => get_audio_bit_rate(params),
				'audio_data_endianness' => params['audio_data_endianness'],				
				'audio_encoder_mode' => params['audio_encoder_mode'],
				'audio_input_format' => params['audio_input_format'],
				'audio_dual_mono_mode' => params['audio_dual_mono_mode'],
				'audio_crc_flag' => params['audio_crc_flag'],
				'audio_anc_flag' => get_anc_flag(params),
				'audio_lfe_flag' => get_lfe_flag(params),
				'audio_output_object_type' => params['audio_output_object_type'],  #[2,5,29],
				'audio_output_file_format' => params['audio_output_file_format'], #[0,1,2]				
				'audio_use_tns' => params['audio_use_tns'],
				'audio_use_pns' => params['audio_use_pns'],
				'audio_down_mix_flag' => params['audio_down_mix_flag'],
				'audio_bit_rate_mode' => params['audio_bit_rate_mode'],
				'audio_anc_rate' => params['audio_anc_rate'],
				'audio_num_lfe_channels' => params['audio_num_lfe_channels'],
	        },
		 
		 'paramsControl' => {
			'audio_num_channels' => params['audio_num_channels'],
			'media_time' => params['media_time'],
			},
     }
   end
  # END_USR_CFG get_outputs
   	
  def get_audio_source(params)
	if params['audio_input_driver'].eql?('encoder')
	  result = @pcm_audio_source_hash["\\w+_"+(params['audio_sampling_rate'].to_i/1000).to_s+"[KkHhz]{3}\\w*_"+params['audio_type']+"\\w*"]
	else
	  result = params['audio_source']
	end
	  result
  end
  
  def get_anc_flag(params)
      if params['audio_anc_rate'].to_i > 0
          '1'
      else
          '0'
      end
  end
  
  def get_lfe_flag(params)
      if params['audio_num_lfe_channels'].to_i > 0
          '1'
      else
          '0'
      end
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