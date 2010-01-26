class Audio_func_hwTestPlan < TestPlan
 
  #  BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['block', 'mic']
    @sort_by = ['block', 'mic']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
    'block'  => ['', '-b'], 
    'mic'     => ['', '-m']
    }
  end
  # END_USR_CFG get_params
=begin
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\A-Audio\audiolb'
      'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-Audio\audio_hw.rb',
    }
    tc = [
      {
        'description'  =>  "Verify that the audio device can be opened in an asynchronous mode and record and playback using Line-in input",
        'testcaseID'   => 'audio_func_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'audiolb -s 44.1 -f 8192' 
        }),
      },
      {
        'description'  =>  "Verify that the audio device can be opened in synchronous mode and record and playback using Mic input",
        'testcaseID'   => 'audio_func_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c update iomode 1 open exit exit`++done--fail|not\s+found`' 
        }),
      },
      {
        'description'  =>  "Verify that the audio device can be opened in synchronous mode and record and playback using Line-in input",
        'testcaseID'   => 'audio_func_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c update iomode 0 open exit exit`--fail|not\s+found`' 
        }),
      },
      {
        'description'  =>  "Verify that the audio device can be opened in synchronous mode and record and playback using Mic input",
        'testcaseID'   => 'audio_func_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 1 exit exit`--fail|not\s+found`'
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
=end 
  # BEG_USR_CFG get_constraints

  def get_constraints()
    [
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    #puts params['block'].to_s
    {
      'paramsChan'     => {
        'block'    => params['block'],
        'mic'    => params['mic'],
       # 'block_desc' => get_block_desc("#{params['block']}"),
       # 'mic_desc' => get_mic_desc("#{params['mic']}"),
        #'bootargs_ext'    => "i2c-davinci\.i2c_davinci_busFreq\\=#{params['bus_speed']}",
        #'cmd'             => "audiolb -s #{params['frate']} -f #{params['fsize']} -b",
        'target_sources'  => 'LSP\A-Audio\audiolb'
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
      
      'description'    => 'Verify that the Audio OSS driver can operate in '+get_block_desc(params['block'].to_s)+' with '+get_mic_desc(params['mic'].to_s),
      'testcaseID'      => "audio_func_hw_000#{@current_id}",
      #'testcaseID'      => "i2c_func_#{params['microtype']}",
      'script'          => 'LSP\A-Audio\audio_hw.rb',
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
  end
  # END_USR_CFG get_outputs

  private
  def get_block_desc(block)
    block_desc = case block
    when '' 
      'Non Blocking mode'
    when '-b' 
      'Blocking mode'
    end
    return block_desc
  end
  def get_mic_desc(mic)
    mic_desc = case mic
    when '' 
      'Line Input'
    when '-m' 
      'Mic Input'
    end
    return mic_desc
  end
 
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
