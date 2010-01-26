require '../media_filer_utils'
include MediaFilerUtils

class Video_func_v4l2_displayTestPlan < TestPlan
   # BEG_CLASS_INIT
  def initialize()
    super
  end
  # END__CLASS_INIT	
  
  # BEG_USR_CFG setup
  def setup()
      @order = 3
      @group_by = ['microType', 'dev_node', 'standard', 'interface']
      @sort_by = ['microType', 'dev_node', 'standard', 'interface']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
      keys = [
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['default']
	}
 	]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    params = 
    {
      'dev_node'	  				=> ['/dev/video2', '/dev/video3'],
      'standard'					=> ['ntsc', 'pal', '1080i-30' ,'1080i-25', '720p-50', '720p-60', '480p-60', '576p-50'],
      'num_of_frames'				=> ['1000'],
      'num_of_buffers'				=> ['3'],
      'interface'					=> ['composite', 'component', 'svideo']
    }
    
    
  end
  # END_USR_CFG get_params
  
   # BEG_USR_CFG get_constraints

  def get_constraints()
    [
      'IF [interface] IN {"composite","svideo"} THEN [standard] IN {"ntsc","pal","480p-60","576p-50"};',
    ]
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      'target_sources'  => 'LSP\A-Video\linux_v4l2_display_test_suite',
    }
    common_vars = {
        'iter'         => 1,
      	'bft'          => true,
      	'basic'        => true,
      	'ext'          => true,
       	'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\default_test_script.rb',
      'paramsControl'   => {},
      'paramsEquip'     => {},
    }
    tc = [
      {
        'description'  => "V4L2 API Tests", 
        'testcaseID'   => 'v4l2_func_api_test_0001',
        'paramsChan'  => common_paramsChan.merge({
        	'cmd'       => '[dut_timeout\=60];'+
        				   'v4l2DisplayTests -T api -t apitests`++\|TEST\s*RESULT\|PASS\|\s*apitests--\|TEST\s*RESULT\|FAIL\|\s*apitests`'
        }),
      },
      {
        'description'  => "V4L2 Stability Test", 
        'testcaseID'   => 'v4l2_func_stability_test_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => '[dut_timeout\=3600];'+
                         'v4l2DisplayTests -T stability -t stabilitytests`++\|TEST\s*RESULT\|PASS\|\s*stabilitytests--\|TEST\s*RESULT\|FAIL\|\s*stabilitytests`'
        }),
      },
    ]
    # merge the common varaibles to the individuals test cases and the value in individuals test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      tc_new << common_vars.merge(val)
    }
    return tc_new
  end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
        'description'  => "V4L2 Display Functionality test on #{params['dev_node']}  #{params['interface']} interface using  #{params['standard']} standard  ",
        'testcaseID'   => "#{params['dev_node']}_#{params['interface']}_#{params['standard']}_func_" + "%04d" % "#{@current_id}",
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\A-Video\video_func_v4l2_display.rb',
        'paramsChan'   => {
            'dev_node'      	=> "#{params['dev_node']}",
            'standard'      	=> "#{params['standard']}",
            'interface'			=> "#{params['interface']}",
            'num_of_buffers'    => "#{params['num_of_buffers']}",
            'num_of_frames'     => "#{params['num_of_frames']}",
            'width' 			=> get_width(params['standard']),
            'height'  			=> get_height(params['standard']),
            'filename'      	=> get_file_name(params['standard']),
            'manual_pass_fail'  => '0',
            'target_sources' 	=> 'LSP\A-Video\linux_v4l2_display_test_suite',
        },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
  private
  def get_file_name(standard)
      case standard
      when 'pal': 		'gals_720x576_422i.yuv'
      when '1080i-30':	'cafeteria_1920x1080_422i.yuv'
      when '1080i-25':	'cafeteria_1920x1080_422i.yuv'
      when '720p-50':	'cafeteria_1280x720_422i.yuv'
      when '720p-60':	'cafeteria_1280x720_422i.yuv'
      when '480p-60':	'shrek_720x480_422i.yuv'
      when '576p-50':	'gals_720x576_422i.yuv'
      else 				'shrek_720x480_422i.yuv'
      end
  end
  
  def get_width(standard)
      case standard
          when '1080i-30':	'1920'
          when '1080i-25':	'1920'
          when '720p-50':	'1280'
          when '720p-60':	'1280'
          when 'pal': 		'720'
          when '576p-50':	'720'
          when '480p-60':	'720'
          else 				'720'
      end
  end
  
  def get_height(standard)
      case standard
          when '1080i-30':	'1080'
          when '1080i-25':	'1080'
          when '720p-50':	'720'
          when '720p-60':	'720'
          when 'pal': 		'576'
          when '576p-50':	'576'
          when '480p-60':	'480'
          else 				'480'
      end
  end
end
