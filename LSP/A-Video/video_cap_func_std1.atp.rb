class Video_cap_func_stdTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
    @ioctl_list = ['GET_STD', 'SET_STD']
    @std_list = ['NTSC', 'PAL', '480P', '576P', '720P-60'] +
                ['1080I-50', '1080I-60']
  end
  # END__CLASS_INIT    
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['ioctl']
    #@sort_by = ['frate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['dma'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        'platform' => ['dm355'],
        'target' => ['210_lsp'],
        'os' => ['linux'],
        'custom' => ['default']
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
    'ioctl'  => ['0', '1'], #0- Get STD, 1- Set STD
    'stds'     => ['0', '1', '2', '3', '4', '5', '6'],    # 0- NTSC, 1- PAL, 2-480P, 3-576P, 4-720P-60, 5-1080I-50, 6-1080I-60
    'ioctl_list' => @ioctl_list,
    'std_list' => @std_list,
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\A-Video\video'
      #'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-Video\video_ioctl.rb',
      'auto' => true,
    }
    tc = [
      {
        'description'  =>  "Verify that the video capture can be set to NTSC standard." +
                                      "/r/n This test verified by transmitting NTSC stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard" ,
        'testcaseID'   => 'video_func_querystd_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture can be set to PAL standard." +
                                      "/r/n This test verified by transmitting PAL stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard" ,
        'testcaseID'   => 'video_func_querystd_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture can be set to 480P standard." +
                                      "/r/n This test verified by transmitting 480P stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard" ,
        'testcaseID'   => 'video_func_querystd_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture can be set to 576P standard." +
                                      "/r/n This test verified by transmitting 576P stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard",
        'testcaseID'   => 'video_func_querystd_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture can be set to 720P-60Hz standard." +
                                      "/r/n This test verified by transmitting 720P-60Hz stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard",
        'testcaseID'   => 'video_func_querystd_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
=begin
      {
        'description'  =>  "Verify that the video capture can be set to 720P-50Hz standard." +
                                      "/r/n This test verified Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard" ,
        'testcaseID'   => 'video_func_querystd_0006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 6`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
=end
      {
        'description'  =>  "Verify that the video capture can be set to 1080I-50Hz standard." +
                                      "/r/n This test verified by transmitting 1080I-50Hz stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard",
        'testcaseID'   => 'video_func_querystd_0006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+STD--Failed\\s+STD`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture can be set to 1080I-60Hz standard." +
                                      "/r/n This test verified by transmitting 1080I-60Hz stream to the input of the DUT " +
                                      "Querying the standard, setting the standard" +
                                      "and verifying the standard that is set by getting the standard and" +
                                      "printout the standard name by enumerating the standard" ,
        'testcaseID'   => 'video_func_querystd_0007',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2`++Success\\s+INPUT--Failed\\s+INPUT`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the G_STD with a NULL parameter.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0008',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 1 -c 0``++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the ENUM_STD with a NULL parameter.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0009',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 2 -c 0``++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the SET_STD with a NULL parameter.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0010',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 3 -c 0``++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the ENUM_STD with a invalid parameter -1.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0011',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 2 -c 1`++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the ENUM_STD with a invalid parameter 0.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0012',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 2 -c 2`++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the SET_STD with a invalid parameter -1.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0013',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 3 -c 1`++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the SET_STD with a invalid parameter 0.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0014',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 3 -c 2`++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the GET_STD with a invalid parameter -1.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0015',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 1 -c 1`++Failed\\s+errno=EINVAL`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the GET_STD with a invalid parameter 0.(Negative Test)",
        'testcaseID'   => 'video_func_querystd_0016',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 2 -i 1 -c 2`++Failed\\s+errno=EINVAL`' 
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
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'ioctl'    => params['ioctl'],
        'stds'    => params['stds'],
        'ioctl_list' => param['ioctl_list'],
        'std_list' => param['std_list']
        #'bootargs_ext'    => "i2c-davinci\.i2c_davinci_busFreq\\=#{params['bus_speed']}",
        #'cmd'             => "audiolb -s #{params['frate']} -f #{params['fsize']} -b",
        #'target_sources'  => 'LSP\A-Audio\audiolb'
        #'ensure'  => ''
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify that the  OSS driver can operate as expected in #{params['frate']} kbps and fragment size of #{params['fsize']} Bytes.",
      'testcaseID'      => "audio_func_000#{@current_id}",
      #'testcaseID'      => "i2c_func_#{params['microtype']}",
      'script'          => 'LSP\A-Audio\audio.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
  end
  # END_USR_CFG get_outputs

=begin
  private
  ioctls = ['I2C_SLAVE', 'I2C_TENBIT']
  def get_ioctl_tc()
    ioctl_a = []
    id = 0
    ioctls.each do |ioctl| 
      ioctl_a <<
      {
        'description'  =>  "Verify IOCTL: #{ioctl}",
        'testcaseID'   => 'i2c_func_api_ioctl_000#{id+1}',
        'paramsChan'  => {
          'target_file' => 'i2c_test.cmd'
        }
      }
    end
    return ioctl_a
  end
=end  
end
