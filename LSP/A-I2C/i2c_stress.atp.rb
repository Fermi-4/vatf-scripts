class I2c_stressTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'bus_speed']
    @sort_by = ['microType', 'bus_speed']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
		'custom'	=> ['default'],
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'slave_device'  => ['led', 'rtc', 'ir', 'aicxx'],
      #'slave_device'  => ['led'],
      'bus_speed'     => ['100', '400'],    # in kHz
    }
  end
  # END_USR_CFG get_params

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
        'slave_device'    => params['slave_device'],
        'bootargs'    => get_bootargs(params['bus_speed']),
        'cmd'             => get_cmd(params['slave_device']),
        'target_sources'  => 'LSP\st_parser',
        'ensure'  => ''
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify that the I2C Driver can write/read the desired number of bytes to/from Slave device: #{params['slave_device']} using IOCTL commands at speed #{params['bus_speed']}KHz.",

      'testcaseID'      => "i2c_stress_#{params['slave_device']}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
      #'last'            => false,
      # 'microType'       => params['microType'],
      # 'dsp'             => params['dsp'],
      # 'micro'         => params['micro'],
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
  def get_bootargs(bus_freq)
    return 'console\=ttyS0\,115200n8 noinitrd ip\=dhcp root\=/dev/nfs rw nfsroot\=${nfs_root_path}\,nolock mem\=116M' + " i2c-davinci\.i2c_davinci_busFreq\\=#{bus_freq}"
  end

  private
  def get_cmd(slave_device)
  # 'slave_device'  => ['led', 'rtc', 'ir', 'aicxx'],
    pass_string = '(?i:done)'
    cmd = case slave_device
    when 'led' then "\./st_parser i2c update config 2 open ioctl 1 stress exit exit `++#{pass_string}--(?i:fail)|(?i:not\\s+found)`"
    when 'rtc' then "\./st_parser i2c update config 5 open ioctl 1 rtc_w rtc_r exit exit`++#{pass_string}--(?i:fail)|(?i:not\\s+found)`" 
    when 'ir' then "\./st_parser i2c update config 4 open ioctl 1 ir_a exit exit `++#{pass_string}--(?i:fail)|(?i:not\\s+found)`" 
    #cmd = './st_parser i2c update config 3 open ioctl 1 codec_oneshot 1 <codec_reg_num> <value> 2 <loop_cnt> codec_oneshot 0 <codec_reg_num> 1 1 <loop_cnt> exit exit' when 'aicxx'
    when 'aicxx' then "\./st_parser i2c update config 3 open ioctl 1 codec_oneshot 1 2 19 2 1000 codec_oneshot 0 2 1 1 1000 exit exit`++#{pass_string}--(?i:fail)|(?i:not\\s+found)`" 
    end
    return cmd
  end

end
