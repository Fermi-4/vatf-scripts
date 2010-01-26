class I2c_func_multitaskTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'micro', 'dsp']
    @sort_by = ['microType', 'micro', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        # 'target'    => ['210_lsp'],
        # 'platform'  => ['dm355'],
        # 'os'        => ['linux'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    expect_str = "++(?i:done)--(?i:fail)|(?i:not\\s+found)"
    common_paramsChan = {
      'target_sources'  => 'LSP\st_parser',
      'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
      
      'ext'             => false,
      'bestFinal'       => false,
      'basic'           => false,
      'bft'             => false,
      'reg'             => false,
      'auto'            => true,
      'paramsControl'   => {
      },
      'paramsEquip'     => {
      },

    }
    tc = [
      {
        'description'  => "Verify that the I2C Driver can simultaneously handle Write and Read operations to the LED slave devices on the bus with default speed",
        'testcaseID'   => 'i2c_multitask_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "st_parser i2c update config 2 open ioctl 1 m_thread 2 2 2 10 5 exit exit`#{expect_str}`",
          'bootargs'    => get_bootargs(400),
        }),
      },
      {
        'description'  => "Verify that the I2C Driver can simultaneously handle Write and Read operations to the LED slave devices on the bus with another speed.",
        'testcaseID'   => 'i2c_multitask_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "st_parser i2c update config 2 open ioctl 1 m_thread 1 2 2 10 5 exit exit`#{expect_str}`",
          'bootargs'    => get_bootargs(100),
        }),
      },
      {
        'description'  => "Verify that the I2C Driver can simultaneously handle Write and Read operations to the LED slave devices on the bus with default speed",
        'testcaseID'   => 'i2c_multitask_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "st_parser i2c update config 2 open ioctl 1 m_proc 2 2 10 5 exit exit`#{expect_str}`",
          'bootargs'    => get_bootargs(400),
        }),
      },
      {
        'description'  => "Verify that the I2C Driver can simultaneously handle Write and Read operations to the LED slave devices on the bus with another speed.",
        'testcaseID'   => 'i2c_multitask_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => "st_parser i2c update config 2 open ioctl 1 m_proc 1 2 10 5 exit exit`#{expect_str}`",
          'bootargs'    => get_bootargs(100),
        }),
      },

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
    }
  end
  # END_USR_CFG get_outputs

  private
  def get_bootargs(bus_freq)
	return 'console\=ttyS0\,115200n8 noinitrd ip\=dhcp root\=/dev/nfs rw nfsroot\=${nfs_root_path}\,nolock mem\=116M' + " i2c-davinci\.i2c_davinci_busFreq\\=#{bus_freq}"
  end
  
end
