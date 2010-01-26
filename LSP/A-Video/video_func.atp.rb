class Video_funcTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
=begin
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['frate']
    @sort_by = ['frate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['dma'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
    'frate'  => ['8', '16', '32', '44.1', '48', '96'], #in kbps
    'fsize'     => ['16', '64', '256', '1024', '4096', '8192']    # in bytes
    }
  end
  # END_USR_CFG get_params
=end
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\A-Video\v4l2_cap_ioctl'
      #'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
    }
    tc = [
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_VIDEO_CAPTURE capability",
        'testcaseID'   => 'video_func_querycap_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 0 -i 1`++Success\\QUERYCAP--Failed\\QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_VBI_CAPTURE capability",
        'testcaseID'   => 'video_func_querycap_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 0 -i 1`++Success\\QUERYCAP--Failed\\QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_SLICED_VBI_CAPTURE capability",
        'testcaseID'   => 'video_func_querycap_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_io -o 0 -i 2`++Success\\QUERYCAP--Failed\\QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_HBI_CAPTURE capability",
        'testcaseID'   => 'video_func_querycap_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_io -o 0 -i 3`++Success\\QUERYCAP--Failed\\QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_RDS_CAPTURE capability",
        'testcaseID'   => 'video_func_querycap_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_io -o 0 -i 4`++Success\\s+QUERYCAP--Failed\\s+QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify that the video capture's supports V4L2_CAP_AUDIO capability",
        'testcaseID'   => 'video_func_querycap_0006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_io -o 0 -i 5`++Success\\QUERYCAP--Failed\\QUERYCAP`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of video capture device when qureied for NULL capture capability",
        'testcaseID'   => 'video_func_querycap_0007',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_io -o 0 -i 6`++Failed\\errno=EINVAL`' 
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
=begin
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
    }
  end
  # END_USR_CFG get_outputs
=end
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
