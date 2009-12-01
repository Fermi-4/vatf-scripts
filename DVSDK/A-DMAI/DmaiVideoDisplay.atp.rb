require '../media_filer_utils'

include MediaFilerUtils

class DmaiVideoDisplayTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  def get_params()
      @res_params = {
          'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
          'display_out'			=> ['composite', 'component', 'svideo', 'dvi', 'lcd'],
          'display_time' => [10],
      }
    @res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      'IF [display_out] IN {"composite","svideo"} THEN [video_signal_format] IN {"525", "625", "vga"};',
      'IF [display_out] IN {"composite","svideo","component"} THEN [video_signal_format] <> "dummy";',	# Dummy constraint to remove dummy video signal format. The dummy is required for PICT
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
     {
	     'testcaseID'  	=> "dmai_video_display.#{@current_id}",
	     'description' 	=> get_test_description(params),
	     'iter' 		=> '1',
		 'bft' 			=> true,
		 'basic' 		=> true,
		 'ext' 			=> false,
		 'bestFinal' 	=> true,
		 'reg'       	=> true,
		 'auto'			=> true,
		 'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		 'configID' 	=> '../Config/dmai_examples.ini',
		 'paramsChan' 	=> {
        'command_name'			=> 'video_display',
        'video_signal_format'	=> params['video_signal_format'],
        'display_out'			=> params['display_out'],
        'display_time' => params['display_time'],
      },
		 'paramsEquip' 	=> {},
		 'paramsControl'=> {
        'test_type'       => 'subjective',
      },
     }
   end
  # END_USR_CFG get_outputs
  
  private
  def get_test_description(params)
      "Video display dmai test with output #{params['display_out']}"
  end
  
end