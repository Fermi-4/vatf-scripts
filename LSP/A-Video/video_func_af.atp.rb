class Video_func_afTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  # BEG_USR_CFG setup
  def setup()
    #@group_by = ['frate']
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
    #'frate'  => ['8', '16', '32', '44.1', '48', '96'], #in kbps
    #'fsize'     => ['16', '64', '256', '1024', '4096', '8192']    # in bytes
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
      'script'      => 'LSP\default_test_script.rb',
      'auto' => true,
    }
    tc = [
      {
        'description'  =>  "Verify that the AF device can be opend and closed successfully" ,
        'testcaseID'   => 'video_func_af_0001',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 5`++Success\\s+IO--Failed\\s+IO`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF device can be opend and closed successfully 10 times" ,
        'testcaseID'   => 'video_func_af_0002',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 6`++Success\\s+IO--Failed\\s+IO`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF S_PARAM ioctl behavior. This also tests setting the parameters" +
                                     "\r\n A-Law disabled, Width and height of the paxel, Horizontal and vertical start position," +
                                     "\r\n horizontal and vertical count and horizontal and vertical line increment" +
                                     "\r\n with GR_BG_BAYER as RGB position.",
        'testcaseID'   => 'video_func_af_0003',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 1`++Success\\s+S_PARAM--Failed\\s+S_PARAM`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF G_PARAM ioctl behaviorThis also tests setting the parameters" +
                                     "\r\n A-Law enabled and horizontal median filter enabled" +
                                     "\r\n with RG_GB_BAYER as RGB position." ,
        'testcaseID'   => 'video_func_af_0004',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 2`++Success\\s+G_PARAM--Failed\\s+G_PARAM`' 
        }),
      },
      {
        'description'  =>  "Verify that the AEW_ENABLE ioctl behavior" +
                                      "\r\n with GR_GB_BAYER as RGB position. and AF mode set to Accumulator PEAK" ,
        'testcaseID'   => 'video_func_af_0005',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 3`++Success\\s+AEW_ENABLE--Failed\\s+AEW_ENABLE`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF_DISABLE ioctl behavior" ,
        'testcaseID'   => 'video_func_af_io_0006',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 4`++Success\\s+AEW_DISABLE--Failed\\s+AEW_DISABLE`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF S_PARAM ioctl handles invalid parameter as expected" ,
        'testcaseID'   => 'video_func_af_io_0007',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 3 -n 1`++Success\\s+Negative\\s+Tests--Failed\\s+Negative\\s+Tests`' 
        }),
      },
      {
        'description'  =>  "Verify that the AF S_PARAM ioctl behavior. This also tests with RB_GG_CUSTOM" +
                                      "as RGB position and in Accumulator PEAK mode.",
        'testcaseID'   => 'video_func_af_0008',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 2 -n 7`++Success\\s+S_PARAM--Failed\\s+S_PARAM`' 
        }),
      },
      {
        'description'  =>  "Verify that the AEW functionality works fine. This involves getting the" +
                                      "\r\n statistic saved in atest fine and inspected. Also this tests the behavior of AF" +
                                      "\r\n with GR_BG_BAYER as RGB position.",
        'testcaseID'   => 'video_func_af_io_0009',
        'script'      => 'LSP\video_h3a.rb',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 4 -n 1`++Success\\s+AF--Failed\\s+AF`' 
        }),
      },
      {
        'description'  =>  "Verify that the AEW functionality works fine. This involves getting the" +
                                      "\r\n statistic saved in atest fine and inspected. Also this tests the behavior of AF" +
                                      "\r\n with GG_RB_CUSTOM as RGB position in ACCUMULATOR PEAK mode.",
        'testcaseID'   => 'video_func_af_io_0010',
        'script'      => 'LSP\video_h3a.rb',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => './af_test_app -t f -c 4 -n 2`++Success\\s+AEW--Failed\\s+AEW`' 
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
=begin
      'paramsChan'     => {
        'frate'    => params['frate'],
        'fsize'    => params['fsize'],
        #'bootargs_ext'    => "i2c-davinci\.i2c_davinci_busFreq\\=#{params['bus_speed']}",
        #'cmd'             => "\./audiolb -s #{params['frate']} -f #{params['fsize']} -b",
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
      
      'description'    => "Verify that the Audio OSS driver can operate as expected in #{params['frate']} kbps and fragment size of #{params['fsize']} Bytes.",
      'testcaseID'      => "audio_func_000#{@current_id}",
      #'testcaseID'      => "i2c_func_#{params['microtype']}",
      'script'          => 'LSP\A-Audio\audio.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
=end
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
