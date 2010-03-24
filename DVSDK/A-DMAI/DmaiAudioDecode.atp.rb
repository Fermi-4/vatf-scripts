require '../media_filer_utils'

include MediaFilerUtils

class DmaiAudioDecodeTestPlan < TestPlan
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
    
	@aac_file_format = "_(RAW|ADIF|ADTF)\\w*" #should be ADTS not ADTF but too much work to change file name in repository
	common_parameters = {
		#Generic Audio parameters
		'audio_codec' => ['mp3','mp2','mp1','aac','g711'],
		'audio_type' => ['mono','stereo', '3.0'] | ['dualmono', '2.1','3.1','2.2','3.2','2.3','3.3','3.4'] | ['5.0', '5.1', '7.1'], #['5.0', '5.1', '7.1'] only in 0.9 xdm codecs; ['dualmono', '2.1','3.1','2.2','3.2','2.3','3.3','3.4'] only on 1.0 or later codecs
    'media_location' => ['default','Storage Card'],
    'speech_companding' => ['ulaw', 'alaw'],
    'start_frame' => [0],
    'test_type' => ['objective','subjective'],
    'output_type' => ['mini35mm', 'file'],
    'speech_quality_metric' => [3],
    'max_num_files'     => [1],
    }
	
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
		
	audio_sampling_rates = []
	audio_bit_rates = []
	audio_sampling_rate_and_bit_rate.each do |audio_param_hash|
		audio_sampling_rates = audio_sampling_rates | audio_param_hash['audio_sampling_rate']
		audio_bit_rates = audio_bit_rates | audio_param_hash['audio_bit_rate']
	end
	file_sampling_rate = Array.new
	audio_sampling_rates.each{|sampling_rate| file_sampling_rate << (sampling_rate/1000).floor.to_i}
	file_bit_rate = Array.new
	audio_bit_rates.each do |bit_rate| 
		if bit_rate.to_s.strip.downcase != 'vbr'
			file_bit_rate << (bit_rate/1000).to_s+"kbps"
		else
			file_bit_rate << bit_rate
		end
	end
	@aac_audio_source_hash = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",common_parameters['audio_type'],"\\w*_",file_bit_rate,"\\w*",@aac_file_format,"\\w+","aac")
	@mpx_audio_source_hash = Hash.new
	common_parameters['audio_codec'].each do |mp_type|
		next if !/mp\d/.match(mp_type)
		@mpx_audio_source_hash[mp_type] = get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*_",file_bit_rate,"\\w*",common_parameters['audio_type'],"\\w*",mp_type)
		@mpx_audio_source_hash[mp_type].merge!(get_source_files_hash("\\w+_",file_sampling_rate,"kHz\\w*",common_parameters['audio_type'],"\\w*_",file_bit_rate,"\\w*",mp_type))
	end
	@res_params = combine_params(common_parameters,audio_sampling_rate_and_bit_rate,['audio_sampling_rate','audio_bit_rate'])
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
	  mponly_samp_and_bit_rate = ''
    @res_params['audio_sampling_rate_and_audio_bit_rate'].each do |sampling_br|
      if sampling_br.downcase.include?('vbr')
        mponly_samp_and_bit_rate += ', ' if mponly_samp_and_bit_rate != ''
        mponly_samp_and_bit_rate += '"'+sampling_br+'"'
      end
    end
    format_constraints = Array.new
    format_constraints << 'IF [audio_codec] <> "mp3" THEN [audio_sampling_rate_and_audio_bit_rate] NOT IN {' + mponly_samp_and_bit_rate +'};' if mponly_samp_and_bit_rate != '' 
    format_constraints | [
                          'IF [audio_codec] = "g711" THEN [audio_sampling_rate_and_audio_bit_rate] = "8000_64000";',
                          'IF [audio_codec] =  "g711" THEN [audio_type] = "mono";',
	]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dmai_audio_dec.#{@current_id}",
	     'description'    => "#{params['audio_codec']} Decode Test, audio_sampling_rate = "+get_audio_sampling_rate(params)+', audio bit rate = '+get_audio_bit_rate(params), 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		 'configID' 	=> 'Config/dmai_examples.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
        'command_name' => get_command_name(params),
				'audio_type' => params['audio_type'],
				'input_file' => get_audio_source(params),
				'audio_sampling_rate' => get_audio_sampling_rate(params),
				'audio_bit_rate' => get_audio_bit_rate(params),
				'audio_codec' => params['audio_codec'],
        'media_location' => params['media_location'],
        'speech_companding' => params['speech_companding'],
        'start_frame' => params['start_frame'],
        'speech_quality_metric' => params['speech_quality_metric'],
        'output_type' => params['output_type'],
				},
		 'paramsEquip' => {
			},
		 'paramsControl' => {
        'test_type' => params['test_type'],
        'max_num_files' => params['max_num_files']
			},
     }
   end
  # END_USR_CFG get_outputs
	
	def get_audio_source(params)
		file_sampling_rate = (get_audio_sampling_rate(params).to_i/1000).floor.to_i.to_s
		file_bit_rate = get_audio_bit_rate(params)
		file_bit_rate = (file_bit_rate.to_i/1000).to_s+"kbps" if file_bit_rate.strip.downcase != 'vbr'
		audio_source = ''
		case params['audio_codec'].strip.downcase
			when 'aac'
	    		audio_source = @aac_audio_source_hash["\\w+_"+file_sampling_rate+"kHz\\w*"+params['audio_type']+"\\w*_"+file_bit_rate+"\\w*"+@aac_file_format+"\\w+"]
      when /mp./
				audio_source = @mpx_audio_source_hash[params['audio_codec'].strip.downcase]["\\w+_"+file_sampling_rate+"kHz\\w*_"+file_bit_rate+"\\w*"+params['audio_type']+"\\w*"].to_s
				audio_source += ';' if audio_source.strip != '' && @mpx_audio_source_hash[params['audio_codec'].strip.downcase]["\\w+_"+file_sampling_rate+"kHz\\w*"+params['audio_type']+"\\w*_"+file_bit_rate+"\\w*"]
				audio_source += @mpx_audio_source_hash[params['audio_codec'].strip.downcase]["\\w+_"+file_sampling_rate+"kHz\\w*"+params['audio_type']+"\\w*_"+file_bit_rate+"\\w*"].to_s
			else
				audio_source = 'test1_16bIntel.'+params['speech_companding'].sub(/law$/,'').sub(/linear$/,'pcm')
		end
	    audio_source = "not found" if audio_source.to_s.strip == ''
		audio_source
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
   
   def get_command_name(params)
      if ['g711', 'g726', 'g729', 'g722', 'g723', 'amr', 'g718', 'g719'].include?(params['audio_codec'].downcase.strip)
        'speech_decode'
      else
        'audio_decode'
      end
   end
 end
