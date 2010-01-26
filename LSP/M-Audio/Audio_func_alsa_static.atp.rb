require '../media_filer_utils'
require '../../TestPlans/LSP/M-Audio/Audio_func_common'

include MediaFilerUtils
class Audio_func_alsa_staticTestPlan < TestPlan
    include Audio_func_common
  def initialize()
    super
  end
  # BEG_USR_CFG setup
  def setup()
      @order = 2
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
      'input'  => [0, 1], # 0 - Line in, 1 - Mic in 
      'output'  => [0, 1], # 0 - Line in, 1 - Mic in 
      'srate'	=> [8000, 16000, 32000, 44100, 48000, 64000], # in Hz
      'frame_sz' => [128, 256, 512, 1024, 2048, 4096], # in bytes
      #'Vid_plane'  => [0, 1], # 0 - Video0, 1 - Video1, 2 - Both the video planes
      #'Cap_Plane'  => [0, 1], # 0 - Capture is displayed in Video0, 1 - Capture is displayed in Video1 	
      #'OSD_en'	=> [0, 1] # 0 - OSD0 is not enabled, 1 - OSD0 is enabled.
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_constraints
  def get_constraints()
      [
       'IF [input] IN {0} THEN [output] IN {0};',
       'IF [input] IN {1} THEN [output] IN {1};',
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
        'description'  =>  "Verify that the ALSA audio loopback works fine with audio driver module loaded dynamically.",
        'testcaseID'   => 'ALSA_dynamic_mod_0001',
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
        'testcaseID'     => "Audio_func_alsa.#{@current_id}",
        'description'	=> "Audio ALSA Functionality test with #{get_input(params['input'])} input and #{get_output(params['output'])} Output with a sampling rate of #{params['srate']} Hertz and frame size of #{params['frame_sz']} Bytes.",
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\M-Audio\Audio_func_static.rb',
        'paramsChan'   => {
            'input'	=> "#{params['input']}",
            'output'	=> "#{params['output']}",
            'srate'	=> "#{params['srate']}",
            'frame_sz'	=> "#{params['frame_sz']}",
            #'vid_plane'	=> "#{params['Vid_plane']}",
            'target_sources' => 'LSP/M-Audio/alsa/',
            'cmd'	=> "psp_test_bench FnTest ALSA",
        },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
end