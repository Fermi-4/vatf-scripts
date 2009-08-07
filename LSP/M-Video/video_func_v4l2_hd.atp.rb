require '../media_filer_utils'
require '../../TestPlans/LSP/M-Video/v4l2_func_common'

include MediaFilerUtils
class Video_func_v4l2_hdTestPlan < TestPlan
    include V4l2_hd_common
  def initialize()
    super
  end
  # BEG_USR_CFG setup
  def setup()
      @order = 3
      @group_by = ['microType']
      @sort_by = ['microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
      keys = [
         {
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld','rtt'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'platform' => ['dm365'],
          'target' => ['210_lsp'],
          'os' => ['linux'],
          'custom'    => ['default']
         }
      ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'Input_vid'  => [2], # 0 - Composite, 1 - S-Video, 2 - Component 
      'Output'  => [2], # 0 - Comosite, 1 - S-Video, 2 - Component 
      'In_Fmt'	=> [5, 6], # 5 - 720P-60, 6 - 1080I-30
      'Out_Fmt' => [5, 6], # 5 - 720P-60, 6 - 1080I-30
      #'Vid_plane'  => [0, 1], # 0 - Video0, 1 - Video1, 2 - Both the video planes
      #'Cap_Plane'  => [0, 1], # 0 - Capture is displayed in Video0, 1 - Capture is displayed in Video1 	
      #'OSD_en'	=> [0, 1] # 0 - OSD0 is not enabled, 1 - OSD0 is enabled.
    }
  end
  # END_USR_CFG get_params
    # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      #'target_sources'  => 'LSP\st_parser'
      #'ensure'  => ''
      #'configID'     => '..\Config\lsp_generic.ini',
      #'script'       => 'LSP\M-Video\video_func_v4l2_sd.rb',
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
    }
    tc = [
      {
        'description'  =>  "Verify that the video loopback works fine in looping back a 720P format video with both the display and capture driver module loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_hd_mod_0001',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the video loopback works fine in looping back a 1080I format video with both the display and capture driver module loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_mod_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      }
      ]
      # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      #val.merge!(common_vars)
      tc_new << common_vars.merge(val)
    }
    return tc_new
  end
  # END_USR_CFG get_manual
  # BEG_USR_CFG get_constraints
  def get_constraints()
      [
       'IF [In_Fmt] IN {5} THEN [Out_Fmt] IN {5};',
       'IF [In_Fmt] IN {6} THEN [Out_Fmt] IN {6};',
      ]
  end
  # END_USR_CFG get_constraints
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
        'testcaseID'     => "video_v4l2_capture_hd.#{@current_id}",
        'description'	=> "V4L2 HD Functionality test in  #{get_in_fmt(params['Out_Fmt'])} format.",
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\M-Video\video_func_v4l2_hd.rb',
        'paramsChan'   => {
            'input_vid'	=> "#{params['Input_vid']}",
            'output'	=> "#{params['Output']}",
            'in_fmt'	=> "#{params['In_Fmt']}",
            'Out_Fmt'	=> "#{params['Out_Fmt']}",
            #'vid_plane'	=> "#{params['Vid_plane']}",
            'target_sources' => 'LSP\M-Video\Video\hd',
            'cmd'	=> "./v4l2_loop_hd -f #{params['Out_Fmt']} -i #{params['Input_vid']} -o #{params['Output']}",
        },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
end