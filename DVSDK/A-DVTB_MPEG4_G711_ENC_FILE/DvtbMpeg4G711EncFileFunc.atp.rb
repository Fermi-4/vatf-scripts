require '../media_filer_utils'
include MediaFilerUtils

class DvtbMpeg4G711EncFileFuncTestPlan < TestPlan
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
	@group_by = ['video_resolution_and_bit_rate']
	@sort_by = ['video_resolution_and_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
common_params ={
						'video_frame_rate'		  => [5, 10, 15, 25, 30],
						'video_bit_rate'		  => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000],
					    'video_resolution'		  => ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576', '128x96', '320x240', '640x480', '704x288', '704x480'],
					    'video_input_chroma_format' => ['420p', '422i'],
					    'video_num_channels'				=> [1,8],
					    'video_gop' => [0,15,30],
						'video_encoder_preset' => [0,1,2,3], # 0 -> default, 1 -> high quality, 2 -> high speed, 3 -> user defined. Only high quality is supported in mpeg4sp
					    'video_rate_control'=>[1,2,5],
						'audio_companding' => ['ulaw','alaw'],
						'audio_sampling_rate' => [8000],
						'audio_num_channels' => [1,4]
					}
	@audio_source_hash = get_source_files_hash("\\w+_8KHz\\w*","pcm")
	@video_source_hash = get_source_files_hash("\\w*",common_params['video_resolution'],"_",common_params['video_input_chroma_format'],"\\w*frames","yuv")	
	video_res_and_bit_rate = [{
		'video_resolution' => ['352x288'],
		'video_bit_rate'  => [128000,350000,768000,1300000,2000000],
	},
	{
		'video_resolution' => ['720x576'],
		'video_bit_rate'  => [1300000,512000,4000000,10000000],
	},
	{
		'video_resolution' => ['176x144'],
		'video_bit_rate'  => [170000,256000,350000,512000,96000],
	},
	{
		'video_resolution' => ['128x96'],
		'video_bit_rate'  => [64000],
	},
	{
		'video_resolution' => ['704x480'],
		'video_bit_rate'  => [1300000,512000,4000000,10000000],
	},
	{
		'video_resolution' => ['352x240'],
		'video_bit_rate'  => [128000,350000,768000,1300000,2000000],
	},
	{
		'video_resolution' => ['640x480'],
		'video_bit_rate'  => [1300000,512000,4000000,10000000],
	},
	{
		'video_resolution' => ['176x120'],
		'video_bit_rate'  => [170000,256000,350000,512000,96000],
	},
	{
		'video_resolution' => ['320x240'],
		'video_bit_rate'  => [128000,350000,768000,1300000,2000000],
	},
	{
		'video_resolution' => ['720x480'],
		'video_bit_rate'  => [1300000,512000,4000000,10000000],
	},
	]
	combine_res_and_bit_rate(common_params, video_res_and_bit_rate)
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [ '{audio_companding,audio_sampling_rate,audio_num_channels} @ 2',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"MPEG4 G711 Encode File Functionality Test, video_res=#{get_video_resolution(params)}, frame_rate=#{params['video_frame_rate']},bit_rate=#{get_video_bit_rate(params)}",
	
									
    'iter'                       => '1',
    'testcaseID'                 => "dvtb_mpeg4_g711_enc_file_func.#{@current_id}",
    'bft'                        => false,
    'basic'                      => false,
    'ext'                        => true,
    'reg'                        => false,
    'auto'                       => false,
    'bestFinal'               => false,
    'script'                     => 'Common\A-DVTB_MPEG4_G711_ENC_FILE\dvtb_mpeg4_g711_enc_file_func.rb',

    # channel parameters
    'paramsChan'                => {
        	'video_frame_rate' => params['video_frame_rate'],
			'video_gop' => params['video_gop'],
			'video_encoder_preset' => params['video_encoder_preset'],
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
    'paramsEquip'     => {
    },
    'paramsControl'     =>{
        'video_num_channels' => params['video_num_channels'],
        'audio_num_channels' => params['audio_num_channels']
        },
    'configID'      => '..\Config\dvtb_mpeg4_g711_enc_file_func.ini',
    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

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
  
  	def get_video_source(params)
		@video_source_hash["\\w*"+get_video_resolution(params)+"_"+get_video_input_chroma_format(params)+"\\w*frames"]
	end
  
    def get_audio_source(params)
        @audio_source_hash["\\w+_8KHz\\w*"]
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
