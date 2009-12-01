require '../../TestPlans/Common/A-DVTB_H264/DvtbH264Loopback.atp'
require '../../TestPlans/Common/A-DVTB_G711/DvtbG711Loopback.atp'

class DvtbH264G711LoopbackTestPlan < TestPlan
	@@g711_test_plan = DvtbG711LoopbackTestPlan.new
	@@h264_test_plan = DvtbH264LoopbackTestPlan.new
	@@base_params = @@h264_test_plan.get_params().merge(@@g711_test_plan.get_params())
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	#@order = 2
	@group_by = ['operation', 'video_rate_control', 'video_resolution']
	@sort_by = ['operation', 'video_rate_control', 'video_resolution','video_bit_rate','video_frame_rate']
	@auto_gen = ['inputs']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  # Input parameters:
  # This function returns a hash table defining test generating parameters and their value sets. 
  # The hash key is the name of the parameter and the hash value is an array of values for that parameter.
  def get_params()
#	my_params = @@h264_test_plan.get_params()
#	my_params.merge!(@@g711_test_plan.get_params())
	@@base_params.merge!({'video_quality_metric' => ['jnd\=5','mos\=3.5'],
                         'ti_logo_resolution' => ['0x0'],
                         'codec_class'		  => ['H264'],
                         'max_num_files'    => 0})
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  # Constraints:
  # This function returns an array of constraints. The constraints are to eliminate some invalid combinations of input parameters.
  # The constraints are written in PICT constraint language.
  def get_constraints()
     ['{ audio_companding, audio_source, audio_sampling_rate, audio_num_channels } @ 2'] | @@g711_test_plan.get_constraints | @@h264_test_plan.get_constraints
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  # Output parameters:
  # This functions generates a set of output parameters based on a specific value of input parameters.
  # The output parameters are the parameters that drive the test application and they will be stored in the test matrix.
  def get_outputs(params)
     {
	     'testcaseID'     => "dvtb_#{params['codec_class']}_file_loopback.#{@current_id}",
	     'description'    => "#{params['codec_class']} Codec Loopback Test using the encoders default values, a resolution of "+params['video_resolution']+", a bit rate of "+params['video_bit_rate']+", and yuv source files.",
		 'ext' => false,
		 'iter' => '1',
		 'bft' => false,
		 'basic' => true,
		 'ext' => false,
		 'bestFinal' => false,
		 'script'    =>  'DVSDK/A-DVTB_H264_G711_YUV_LOOPBACK/dvtb_h264_g711.rb',
		 'configID' => '../Config/dvtb_h264_g711_loopback.ini',
		 'reg'                       => true,
		 'auto'                     => true,
		 'paramsChan'     => get_test_params('paramsChan',params).merge!({
                                                                         'video_quality_metric' => params['video_quality_metric'],}),
		 'paramsEquip'	 => get_test_params('paramsEquip',params),
		 'paramsControl' => get_test_params('paramsControl',params).merge!({
                                                                           'ti_logo_resolution' => params['ti_logo_resolution'],
                                                                           'codec_class'	  	=> params['codec_class'],
                                                                           'max_num_files'    => params['max_num_files']}),
     }
   end
  # END_USR_CFG get_outputs
  
  private
	def get_test_params(type,params)
		result = {}
		if @@g711_test_plan.get_outputs(params)[type]
			result.merge!(@@g711_test_plan.get_outputs(params)[type])
		end
		if @@h264_test_plan.get_outputs(params)[type]
			result.merge!(@@h264_test_plan.get_outputs(params)[type])
		end
		result
	end
   	
end