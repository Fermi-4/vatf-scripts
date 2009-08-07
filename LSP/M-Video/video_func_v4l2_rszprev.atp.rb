require '../media_filer_utils'
require '../../TestPlans/LSP/M-Video/v4l2_func_common'

include MediaFilerUtils
class Video_func_v4l2_rszprevTestPlan < TestPlan
    include V4l2_rszprev_common
  def initialize()
    super
  end
  # BEG_USR_CFG setup
  def setup()
      @order = 5
      @group_by = ['microType', 'rsz_mode', 'input']
      @sort_by = ['microType', 'rsz_mode', 'input']
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
      'rsz_mode'=> ['otf','ss'], # otf - On the fly, ss - Single shot
      'input'  => ['NTSC', '720P', '1080I'], # 0 - Composite, 2 - 720P-60, 3 - 1080I-30
      #'input_param' => [0,2,3], # 0 - Composite, 2 - 720P-60, 3 - 1080I-30 
      'output'  => ['NTSC', '720P', '1080I'], # 0 - Composite, 2 - 720P-60, 3 - 1080I-30
      'ipipe_fmt'=> ['UYVY', 'SEMIPLANAR'], # 0 - UYVY, 1 - NV12
      #'resolution' => ['NTSC', '720P', '1080I'], # 0 - Composite, 2 - 720P-60, 3 - 1080I-30
      #'Vid_plane'  => [0, 1], # 0 - Video0, 1 - Video1, 2 - Both the video planes
      #'Cap_Plane'  => [0, 1], # 0 - Capture is displayed in Video0, 1 - Capture is displayed in Video1 	
      #'OSD_en'	=> [0, 1] # 0 - OSD0 is not enabled, 1 - OSD0 is enabled.
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_constraints
  def get_constraints()
      [
       #'IF [input] IN {2} THEN [input_param] IN {2,3};',
       #'IF [input] IN {0} THEN [] IN {6};',
      ]
  end
  # END_USR_CFG get_constraints
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
        'description'  =>  "Verify that the loopback works fine in capturing in NTSC and displaying in NTSC with the display, preview-resize and capture driver modules loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_prevrsz_mod_0001',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the loopback works fine in capturing in NTSC and displaying in 720P with the display, preview-resize and capture driver modules loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_prevrsz_mod_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the loopback works fine in capturing in NTSC and displaying in 1080I with the display, preview-resize and capture driver modules loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_prevrsz_mod_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the loopback works fine in capturing in 720P and displaying in NTSC with the display, preview-resize and capture driver modules loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_prevrsz_mod_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => ' ' #./st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify that the loopback works fine in capturing in 1080I and displaying in NTSC with the display, preview-resize and capture driver modules loaded dynamically.",
        'testcaseID'   => 'V4l2_dynamic_prevrsz_mod_0005',
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
        'testcaseID'     => "video_v4l2_ipipe.#{@current_id}",
        'description'	=> "V4L2 IPIPE Functionality test using  #{get_rsz_mode_name(params['rsz_mode'])} mode with #{params['input']} Capture format" +
        " #{params['output']} display format in #{params['ipipe_fmt']} pixel format. ",	
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\M-Video\video_func_v4l2_rszprev.rb',
        'paramsChan'   => {
            'input'	=> "#{params['input']}",
            'output'	=> "#{params['output']}",
            'rsz_mode'	=> "#{params['rsz_mode']}",
            'ipipe_fmt'	=> "#{params['ipipe_fmt']}",
            #'vid_plane'	=> "#{params['Vid_plane']}",
            'target_sources' => 'LSP\M-Video\Video\rszprev',
            'cmd'	=> "./#{get_cmd_name(params['rsz_mode'])} -i #{get_input(params['input'])} -s 0 -p 0 -f #{get_pix_fmt(params['ipipe_fmt'])} -r #{get_output(params['output'])}",
        },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
end