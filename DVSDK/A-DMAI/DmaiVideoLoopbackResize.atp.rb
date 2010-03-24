require '../media_filer_utils'

include MediaFilerUtils

class DmaiVideoLoopbackResizeTestPlan < TestPlan
	# BEG_USR_CFG setup
  # General setup:
  def setup()
	@order = 2
	@sort_by = ['input_resolution']
	@group_by = ['input_resolution']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_params
  def get_params()
      @signal_format_max_res = {
           '525' => [720,480],
           '625' => [720,576], 
           '720p50' => [1280,720],
           '720p59' => [1280,720],
           '720p60' => [1280,720],          
      }
      @video_resolutions = ['176x120', '352x240', '720x480', '176x144', '352x288', '720x576',   '128x96', '320x240', '640x480', '704x288', '704x480', '704x576', '800x600', '1024x768', '1280x720', '1280x960', '1920x1080']
      @res_params = {
          'video_input'			=> ['component', 'composite', 'svideo'],
          'video_signal_format' => ['525', '625', '1080i50', '1080i59', '1080i60', '720p50', '720p59', '720p60', '1080p23', '1080p24', '1080p25', '1080p29', '1080p30', '1080p50', '1080p59', '1080p60', 'dummy'],
          'display_out'			=> ['composite', 'component', 'svideo'],
          'video_source' => ['dvd'],
          'output_resolution'	=> ['equal', 'bigger', 'smaller'],
          'input_resolution'	=> @video_resolutions,
          'capture_ualloc' => ['yes','no'],
          'display_ualloc' => ['yes','no'],
          'output_position' => ['0x0','default'],
          'input_position' => ['0x0','default'],
          'crop'         =>  ['yes', 'no'],
          'display_time' => [10],
      }
    
    @res_params
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_constraints
  def get_constraints()
     const_hash = {}
     const_hash.default = []
     @res_params['input_resolution'].each do |video_resolution|
         resolution = video_resolution.split('x')
         @res_params['video_signal_format'].each do |format|
             if @signal_format_max_res[format] && (@signal_format_max_res[format][0] < resolution[0].to_i || @signal_format_max_res[format][1] < resolution[1].to_i)
                 const_hash[format] = const_hash[format]|[video_resolution]
             end
         end
     end
     format_constraints = Array.new
     const_hash.each do |format,res|
         current_group ='"'+res[0]+'"'
         1.upto(res.length-1){|i| current_group+=', "'+res[i]+'"'}
         format_constraints << 'IF [video_signal_format] = "'+ format + '" THEN [input_resolution] NOT IN {'+ current_group +'};'
     end
     format_constraints | [
      'IF [display_out] IN {"composite","svideo"} THEN [video_signal_format] IN {"525", "625", "vga"};',
      'IF [display_out] IN {"composite","svideo","component"} THEN [video_signal_format] <> "dummy";',	# Dummy constraint to remove dummy video signal format. The dummy is required for PICT
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
     {
	     'testcaseID'  	=> "dmai_video_loopback_resize.#{@current_id}",
	     'description' 	=> get_test_description(params),
	     'iter' 		=> '1',
		 'bft' 			=> true,
		 'basic' 		=> true,
		 'ext' 			=> false,
		 'bestFinal' 	=> true,
		 'reg'       	=> true,
		 'auto'			=> true,
		 'script'    =>  'DVSDK/A-DMAI/dmai_app.rb',
		 'configID' 	=> 'Config/dmai_examples_subjective.ini',
		 'paramsChan' 	=> {
        'command_name'			=> 'video_loopback_resize',
        'video_input'			=> params['video_input'],
        'video_signal_format' => params['video_signal_format'],
        'display_out'			=> params['display_out'],
        'video_source' => get_video_source(params),
        'output_resolution'	=> get_output_resolution(params),
        'input_resolution'	=> params['input_resolution'],
        'capture_ualloc' => params['capture_ualloc'],
        'display_ualloc' => params['display_ualloc'],
        'output_position' => params['output_position'],
        'input_position' => params['input_position'],
        'crop'         =>  params['crop'],
      },
		 'paramsEquip' 	=> {},
		 'paramsControl'=> {
        'display_time' => params['display_time'], 
      },
     }
   end
  # END_USR_CFG get_outputs
  
  private
  def get_test_description(params)
      "Video loopback resize test from #{params['input_resolution']} to a #{params['output_resolution']} resolution"
  end
  
  def get_video_source(params)
    params['video_signal_format'].gsub('525','ntsc').gsub('625','pal')+'_'+params['video_source']
  end
  
  def get_output_resolution(params)
    bigger_res = []
    smaller_res = []
    input_width = params['input_resolution'].split('x')[0].to_i
    @video_resolutions.each do |current_res|
      width = current_res.split('x')[0].to_i
      bigger_res = bigger_res | [current_res] if width > input_width
      smaller_res = smaller_res | [current_res] if width < input_width
    end
    case params['output_resolution'].downcase.strip
      when 'equal'
        params['input_resolution']
      when 'bigger'
        bigger_res[rand(bigger_res.length)]
      when 'smaller'
        smaller_res[rand(smaller_res.length)]
    end
  end
  
end