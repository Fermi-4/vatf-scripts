require '../media_filer_utils'
require '../../TestPlans/LSP/M-Video/fbdev_func_common'

include MediaFilerUtils
class Video_func_fbdev_sd_twoplanesTestPlan < TestPlan
    include Fbdev_sd_common
  def initialize()
    super
  end
  # BEG_USR_CFG setup
  def setup()
      @order = 6
      @group_by = ['microType', 'In_Fmt', 'Vid_plane']
      @sort_by = ['microType', 'In_Fmt', 'Vid_plane']
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
      'Input_vid'  => [0, 1, 2], # 0 - Composite, 1 - S-Video, 2 - Component 
      'Output'  => [0, 2], # 0 - Comosite, 1 - S-Video, 2 - Component 
      'In_Fmt'	=> [0, 1, 2, 3], # 0 - NTSC, 1 - PAL
      'Out_Fmt' => [0, 1, 2, 3], # 0- NTSC, 1 - PAL, 2 - 420P, 3 - 576P
      'Vid_plane'  => [0, 1, 2, 3, 4, 5], # 0 - Video0 gets streaming without OSD0, 1 - Video1 gets streaming without OSD0, 2 - Video0 gets streaming with OSD0, 3 - Video1 gets streaming with OSD0
      # 4 - Video0 gets streaming with OSD1, 5 - Video1 gets streaming with OSD1
      'blend_value' => [0,1,2,3,4,5,6,7]
      #'Cap_Plane'  => [0, 1], # 0 - Capture is displayed in Video0, 1 - Capture is displayed in Video1 	
      #'OSD_en'	=> [0, 1] # 0 - OSD0 is not enabled, 1 - OSD0 is enabled.
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_constraints
  def get_constraints()
      [
       #'IF [Input_vid] IN {0, 1} THEN [Output] IN {0,1};',
       'IF [Input_vid] IN {0, 1} THEN [Output] IN {0};',
       'IF [Input_vid] IN {2} THEN [Output] IN {2};',
       'IF [Input_vid] IN {0, 1} THEN [In_Fmt] IN {0,1};',
       'IF [Input_vid] IN {2} THEN [In_Fmt] IN {2,3};',
       'IF [Input_vid] IN {0, 1} THEN [Out_Fmt] IN {0,1};',
       'IF [Input_vid] IN {2} THEN [Out_Fmt] IN {2,3};',
       #'IF [Input_vid] IN {0, 1} AND [platform] in {"dm6446"} THEN [Output] IN {0,1,2};',
       #'IF [Input_vid] IN {2} THEN [Output] IN {2};',
       #'IF [Input_vid] IN {2} THEN [In_Fmt] IN {2, 3};',
       #'IF [Output] IN {2} THEN [In_Fmt] IN {0};',
       #'IF [Output] IN {0, 1} THEN [Out_Fmt] IN {0,1};',
       #'IF [Output] IN {2} THEN [Out_Fmt] IN {2,3};',
       'IF [In_Fmt] IN {0} THEN [Out_Fmt] IN {0};',
       'IF [In_Fmt] IN {1} THEN [Out_Fmt] IN {1};',
       'IF [In_Fmt] IN {2} THEN [Out_Fmt] IN {2};',
       'IF [In_Fmt] IN {3} THEN [Out_Fmt] IN {3};',
       'IF [Vid_plane] IN {0,1,2,3} THEN [blend_value] IN {0};',
      ]
  end
  # BEG_USR_CFG get_constraints
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
        'description'  =>  "Verify that the video loopback works fine in looping back a NTSC format video in SEMI PLANAR pixel format.",
        'testcaseID'   => 'fbdev_SP_0001',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the video loopback works fine in looping back a PAL format video in SEMI PLANAR pixel format.",
        'testcaseID'   => 'fbdev_SP_0002',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the video loopback works fine in looping back a 720P format video in SEMI PLANAR pixel format.",
        'testcaseID'   => 'fbdev_SP_0003',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the video loopback works fine in looping back a 1080I format video in SEMI PLANAR pixel format.",
        'testcaseID'   => 'fbdev_SP_0004',
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
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
        'testcaseID'     => "video_fbdev_capture_sd_twoplanes.#{@current_id}",
        'description'	=> "Fbdev Functionality test with #{get_input(params['Input_vid'])} input and #{get_output(params['Output'])} Output in #{get_out_fmt(params['Out_Fmt'])}" +
         "with the streaming in #{get_vid_plane(params['Vid_plane'])} #{get_osd(params['Vid_plane'])} OSD0 window and #{get_blend(params['Vid_plane'])}.",
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\default_test_script.rb',
        'paramsChan'   => {
            'input_vid'	=> "#{params['Input_vid']}",
            'output'	=> "#{params['Output']}",
            'in_Fmt'	=> "#{params['In_Fmt']}",
            'Out_Fmt'	=> "#{params['Out_Fmt']}",
            'vid_plane'	=> "#{params['Vid_plane']}",
            'blend_val'	=> "#{params['blend_value']}",
            'target_sources' => '',#LSP\M-Video\video\sd',
            'cmd'	=> '',#"v4l2_loop_sd -f #{params['Out_Fmt']} -i #{params['Input_vid']} -o #{params['Output']} -v #{params['Vid_plane']}",
        },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
end