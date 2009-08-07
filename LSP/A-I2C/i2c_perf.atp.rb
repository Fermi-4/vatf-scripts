class I2c_perfTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
  end
  # END__CLASS_INIT 
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType']
    @sort_by = ['microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
     {
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['lld'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     },
     {
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['rtt'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     },
     {
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['server'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     }
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'buffer_size'  => ['16 32 64 128 1024'],
      'file_size'    => ['1024'], # Should use bigger value. Using small one for testing purposes
      'dev_node'     => ['/dev/i2c/0'],
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
      'description'  => "I2c Performance test.",
      'iter'         => 1,
      'bft'          => true,
      'basic'        => true,
      'ext'          => true,
      'reg'          => true,
      'auto'         => true,
      'bestFinal'    => false,
      'configID'     => '..\Config\lsp_generic.ini',
      'script'       => 'LSP\A-I2C\i2c_perf_script.rb',
      'paramsChan'   =>  {
        #'init_cmd'       => 'cat /proc/mtd`++spi_eeprom`',
        'buffer_size'    => "#{params['buffer_size']}",
        'file_size'      => "#{params['file_size']}",
        'target_sources' => 'dsppsp-validation\psp_test_bench',
        'dev_node'      => "#{params['dev_node']}",
      },
      'paramsEquip'  => {},
      'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
end
