require '../media_filer_utils'

include MediaFilerUtils

class DvtbH264G711EncFileOVQTestPlan < TestPlan
 	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@group_by = ['video_resolution_and_bit_rate']
	@sort_by = ['video_resolution_and_bit_rate','video_frame_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	params = {
		'video_resolution' => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576', '128x96', '320x240', '640x480', '704x288', '704x480','704x576'],
		'video_frame_rate'=> [5, 10, 15, 25, 30],
		'video_gop'=>[0,15,30],
		'video_rate_control'=>[1,2,5],
		'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined
		'video_input_chroma_format'=>['420p','422i'],
		'video_num_channels' => [1,8],
		'audio_companding' => ['ulaw','alaw'],
		'audio_sampling_rate' => [8000],
		'audio_num_channels' => [1,4]
	}
	@audio_source_hash = get_source_files_hash("\\w+_8KHz\\w*","pcm")
	@video_source_hash = get_source_files_hash("\\w*",params['video_resolution'],"_",params['video_input_chroma_format'],"\\w*_\\d{2,3}frames","yuv")	
	video_res_and_bit_rates = [
    {
        'video_resolution' => ['128x96'],
        'video_bit_rate'  => [64000],
    },
	{
		'video_resolution' => ['176x120'],
		'video_bit_rate'  => [128000,256000,64000,800000,96000],
	},
	{
		'video_resolution' => ['320x240'],
		'video_bit_rate'  => [128000,256000,512000,768000,1000000],
	},
	{
		'video_resolution' => ['640x480'],
		'video_bit_rate'  => [4000000,2000000,512000,1000000,786000],
	},
    {
         'video_resolution' => ['176x144'],
         'video_bit_rate' => [64000, 128000, 192000, 256000, 1000000],
    },
    {
         'video_resolution' => ['352x240'],
         'video_bit_rate' => [128000, 256000, 768000 , 1000000, 3000000],
    },
    {
         'video_resolution' => ['352x288'],
         'video_bit_rate' => [128000, 256000, 768000 , 1000000, 3000000],
    },
    {
         'video_resolution' => ['704x480'],
         'video_bit_rate' => [512000, 1000000, 4000000],
    },
    {
         'video_resolution' => ['704x576'],
         'video_bit_rate' => [512000, 1000000, 4000000],
    },
    {
         'video_resolution' => ['720x480'],
         'video_bit_rate' => [512000, 1000000, 4000000],
    },
    {
         'video_resolution' => ['720x576'],
         'video_bit_rate' => [512000, 1000000, 4000000],
    },
     ]
     
     combine_res_and_bit_rate(params,video_res_and_bit_rates)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     [
      '{audio_companding,audio_sampling_rate,audio_num_channels} @ 2',
	 ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_h264_g711_enc_file_ovq.#{@current_id}",
	     'description'    => "H264_G711 Encode file Objective Quality Test using the encoders default values, a resolution of "+get_video_resolution(params)+",and a bit rate of "+get_video_bit_rate(params), 
		 'script' => 'Common\A-DVTB_H264_G711_ENC_FILE\dvtb_h264_g711_enc_file_ovq.rb',
		 'configID' => '..\Config\dvtb_h264_g711_enc_file_ovq.ini', 
	     'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'bestFinal' => false,
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => {
					'video_encoder_preset' => params['video_encoder_preset'],
					'video_frame_rate' => params['video_frame_rate'],
					'video_gop' => params['video_gop'],
					'video_rate_control' => params['video_rate_control'],
					'video_input_chroma_format' => get_video_input_chroma_format(params),
					'video_height' => get_video_height(params),
					'video_width' => get_video_width(params),
					'video_bit_rate' => get_video_bit_rate(params),
					'video_source' => get_video_source(params),
					'audio_companding' => params['audio_companding'],
		            'audio_sampling_rate' => params['audio_sampling_rate'],
		            'audio_source' => get_audio_source(params),
		            
   			 },
		 'paramsEquip'	 => {
			 },
		 'paramsControl' => {
			 'video_num_channels' => params['video_num_channels'],
			 'audio_num_channels' => params['audio_num_channels']
			 },
	 }
  end
   
   
   
    private
	def get_video_source(params)
		@video_source_hash["\\w*"+get_video_resolution(params)+"_"+get_video_input_chroma_format(params)+"\\w*_\\d{2,3}frames"]
	end
	
	def get_audio_source(params)
		@audio_source_hash["\\w+_8KHz\\w*"]
	end
	
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
      params['video_resolution_and_bit_rate'].strip.split("_")[0]
  	end
  
  	def get_video_bit_rate(params)
      params['video_resolution_and_bit_rate'].strip.split("_")[1]
  	end
  	
  	def get_video_input_chroma_format(params)
        case params['video_resolution_and_bit_rate'].strip
         when /(176x144|704x480|704x576|128x96|176x120|320x240|640x480)\w+/
             "420p"
         else
             params['video_input_chroma_format']
         end
    end
    
    def combine_res_and_bit_rate(dst_hash, array_of_hash=nil)
      result = Array.new
      array_of_hash = [{'video_bit_rate' => dst_hash['video_bit_rate'], 'video_resolution' => dst_hash['video_resolution']}] if !array_of_hash
      array_of_hash = [array_of_hash] if array_of_hash.kind_of?(Hash)
      array_of_hash.each do |val_hash|
          val_hash['video_resolution'].each do |video_resolution|
              val_hash['video_bit_rate'].each do |video_bit_rate|
              	result << video_resolution.to_s+"_"+video_bit_rate.to_s
              end
          end
      end
      dst_hash.delete('video_resolution')
      dst_hash.delete('video_bit_rate')
      dst_hash.merge!({'video_resolution_and_bit_rate' => result})
      dst_hash
    end
end
