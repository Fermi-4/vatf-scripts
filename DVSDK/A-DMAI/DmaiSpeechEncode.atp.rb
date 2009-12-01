require '../media_filer_utils'

include MediaFilerUtils

class DmaiSpeechEncodeTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by = ['audio_codec', 'audio_sampling_rate_and_audio_bit_rate']
	@group_by = ['audio_codec', 'audio_sampling_rate_and_audio_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
    
	common_parameters = {
		#Generic Audio parameters
		'audio_codec' => ['g711', 'g726', 'g729', 'g722', 'g723', 'amr', 'g718', 'g719'],
		'audio_type' => ['mono'], 
    'media_location' => ['default'],
    'speech_companding' => ['ulaw', 'alaw'],
    'start_frame' => [0],
    'test_type' => ['objective','subjective'],
    'speech_quality_metric' => [3],
    }
	  
    audio_sampling_rate_and_bit_rate = [
		{
          'audio_sampling_rate' => [8000],
          'audio_bit_rate' => [8000, 16000, 32000, 48000, 64000],
					},
    ]
		
	audio_sampling_rates = []
	audio_sampling_rate_and_bit_rate.each do |audio_param_hash|
		audio_param_hash['audio_sampling_rate'].each{|sampling_rate| audio_sampling_rates =  audio_sampling_rates | [(sampling_rate/1000).floor]}
	end
	@pcm_audio_source_hash = get_source_files_hash("\\w+_",audio_sampling_rates,"[KkHhz]{3}\\w*_",common_parameters['audio_type'],"\\w*","pcm")
	@res_params = combine_params(common_parameters,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
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
	     'testcaseID'     => "dmai_speech_dec.#{@current_id}",
	     'description'    => "#{params['audio_codec']} Decode Test, audio_sampling_rate = "+get_audio_sampling_rate(params)+', audio bit rate = '+get_audio_bit_rate(params), 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		 'configID' 	=> '../Config/dmai_examples.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
        'command_name' => 'speech_encode',
				'input_file' => get_audio_source(params),
				'audio_sampling_rate' => get_audio_sampling_rate(params),
				'audio_bit_rate' => get_audio_bit_rate(params),
				'audio_codec' => params['audio_codec'],
        'media_location' => params['media_location'],
        'speech_companding' => params['speech_companding'],
        'start_frame' => params['start_frame'],
        'speech_quality_metric' => params['speech_quality_metric'],
				},
		 'paramsEquip' => {
			},
		 'paramsControl' => {
        'test_type' => params['test_type']
			},
     }
   end
  # END_USR_CFG get_outputs
	
	def get_audio_source(params)
    if params['test_type'].strip.downcase == 'subjective'
      @pcm_audio_source_hash["\\w+_"+(get_audio_sampling_rate(params).to_i/1000).to_s+"[KkHhz]{3}\\w*_"+params['audio_type']+"\\w*"]
    else
      'test1_16bIntel.pcm'
    end
	end
   
   private
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
