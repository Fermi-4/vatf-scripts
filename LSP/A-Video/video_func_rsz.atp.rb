class Video_func_rszTestPlan < TestPlan
 
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
        'platform' => ['dm6446'],
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
        'description'  =>  "Verify that the Resizer in DM6446 can successfully zoom in on to an input image by 2x times" +
                                     "This test also verifies the Ioctls RSZ_REQBUFS,RSZ_S_PARAMS,RSZ_QUERYBUFS" +
                                     "also mmaping the buffer for Resizer device",
        'testcaseID'   => 'video_func_rsz_0001',
        'script'      => 'LSP\A-Video\video_prev_rsz.rb',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => 'PlanarResize -o 0'#`++Passed\\s+Resizer--Failed\\s+Resize`' 
        }),
      },
      {
        'description'  =>  "Verify that the Resizer in DM6446 can successfully downscale upto 4x times and then upscale 2.5x times of an input image." ,
        'testcaseID'   => 'video_func_rsz_0002',
        'script'      => 'LSP\A-Video\video_prev_rsz.rb',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => 'YUVMultiPassResize'#`++Passed\\s+Resizer--Failed\\s+Resizer`' 
        }),
      },
      {
        'description'  =>  "Verify that the functionality of RSZ_REQBUFS with Null value(Negative test)" ,
        'testcaseID'   => 'video_func_rsz_0003',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => 'PlanarResize -o 1`++Passed\\s+Negative\\s+Tests--Failed\\s+Negative\\s+Tests`' 
        }),
      },
      {
        'description'  =>  "Verify that the functionality of PREV_QUERYBUFS with Null value(Negative test)" ,
        'testcaseID'   => 'video_func_rsz_0004',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => 'PlanarResize -o 2`++Passed\\s+Negative\\s+Tests--Failed\\s+Negative\\s+Tests`' 
        }),
      },
      {
        'description'  =>  "Verify that the functionality of RSZ_S_PARAMS with Null value(Negative test)" ,
        'testcaseID'   => 'video_func_prev_0004',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => 'PlanarResize -o 3`++Passed\\s+Negative\\s+Tests--Failed\\s+Negative\\s+Tests`' 
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
