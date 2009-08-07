
class DvtbMpeg4OVQTestPlan < TestPlan
  # BEG_USR_CFG setup
  # General setup:
  def setup()
    @order = 2
	@group_by = ['video_source']
	@sort_by = ['video_source', 'video_bit_rate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
	{ 
		'video_input_driver'  => ['vpfe+encode','none'],
		'video_output_driver'  => ['vpbe+decode','none'],              
        'video_bit_rate'	  => [64000, 96000, 128000, 192000, 256000, 350000, 384000, 500000, 512000, 768000, 786000, 800000,1000000, 1100000, 1500000, 2000000, 2500000, 3000000, 4000000, 5000000, 6000000, 8000000, 10000000],
        'video_source'	  => ['football_704x480_420p_150frames_30fps.avi', 'sheilds_720x480_420p_252frames_30fps.avi','mobile_704x480_420p_150frames_30fps.avi'],
        'video_num_channels'  => [1,8],
		'video_encoder_preset' => [0, 1, 2, 3],
		'video_rate_control' => [1, 2, 3, 4, 5],
        'setup_delay' 	  => [32],
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
    [
     'IF [video_input_driver] = "none" THEN [video_output_driver] <> "none";'
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
    {
	'description'		=>"Objective Video Quality from composite in to composite out, video_res=#{get_video_resolution(params['video_source'])}, bit_rate=#{params['video_bit_rate']}, frame_rate=#{get_video_frame_rate(params['video_source'])}",
    	'iter'                       => '1',
        'testcaseID'                 => "dvtb_mpeg4_ovq.#{@current_id}",
        'bft'                        => false,
        'basic'                      => false,
        'ext'                        => true,
        'reg'                        => false,
        'auto'                       => false,
        'bestFinal'                  => false,
        'script'                     => 'Common\A-DVTB_MPEG4\dvtb_mpeg4_ovq.rb',

        # channel parameters
        'paramsChan'                => {
		    'test_type'              	=> (params['video_input_driver']+'+'+params['video_output_driver']).gsub(/\+{0,1}none\+{0,1}/,""),
		    'video_codec'              	=> 'mpeg4',
	        'video_frame_rate'		=> get_video_frame_rate(params['video_source']),
	        'video_bit_rate'          	=> params['video_bit_rate'],
		    'video_height'			=> get_video_height(get_video_resolution(params['video_source'])), 
		    'video_width'			=> get_video_width(get_video_resolution(params['video_source'])), 
		    'video_input_chroma_format' => get_video_chroma_format(params['video_source']),
		    'video_number_of_frames' 	=> get_video_number_frames(params['video_source']),
			'video_rate_control' => params['video_rate_control'],
			'video_encoder_preset' => params['video_encoder_preset'],
		    'video_source'           	=> params['video_source'],
	},
    'paramsEquip'     => {
    },
    'paramsControl'     => {
		'video_num_channels' => params['video_num_channels'],
		'setup_delay' 	     => params['setup_delay'], 
     },
    'configID'      => '..\Config\dvtb_mpeg4_ovq.ini',
    'last'            => true,
   }
  end
  # END_USR_CFG get_outputs

  private
  def get_video_height(resolution)
	pat = /(\d+)[x|X](\d+)/i
	res = pat.match(resolution)
	res[2]
  end
  
  def get_video_width(resolution)
	  pat = /(\d+)[x|X](\d+)/i
    res = pat.match(resolution)
		res[1]
  end
  
  def get_video_resolution(video_file)
	pat = /_(\d+[x|X]\d+)_/i
    res = pat.match(video_file)
	res[1]
  end
  
  def get_video_frame_rate(video_file)
	pat = /_(\d+)fps/i
    	res = pat.match(video_file)
	res[1]
  end
  
  def get_video_number_frames(video_file)
	pat = /_(\d+)[Ff]rames_/i
    res = pat.match(video_file)
	res[1]
  end
  
  def get_video_chroma_format(video_file)
	pat = /_(42[02][pPiI])_/i
    res = pat.match(video_file)
	res[1]
	"422i"			# forced it to be 422i for composite in/out cases
  end
  
  
  
end
