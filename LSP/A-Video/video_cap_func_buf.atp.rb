class Video_cap_func_bufTestPlan < TestPlan
 
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
        'description'  =>  "Verify that the Capture can setup the memory map buffer" +
                                      "This involves requesting the buffer, querying to verify the availability" +
                                      "queuing the buffer, enabling the streaming and then dequeuing the buffer and disabling the streaming and" +
                                      "unmapping the buffer",
        'testcaseID'   => 'video_func_buf_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 0 `++Success\\s+BUF--Failed\\s+BUF`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the REQ_BUF with a Invalid device type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 1 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the REQ_BUF with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 1 -i 0 -s 1`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the QUERY_BUF with a Invalid device type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 2 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the QUERY_BUF with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 2 -i 0 -s 1`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the QBUF with a Invalid device type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 3 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the QBUF with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_007',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 3 -i 0 -s 1`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the DQBUF with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_008',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 4 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the STREAMON with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_009',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 5 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
        }),
      },
      {
        'description'  =>  "Verify the behavior of the STREAMOFF with a Invalid memory type(20) value.(Negative Test)",
        'testcaseID'   => 'video_func_fmt_010',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'v4l2_cap_ioctl -o 5 -p 0 -c 0 -n 6 -i 0 -s 0`++Passed\\s+Negative\\s+Test`' 
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
